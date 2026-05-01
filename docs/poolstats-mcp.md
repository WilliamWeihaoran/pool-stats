# Pool Stats Read-Only MCP

This repo includes a small stdio MCP server for reading Pool Stats session data from the app's local JSON cache. It is read-only: it never writes to CloudKit, the app cache, or repo files.

## Data Source

By default the server reads the newest available local cache from either:

```text
~/Library/Application Support/PoolStats/sessions.json
~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Application Support/PoolStats/sessions.json
```

You can point it at another export with either `--sessions-json` or `POOL_STATS_SESSIONS_JSON`.

## Run

```bash
python3 /Users/williamwei/Desktop/Projects/pool-stats/scripts/poolstats_mcp.py
```

Quick status check:

```bash
python3 /Users/williamwei/Desktop/Projects/pool-stats/scripts/poolstats_mcp.py --status
```

## Codex Or Claude MCP Config

Add this server to the MCP client that runs your existing weekly automation:

```json
{
  "mcpServers": {
    "poolstats": {
      "command": "python3",
      "args": [
        "/Users/williamwei/Desktop/Projects/pool-stats/scripts/poolstats_mcp.py"
      ]
    }
  }
}
```

For a fixed export file instead of the app cache:

```json
{
  "mcpServers": {
    "poolstats": {
      "command": "python3",
      "args": [
        "/Users/williamwei/Desktop/Projects/pool-stats/scripts/poolstats_mcp.py",
        "--sessions-json",
        "/path/to/pool.json"
      ]
    }
  }
}
```

## Tools

- `poolstats_data_status`: source path, existence, session count, latest session date.
- `poolstats_list_sessions`: filtered session rows by date range, type, opponent, and limit.
- `poolstats_summary`: aggregate stats for any date range.
- `poolstats_weekly_summary`: markdown or JSON weekly digest for automations.

The summary logic mirrors the app's current rules:

- Match analytics ignore drill-practice sessions.
- `converted` means `outcome == "runout"`.
- Conversion rate uses only open-layout match racks as the denominator.
- Unforced errors are `missCount + badPosition + badSafety + fouls`.
