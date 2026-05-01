#!/usr/bin/env python3
"""Read-only MCP server for Pool Stats local session data.

The server intentionally uses only the Python standard library so it can be
launched by Codex/Claude automation without installing project dependencies.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any


PROTOCOL_VERSION = "2024-11-05"
SERVER_NAME = "poolstats-readonly"
SERVER_VERSION = "0.1.0"


def default_sessions_path() -> Path:
    return Path.home() / "Library" / "Application Support" / "PoolStats" / "sessions.json"


def discover_sessions_path() -> Path:
    """Find the best local Pool Stats cache path.

    A macOS app would use ~/Library/Application Support directly, while the iOS
    simulator stores Application Support inside a changing app-container UUID.
    Prefer the newest existing cache so automation survives simulator rebuilds.
    """
    direct = default_sessions_path()
    candidates = [direct]
    simulator_root = Path.home() / "Library" / "Developer" / "CoreSimulator" / "Devices"
    if simulator_root.exists():
        candidates.extend(
            simulator_root.glob(
                "*/data/Containers/Data/Application/*/Library/Application Support/PoolStats/sessions.json"
            )
        )
    existing = [path for path in candidates if path.exists()]
    if not existing:
        return direct
    return max(existing, key=lambda path: path.stat().st_mtime)


@dataclass(frozen=True)
class DataSource:
    path: Path

    @classmethod
    def from_env(cls) -> "DataSource":
        override = os.environ.get("POOL_STATS_SESSIONS_JSON")
        return cls(Path(override).expanduser() if override else discover_sessions_path())


def parse_ts(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        timestamp = value / 1000 if value > 10_000_000_000 else value
        return datetime.fromtimestamp(timestamp, tz=timezone.utc).astimezone()
    if isinstance(value, str):
        try:
            normalized = value.replace("Z", "+00:00")
            return datetime.fromisoformat(normalized).astimezone()
        except ValueError:
            return None
    return None


def parse_date(value: Any, *, fallback: date | None = None) -> date | None:
    if not value:
        return fallback
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if isinstance(value, str):
        try:
            return date.fromisoformat(value[:10])
        except ValueError as exc:
            raise ValueError(f"Expected date as YYYY-MM-DD, got {value!r}") from exc
    raise ValueError(f"Expected date as YYYY-MM-DD, got {value!r}")


def load_sessions(source: DataSource) -> list[dict[str, Any]]:
    if not source.path.exists():
        return []
    with source.path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, list):
        raise ValueError(f"Expected top-level JSON array in {source.path}")
    sessions = [s for s in payload if isinstance(s, dict)]
    return sorted(sessions, key=lambda s: parse_ts(s.get("ts")) or datetime.min.replace(tzinfo=timezone.utc))


def session_date(session: dict[str, Any]) -> date | None:
    ts = parse_ts(session.get("ts"))
    return ts.date() if ts else None


def display_label(session: dict[str, Any]) -> str:
    label = str(session.get("label") or "").strip()
    if label:
        return label
    drill_title = str(session.get("drillTitle") or "").strip()
    if session.get("type") == "practice" and drill_title:
        return drill_title
    game = "8 ball" if session.get("game") == "8ball" else "9 ball"
    mode = "practice" if session.get("type") == "practice" else "match"
    return f"{game} {mode}"


def is_match(session: dict[str, Any]) -> bool:
    return session.get("type") == "match"


def racks(session: dict[str, Any]) -> list[dict[str, Any]]:
    raw = session.get("racks") or []
    return [r for r in raw if isinstance(r, dict)]


def int_value(value: Any) -> int:
    return value if isinstance(value, int) else 0


def unforced_errors(rack: dict[str, Any]) -> int:
    return (
        int_value(rack.get("missCount"))
        + int_value(rack.get("badPosition"))
        + int_value(rack.get("badSafety"))
        + int_value(rack.get("fouls"))
    )


def session_row(session: dict[str, Any]) -> dict[str, Any]:
    rs = racks(session)
    wins = sum(1 for r in rs if r.get("result") == "won")
    losses = sum(1 for r in rs if r.get("result") == "lost")
    dt = parse_ts(session.get("ts"))
    return {
        "id": session.get("id"),
        "sessionUUID": session.get("sessionUUID"),
        "date": dt.date().isoformat() if dt else None,
        "label": display_label(session),
        "opponent": session.get("opponent") or "",
        "game": session.get("game"),
        "type": session.get("type"),
        "racks": len(rs),
        "wins": wins,
        "losses": losses,
        "performanceRating": session.get("performanceRating"),
        "durationSeconds": session.get("durationSeconds"),
        "drillTitle": session.get("drillTitle"),
        "drillDifficulty": session.get("drillDifficulty"),
    }


def filtered_sessions(sessions: list[dict[str, Any]], args: dict[str, Any]) -> list[dict[str, Any]]:
    start = parse_date(args.get("start_date"))
    end = parse_date(args.get("end_date"))
    session_type = args.get("type")
    opponent = str(args.get("opponent") or "").strip().lower()

    result: list[dict[str, Any]] = []
    for session in sessions:
        day = session_date(session)
        if start and (not day or day < start):
            continue
        if end and (not day or day > end):
            continue
        if session_type and session.get("type") != session_type:
            continue
        if opponent and opponent not in str(session.get("opponent") or "").lower():
            continue
        result.append(session)
    return result


def summarize(sessions: list[dict[str, Any]], start: date | None, end: date | None) -> dict[str, Any]:
    match_sessions = [s for s in sessions if is_match(s)]
    match_racks = [r for s in match_sessions for r in racks(s)]
    all_racks = [r for s in sessions for r in racks(s)]
    open_racks = [r for r in match_racks if r.get("layout") == "open"]
    converted = [r for r in open_racks if r.get("outcome") == "runout"]
    wins = sum(1 for r in match_racks if r.get("result") == "won")
    losses = sum(1 for r in match_racks if r.get("result") == "lost")
    drill_attempts = [r for r in all_racks if r.get("drillOutcome")]
    drill_successes = [r for r in drill_attempts if r.get("drillOutcome") == "success"]

    error_counts = Counter()
    for r in match_racks:
        error_counts["miss"] += int_value(r.get("missCount"))
        error_counts["position"] += int_value(r.get("badPosition"))
        error_counts["safety"] += int_value(r.get("badSafety"))
        error_counts["foul"] += int_value(r.get("fouls"))

    ratings = [s.get("performanceRating") for s in sessions if isinstance(s.get("performanceRating"), int)]
    break_and_runs = sum(1 for r in match_racks if r.get("breakAndRun") is True)
    runouts = sum(1 for r in match_racks if r.get("outcome") == "runout")
    opponents = Counter(str(s.get("opponent") or "").strip() for s in match_sessions)
    opponents.pop("", None)

    return {
        "dateRange": {
            "start": start.isoformat() if start else None,
            "end": end.isoformat() if end else None,
        },
        "sessions": len(sessions),
        "matchSessions": len(match_sessions),
        "practiceSessions": len(sessions) - len(match_sessions),
        "racks": len(all_racks),
        "matchRacks": len(match_racks),
        "rackWins": wins,
        "rackLosses": losses,
        "rackWinRate": round(wins / (wins + losses) * 100, 1) if wins + losses else None,
        "openLayoutRacks": len(open_racks),
        "openLayoutConversions": len(converted),
        "conversionRate": round(len(converted) / len(open_racks) * 100, 1) if open_racks else None,
        "totalRunouts": runouts,
        "breakAndRuns": break_and_runs,
        "unforcedErrors": dict(error_counts),
        "unforcedErrorsPerMatchRack": round(sum(error_counts.values()) / len(match_racks), 2) if match_racks else None,
        "averagePerformanceRating": round(sum(ratings) / len(ratings), 1) if ratings else None,
        "drillAttempts": len(drill_attempts),
        "drillSuccesses": len(drill_successes),
        "drillSuccessRate": round(len(drill_successes) / len(drill_attempts) * 100, 1) if drill_attempts else None,
        "topOpponents": [{"name": name, "sessions": count} for name, count in opponents.most_common(5)],
        "recentSessions": [session_row(s) for s in sorted(sessions, key=lambda s: parse_ts(s.get("ts")) or datetime.min.replace(tzinfo=timezone.utc), reverse=True)[:8]],
    }


def format_summary_markdown(summary: dict[str, Any]) -> str:
    range_info = summary["dateRange"]
    title = "Pool Stats Summary"
    if range_info["start"] and range_info["end"]:
        title += f" ({range_info['start']} to {range_info['end']})"

    def pct(value: Any) -> str:
        return "n/a" if value is None else f"{value}%"

    errors = summary["unforcedErrors"]
    error_line = ", ".join(f"{name}: {count}" for name, count in errors.items()) or "none"
    sessions = summary["recentSessions"]
    recent = "\n".join(
        f"- {s['date']}: {s['label']} ({s['type']}, {s['wins']}-{s['losses']}, {s['racks']} racks)"
        for s in sessions
    ) or "- No sessions in this range."

    return "\n".join(
        [
            f"# {title}",
            "",
            f"- Sessions: {summary['sessions']} total ({summary['matchSessions']} match, {summary['practiceSessions']} practice)",
            f"- Match racks: {summary['matchRacks']} ({summary['rackWins']}-{summary['rackLosses']}, win rate {pct(summary['rackWinRate'])})",
            f"- Open-layout conversion: {summary['openLayoutConversions']}/{summary['openLayoutRacks']} ({pct(summary['conversionRate'])})",
            f"- Runouts: {summary['totalRunouts']} total, {summary['breakAndRuns']} break-and-runs",
            f"- Unforced errors: {error_line}",
            f"- Errors per match rack: {summary['unforcedErrorsPerMatchRack'] if summary['unforcedErrorsPerMatchRack'] is not None else 'n/a'}",
            f"- Average performance rating: {summary['averagePerformanceRating'] if summary['averagePerformanceRating'] is not None else 'n/a'}",
            f"- Drill attempts: {summary['drillAttempts']} ({summary['drillSuccesses']} successes, success rate {pct(summary['drillSuccessRate'])})",
            "",
            "## Recent Sessions",
            recent,
        ]
    )


def json_text(payload: Any) -> str:
    return json.dumps(payload, indent=2, sort_keys=True)


def content_text(text: str) -> dict[str, Any]:
    return {"content": [{"type": "text", "text": text}]}


def tool_definitions() -> list[dict[str, Any]]:
    date_props = {
        "start_date": {"type": "string", "description": "Inclusive start date as YYYY-MM-DD."},
        "end_date": {"type": "string", "description": "Inclusive end date as YYYY-MM-DD."},
    }
    return [
        {
            "name": "poolstats_data_status",
            "description": "Show where Pool Stats data is read from and basic cache freshness.",
            "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
        },
        {
            "name": "poolstats_list_sessions",
            "description": "List read-only Pool Stats sessions with optional date/type/opponent filters.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    **date_props,
                    "type": {"type": "string", "enum": ["match", "practice"]},
                    "opponent": {"type": "string"},
                    "limit": {"type": "integer", "minimum": 1, "maximum": 200, "default": 25},
                },
                "additionalProperties": False,
            },
        },
        {
            "name": "poolstats_summary",
            "description": "Return aggregate Pool Stats metrics for a date range.",
            "inputSchema": {
                "type": "object",
                "properties": date_props,
                "additionalProperties": False,
            },
        },
        {
            "name": "poolstats_weekly_summary",
            "description": "Generate a weekly Pool Stats summary, suitable for automation digests.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "week_start": {"type": "string", "description": "Monday/Sunday/etc. starting date as YYYY-MM-DD. Defaults to the current local week Monday."},
                    "weeks_ago": {"type": "integer", "minimum": 0, "default": 0, "description": "Use 1 for last week, 2 for two weeks ago, and so on."},
                    "format": {"type": "string", "enum": ["markdown", "json"], "default": "markdown"},
                },
                "additionalProperties": False,
            },
        },
    ]


def call_tool(name: str, args: dict[str, Any], source: DataSource) -> dict[str, Any]:
    sessions = load_sessions(source)
    if name == "poolstats_data_status":
        latest = max((dt for dt in (parse_ts(s.get("ts")) for s in sessions) if dt), default=None)
        return content_text(
            json_text(
                {
                    "path": str(source.path),
                    "exists": source.path.exists(),
                    "sessionCount": len(sessions),
                    "latestSessionDate": latest.date().isoformat() if latest else None,
                }
            )
        )

    if name == "poolstats_list_sessions":
        rows = [session_row(s) for s in filtered_sessions(sessions, args)]
        rows.sort(key=lambda row: row.get("date") or "", reverse=True)
        limit = int(args.get("limit") or 25)
        return content_text(json_text(rows[:limit]))

    if name == "poolstats_summary":
        start = parse_date(args.get("start_date"))
        end = parse_date(args.get("end_date"))
        selected = filtered_sessions(sessions, args)
        return content_text(json_text(summarize(selected, start, end)))

    if name == "poolstats_weekly_summary":
        if args.get("week_start"):
            start = parse_date(args.get("week_start"))
        else:
            today = date.today()
            start = today - timedelta(days=today.weekday())
        assert start is not None
        start = start - timedelta(weeks=int(args.get("weeks_ago") or 0))
        end = start + timedelta(days=6)
        selected = filtered_sessions(sessions, {"start_date": start.isoformat(), "end_date": end.isoformat()})
        summary = summarize(selected, start, end)
        if args.get("format") == "json":
            return content_text(json_text(summary))
        return content_text(format_summary_markdown(summary))

    raise ValueError(f"Unknown tool: {name}")


class MCPServer:
    def __init__(self, source: DataSource) -> None:
        self.source = source

    def response(self, request_id: Any, result: Any) -> dict[str, Any]:
        return {"jsonrpc": "2.0", "id": request_id, "result": result}

    def error(self, request_id: Any, code: int, message: str) -> dict[str, Any]:
        return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}

    def handle(self, message: dict[str, Any]) -> dict[str, Any] | None:
        method = message.get("method")
        request_id = message.get("id")

        if request_id is None:
            return None

        try:
            if method == "initialize":
                return self.response(
                    request_id,
                    {
                        "protocolVersion": PROTOCOL_VERSION,
                        "capabilities": {"tools": {}},
                        "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                    },
                )
            if method == "tools/list":
                return self.response(request_id, {"tools": tool_definitions()})
            if method == "tools/call":
                params = message.get("params") or {}
                name = params.get("name")
                args = params.get("arguments") or {}
                if not isinstance(args, dict):
                    raise ValueError("Tool arguments must be an object")
                return self.response(request_id, call_tool(name, args, self.source))
            return self.error(request_id, -32601, f"Method not found: {method}")
        except Exception as exc:
            return self.error(request_id, -32000, str(exc))

    def serve(self) -> None:
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            try:
                message = json.loads(line)
            except json.JSONDecodeError as exc:
                response = self.error(None, -32700, f"Parse error: {exc}")
            else:
                response = self.handle(message) if isinstance(message, dict) else self.error(None, -32600, "Invalid request")
            if response is not None:
                sys.stdout.write(json.dumps(response, separators=(",", ":")) + "\n")
                sys.stdout.flush()


def main() -> None:
    parser = argparse.ArgumentParser(description="Read-only MCP server for Pool Stats sessions.")
    parser.add_argument("--sessions-json", help="Path to sessions.json or an exported Pool Stats JSON file.")
    parser.add_argument("--status", action="store_true", help="Print data status JSON and exit.")
    args = parser.parse_args()

    source = DataSource(Path(args.sessions_json).expanduser()) if args.sessions_json else DataSource.from_env()
    if args.status:
        sessions = load_sessions(source)
        latest = max((dt for dt in (parse_ts(s.get("ts")) for s in sessions) if dt), default=None)
        print(
            json_text(
                {
                    "path": str(source.path),
                    "exists": source.path.exists(),
                    "sessionCount": len(sessions),
                    "latestSessionDate": latest.date().isoformat() if latest else None,
                }
            )
        )
        return

    MCPServer(source).serve()


if __name__ == "__main__":
    main()
