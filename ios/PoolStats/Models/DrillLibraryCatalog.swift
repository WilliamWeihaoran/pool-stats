import Foundation

enum DrillLibraryCatalog {
    static let templates: [DrillTemplate] = [
        DrillTemplate(
            id: "l_drill",
            title: "L Drill",
            kind: .staticLayout,
            pictureID: "l_drill",
            description: "Run a close-spaced L of balls into the same corner pocket while controlling short stun, follow, and draw routes.",
            primarySkills: ["Position", "Pattern", "Potting"],
            secondarySkills: ["Short routes", "Speed control", "Pocket speed"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five-ball mini L. Ball in hand only for the first shot."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven balls, about two inches apart. Any legal route is allowed."),
                DrillDifficulty(level: .standard, ballCount: 9, constraint: "Nine balls. Run the L in order into the same corner pocket."),
                DrillDifficulty(level: .hard, ballCount: 11, constraint: "Eleven balls. No bumping other balls and no ball in hand after a miss."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Full L with all fifteen balls. Call the next three cue-ball routes before shooting.")
            ],
            instructions: [
                "Build the L from the middle of one long rail toward a corner, then across the foot rail, with balls about two inches apart.",
                "Start with cue ball in hand near the first ball and pocket every ball into the same corner in numerical order.",
                "Success: clear the whole L without a miss, scratch, collision with a non-shot ball, or lost next-shot angle."
            ]
        ),
        DrillTemplate(
            id: "one_side_pattern",
            title: "Line drill",
            kind: .randomLayout,
            pictureID: "line_drill",
            description: "Pocket the selected balls from a loose table-length line while controlling speed and getting on the correct side of the next ball.",
            primarySkills: ["Pattern", "Position"],
            secondarySkills: ["Speed control", "Pattern planning", "Minimal spin"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four balls from the line. Start with ball in hand and use any pocket."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six balls. Any order, but no contact with other object balls."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight balls. Run them in numerical order with ball in hand only at the start."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten balls in order. Avoid getting frozen on a rail or another ball."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve balls in order. Call the next position side before every shot.")
            ],
            instructions: [
                "Place the balls in a loose line down the table with enough room to cue cleanly.",
                "Start with ball in hand and pocket the selected balls, using the required order for your difficulty level.",
                "Success: clear all selected balls without contacting a non-shot ball or leaving yourself unable to continue."
            ]
        ),
        DrillTemplate(
            id: "stop_shot_ladder",
            title: "Stop-shot progressive",
            kind: .staticLayout,
            pictureID: "stop_shot_ladder",
            description: "Pocket one straight-in object ball and make the cue ball stop on the object-ball contact spot from increasing distances.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Stop shot", "Speed control", "Fundamentals"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Make three clean short stop shots from one-diamond distance."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Make five stops, moving the cue ball between one and two diamonds away."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Make seven stops, increasing distance after every clean make."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Make nine stops up to side-pocket distance. Cue ball may drift less than one ball."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Make ten consecutive stops across multiple diamonds with no visible drift.")
            ],
            instructions: [
                "Place one object ball on a straight line to a pocket and align the cue ball directly behind it.",
                "Pocket the object ball and strike so the cue ball stops on the object-ball contact spot.",
                "Success: the object ball is pocketed and the cue ball has no visible follow, draw, side drift, or scratch."
            ]
        ),
        DrillTemplate(
            id: "centerline_control",
            title: "Circle control",
            kind: .randomLayout,
            pictureID: "circle_drill",
            description: "Pocket balls from a center circle while keeping the cue ball inside the circle and away from other object balls.",
            primarySkills: ["Position", "Pattern"],
            secondarySkills: ["Small-area control", "Shot selection", "Cue-ball discipline"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Pocket four balls from a large circle. Cue ball must stay inside."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Pocket six balls. Any order, any pocket, no rails after contact."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Pocket eight balls. No cue-ball exit and no contact with non-shot balls."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Pocket ten balls from a medium circle. Call the next ball before shooting."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Pocket twelve balls from a tight circle. Any cue-ball exit ends the attempt.")
            ],
            instructions: [
                "Arrange the balls in a circle near the center of the table and start with cue ball in hand inside the circle.",
                "Pocket balls in any order and into any pocket while keeping the cue ball inside the circle.",
                "Success: pocket all selected balls without a scratch, cue-ball escape, rail contact, or accidental contact with another object ball."
            ]
        ),
        DrillTemplate(
            id: "rail_avoidance",
            title: "1-10 control ladder",
            kind: .staticLayout,
            pictureID: "one_to_ten",
            description: "Pocket numbered balls from alternating side rows while moving the cue ball to the opposite side for the next shot.",
            primarySkills: ["Position", "Pattern"],
            secondarySkills: ["Distance control", "Angle control", "Route discipline"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three balls. Land anywhere behind the opposite row after each shot."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four balls. Alternate sides and keep a playable angle."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five balls. Land behind the opposite row without bumping another ball."),
                DrillDifficulty(level: .hard, ballCount: 7, constraint: "Seven balls. Use the designated corner pockets and call the cue-ball lane."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Full 1-10 pattern. Any missed position or collision ends the attempt.")
            ],
            instructions: [
                "Set odd balls in one side row and even balls in the opposite side row.",
                "Pocket each next-numbered ball into the assigned corner and send the cue ball behind the opposite row for the next shot.",
                "Success: complete the selected sequence without a missed pot, scratch, collision, or missed next-side position zone."
            ]
        ),
        DrillTemplate(
            id: "open_table_runout",
            title: "Runout drill mini",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A small progressive runout challenge: start with ball in hand, clear an open layout, then add balls as it gets easier.",
            primarySkills: ["Runout", "Pattern", "Potting"],
            secondarySkills: ["Planning", "Pattern selection", "Route discipline"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three open balls. Ball in hand before the first shot."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four open balls. Ball in hand before the first shot."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five open balls. Choose the order before shooting."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six open balls. Call the final three-ball pattern first."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven open balls. One planned route and no extra ball in hand.")
            ],
            instructions: [
                "Scatter the selected number of balls into open, runnable positions with no clusters.",
                "Take ball in hand for the first shot, choose the full pattern, and pocket every ball.",
                "Success: clear the layout without a miss, scratch, foul, or extra ball in hand."
            ]
        ),
        DrillTemplate(
            id: "cut_shot_progressive",
            title: "Cut-shot progressive",
            kind: .staticLayout,
            pictureID: "cut_progressive",
            description: "Pocket one repeatable cut shot, then increase cue-ball distance or cut angle as your aim and stroke hold up.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Aiming", "Stroke", "Pre-shot routine"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five medium cuts with ball in hand reset after every shot."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven cuts. Keep the same object ball and vary the cue-ball distance."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten cuts from alternating sides of the object ball."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve thinner cuts. No rail-first contact and no soft rolling cheats."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen cuts from both sides. Missed pot ends the set.")
            ],
            instructions: [
                "Place one object ball near a corner-pocket line and set the cue ball for a repeatable cut angle.",
                "Pocket the object ball, reset the shot, and alternate sides or distances as required by the level.",
                "Success: the object ball is pocketed cleanly with a balanced finish and no rail-first or unintended contact."
            ]
        ),
        DrillTemplate(
            id: "follow_progressive",
            title: "Follow progressive",
            kind: .staticLayout,
            pictureID: "straight_progressive",
            description: "Pocket a straight-in object ball and follow the cue ball forward into a called target zone.",
            primarySkills: ["Position", "Potting"],
            secondarySkills: ["Follow", "Speed control", "Fundamentals"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three follow shots. Cue ball must roll forward at least one diamond."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five follows to a broad forward target zone."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven follows. Increase distance after each clean result."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine follows to a narrow target lane without side spin."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten follows at varying speeds. Cue ball must finish in the called zone.")
            ],
            instructions: [
                "Set a straight-in shot and mark a forward cue-ball target zone beyond the object ball.",
                "Pocket the object ball with follow and send the cue ball forward into the called zone.",
                "Success: clean pot plus cue-ball finish in the forward target zone; wrong speed, scratch, or missed pot is a miss."
            ]
        ),
        DrillTemplate(
            id: "draw_progressive",
            title: "Draw progressive",
            kind: .staticLayout,
            pictureID: "straight_progressive",
            description: "Pocket a straight-in object ball and draw the cue ball back into a called target zone.",
            primarySkills: ["Position", "Potting"],
            secondarySkills: ["Draw", "Tip accuracy", "Speed control"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three short draw shots. Cue ball must come back at least half a diamond."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five draws from short distance into a broad target zone."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven draws. Move the cue ball farther after each clean shot."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine draws. Cue ball must return to a called one-diamond zone."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten draws across multiple distances with no miscues or rail contact.")
            ],
            instructions: [
                "Set a straight-in shot with the object ball on a pocket line and a draw target behind the cue ball.",
                "Pocket the object ball and draw the cue ball back into the called target zone.",
                "Success: clean pot plus controlled draw into the target; miscue, scratch, missed pot, or wrong distance is a miss."
            ]
        ),
        DrillTemplate(
            id: "stun_tangent_line",
            title: "Stun tangent-line drill",
            kind: .staticLayout,
            pictureID: "stun_tangent",
            description: "Pocket a cut shot with stun and send the cue ball along the natural tangent line into a called zone.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Stun", "Tangent line", "Speed control"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four stun shots to a wide tangent-line target."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six stun shots. Cue ball must cross the called side of the target."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight stun shots to alternating target zones."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten stun shots. No forward roll or draw outside the target lane."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve stun shots at varied angles with a narrow target lane.")
            ],
            instructions: [
                "Set a cut shot and place a target zone on the natural tangent-line path.",
                "Pocket the object ball with a stun stroke so the cue ball travels along the tangent line.",
                "Success: clean pot plus cue-ball path crossing or landing in the called tangent-line zone."
            ]
        ),
        DrillTemplate(
            id: "wagon_wheel",
            title: "Wagon-wheel position",
            kind: .staticLayout,
            pictureID: "wagon_wheel",
            description: "A classic cue-ball direction drill: pocket one object ball while sending the cue ball to different spoke-like target zones.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Cue-ball direction", "Speed control", "Route selection"],
            countUnit: .targets,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four wide target zones around the table."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six targets. Use any natural follow, stun, or draw route."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight targets. Call the cue-ball route before shooting."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten targets. Avoid side spin unless the route requires it."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve targets. Land within one ball width of each called zone.")
            ],
            instructions: [
                "Keep one object ball in the same pocketable position and choose a different cue-ball target for each rep.",
                "Pocket the object ball and use follow, stun, or draw to send the cue ball to the called spoke target.",
                "Success: clean pot plus cue-ball finish in the called target area without a scratch or extra-ball contact."
            ]
        ),
        DrillTemplate(
            id: "target_pool",
            title: "Target-pool position",
            kind: .staticLayout,
            pictureID: "target_pool",
            description: "A target-practice position drill based on BU/Dr. Dave target-pool work: pocket the object ball and land the cue ball in a marked zone.",
            primarySkills: ["Position", "Pattern"],
            secondarySkills: ["Speed control", "Target zones", "Cue-ball discipline"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four shots to a large target zone."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six shots. Cue ball must finish inside a hand-span target."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight shots to alternating target zones."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten shots. Target is about one-diamond wide."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve shots. Target is about one ball-width plus margin.")
            ],
            instructions: [
                "Place a paper target, coin, or chalk outline where you want the cue ball to finish.",
                "Pocket the object ball and play position to the target.",
                "Success: clean pot plus cue-ball finish inside the target zone; missed pot, scratch, or missed zone fails the rep."
            ]
        ),
        DrillTemplate(
            id: "rail_cut_progressive",
            title: "Rail-cut progressive",
            kind: .staticLayout,
            pictureID: "rail_cut",
            description: "A rail-cut drill from the BU skills family for pocketing balls near the rail while controlling cue-ball position.",
            primarySkills: ["Potting", "Position"],
            secondarySkills: ["Rail cuts", "Aiming", "Position speed"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four easy rail cuts from short distance."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six rail cuts. Cue ball must stay off the rail after contact."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight rail cuts alternating left and right sides."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten thin rail cuts with a called cue-ball finish side."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve rail cuts from distance. Missed pot ends the set.")
            ],
            instructions: [
                "Place the object ball a few inches off the long rail and choose the called corner pocket.",
                "Pocket the rail cut, reset the shot, and alternate cue-ball side or distance as required.",
                "Success: cleanly pocket the rail ball and leave a playable cue-ball finish."
            ]
        ),
        DrillTemplate(
            id: "spot_shot_challenge",
            title: "Spot-shot challenge",
            kind: .staticLayout,
            pictureID: "spot_shot",
            description: "A standard shot-making challenge: shoot repeated spot shots and track how many you pocket cleanly.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Aiming", "Stroke", "Routine"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five spot shots with cue ball in hand behind the head string."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven spot shots. Use the same cue-ball starting area."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten spot shots. Alternate left and right cue-ball positions."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve spot shots from a fixed cue-ball position."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen spot shots. Track streaks and misses.")
            ],
            instructions: [
                "Place the object ball on the foot spot and put the cue ball behind the head string.",
                "Shoot the spot shot into the called corner pocket, resetting after every shot.",
                "Success: the object ball is pocketed cleanly; missed pot, scratch, or wrong pocket is a miss."
            ]
        ),
        DrillTemplate(
            id: "long_straight_in",
            title: "Long straight-in",
            kind: .staticLayout,
            pictureID: "straight_progressive",
            description: "Pocket long straight-in shots while keeping the cue ball on the shot line after contact.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Stroke", "Alignment", "Quiet finish"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four medium-distance straight shots."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six straight shots from half-table distance."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight long straight shots. Cue ball should stop or follow straight."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten long shots. No side drift after contact."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve full-table shots. Any unintended side spin counts as a miss.")
            ],
            instructions: [
                "Set the cue ball, object ball, and pocket on one straight line.",
                "Pocket the object ball with a smooth, centered stroke.",
                "Success: clean pot with the cue ball stopping, following, or drawing straight on the shot line with no side drift."
            ]
        ),
        DrillTemplate(
            id: "thin_cut_ladder",
            title: "Thin-cut ladder",
            kind: .staticLayout,
            pictureID: "cut_progressive",
            description: "Pocket progressively thinner cut shots while preserving a repeatable stroke and realistic pocket speed.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Thin cuts", "Aiming", "Speed choice"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four modest cuts; move thinner only after a make."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six cuts with a slightly thinner angle each make."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight cuts, alternating left and right."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten thin cuts; no rail-first contact unless called."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve thin cuts from distance. Miss resets the angle.")
            ],
            instructions: [
                "Start with a comfortable cut into a called pocket.",
                "Pocket the object ball, then move the cue ball to create a thinner cut after each clean make.",
                "Success: clean pot at the called angle with realistic speed; missed pot, rail-first contact, or over-hit speed fails the rep."
            ]
        ),
        DrillTemplate(
            id: "back_cut_ladder",
            title: "Back-cut ladder",
            kind: .staticLayout,
            pictureID: "cut_progressive",
            description: "Pocket back cuts while controlling the cue-ball route away from scratch lines and traffic.",
            primarySkills: ["Potting", "Position"],
            secondarySkills: ["Back cuts", "Cue-ball route", "Pocket speed"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four short back cuts with ball in hand reset."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six back cuts. Cue ball must avoid the scratch path."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight back cuts alternating sides."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten back cuts with a called cue-ball path."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve back cuts from distance. Missed route counts as a miss.")
            ],
            instructions: [
                "Place the object ball near a pocket line where the cue ball must cut it backward into the pocket.",
                "Pocket the back cut and send the cue ball on the planned route away from the scratch line.",
                "Success: clean pot plus a cue-ball route that leaves a playable next shot."
            ]
        ),
        DrillTemplate(
            id: "no_rail_pattern",
            title: "No-rail pattern",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A Dr. Dave cue-ball-control style pattern drill: run an open layout while avoiding rail contact with the cue ball.",
            primarySkills: ["Pattern", "Position"],
            secondarySkills: ["Small routes", "Speed control", "Planning"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three open balls. Cue ball may not contact a rail."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four balls. No cue-ball rail contact after the first shot."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five balls. No rail contact and no accidental object-ball contact."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six balls. Call the full route before shooting."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven balls. Any rail contact ends the attempt.")
            ],
            instructions: [
                "Scatter a small open layout where every selected ball has a reasonable pocket.",
                "Take ball in hand first and pocket the balls in your chosen order without sending the cue ball to a rail.",
                "Success: clear all selected balls with no cue-ball rail contact, scratch, foul, or accidental object-ball contact."
            ]
        ),
        DrillTemplate(
            id: "three_ball_ghost",
            title: "3-ball ghost",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A simple ghost drill: scatter three balls, take ball in hand, and try to run out before the ghost gets the rack.",
            primarySkills: ["Runout", "Pattern", "Potting"],
            secondarySkills: ["Planning", "Confidence", "Open-table routes"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three open balls. Any order."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four open balls. Any order."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five open balls. Choose the order before shooting."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six open balls. No clusters and no second ball in hand."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven open balls. Call the pattern before shooting.")
            ],
            instructions: [
                "Scatter the selected number of balls in open positions.",
                "Take ball in hand and pocket every ball in any order.",
                "Success: full runout before any miss, scratch, or foul; any failure gives the rack to the ghost."
            ]
        ),
        DrillTemplate(
            id: "nine_ball_ghost",
            title: "9-ball ghost mini",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A rotation-style ghost drill: run a small set in numerical order from ball in hand.",
            primarySkills: ["Runout", "Pattern", "Position"],
            secondarySkills: ["Rotation routes", "Planning", "Shot selection"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three-ball rotation from ball in hand."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four-ball rotation from ball in hand."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five-ball rotation. No extra ball in hand."),
                DrillDifficulty(level: .hard, ballCount: 7, constraint: "Seven-ball rotation. Call the next two routes."),
                DrillDifficulty(level: .expert, ballCount: 9, constraint: "Full nine-ball ghost. Any miss gives the rack to the ghost.")
            ],
            instructions: [
                "Scatter the selected number of balls and identify the lowest-numbered ball.",
                "Take ball in hand and pocket the balls in numerical rotation order.",
                "Success: clear the set in order before any miss, scratch, foul, or illegal first contact."
            ]
        ),
        DrillTemplate(
            id: "eight_ball_pattern",
            title: "8-ball pattern mini",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A small 8-ball pattern drill for choosing a group, clearing problem balls, and saving a key ball for shape.",
            primarySkills: ["Pattern", "Runout", "Position"],
            secondarySkills: ["Key ball", "Problem solving", "Route discipline"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four balls from one group plus an easy 8-ball finish."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five balls. Choose a key ball for the 8 before shooting."),
                DrillDifficulty(level: .standard, ballCount: 6, constraint: "Six balls. Identify and solve the problem ball early."),
                DrillDifficulty(level: .hard, ballCount: 7, constraint: "Seven balls. Call the full pattern before the first shot."),
                DrillDifficulty(level: .expert, ballCount: 8, constraint: "Full group plus 8. No second ball in hand.")
            ],
            instructions: [
                "Lay out one group of balls plus the 8 in open but realistic positions.",
                "Choose a key ball for the 8, then pocket the group and finish by pocketing the 8.",
                "Success: clear the group and pocket the 8 without losing key-ball shape, missing, scratching, or fouling."
            ]
        ),
        DrillTemplate(
            id: "placement_pool_challenge",
            title: "Placement challenge",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A PPC-inspired pattern challenge: try a sequence of preset runnable layouts and count how many balls are cleared.",
            primarySkills: ["Runout", "Pattern", "Position"],
            secondarySkills: ["Layout reading", "Problem solving", "Scoring"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three-ball placement layouts."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four-ball placement layouts."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five-ball placement layouts with one required route."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six-ball layouts. Miss or foul ends the attempt."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven-ball layouts with planned key-ball position.")
            ],
            instructions: [
                "Create a small preset layout rather than a random scatter.",
                "Take ball in hand, call the full pattern, and pocket balls in that pattern.",
                "Score: count balls cleared before the first miss, scratch, foul, or pattern breakdown."
            ]
        ),
        DrillTemplate(
            id: "rds_break_run",
            title: "RDS break-and-run",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A Runout Drill System inspired challenge: use break-and-run style layouts that increase in difficulty as you improve.",
            primarySkills: ["Runout", "Pattern", "Potting"],
            secondarySkills: ["Break transition", "Planning", "Pressure"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three-ball runout after a controlled spread."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four-ball runout. Ball in hand after the simulated break."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five-ball runout from an open break-like layout."),
                DrillDifficulty(level: .hard, ballCount: 7, constraint: "Seven-ball runout with one awkward transition."),
                DrillDifficulty(level: .expert, ballCount: 9, constraint: "Nine-ball runout. Miss, scratch, or foul ends the rack.")
            ],
            instructions: [
                "Create an open break-like layout with no frozen clusters.",
                "Start from ball in hand or the cue-ball position after a controlled break and pocket the balls in the chosen game order.",
                "Success: clear the selected layout without a miss, scratch, foul, or second ball in hand."
            ]
        ),
        DrillTemplate(
            id: "equal_offense",
            title: "Equal Offense",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A classic scoring drill: spread balls, take ball in hand, and score how many you can legally pocket in a turn.",
            primarySkills: ["Runout", "Potting", "Pattern"],
            secondarySkills: ["Straight-pool scoring", "Shot selection", "Pressure"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five-ball rack. Count balls made before the first miss."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven-ball rack. Start with ball in hand."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten-ball rack. Any miss ends the inning."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve-ball rack. Call pockets and avoid clusters."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen-ball rack. Score balls made before the first miss.")
            ],
            instructions: [
                "Spread the balls in open positions and start with ball in hand.",
                "Pocket any legal ball and continue until the inning ends.",
                "Score: count legal balls pocketed before the first miss, scratch, foul, or illegal shot."
            ]
        ),
        DrillTemplate(
            id: "fargo_rotation",
            title: "Fargo rotation drill",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A rotation rating drill inspired by Dr. Dave's rating-drill list: shoot balls in order and count legal balls pocketed.",
            primarySkills: ["Runout", "Potting", "Position"],
            secondarySkills: ["Rotation", "Scoring", "Cue-ball control"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five-ball rotation set."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven-ball rotation set."),
                DrillDifficulty(level: .standard, ballCount: 9, constraint: "Nine-ball rotation set."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve-ball rotation set."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen-ball rotation set. Play balls in numerical order.")
            ],
            instructions: [
                "Scatter the selected number of balls and start with ball in hand.",
                "Pocket the lowest-numbered ball first and continue in rotation order.",
                "Score: count legal balls pocketed in order before the first miss, scratch, foul, or illegal first contact."
            ]
        ),
        DrillTemplate(
            id: "fifteen_ball_rotation",
            title: "15-ball rotation",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A full-table rotation workout for planning, endurance, and precise cue-ball movement through many transitions.",
            primarySkills: ["Runout", "Pattern", "Position"],
            secondarySkills: ["Rotation order", "Endurance", "Recovery shots"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 6, constraint: "Six-ball rotation subset."),
                DrillDifficulty(level: .easy, ballCount: 8, constraint: "Eight-ball rotation subset."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten-ball rotation subset."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve-ball rotation subset."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Full fifteen-ball rotation. Miss or foul ends the run.")
            ],
            instructions: [
                "Scatter or rack the selected balls and start with ball in hand.",
                "Pocket balls in numerical rotation order.",
                "Score: count legal balls pocketed before the first miss, scratch, foul, or illegal first contact."
            ]
        ),
        DrillTemplate(
            id: "hopkins_q_skills",
            title: "Hopkins Q Skills",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "A Q Skills style scoring drill: start with ball in hand and score your open-table run before the inning ends.",
            primarySkills: ["Runout", "Potting", "Pattern"],
            secondarySkills: ["Scoring", "Consistency", "Shot choice"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five balls. Score balls made before a miss."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven balls. Start with ball in hand."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten balls. Call pockets and track the run."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve balls. Avoid unnecessary traffic and clusters."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen balls. Score the inning before the first miss.")
            ],
            instructions: [
                "Spread the balls and take ball in hand.",
                "Pocket any legal ball and continue your run until the inning ends.",
                "Score: count balls pocketed before the first miss, scratch, foul, or illegal shot."
            ]
        ),
        DrillTemplate(
            id: "one_rail_kick",
            title: "One-rail kick ladder",
            kind: .staticLayout,
            pictureID: "kick_bank",
            description: "Contact the object ball by kicking one rail from progressively harder cue-ball positions; pocketing is optional unless called.",
            primarySkills: ["Overall", "Position"],
            secondarySkills: ["Kicks", "Rail systems", "Speed"],
            countUnit: .kicks,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three one-rail kicks to a large contact zone."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five one-rail kicks. Object-ball contact is required."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven kicks. Call the rail and object-ball contact side."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine kicks with smaller cue-ball windows."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten kicks. Contact plus called safety side is required.")
            ],
            instructions: [
                "Place an object ball in a repeatable position and move the cue ball to create one-rail kick routes.",
                "Call the rail first, then kick one rail to contact the object ball; do not require a pot unless you call one.",
                "Success: legal object-ball contact on the called side, plus any called safety or pocketing requirement for the level."
            ]
        ),
        DrillTemplate(
            id: "cross_side_bank",
            title: "Cross-side bank ladder",
            kind: .staticLayout,
            pictureID: "kick_bank",
            description: "A bank-shot ladder for learning speed, angle, and pocket adjustment on cross-side banks.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Banks", "Speed", "Rail angle"],
            countUnit: .banks,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three short cross-side banks."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five banks from comfortable angles."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven banks. Alternate left and right cross-side routes."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine banks from distance. Call speed and pocket."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten banks with no second chances after a miss.")
            ],
            instructions: [
                "Place the object ball near a side-pocket bank angle.",
                "Bank the object ball cross-side into the called side pocket and reset after each shot.",
                "Success: the banked object ball is pocketed cleanly in the called side pocket."
            ]
        ),
        DrillTemplate(
            id: "safety_hide",
            title: "Hide-the-ball safety",
            kind: .staticLayout,
            pictureID: "target_pool",
            description: "Play a legal safety: contact the object ball and hide either the cue ball or object ball from a direct makeable shot.",
            primarySkills: ["Overall", "Position"],
            secondarySkills: ["Safety", "Speed control", "Cue-ball path"],
            countUnit: .safeties,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three safeties to a broad hiding zone."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five safeties. Cue ball must finish behind the blocker."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven safeties. Object ball must also move to a safe distance."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine safeties with a narrow hiding lane."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten safeties. Full-ball hide required after legal contact.")
            ],
            instructions: [
                "Place an object ball, cue ball, and blocker ball to create a realistic safety.",
                "Make legal contact and send the cue ball or object ball behind the blocker or into the called safe zone.",
                "Success: the incoming player has no direct makeable shot; pocketing the object ball is not the goal unless specifically called."
            ]
        ),
        DrillTemplate(
            id: "break_control",
            title: "Break control",
            kind: .staticLayout,
            pictureID: "break_control",
            description: "Break normally and evaluate cue-ball control, balls pocketed, scratch avoidance, and whether the rack opens cleanly.",
            primarySkills: ["Overall", "Runout"],
            secondarySkills: ["Break", "Cue-ball control", "Opening layout"],
            countUnit: .breaks,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five controlled breaks. Keep cue ball on the table."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven breaks. Make legal contact and avoid scratches."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten breaks. Track pocketed balls and cue-ball center-table control."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve breaks. Cue ball must finish in the middle half of the table."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen breaks. Pocket a ball, avoid scratch, and leave an open starter.")
            ],
            instructions: [
                "Rack normally for the game you are practicing.",
                "Break with cue-ball control as the first goal and power as the second goal.",
                "Success: legal break, no scratch, controlled cue-ball finish, and either a pocketed ball or a realistic opening shot."
            ]
        ),
        DrillTemplate(
            id: "center_ball_stroke",
            title: "Center-ball stroke",
            kind: .staticLayout,
            pictureID: "straight_progressive",
            description: "A center-ball stroke drill inspired by Dr. Dave's center-ball stroke resources: pocket straight shots without unintended side spin.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Center ball", "Stroke", "Alignment"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five center-ball shots from short distance."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven shots. Cue ball must stay on the shot line."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten shots. No visible left/right cue-ball drift."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve shots from longer distance."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen shots. Any unintended side spin resets the set.")
            ],
            instructions: [
                "Set up a straight-in shot and aim with center cue-ball contact.",
                "Pocket the object ball with a center-ball stroke and watch the cue ball after contact.",
                "Success: clean pot with the cue ball staying on the shot line; left/right drift means alignment or stroke error."
            ]
        ),
        DrillTemplate(
            id: "side_spin_ladder",
            title: "Sidespin ladder",
            kind: .staticLayout,
            pictureID: "target_pool",
            description: "A controlled sidespin drill: use measured side only when needed and land the cue ball in a called zone.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Sidespin", "Speed", "Deflection awareness"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three shots with small outside spin to a large zone."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five shots alternating inside and outside spin."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven shots. Call spin direction and target zone."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine shots with thinner cuts and smaller target zones."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten shots. Land in the called zone despite spin throw and deflection.")
            ],
            instructions: [
                "Set a repeatable cut shot with a cue-ball target zone.",
                "Call inside or outside spin, pocket the object ball, and send the cue ball to the target zone.",
                "Success: clean pot plus called spin effect and cue-ball finish inside the target zone."
            ]
        ),
        DrillTemplate(
            id: "carom_touch",
            title: "Carom touch drill",
            kind: .staticLayout,
            pictureID: "target_pool",
            description: "Carom the cue ball or first object ball into a called target ball; pocketing is optional unless you call it.",
            primarySkills: ["Overall", "Position"],
            secondarySkills: ["Carom", "Contact point", "Speed"],
            countUnit: .caroms,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three short caroms to a large target ball."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five caroms. Legal first-ball contact and target contact required."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven caroms. Call the target contact side."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine caroms with smaller target windows."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten caroms. Contact and final cue-ball control both count.")
            ],
            instructions: [
                "Place two object balls so the cue ball or first object ball can carom into the called target ball.",
                "Call the first contact and target-ball contact before shooting; pocketing is optional only if you call it.",
                "Success: the called carom contacts the target ball with controlled speed; missed contact or wrong first contact fails the rep."
            ]
        ),
        DrillTemplate(
            id: "jump_escape_basic",
            title: "Jump escape basics",
            kind: .staticLayout,
            pictureID: "kick_bank",
            description: "Jump safely over a blocker to make legal object-ball contact; pocketing is optional unless you call it.",
            primarySkills: ["Overall"],
            secondarySkills: ["Jump", "Obstacle clearance", "Cue-ball control"],
            countUnit: .jumps,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three short jump contacts over a low obstacle gap."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five jumps. Contact the object ball legally."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven jumps. Call the target side of the object ball."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine jumps with smaller landing windows."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten jumps. Legal contact plus safe cue-ball landing required.")
            ],
            instructions: [
                "Use a legal jump cue and practice only on equipment where jumps are permitted.",
                "Place a blocker between cue ball and object ball, then jump to make legal object-ball contact.",
                "Success: clear the blocker safely, make legal contact, and land the cue ball under control; pocketing is optional unless called."
            ]
        ),

        DrillTemplate(
            id: "t_drill",
            title: "T Drill",
            kind: .staticLayout,
            pictureID: "t_drill",
            description: "Run a T-shaped layout in numerical order without letting the cue ball or object balls disturb the remaining balls.",
            primarySkills: ["Pattern", "Position", "Potting"],
            secondarySkills: ["Traffic control", "Numerical order", "Soft routes"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five-ball mini T. Ball in hand for the first shot."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven balls. Run in order without bumping another ball."),
                DrillDifficulty(level: .standard, ballCount: 9, constraint: "Nine-ball T. Call the next position side before each shot."),
                DrillDifficulty(level: .hard, ballCount: 11, constraint: "Eleven balls. No collisions and no cue ball frozen to a rail."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Full T. Run in order with no ball in hand after the opening shot.")
            ],
            instructions: [
                "Arrange the balls in a T shape, with the stem pointing toward the lower half of the table.",
                "Start with ball in hand and pocket the balls in numerical order.",
                "Success: clear the selected T without a miss, scratch, collision with a non-shot ball, or lost next-shot angle."
            ]
        ),
        DrillTemplate(
            id: "down_rail_drill",
            title: "Down-the-rail drill",
            kind: .staticLayout,
            pictureID: "down_rail",
            description: "Run balls set along one long rail in order while using draw/follow and side spin to avoid the side-pocket scratch.",
            primarySkills: ["Position", "Pattern", "Potting"],
            secondarySkills: ["Rail work", "English", "Scratch avoidance"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four rail balls. Ball in hand on the first shot."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six balls. Run in order and avoid the side-pocket scratch path."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight balls. Use the same corner-pocket direction for the full set."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten balls. Alternate draw/right and follow/left routes between attempts."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Full rail. No scratches, no rail-frozen cue ball, and no second ball in hand.")
            ],
            instructions: [
                "Place the balls in numerical order along one long rail with enough room to cue cleanly.",
                "Pocket them in order, using draw, follow, and side spin to keep the cue ball out of the side pocket.",
                "Success: clear the rail sequence without a missed pot, scratch, or position that leaves no realistic next shot."
            ]
        ),
        DrillTemplate(
            id: "spot_rotation_drill",
            title: "Spot rotation drill",
            kind: .staticLayout,
            pictureID: "spot_drill",
            description: "A spot-drill variation: pocket diagonal shots in rotation order without missing or touching non-shot balls.",
            primarySkills: ["Potting", "Position", "Pattern"],
            secondarySkills: ["Diagonal cuts", "Rotation", "Rail avoidance"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three diagonal shots with ball in hand to start."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five balls in rotation order."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven balls. Do not contact any non-shot ball."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine balls. Avoid leaving the cue ball frozen to a rail."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten balls. Run the full sequence with no extra ball in hand.")
            ],
            instructions: [
                "Place the first object ball on or near the spot and set the cue ball diagonally from it.",
                "Pocket into the diagonal corner and continue through the remaining balls in rotation order.",
                "Success: clear the selected sequence without a miss, scratch, or accidental contact with another object ball."
            ]
        ),
        DrillTemplate(
            id: "inside_outside_english",
            title: "Inside-outside English",
            kind: .staticLayout,
            pictureID: "inside_outside_english",
            description: "Pocket balls in rotation from diagonal rail-side positions while alternating inside and outside English routes.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Inside English", "Outside English", "Spin control"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three shots with a large cue-ball target lane."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five shots alternating inside and outside English."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven shots. Call the spin before each stroke."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine shots with thinner cuts and a smaller target lane."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten shots. Pocket the ball and land on the called side of the table.")
            ],
            instructions: [
                "Set the balls on diagonal rail-side positions and begin with the cue ball in front of the first ball.",
                "Pocket the sequence in order, alternating inside and outside English routes across the table.",
                "Success: clean pot on each shot plus cue-ball finish in the called lane."
            ]
        ),
        DrillTemplate(
            id: "side_pocket_cut_ladder",
            title: "Side-pocket cut ladder",
            kind: .staticLayout,
            pictureID: "side_pocket_cut",
            description: "Practice thin side-pocket cuts where the cue ball travels down-table after contact instead of dying near the side pocket.",
            primarySkills: ["Potting", "Position"],
            secondarySkills: ["Side-pocket cuts", "Long cue-ball travel", "Speed"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three comfortable side-pocket cuts."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five cuts. Cue ball must reach the lower half of the table."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven thin cuts with a called down-table lane."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine cuts. Cue ball must reach the short rail or called zone."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten cuts from distance. Pocket speed and position both count.")
            ],
            instructions: [
                "Place the object ball for a side-pocket cut and put the cue ball far enough away that speed control matters.",
                "Pocket the object ball into the side pocket and send the cue ball down-table to the called lane.",
                "Success: clean side-pocket pot plus cue-ball finish in the called down-table lane."
            ]
        ),
        DrillTemplate(
            id: "brainwashing_no_rail",
            title: "Brainwashing no-rail",
            kind: .randomLayout,
            pictureID: "brainwashing",
            description: "A no-rail pattern drill for stun, draw, and small cue-ball routes: clear the balls without the cue ball touching a cushion.",
            primarySkills: ["Pattern", "Position"],
            secondarySkills: ["No-rail control", "Stun", "Draw"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three open balls. Cue ball may not touch a rail."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four balls. Use mostly stun and draw routes."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five balls. Call the order before shooting."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six balls. Any rail contact ends the attempt."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven balls with no rail contact and no accidental object-ball contact.")
            ],
            instructions: [
                "Lay out a small open pattern in the middle of the table.",
                "Pocket every selected ball without allowing the cue ball to touch a rail.",
                "Success: clear the pattern with no cue-ball rail contact, scratch, foul, or accidental object-ball contact."
            ]
        ),
        DrillTemplate(
            id: "ghost_ball_aiming",
            title: "Ghost-ball aiming",
            kind: .staticLayout,
            pictureID: "ghost_ball_aiming",
            description: "A fundamentals aiming drill: visualize the ghost-ball contact point, pocket the object ball, and reset the same shot.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Aiming", "Alignment", "Stroke"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five medium cuts with a large visualized contact point."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven cuts from two cue-ball positions."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten cuts alternating left and right sides."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve thinner cuts. No steering after the final warmup stroke."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen cuts from distance. Missed pot ends the set.")
            ],
            instructions: [
                "Place one object ball on a repeatable cut-shot line to a corner pocket.",
                "Visualize the ghost-ball contact point, then pocket the object ball and reset the shot.",
                "Success: clean pot in the called pocket with no steering or rushed stroke."
            ]
        ),
        DrillTemplate(
            id: "vision_center_alignment",
            title: "Vision-center alignment",
            kind: .staticLayout,
            pictureID: "straight_progressive",
            description: "An alignment drill inspired by vision-center work: shoot straight shots and watch whether the cue ball stays on line.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Alignment", "Vision center", "Stroke"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 5, constraint: "Five short straight shots."),
                DrillDifficulty(level: .easy, ballCount: 7, constraint: "Seven straight shots from medium distance."),
                DrillDifficulty(level: .standard, ballCount: 10, constraint: "Ten shots. Cue ball must stay on the center line after contact."),
                DrillDifficulty(level: .hard, ballCount: 12, constraint: "Twelve longer shots with no visible side drift."),
                DrillDifficulty(level: .expert, ballCount: 15, constraint: "Fifteen full-table alignment checks. Any side spin resets the set.")
            ],
            instructions: [
                "Set a straight-in shot with the cue ball, object ball, and pocket on one line.",
                "Use the same stance and head position each time, then pocket the object ball with center-ball contact.",
                "Success: clean pot with the cue ball staying on the shot line; side drift means the alignment check failed."
            ]
        ),
        DrillTemplate(
            id: "up_down_speed_control",
            title: "Up-and-down speed",
            kind: .staticLayout,
            pictureID: "up_down_speed",
            description: "A cue-ball-only speed drill: lag up and down the table to finish in progressively smaller end zones.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Speed control", "Lag speed", "Touch"],
            countUnit: .lags,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four lags to a broad end zone."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six lags. Cue ball must finish within two diamonds."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight lags to alternating end zones."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten lags. Target is one diamond deep."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve lags. Finish within a narrow rail-side strip without touching the pocket points.")
            ],
            instructions: [
                "Start with only the cue ball near one short rail; there is no object ball to pocket in this drill.",
                "Lag the cue ball to the far end zone, then alternate back to the opposite end zone on the next rep.",
                "Success: the cue ball comes to rest inside the called zone without overrun, underrun, pocket contact, or cushion-point contact."
            ]
        ),
        DrillTemplate(
            id: "cross_line_speed",
            title: "Cross-line speed",
            kind: .staticLayout,
            pictureID: "cross_line_control",
            description: "A cue-ball-only speed drill: roll across a chosen line and stop in the called lane beyond it.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Speed", "Line control", "Touch"],
            countUnit: .attempts,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four attempts to cross a wide center line."),
                DrillDifficulty(level: .easy, ballCount: 6, constraint: "Six attempts. Stop in the called half of the table."),
                DrillDifficulty(level: .standard, ballCount: 8, constraint: "Eight attempts to alternating target lanes."),
                DrillDifficulty(level: .hard, ballCount: 10, constraint: "Ten attempts. Target lane is one diamond wide."),
                DrillDifficulty(level: .expert, ballCount: 12, constraint: "Twelve attempts. Stop within a narrow lane after crossing the line.")
            ],
            instructions: [
                "Start with only the cue ball and choose a cross-table line plus a target lane beyond it.",
                "Roll the cue ball across the line and stop it in the called lane.",
                "Success: the cue ball crosses the line and comes to rest inside the called lane; there is no object ball to pocket."
            ]
        ),
        DrillTemplate(
            id: "clock_system_spin",
            title: "Clock-system spin",
            kind: .staticLayout,
            pictureID: "clock_system",
            description: "Pocket a repeatable cut shot while calling the cue-tip clock position and cue-ball finish zone.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Clock system", "Sidespin", "Cue tip accuracy"],
            countUnit: .reps,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three reps using small 10 or 2 o'clock side."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five reps alternating left and right side."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven reps. Call the clock point and finish zone."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine reps with smaller finish zones."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten reps using multiple clock points with no miscues or over-spin.")
            ],
            instructions: [
                "Set a repeatable cut shot with a cue-ball finish zone.",
                "Call the cue-tip clock position, pocket the object ball, and send the cue ball to the matching finish zone.",
                "Success: clean pot plus the called cue-ball spin effect and finish zone."
            ]
        ),
        DrillTemplate(
            id: "gearing_outside_spin",
            title: "Gearing outside spin",
            kind: .staticLayout,
            pictureID: "gearing_outside",
            description: "Pocket a cut shot with outside English to reduce throw while still sending the cue ball through a called route.",
            primarySkills: ["Potting", "Position"],
            secondarySkills: ["Outside English", "Throw control", "Deflection awareness"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three medium cuts with small outside spin."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five cuts. Pocket speed must stay controlled."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven cuts alternating left and right outside English."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine thinner cuts with a called cue-ball lane."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten cuts. Match outside spin without over-cutting or over-running shape.")
            ],
            instructions: [
                "Set one cut shot that can be repeated from both sides.",
                "Use outside English to pocket the object ball while calling the cue-ball route.",
                "Success: clean pot with reduced throw and a cue-ball finish on the called route; over-cutting or over-running fails the rep."
            ]
        ),
        DrillTemplate(
            id: "one_rail_target_pool",
            title: "One-rail target pool",
            kind: .staticLayout,
            pictureID: "one_rail_target",
            description: "Pocket the object ball and send the cue ball one rail to a marked target zone.",
            primarySkills: ["Position", "Pattern"],
            secondarySkills: ["One-rail routes", "Speed", "Target pool"],
            countUnit: .routes,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three one-rail routes to a large target."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five routes. Cue ball must contact exactly one rail."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven routes to alternating target zones."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine routes. Target is one diamond wide."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten routes. Exact rail and final zone must both be called.")
            ],
            instructions: [
                "Set a pocketable object ball and place a cue-ball target zone after a one-rail route.",
                "Pocket the object ball and send the cue ball exactly one rail to the target.",
                "Success: clean pot, exactly one cue-ball rail, and final rest inside the called target zone."
            ]
        ),
        DrillTemplate(
            id: "two_rail_target_pool",
            title: "Two-rail target pool",
            kind: .staticLayout,
            pictureID: "two_rail_target",
            description: "A target-pool route drill: pocket the object ball and play the cue ball two rails into a finish zone.",
            primarySkills: ["Position", "Pattern"],
            secondarySkills: ["Two-rail routes", "Speed", "Spin choice"],
            countUnit: .routes,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three two-rail routes to a broad target."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five routes. Call the first rail before shooting."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven routes. Cue ball must contact two rails before the zone."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine routes with smaller targets and controlled spin."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten routes. Wrong rail count or missed target fails the rep.")
            ],
            instructions: [
                "Set a pocketable object ball and place a cue-ball target zone after a two-rail route.",
                "Pocket the object ball and send the cue ball through the called two-rail path.",
                "Success: clean pot, correct two-rail path, and final rest inside the called target zone."
            ]
        ),
        DrillTemplate(
            id: "three_rail_target_pool",
            title: "Three-rail target pool",
            kind: .staticLayout,
            pictureID: "three_rail_target",
            description: "A higher-control target-pool drill: pocket the object ball and send the cue ball three rails to the called finish area.",
            primarySkills: ["Position", "Overall"],
            secondarySkills: ["Three-rail routes", "Speed", "Spin management"],
            countUnit: .routes,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three attempts to a large three-rail target."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five attempts. Use natural angle when available."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven attempts. Call the three-rail path."),
                DrillDifficulty(level: .hard, ballCount: 9, constraint: "Nine attempts with a smaller target and no scratch path."),
                DrillDifficulty(level: .expert, ballCount: 10, constraint: "Ten attempts. Exact rail path and final zone required.")
            ],
            instructions: [
                "Choose a pocketable object ball where a three-rail cue-ball path is realistic.",
                "Pocket the object ball and send the cue ball through the called three-rail route.",
                "Success: clean pot, correct three-rail path, and final rest inside the called target zone."
            ]
        )
    ]
}
