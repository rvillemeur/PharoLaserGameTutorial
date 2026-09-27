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

## 6. Roadmap — one commit per tutorial subsection

### Numbering

Work is numbered `section.subsection`, counting the `<h3>` headings of `tut2007/html` inside each
Section, and skipping the interpolated lowercase page `038a` (a sub-step of 2.3). The anchor is
fixed, so any disagreement about counting is settled by it:

- **2.8 = page 048A, The Smalltalk-Way To Do A Case Statement — done.**
- **2.9 = pages 049–050, Game Graphics — done (`f666984`).**
- **2.10 = pages 051–052, Rendering The Cells — done (`2f5a502`).**
- **2.11 = pages 053–054, LaserGame Morph — the next commit.**

### Commit convention

One commit per numbered subsection, in order. Subject line: `Section <n.m> — <tutorial heading>: <what
changed>`. The body names the original pages covered. A commit carries three things together:

1. the code, compiled in the image and written out by Iceberg;
2. the matching Pillar chapter text;
3. green tests (`run_tests` on `Laser-Game`) and a clean critics run on what changed.

Never bundle two subsections in one commit, and never commit code without its chapter.

### Book files

Sections 2 to 6 continue the Pillar book. New chapters go to `SectionTwo/`, `SectionThree/`, … as
`12-GameGraphics.pier`, `13-CellRendering.pier`, and so on, each added to `inputFiles` in
`pillar.conf`. The original chapter structure is kept: one book chapter per tutorial heading group,
same order, same explanations, with the Squeak graphics replaced by the Bloc equivalent and a short
note whenever the port diverges from the 2007 text. The `doc/section1..6` markdown scaffold from 2023
is dead and is not used.

### Preparation, already committed

| Commit | Work |
|---|---|
| `84acd71` | this map |
| `db9fdff` | dead duplicate package directories removed |
| `bd388d7` | `testCellOffsetCalculations` freed from `Display`; `CellRenderer class>>rendererFor:grid:` added |
| `c23d354` | click region tests derived from the region rectangles, proven independent of `cellExtent` |
| `5593078` | the two hard constraints recorded |

### Section 2 — the game appears on screen

| # | Pages | Work on the new stack | Done when |
|---|---|---|---|
| 2.9 | 049–050 | **Done (`f666984`).** `CellRenderer` keeps `cellLocation` and `grid`, drops the target form from its geometry API (`rendererFor:grid:`), and gains a renderer hierarchy selected by `modelClass`. Tests cover selection, one renderer per cell class, and failure for a non-cell. Chapter `SectionTwo/12-GameGraphics.pier` explains why we take one element per cell instead of the tutorial's single shared `Form`. | Renderer selection is green and size-independent |
| 2.10 | 051–052 | **Done (`2f5a502`).** `CellRenderer>>newElement` answers a square `BlElement` with `BlRectangleGeometry`, board background and a one pixel border, plus the empty `renderContentsOn:` hook. `borderWidth` added; the original's target-form size computation has no counterpart. `openExample` opens one cell in a `BlSpace`. `testBlankCellElement` reads the size from the layout constraints, since `forceLayout` is forbidden. Mirror and target contents come later. | A blank cell renders, 53 tests green |
| 2.11 | 053–054 | The chapter's `LaserGame` Morph becomes `LaserGameElement`, a root element holding the board. `LaserGame` keeps the model role (grid, stats) and gains `open`. The board itself is a `BlElement` with `BlGridLayout`, sized by the layout rather than by a computed form extent. | `LaserGame new open` shows a board of blank cells |
| 2.12 | 055–060 | `GridFactory` wired to the element, named grids selectable | Each factory grid renders |
| 2.13 | 061–063 | `LaserGameColors` reviewed as Bloc paints; background, border and cell colors come from it alone | No literal `Color` outside `LaserGameColors` |
| 2.14 | 064 | Progress chapter: screenshots regenerated from the Bloc version | Chapter text matches what the reader sees |
| 2.15 | 065–067 | Board refresh path: the element observes model changes instead of `changed`/`redrawCell` on a `Form` | Changing a cell in the model updates the view |
| 2.16 | 068–072 | Control panel with Toplo buttons (`ToButton`), laid out by `BlLinearLayout`, plus the panel divider | Buttons act on the model and the board follows |
| 2.17 | 073–073A | Port the bug-demonstrating unit test of the original page | Test reproduces the bug, then passes |

### Section 3 — interaction

| # | Pages | Work on the new stack | Done when |
|---|---|---|---|
| 3.1 | 074–077 | Cells become event targets; hit testing is per element, so board-wide offset arithmetic goes away | Clicking a cell identifies it without coordinate maths |
| 3.2 | 078–079 | `BlClickEvent`, `BlMouseMoveEvent`, `BlMouseEnterEvent`, `BlMouseLeaveEvent` handlers replace the `mouse*forMorph:` family | Events reach the right cell |
| 3.3 | 080 | `CellClickRegion` reused unchanged on cell-local coordinates | Region reported for every click position |
| 3.4 | 081–085 | *Diverges from the original.* "Creating Custom Forms" becomes "Creating Custom Shapes": `LaserGameShapes` holds vertex arrays and answers elements with `BlPolygonGeometry`. `LaserGameForms`, flood fill and the `Form` extension are not ported. | Arrow and crosshair shapes render at any size |
| 3.5 | 086–092 | Push regions wired to the push actions | Correct push region for every inside point |
| 3.6 | 093–094 | Hint arrows drawn as overlay elements on the hovered cell | Hints appear and follow the pointer |
| 3.7 | 095–100 | Debugging chapter kept; `haltOnce` still exists in Pharo 13 | Chapter text valid against Pharo 13 |
| 3.8 | 101–106 | Rotate regions | Correct rotate region for every outside point |
| 3.9 | 107–110 | Rotate a mirror cell in the model | Model rotates, view follows |
| 3.10 | 111–115 | Click to rotate, end to end | Clicking a mirror rotates it on screen |
| 3.11 | 116–117 | Hint cleanup on mouse leave — trivial once hints are child elements | No stale hint remains |
| 3.12 | 118–121 | Target cell bug, with its failing test first | Test fails, then passes |
| 3.13 | 122–124 | Push a cell in the model | Push rules respected, undo entry recorded |
| 3.14 | 125–126 | Push with the mouse | Dragging or clicking pushes the row or column |
| 3.15 | 127 | The original's visual push bug; check whether the vector rendering still has it and say so in the chapter | Behaviour documented, bug fixed if present |
| 3.16 | 128–129A | *Rewritten.* Monticello becomes Iceberg and git: baseline, branches, commit from the image | Chapter matches the workflow this project uses |

### Section 4 — feedback and the laser beam

| # | Pages | Work on the new stack | Done when |
|---|---|---|---|
| 4.1 | 130–133 | Arrow colors from `LaserGameColors` | Hint color states distinguishable |
| 4.2 | 134–136 | *Diverges.* `Cursor` manipulation is replaced by hover feedback on elements, or `BlSpace` cursor if available | Pointer feedback without the `Cursor` global |
| 4.3 | 137–138 | Larger cells — a one-line change now that everything derives from `cellExtent` | Board renders at the new size, tests still green |
| 4.4 | 139–142 | Counter and window colors, with Toplo labels | Counter visible and correct |
| 4.5 | 143–146 | Move counter and grid randomizer | Randomized grids solvable |
| 4.6 | 147–148 | Bigger game board | Layout holds at the larger grid |
| 4.7 | 149–155 | Laser beam as line elements along the computed path, replacing the beam mask `Form`s | Beam drawn for a straight path |
| 4.8 | 156–158 | Beam across blank cells | Path continues correctly |
| 4.9 | 159–165 | Beam hitting the target | Target lights up |
| 4.10 | 166–173 | Beam reflected by mirrors | Full demo grid solves visually |

### Section 5 — polish

| # | Pages | Work on the new stack | Done when |
|---|---|---|---|
| 5.1 | 174–179 | The missed bug, failing test first | Test fails, then passes |
| 5.2 | 180–182 | More game stats in the panel | Stats update live |
| 5.3 | 183–187 | Undo, on the existing `Reverse*LaserGameAction` classes | Undo reverses pushes and rotations |
| 5.4 | 187A | Baseline updated for the final package structure | Fresh image loads the finished game |
| 5.5 | 188 | Reset, and the bug fix the page describes | Reset returns the start state |
| 5.6 | 189 | Laser home shown visually | Home marker rendered |
| 5.7 | 190–196 | Less brittle test design, in the spirit already applied in `c23d354` | Tests survive a change of `cellExtent` and of grid size |
| 5.8 | 197–199 | Hint arrow alignment | Arrows centred in their region |
| 5.9 | 200–204 | Cosmetic tweaks | Final look agreed |

### Section 6 — shipping

| # | Pages | Work on the new stack | Done when |
|---|---|---|---|
| 6.1 | 205–207 | *Rewritten for Pharo 13.* Deployment preparation: Metacello baseline, package structure, headless considerations | Baseline loads into a clean image with no manual step |
| 6.2 | 208–213 | *Rewritten.* Build script producing a runnable image, Pharo Launcher usage | A script produces a launchable game image |
| 6.3 | 214–217 | *Rewritten.* Double-clickable application on current macOS, Linux and Windows | Instructions verified on at least one platform |
| 6.4 | 218–index | *Rewritten.* Lock-down and stripping replaced by what Pharo 13 actually supports | Chapter honest about what is possible today |

`notes.html` and `notes01`–`notes04` (the author's notes and the longest-path puzzle) are an optional
appendix, taken last if at all.

### Then, and only then

| # | Work | Done when |
|---|---|---|
| Z | Delete `MorphPath`, `Arc`, `Circle`, `Line`, `LaserGameForms` and the `Form` extension; final critics pass over the package | No reference to `Form`, `BitBlt`, `Morph`, `SketchMorph`, `Display`, `World`, `Cursor` or `DisplayObject` remains anywhere in `Laser-Game` |

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

### One commit per tutorial subsection

Every commit corresponds to exactly one numbered subsection of the original tutorial, taken in
order, and its subject says which: `Section <n.m> — <tutorial heading>: <what changed>`. Section 2.8
(page 048A) is done; the next commit is Section 2.9 (pages 049–050, Game Graphics). Code and the
matching Pillar chapter travel in the same commit. Section 6 of this file holds the full list.

### Committing from the image

```smalltalk
| repo wc |
repo := IceRepository registry detect: [ :each | each name = 'PharoLaserGameTutorial' ].
wc := repo workingCopy.
wc commitWithMessage: 'Section 2.9 - ...'
```

This writes the Tonel files and makes the git commit in one step. The book chapter, which lives
outside `src/`, is added to that same commit from the shell with `git add` and `git commit --amend
--no-edit`.

Iceberg fails with `IceWorkingCopyDesyncronized` whenever git HEAD moved without it — a doc-only
commit or an amend is enough. Repair with `wc adoptCommit: repo headCommit`, which re-bases the
working copy on HEAD and keeps the image code. Never answer that situation with "Load version": that
overwrites the image from disk.

### Other rules

- A change to a class the package does not own belongs in `*.extension.st`, with the `*Laser-Game`
  protocol prefix — never in a `*.class.st`. A kernel class must never be captured into the package
  again; that mistake froze one image and was undone in `fdbf6cb`.
- Tests first. `run_tests` on `Laser-Game` after each compile, `run_critics` on what changed before
  each commit.
- No literal pixel coordinates in tests. Everything derives from `CellRenderer class>>cellExtent`.

## 8. Known debt

- `Form >> floodFill:at:` and `FloodFillBlt` are gone from Pharo 13; the eight call sites disappear
  at 3.4, where the bitmap masks become polygons, and the classes holding them go at Z.
- The `Display` and `World` globals are gone; the six sites go at 2.9, 2.11 and Z. One was already
  removed in `bd388d7`.
- Pharo 13 API changes already met: `RPackageOrganizer` is now `Smalltalk packageOrganizer`,
  `SystemNavigation>>senders:` is gone, `TonelRepository>>version:` is now `versionFrom:`,
  `Package>>snapshot` is now `(MCPackage named: 'Laser-Game') snapshot`.
