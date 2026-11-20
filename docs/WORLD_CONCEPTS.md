# Miniature world concepts

Three dials share one rule: many small bodies slide and pile at the physically lowest point of the face. Wrist tilt comes from `CMMotionManager` device-motion gravity. The same scenes run on iPhone and Apple Watch.

Keep each world in the **8–20 dynamic body** range. That is enough for a pile to read as a pile, and cheap enough for a 30 Hz watch scene. Sizes below are authored for a **190-point** dial; `GameScene` scales them with the real face.

All three concepts below are implemented and switchable from the Worlds screen. The choice is stored in `UserDefaults` under `selectedWorldID`.

## Shared behavior

| Input | What it does |
| --- | --- |
| Wrist tilt | Hardware gravity drives `physicsWorld.gravity`. A flat face (gravity along −z) lets the pile rest. |
| Digital Crown | One revolution rotates which way is "down". Used automatically in the simulator, or when **Use crown and drag** is on. |
| Drag | The point you touch on the dial becomes the low side. Same manual-tilt rules as the crown. |
| Tap | Tosses the pile upward. |
| Long-press | Scatters the pile. |
| Shake | On a real device, user acceleration above **2.3 g** (gravity removed) scatters the pile, at most once every **0.9 s**. |
| Hard hit | Approach speed into a wall or obstacle above **240 pt/s** plays a haptic, at most once every **0.14 s**. Watch: `WKInterfaceDevice` `.click`. iPhone: light impact, or medium above **640 pt/s**. |

Gravity is smoothed with a time constant of **0.12 s** so sensor noise does not buzz the pile. Motion is sampled at **30 Hz on watchOS** and **60 Hz on iOS**, and both the sampler and the scene pause when `scenePhase` is not `.active`.

## Treasure Chest

**Theme.** A walnut tray inside a gold bezel. Heavy bars and light gems share the box, so a tilt sorts them: bars sink, diamonds skitter and end up on top.

**Count.** 14 bodies — 8 gold bars and 6 diamonds.

**Background.** Radial gradient from warm bronze (`#734D29`-ish) into near-black brown. The tray is a darker wood panel with a gold stroke, four rivets, and two wooden ribs plus a small lock post. The ribs do not span the full width, so pieces can slip past the ends and stack.

**Physics.**

| Piece | Shape | Mass | Friction | Restitution | Linear damping | Angular damping |
| --- | --- | --- | --- | --- | --- | --- |
| Gold bar | Rounded rect 28×11 | 0.42 | 0.78 | 0.10 | 0.35 | 0.55 |
| Diamond | Diamond, radius 7 | 0.07 | 0.18 | 0.50 | 0.12 | 0.20 |
| Tray walls | Edge loop | — | 0.55 | 0.22 | — | — |

Bars are dull and sticky. Diamonds bounce and spin. That mix is the point of the world: one tilt produces two behaviors in the same pile.

**Interactions in this prototype.** Crown or drag rolls the hoard to a corner. Tap spills it. Shake (or a long-press) rattles the gems off the bars. Hard hits on the ribs and the tray click.

**Later.** A lid that opens with the crown, a tap that inspects one gem, and a heavier "coin" layer between the bars and the diamonds.

## Tennis Court

**Theme.** A green hard court on a dark bezel, optic-yellow balls, a white net.

**Count.** 12 tennis balls.

**Background.** Deep green radial dial, lighter court-green tray, white sidelines and service lines painted on the tray (decoration only — they have no physics). The net is a static bar across about 70% of the tray, with a post at each end, so balls can squeeze around the sidelines or stack against the tape.

**Physics.**

| Piece | Shape | Mass | Friction | Restitution | Linear damping | Angular damping |
| --- | --- | --- | --- | --- | --- | --- |
| Tennis ball | Circle, radius 8 | 0.12 | 0.42 | 0.74 | 0.18 | 0.22 |
| Tray and net | Edge loop / static bar | — | 0.36 | 0.46 | — | — |

Balls bounce, then settle. The net is the obstacle they pile against when the low side is left or right.

**Interactions in this prototype.** Tilt serves the balls to one side. Tap is a pop (a poor man's serve). Shake or long-press sprays the court. Impacts on the net and the tray haptic.

**Later.** Crown sets sidespin. A drag that aims a single serve. A tiny score that ticks when a ball crosses the net.

## Basketball Court

**Theme.** Maple floor, painted key, orange basketballs mixed with soccer balls. A backboard and an open rim sit at the top of the tray.

**Count.** 12 bodies — 7 basketballs and 5 soccer balls.

**Background.** Warm wood radial dial, lighter maple tray, cream court lines (the key and a free-throw circle) with no physics. The backboard is a short static bar. The rim is an open arc (a bowl), so a ball can sit in it while the rest pile on the floor.

**Physics.**

| Piece | Shape | Mass | Friction | Restitution | Linear damping | Angular damping |
| --- | --- | --- | --- | --- | --- | --- |
| Basketball | Circle, radius 9 | 0.22 | 0.55 | 0.70 | 0.16 | 0.28 |
| Soccer ball | Circle, radius 8 | 0.16 | 0.38 | 0.58 | 0.16 | 0.24 |
| Tray | Edge loop | — | 0.45 | 0.40 | — | — |

Basketballs are heavier and livelier. Soccer balls are a bit deader, so they tend to stop underneath.

**Interactions in this prototype.** Tilt rolls the floor. Tap is a tip-off. A lucky toss can drop a ball into the rim. Shake scatters the rack. Rim and wall hits haptic.

**Later.** Scoring when a ball passes through the rim, and a crown-controlled shot angle.

## Adding one of these, or a new one

The numbers above live in `Shared/Worlds`. A world is a `MiniatureWorld`: palette, body specs, obstacles, and optional painted decorations. `GameScene` turns that data into nodes. See the README for the three steps to register a new world.

## More worlds (not built)

Same budget — under about 20 dynamic bodies — and the same tilt rule:

- **Sand tray.** Many tiny grains. On watch, stay near the top of the budget or the frame time will climb.
- **Marbles maze.** One marble or a handful, and a maze of static walls.
- **Snow globe.** Low gravity, high restitution, shake stirs flakes that then settle.
- **Hourglass.** A narrow throat obstacle and two chambers. Tilt past vertical starts the flow.
- **Tide pool.** A few shells and pebbles with very different masses, plus a slow sway added on top of wrist gravity.
- **Pinball.** Flippers on tap, tilt still moves the ball, haptics on the bumpers.
