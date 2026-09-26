# Laser Game — Project Map

Status date: 2026-09-26. Image: Pharo 13.1.0SNAPSHOT, driven live through the `pharo` MCP server.

This file is the reference for finishing the Laser Game tutorial on Pharo 13 with Bloc as the
graphics foundation, while keeping the chapter structure of the original 2007 Squeak tutorial.

## 1. Where we are

| Item | State |
|---|---|
| Book text (Pillar) | `SectionOne/1-Introduction.pier` … `11-BeamPath.pier`, listed in `pillar.conf`, built by `compile.sh` |
| Reader position | end of `tut2007/html/048A.html` (the Smalltalk-way case statement); `049.html` (Game Graphics) is the next page to port |
| Code | package `Laser-Game` in `src/`, loaded by `BaselineOfLaserGame` (which already declares the Bloc baseline) |
| Tests | 51 tests, 50 pass, 1 error — `CellRendererTestCase>>testCellOffsetCalculations` fails on `Display`, removed from Pharo 13 |
| Git | branch `master`, in sync with `origin/master`, head `2552a5d fix failing unit test.` |

A second, abandoned documentation scaffold exists in `doc/section1..6` (markdown, dated October 2023;
only `section1.md` has content). The Pillar sources under `SectionOne/` are further along and are the
ones the build uses, so new chapters go to Pillar. Delete or revive `doc/` as a separate decision.

## 2. Sources of the original code

The original code is *not* only available as screenshots. Plain-text originals exist:

- `tut2007/html/sources/Laser-Game.1.cs` (15 KB Squeak changeset) — early model: `Cell`, `BlankCell`,
  `MirrorCell`, `TargetCell`, `Grid` and their test cases, with full method bodies.
- `tut2007/html/sources/Laser-Game.2.cs` (51 KB) — everything up to mid-tutorial: `CellRenderer`,
  `BlankCellRenderer`, `CellRendererTestCase`, `GridDirection` + four subclasses,
  `GridDirectionTestCase`, `GridFactory`, `LaserGame` (as a `Morph`), `LaserGameColors`,
  `LaserPathElement`, `MirrorCellRenderer`, `TargetCellRenderer`. It stops before the click regions,
  the reverse/undo actions, `MorphPath` and `LaserGameForms`.
- `tut2007/html/sources/Laser-Game-sbw.1.mcz`, `tut2007/Laser-Game-sbw-published.mcz`,
  `tut2007/LaserGame-Tests-sbw-published.mcz`, `tut2007/LaserGameChangeSets.zip`,
  `tut2007/Laser Game.zip`. Python's `zipfile` rejects the `.mcz` files ("Bad offset for central
  directory"), but Monticello in the image may still read them — try that before transcribing from
  images.

Screenshots are therefore only needed for the parts no changeset covers: the click-region classes,
the hint arrows, the undo actions and everything from Section 3 onward. Page text itself is already
plain HTML in `tut2007/html/*.html`.

## 3. Tutorial page map

Section boundaries in `tut2007/html`: S1 000–035A, S2 035B–073, S3 074–129A, S4 130–173,
S5 174–204, S6 205–220. Headings from the reader position onward:

- **S2 (remaining)**: 049 Game Graphics · 051 Rendering The Cells · 053 LaserGame Morph ·
  055 A Factory For Grids · 061 Management of Colors · 064 Progress So Far ·
  065 Back to the LaserGame Morph · 068 Adding Controls · 073 A Unit Test To Demonstrate A Bug
- **S3**: 074 Interacting With Cells · 078 Handle Mouse Events · 080 Detecting Mirror Cell Click
  Regions · 081 Creating Custom Forms · 086 Determine Push Regions · 093 Drawing Push Hints On The
  Game Board · 095 Using "Halt Once" · 101 Determine Rotate Regions · 107 Rotate A Mirror Cell ·
  111 Click And Rotate A Cell · 116 Clean Up Left-Over Hints · 118 Bug With Target Cell ·
  122 Push A Cell · 125 Push Cells With The Mouse · 127 Visual Bug With Push ·
  128 Source Management With Monticello
- **S4**: 130 Communicate With Arrow Colors · 134 Better Cursor Management · 137 Making Larger
  Cells · 139 Add A Counter and Window Colors · 143 Add Move Counter And Randomizer ·
  147 A Bigger Game Board · 149 Drawing The Laser Beam · 156 Laser On Blank Cell ·
  159 Laser On Target Cell · 166 Laser On Mirror Cell
- **S5**: 174 A Missed Bug · 180 Adding More Game Stats · 183 Undo · 187A Modify Package Definition ·
  188 Reset (and a bug fix) · 189 Showing Laser Home Visually · 190 A Less Brittle Unit Test
  Design · 197 Better Hint Arrows Alignment · 200 Minor Cosmetic Tweaks
- **S6**: 205 Prepare For Application Deployment · 208 Next Steps Towards Deployment ·
  214 A Double-Clickable Mac Application · 218 Better Lock-Down Steps

## 4. Code inventory

### Portable as is (pure model, no display dependency)

`Cell`, `BlankCell`, `MirrorCell`, `TargetCell`, `Grid`, `GridFactory`, `GridDirection` +
`GridDirectionNorth/South/East/West`, `LaserPathElement`, `LaserGameColors`,
`ReverseLaserGameAction` + its six subclasses, and all model test cases.

### Portable with care (geometry only)

`CellClickRegion`, `CellClickRegionInside`, `CellClickRegionOutside`, `CellClickRegionIgnore`,
`CellClickRegionPushNorth/South/East/West`, `CellClickRegionRotateClockwise`,
`CellClickRegionRotateCounterClockwise`. These use only `Rectangle` and `Point` arithmetic, so they
survive the move to Bloc untouched — except `CellClickRegionInside class>>scaledHintArrowAndOffsetFromWithinCell:`
and the `arrowForm` methods, which return `Form`s and must return elements or shapes instead.

### To be replaced (72 methods touch the Squeak display stack)

Legacy API used: the removed `Display` global (6 sites), `Form >> floodFill:at:` (8 sites, the
method and `FloodFillBlt` no longer exist), `DisplayObject`, `SketchMorph`, `Form extent:` with
`displayOn:at:clippingBox:rule:fillColor:`, `World`, `Cursor`.

| Class | Fate |
|---|---|
| `MorphPath` (subclass of `DisplayObject`), `Arc`, `Circle`, `Line` | Delete. These are copies of Squeak display infrastructure captured into the package, the same mistake as the captured kernel `Object` already removed in `fdbf6cb`. Bloc geometries replace all of them. |
| `Form` extension (`anyOfColor:inRow:`, `tightRectangleAroundColor:`, …) | Delete. It exists only to measure bitmaps produced by flood fill. |
| `LaserGameForms` (cached arrow/crosshair/beam `Form`s, flood fill) | Replace with `LaserGameShapes`: vertex arrays and `BlElement` factories. Arrows become `BlPolygonGeometry`, so flood fill disappears entirely. |
| `CellRenderer`, `BlankCellRenderer`, `MirrorCellRenderer`, `TargetCellRenderer` | Keep the names and the hierarchy (the chapters are written around them), move the bodies from `Form` drawing to Bloc elements and geometries. |
| `LaserGame` (a `Morph`, plus `World`/`Display` class-side launchers) | Split into a model-side `LaserGame` (grid, stats, undo stack, actions) and Bloc elements `LaserGameElement`, `LaserGameBoardElement`, `LaserGameControlPanelElement`. `LaserGame class >> open` opens a `BlSpace`. |
| `LaserGame>>mouse*forMorph:` family | Replace with per-element handlers via `addEventHandlerOn:do:` (`BlClickEvent`, `BlMouseMoveEvent`, `BlMouseEnterEvent`, `BlMouseLeaveEvent`). One element per cell removes the manual hit-testing against the board bitmap. |

## 5. Target architecture on Bloc

Bloc is present in the image (67 Bloc/Alexandrie packages, Toplo too). Available and relevant:
`BlElement`, `BlSpace`, `BlRectangleGeometry`, `BlCircleGeometry`, `BlEllipseGeometry`,
`BlLineGeometry`, `BlPolygonGeometry`, `BlGridLayout`, `BlLinearLayout`, `BlFrameLayout`,
`BlTextElement`, `BlClickEvent`, `BlElement>>aeDrawOn:`, `ToButton`, `ToLabel`.

Rules for the port:

1. **Compose, do not draw.** Prefer an element with a geometry and a background/border over custom
   `aeDrawOn:` code. A mirror is a thick diagonal `BlLineGeometry`; a target is a
   `BlCircleGeometry` plus two crosshair lines; a laser beam segment is a line; a hint arrow is a
   polygon. This removes every flood fill and every bitmap mask.
2. **One element per cell.** The board is a `BlElement` with a `BlGridLayout`; each cell renderer is
   its own element, so click regions are computed in cell-local coordinates — which is exactly what
   `CellClickRegion class>>clickRegionForPoint:` already expects.
3. **Keep the model display-free.** No element ever appears in `Cell`, `Grid` or `GridDirection`.
   Rendering asks the model; the model never asks the view.
4. **Vector, not pixels.** Cell size stays a single class-side constant (`CellRenderer class>>cellExtent`),
   and every region rectangle is derived from it. No literal pixel coordinates in tests — the two
   stale tests already fixed in `2552a5d` failed for exactly that reason.
5. **Deployment section rewritten.** Section 6's Squeak-specific packaging is replaced by the current
   story: Metacello baseline, Pharo Launcher, a headless start script.

## 6. Step plan (one commit per step)

Every step: write the code in the image through the MCP server, run `run_tests` on the package, run
`run_critics` on what changed, write the matching Pillar chapter, then commit code and chapter
together.

| # | Pages | Work | Done when |
|---|---|---|---|
| 0 | — | Housekeeping: delete the stale duplicate directories `src/Laser-Game-Model/`, `src/Laser-Game-Graphics/`, `src/Laser-Game-Tests/` (dead copies, not in the baseline) and the leftover `.probe-out.txt` | Baseline still loads in a fresh image |
| 1 | — | Fix `CellRendererTestCase>>testCellOffsetCalculations` (drop the `Display` reference) | 51 tests, 51 pass |
| 2 | — | Derive `testClicksInOutsideRegion` and the duplicate `testClicksInsideRegion` from the region rectangles instead of literal points | Tests still green after changing `cellExtent` |
| 3 | 049–052 | `CellRenderer` hierarchy on Bloc: cell element with background, border and per-subclass contents (blank, mirror, target). New tests assert element structure and geometry, not pixels | Cells render in a `BlSpace` opened from a class-side example |
| 4 | 053–054 | `LaserGameBoardElement` with a `BlGridLayout` over `Grid` | Whole demo grid renders |
| 5 | 055–063 | `GridFactory` wiring and `LaserGameColors` reviewed against Bloc paints | Named grids render with the right colors |
| 6 | 064–073 | `LaserGameElement` root, control panel (Toplo buttons), `LaserGame class >> open`; port page 073's bug-demonstrating test | Game window opens, controls respond |
| 7 | 074–080 | Mouse events per cell element; reuse `CellClickRegion` unchanged | Clicking a mirror cell reports its region |
| 8 | 081–100 | Hint arrows as polygons (`LaserGameShapes`), hint overlay on hover, push regions | Arrows appear where the Squeak version drew forms |
| 9 | 101–121 | Rotate regions and the rotate action, click-and-rotate | Mirror rotates on click, model updated |
| 10 | 122–129A | Push a cell, push with the mouse, hint cleanup; page 128 rewritten for Iceberg/git instead of Monticello | Push works, no left-over hints |
| 11 | 130–148 | Arrow colors, cursor/hover feedback, larger cells, move counter, randomizer | Section 4 first half renders |
| 12 | 147–173 | Bigger board, laser beam drawing for blank, target and mirror cells | Beam follows the computed path |
| 13 | 174–204 | Missed bug, game stats, undo (the `Reverse*LaserGameAction` classes already exist), baseline update, reset, laser home visual, less brittle tests, alignment and cosmetics | Section 5 complete |
| 14 | 205–220 | Deployment chapter rewritten for Pharo 13 | A fresh image loads and launches the game from the baseline |
| 15 | — | Delete `MorphPath`, `Arc`, `Circle`, `Line`, `LaserGameForms`, the `Form` extension; final critics pass | No reference to `Display`, `Form`, `SketchMorph`, `World` or `Cursor` remains |

## 7. Working rules

These are constraints, not preferences.

### All code is written in the image

No detached working copy. Code is compiled in the running image through the MCP server, and the
image writes it out to `src/` through Iceberg. Never hand-edit a `.class.st` file, never call
`TonelWriter` or `fileOut`, never change the file side and expect the image to notice. If the image
and this clone disagree, repair the image's Iceberg repository instead of patching files. Commits
are made from the image side, one per finished step.

The repository is Tonel v2 (`#name : 'Foo'`, with `#package` and `#tag`), which is what Iceberg in
Pharo 13 writes. Paths differ between the two sides: the shell sees this clone as
`/home/me/workspace`, the image sees it as `/home/renaud/devzone/sources/PharoLaserGameTutorial`.
The Iceberg repository `PharoLaserGameTutorial` is registered in the image, on branch `master`, and
owns the `Laser-Game` package.

### All graphics are Bloc, Alexandrie and Toplo

Nothing else. New code never mentions `Form`, `BitBlt`, `Morph`, `SketchMorph`, `Display`, `World`,
`Cursor` or `DisplayObject`. The Squeak display classes captured into the package — `MorphPath`,
`Arc`, `Circle`, `Line`, `LaserGameForms` and the `Form` extension — are deleted, not ported.
Drawing composes elements that carry geometries (`BlPolygonGeometry`, `BlCircleGeometry`,
`BlLineGeometry`, `BlRectangleGeometry`); `aeDrawOn:` and the Alexandrie canvas are reserved for
shapes no geometry can express. Toplo provides the control panel widgets. `BlSpace` replaces the
`World`.

### Other rules

- A change to a class the package does not own belongs in `*.extension.st`, with the `*Laser-Game`
  protocol prefix — never in a `*.class.st`. A kernel class must never be captured into the package
  again; that mistake froze one image and was undone in `fdbf6cb`.
- Tests first. `run_tests` on `Laser-Game` after each compile, `run_critics` on what changed before
  each commit.
- No literal pixel coordinates in tests. Everything derives from `CellRenderer class>>cellExtent`.

## 8. Known debt

- `Form >> floodFill:at:` and `FloodFillBlt` are gone from Pharo 13; the eight call sites disappear
  with step 8 rather than being ported.
- `Display` and `World` globals are gone; six sites, handled in steps 1, 6 and 15.
- Pharo 13 API changes already met: `RPackageOrganizer` is now `Smalltalk packageOrganizer`,
  `SystemNavigation>>senders:` is gone, `TonelRepository>>version:` is now `versionFrom:`,
  `Package>>snapshot` is now `(MCPackage named: 'Laser-Game') snapshot`.
