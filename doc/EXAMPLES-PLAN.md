# Examples and views plan — reviewing the book under the new development cycle

Plan date: 2026-10-07. Decided with the user in the session of 2026-10-06/07.

The method this plan applies is written in `doc/DEV-CYCLE.md`, which is project-neutral and is the
normative document: where this plan and that one disagree, that one wins and this one is corrected.

Examples and inspector views did not exist in 2007, and they were added to this port at the end, as
a documentation pass. The result works and is gated, but it teaches the reader nothing about *when*
to reach for either, because in the book they arrive almost entirely in one late chapter. This plan
rewrites the book, and adapts the code, so that both arrive at the moment a developer following the
cycle would have written them.

## 1. Where we are, measured

| Item | Count |
|---|---|
| Code | `Laser-Game` 42 classes · `Laser-Game-Examples` 12 classes, 25 examples · `Laser-Game-Tests` 25 classes |
| Tests | 273 methods, 305 runs, all green |
| Book | five Markdown files under `doc/`, 20,932 lines, 65 chapters, 734 code fences, all gated against the image |
| Inspector views | 19, across 11 classes: 10 instance-side, 9 class-side |
| Views introduced in Section 3, at the bug that wanted them | 4 — `Cell` *Sides*, `Grid` *Board*, *Beam*, *Cells* |
| Views introduced in Section 5, chapter *Looking at objects* | 15 |
| `GridFactory demoGrid` in the book | 144 fences: S1 2 · S2 22 · S3 50 · S4 35 · S5 35 |
| `GridFactory demoGrid` in the tests | 86 sites across 10 test classes, the largest being `LaserGameCellElementTestCase` 34 and `LaserGameElementTestCase` 28 |

## 2. Findings — where the project departs from the cycle

**F1. The shared test board lives in core.** `GridFactory class >> demoGrid` is a test fixture in the
production package. The book says so in as many words, in *Drawing the mirror*: "we pick up
`GridFactory` on the way, so that every example and every test from here on deals the same board."
It went there because it had to go somewhere and the example package did not exist yet — the exact
failure `DEV-CYCLE.md` §8 names. Consequences: core now depends on a fixture
(`GridFactory class >> inspectionBoardFacts` lists it as one of the boards the factory deals, which
it is not), the *Boards* view shows a fixture to the reader as production behaviour, and 144 book
fences and 86 test sites name the wrong owner.

**F2. Views arrive as an appendix.** Fifteen of nineteen views are written in one chapter at the end
of Section 5, which opens by admitting it: "In this chapter we write the rest of them on purpose."
Four were written at a bug, which is the right trigger and the right narrative, and those four are
the ones a reader learns anything from.

**F3. Six bookmark examples exist only to satisfy a gate.**
`CellClickRegionExample class >> clickRegions`, `GridDirectionExample class >> directions`,
`GridFactoryExample class >> boardsTheFactoryDeals`, `LaserGameColorsExample class >> palette`,
`LaserGameControlPanelExample class >> panelMeasures` and `LaserGameShapesExample class >> shapes`
each have `^ SomeClass` for a body. They were forced into existence by
`LaserGameExamplesTestCase`, which demands that the examples reach every view, including the nine on
the class side — and a class needs no example to be reachable.

**F4. An opener is still in core, and two class comments point at openers that have moved.**
`CellRenderer class >> openExample` is in `Laser-Game`. `LaserGameBoardElement` and
`LaserGameElement` have class comments quoting `… openExample`, which is now on
`LaserGameBoardExample` and `LaserGameElementExample`. The book quotes the moved openers at their
old home in about a dozen places, three of them full method fences.

**F5. The teaching spine says nothing about either tool.** Section 1's *Test driven development*
chapter teaches red-green-refactor and stops there. Nothing in the book tells the reader when a
snippet becomes an example, or when a hard diagnosis means a view is missing.

**F6. Test fixtures are inlined 86 times.** Most test methods build the board in their own first
line. Two classes do it 34 and 28 times. A per-class fixture would read better and would make the
board one edit instead of 86.

**F7. The gate is good and should be kept.** `LaserGameExamplesTestCase` already implements both
generic gates of `DEV-CYCLE.md` §9, and more besides. It needs one correction (F3) and it then
becomes the reference implementation the method document points at.

**F8. The book uses the `GridDirection` hierarchy 1,500 lines before it introduces it.** `Grid >>
nextElementIn:` is quoted at section3 3587 and 3593, in *Determine rotate regions*, sending
`GridDirection directionFor:` and `adjacentInversionSymbol`, but the four direction classes are only
built at section3 5126, in *Push a cell*. `adjacentInversionSymbol` has no fence anywhere in the
book: the first time a reader sees the selector defined is a prose line of *Looking at objects*
(section5 4520). Found by the P3 audit; it blocks the *Directions* and *Step* views, and it is a
defect of the book independently of them.

**F9. Three slots and their accessors are promised and never shown.** `Cell`'s `gridLocation` is
announced in two notes (section1 909 and 1540) but no class-definition fence ever adds it;
`Grid >> laserIsActive:` is never shown; `LaserGameLedElement` has no class-definition fence at all,
and `digits:`, `value:` and `value` are never defined, although the chapter builds a display and the
examples send all three. The *Picture* and *Segments* views and the two LED examples depend on them.
Partly closed by P7: the five `LaserGameLedElement` methods are now fenced in Section 4, and the
*Segments* view and both LED examples with them. Still open: `Cell`'s `gridLocation` has no
class-definition fence, `LaserGameLedElement` has none either, and `Grid >> laserIsActive:` is still
never quoted — it is a generated accessor whose comment says nothing, so P9 should decide whether it
earns a fence or whether the two notes that promise it should stop promising it.

**F10. Two shapes and one colour have no fence.** `LaserGameShapes class >>
southArrowElementOfExtent:` and `westArrowElementOfExtent:` are missing although `north` and `east`
are shown, and `LaserGameColors class >> confirmationTextColor` is missing. The *Shapes* view names
all seven shape selectors, so the two missing arrows have to be written before it can be quoted.

**F11. The examples cluster on `fireLaser`.** Six examples send `Grid >> fireLaser`
(`gridWithTheLaserFiring`, `firstStepOfTheBeam`, `lastStepOfTheBeam`, `litMirrorCell`,
`litTargetCell`, `openExampleWithLaserFired`). The book first evaluates `grid fireLaser` at section2
1205, in *Drawing the target*, so none of the six can be promoted in Section 1, whatever its trigger
says. The *Beam* view goes with them.

**F12. Nine of the nineteen view relocations of §5 were impossible as first written.** The P3 audit
checked every view's own sends and its paired example against the chapter the view was sent to. See
§5 for the corrected homes and the blocking dependency in each case.

**F13. Section 2 fires a laser two chapters before it writes one.** `grid fireLaser` is evaluated at
`doc/section2/section2.md:1205`, inside the example of *Firing the laser*, and `Grid >> fireLaser` is
first defined at `doc/section2/section2.md:2318`, in *A unit test to demonstrate a bug*. The same
fence is stale in a second way: it heads the example `LaserGameBoardElement class >>
openExampleWithLaserFired`, and the image holds it as `LaserGameBoardExample class >>
openExampleWithLaserFired`. P5 either moves `fireLaser` and `stopLaser` forward to *Drawing the
target*, where the board first needs lighting, or moves the example back to the chapter that writes
them. Everything F11 sends to *Drawing the target* depends on that choice.

## 3. Decisions to lock before any work starts

**All seven were locked on 2026-10-07: the user approved every recommendation below.** They stay
written out, with the alternatives that were turned down, so that a later reader knows what was
decided and what was not.

**D1. Who owns the demo board.** *Recommended:* `GridExample class >> demoGrid` holds the body;
`GridFactory class >> demoGrid` is deleted; `GridFactory class >> inspectionBoardFacts` drops the
`demoGrid` row and shows the two boards the factory really deals. The factory keeps `defaultGrid`,
`emptyStandardGrid` and `randomizedGridOfExtent:`.

**D2. When the example package is born.** *Recommended:* in Section 1, chapter *Grid*, in the
section now called *A better context for the tests*, which is the first promotion the project ever
makes — a fixture a second test class wants. The book therefore grows a third package at a moment
the narrative asks for one, rather than at the start.

**D3. Where `GridFactory` is introduced.** The factory currently arrives in *Drawing the mirror*
only because the demo board needed a home. *Recommended (option A):* keep the factory where it is in
Section 2 and have it arrive with `emptyStandardGrid`, a board the game really deals, so the chapter
keeps its place against the 2007 page order. *Option B* defers the factory to Section 4, where the
standard and randomised boards appear; it is tidier and departs further from the original structure.

**D4. When the two generic gates are written.** *Recommended:* at the package's birth in Section 1,
as one short section, with a forward note that the view gate gains teeth once views exist. The
alternative is to defer the gates to Section 2, when there are three examples, on the grounds that
the pragma walk is heavy code for chapter eleven of a beginners' book.

**D5. Fixture style in the tests.** *Recommended:* a test class with three or more uses gets the
board in `setUp` and reads it from an instance variable; a class with one or two keeps it inline as
`GridExample demoGrid`. Tests that need two boards, or a second fresh board mid-method, stay inline
whatever the count. This is the user's "internal input variable", applied where it pays.

**D6. What becomes of *Looking at objects*.** *Recommended:* keep the chapter and shrink it. The
thirteen "write a view" sections move to the chapters named in §5. What stays is the practice: the
five lessons the chapter already states, how a view is tested, the two gates, the garbage-collection
rule, and *Which object to inspect*, which is the only map of all nineteen views the reader gets.

**D7. Whether the six bookmark examples die.** *Recommended:* yes, with the gate corrected to exempt
class-side views. The example count falls from 25 to 20 (six deleted, one added by F4).

## 4. Phases

Project convention is unchanged: a commit carries code only, never book text; one commit per
numbered step; `run_tests` on `Laser-Game-Tests` green and `run_critics` clean on what changed.

### P0 — Lock the decisions — done, 2026-10-07

D1 to D7 all answered with the recommended option. See §3.

### P1 — Move the fixture out of core — done in the image, 2026-10-07, awaiting commit

What was done, and where it differs from the steps below: the test rewrite went further than a
textual swap. Each of the six test classes that used the board three times or more now builds its
fixture in `setUp` and holds it in an instance variable, and the methods that built it inline lost
both the build line and the temporary declaration — `LaserGameCellElementTestCase` (`grid` and
`board`, 33 methods), `LaserGameElementTestCase` (`game`, 31), `GridTestCase` (`grid`, 29, and
`generateDemoGrid` deleted rather than one-lined), `LaserGameBoardElementTestCase` (`grid`, 5),
`CellRendererTestCase` (`grid`, 7) and `TargetCellRendererTestCase` (`grid`, 4). A method that needs
a second board, or one built after the laser is fired, keeps its own assignment, which now writes the
instance variable instead of a temporary. Three shadowing critiques that this raised were fixed, and
`GridExample` lost two `ReRefersToClassRule` critiques by sending `self demoGrid`. The stale
`openExample` lines in the `LaserGameElement` and `LaserGameBoardElement` class comments were fixed
here rather than in P2, and the two core `openOn:` comments now show `GridFactory defaultGrid`, so no
core comment points at the examples except the one sentence in `GridFactory`'s class comment that
says where the fixed board went. 305 runs green, critics clean on the three packages apart from
pre-existing findings.

#### Steps as planned

1. Compile `GridExample class >> demoGrid` with the body now in `GridFactory class >> demoGrid`,
   keeping the comment and adding `<sampleInstance>`.
2. Rewrite the 86 test sites per D5: `setUp` in `LaserGameCellElementTestCase` (34),
   `LaserGameElementTestCase` (28), `LaserGameBoardElementTestCase` (9), `CellRendererTestCase` (5)
   and `TargetCellRendererTestCase` (3); inline `GridExample demoGrid` in
   `MirrorCellRendererTestCase` (2), `LaserPathElementTestCase` (2),
   `LaserGameHintEventTestCase` (1), `LaserGameControlPanelElementTestCase` (1); and
   `GridTestCase >> generateDemoGrid` becomes `^ GridExample demoGrid` or goes away entirely.
3. Rewrite the four senders inside the example package (`GridExample` ×3, `CellExample` ×5) to call
   `GridExample demoGrid`.
4. Fix `GridFactory class >> inspectionBoardFacts` per D1 and update its comment and its test.
5. Delete `GridFactory class >> demoGrid`.
6. Verify: 305 runs green; `find_senders: #demoGrid` names nothing in `Laser-Game`; critics clean.

*Verification that matters most:* no method of `Laser-Game` references `Laser-Game-Examples`. Check
it mechanically, not by eye.

### P2 — Tidy the openers, the bookmarks and the gate — done in the image, 2026-10-07, awaiting commit

Done as written, with four notes.

The example package is **7 classes and 20 examples**, not the 8 or 9 of step 5: `GridFactoryExample`
and `LaserGameControlPanelExample` held nothing but a bookmark, so both died with the other four.

`CellRendererExample class >> openExample` keeps the body of the deleted core method, which builds
its own `BlSpace` and sends `show` instead of asking an element to open on an object. That broke
`testOnlyAnExampleNamedOpenOpensAWindow`, which decided what opens a window by searching the source
for `openOn:`. The test now reads the selectors a method sends, through a new support method
`opensAWindow:`, and accepts either `openOn:` or `show`. DEV-CYCLE.md §6 rule 5 gained the same
point.

The gate's view walk is split in two: `instanceSideTabNames` with
`testTheExamplesReachEveryInstanceSideTabTheGameDefines`, which the examples must cover, and
`classSideTabMethods` with `testEveryClassSideTabIsShownByInspectingItsClass`, which asserts the
inspector shows each class-side view on its own class. The class comment states four rules and says
why the class side is exempt. `LaserGameExamplesTestCase` is 5 tests.

Step 4 was done in P1, so nothing was left here.

Fallout for later: `doc/section2/section2.md` lines 229, 248 and 310 still say
`CellRenderer openExample` — one inside a quoted class comment, two in prose — so three more fences
dangle until P5. `PROJECT_MAP.md` line 489 still describes twelve example classes, 21 examples and the
six class-side bookmarks as a feature; P9 rewrites it.

#### Steps as planned

1. Add `CellRendererExample class >> openExample`; delete `CellRenderer class >> openExample`.
2. Delete the six bookmark examples of F3, and the four example classes left with nothing in them
   (`CellClickRegionExample`, `GridDirectionExample`, `LaserGameColorsExample`,
   `LaserGameShapesExample`, and `GridFactoryExample` and `LaserGameControlPanelExample` if D1 and
   D7 leave them empty).
3. Correct `LaserGameExamplesTestCase` to require coverage of instance-side views only, and to
   assert that every class-side view is reachable by inspecting its class. Rewrite the class comment,
   which states the old three rules.
4. Fix the stale `openExample` lines in the `LaserGameBoardElement` and `LaserGameElement` class
   comments.
5. Verify: tests green; the example package is 8 or 9 classes and 20 examples; every example either
   has a sender or carries `<sampleInstance>`.

### P3 — Feasibility audit for every view relocation — done in the image, 2026-10-07, awaiting commit

Nineteen view rows audited, and the paired examples with them. Nine view rows moved to a later
chapter, ten were confirmed, and no view needed splitting. §5 above carries the audited table and §6
the corrected promotion chapters. The audit also found five gaps in the book that P4–P8 must repair:
findings F8–F12. One code change came out of it, `CellExample class >> mirrorOnNoBoard`, which gives
the *Sides* and *Lean* views a cell to open on before the book has a board. `Laser-Game-Tests` runs
306 tests green; critics on `CellExample` report only `ReClassNotReferencedRule`, which is the
standing pattern for an example entry point.

#### Steps as planned

For each of the nineteen views, confirm that everything it calls exists at the chapter §5 sends it
to. A view that needs an element, a shape or a colour that the book has not introduced yet cannot
move there; it moves to the earliest chapter that can carry it, and §5 is corrected.

Output: §5 of this file, with a "verified" mark per row and the blocking dependency named where a row
had to move later. No code changes expected — the views are already on the right classes. Where a
view must be *split* so that a tier-1 half can arrive early and a tier-3 half later, that split is
the only code this phase writes.

### P4 — Section 1: the teaching spine, and the first promotion — book rewritten, 2026-10-07, awaiting commit

Section 1 now carries the cycle: three artefacts named in *Conventions used in this book*, the
feature checkpoint at the end of *Test driven development*, one example and two views in *Enhancing
MirrorCell*, a collected tab in *Enhancing TargetCell*, four examples and one view in *Grid*, and a
closing section in *Chasing the beam* that writes down the two signals the section cannot collect
yet. All 57 gated fences of `doc/section1/section1.md` match the image, the one exception being the
`MyClass >> myMethod` placeholder the conventions chapter teaches the notation with.

Three deviations from the steps as planned, all forced by the P3 audit:

**The example package is born in *Enhancing MirrorCell*, not in *Grid*, which amends D2.** The audit
put the *Sides* and *Lean* views in that chapter, three chapters before a board exists. §3 rule 6 of
the method document requires every view to have an example to open on, so the package is born where
the first example is earned, which is what D2 asked for — the chapter changed, the rationale did not.
*Grid* then promotes `demoGrid` and the three cells read off it, and the section *A better context
for the tests* keeps its place as the chapter that explains why a fixture does not live in the model.

**The gates arrive with the package, which amends D4 in the same way.** §9 says the two generic tests
are written when the example package is created and not retrofitted, so the short gate section sits
at the end of *Enhancing MirrorCell*. It states both gates, quotes a reduced *every example builds*
in an ungated `st` fence, and points at *Looking at objects* for the finished pair, which is where D6
keeps them. The view gate has teeth the day it is written, since two views and one example exist.

**Two chapters lose their planned content and get narrative instead.** *Improving our model* has no
view, because `Cell` is not born until the next chapter, and no example, because every cell worth
keeping is read off a board; it ends with the checkpoint answered "no" four times, which is the
honest and the usual outcome. *The path the beam takes* and *Chasing the beam* promote nothing, for
the reason F11 gives, and say so in a closing section that names where each deferred signal is
collected.

Repairs made in passing: the two `GridTestCase` fences of *The first test* declared a `grid`
temporary the image no longer has, a leftover from P1's move to `setUp`, and the test class is now
shown with its `grid` slot from the start; the three playground snippets of *Chasing the beam* and
the intermediate `testCellInteractions` still borrowed the board through `GridTestCase new
generateDemoGrid`, and now read `GridExample demoGrid`; the final `testCellInteractions` fence was
replaced with the image's version. One code change: `CellExample`'s class comment said every example
answers a cell of a board, which `mirrorOnNoBoard` made false. `Laser-Game-Tests` is 306 tests, all
passing.

A new finding, F13, came out of the fence work and belongs to P5.

#### Steps as planned

1. *Introduction*, section *Conventions used in this book*: name the three artefacts and say that the
   book writes all three.
2. *Test driven development*: after the red-green-refactor sections, add one section — the feature
   checkpoint of `DEV-CYCLE.md` §3, four questions, in two paragraphs. No code.
3. *Improving our model*: the `Cell` *Sides* view and the `GridDirection` *Directions* view arrive
   here, each at its diagnosis gap. `CellExample` gets `blankCell`.
4. *Enhancing MirrorCell*: the *Lean* view arrives, triggered by the sentence the chapter already
   carries about holding four mappings in your head. `CellExample` gets `mirrorCell` and
   `litMirrorCell`.
5. *Enhancing TargetCell*: `CellExample` gets `targetCell` and `litTargetCell`.
6. *Grid*, section *A better context for the tests*: rewrite as the birth of
   `Laser-Game-Examples` and of `GridExample class >> demoGrid`, per D2 and D4, keeping the existing
   paragraph about row-and-column confusion and turning it into the trigger for the *Cells* view,
   which also arrives here. Delete the forward note that points at `GridFactory`.
7. *The path the beam takes* and *Chasing the beam*: the *Beam* view and the `LaserPathElement`
   *Step* view arrive; `GridExample gridWithTheLaserFiring` and the two `LaserPathExample` examples
   are promoted.
8. Re-gate every fence this section touched.

### P5 — Section 2 — book rewritten, 2026-10-07, awaiting commit

Section 2 now carries the cycle through the drawing chapters: `CellRendererExample openExample`
replaces the core opener, `GridFactory` arrives with `emptyStandardGrid` as D3 asked, the *Picture*,
*Board* and *Palette* views arrive at the question each answers, the two `LaserGameBoardExample`
openers and `LaserGameElementExample openExample` are promoted, and every `GridFactory demoGrid` in
the text now reads `GridExample demoGrid`. The widened gate finds 119 gated fences in
`doc/section2/section2.md`, and all 119 match the image; the same widened gate finds 68 in
`doc/section1/section1.md`, up from the 57 P4 reported, and those match too.

Five deviations from the steps as planned.

**F13 is resolved by moving the laser switch two chapters earlier.** `Grid >> fireLaser`,
`Grid >> stopLaser`, `Grid >> clearCellsInPath`, `LaserPathElement >> clearCell` and
`Cell >> clearCell` now arrive in *Drawing the target*, under a new sub-section *A switch for the
beam*, because that is the chapter that draws a target with two states and therefore needs a switch
for both of them. *A unit test to demonstrate a bug* is recast as a re-reading of code written two
chapters earlier, which is what the chapter was already doing with its Section 1 methods, and which
makes its own sentence about the two laser tests checking only the flag true for the first time. The
lesson that resetting an object to how it started is the same thing as initialising it moves out of
the bug chapter and into *A switch for the beam* with the methods it describes. Section 1's closing
checkpoint in *Chasing the beam* is repointed accordingly, and now also names `CellExample
litMirrorCell` and `litTargetCell` among the deferred signals.

**`Cell >> inspectionPicture:` is split across two sections, and its final version is deferred to
P7.** *Drawing the mirror* keeps the intermediate version in an ungated `st` fence, because the
finished view sends `grid laserIsActive: true` and the only reader of that flag in the drawing path,
`CellRenderer >> renderLaserOn:`, is not written until *Laser on blank cell* in Section 4. The note
under the fence says so. The gated final version is therefore P7 work.

**Two new sub-sections carry the promotions the switch earns.** *The board with its laser lit* holds
`LaserGameBoardExample class >> openExampleWithLaserFired`, `GridExample class >>
gridWithTheLaserFiring`, `CellExample class >> litMirrorCell` and `litTargetCell`, and the two
`LaserPathExample` examples; *A tab for the beam* holds `Grid >> inspectionBeam:` and its test.
`LaserPathExample` gets no class-definition fence, only prose, which is how `LaserGameBoardExample`
was introduced two chapters earlier.

**A `setUp` fixture is introduced in *Assembling the game window*.** Three fences of the *Checking
it* section failed the gate because the image builds its game in `LaserGameElementTestCase >> setUp`
rather than in each test. The class definition and the `setUp` are now shown, which is the §4
trigger — one test class wanting a fixture is what `setUp` is for — stated in the book at the point
it applies.

**`LaserGameBoardElement class >> openOn:` keeps its comment on `GridFactory defaultGrid`.** The
obvious edit was to point the comment at `GridExample demoGrid`, and §8 forbids it: core must not
name the example package, not even in a comment. The bogus `tag: 'Graphics'` line was removed from
the `LaserGameBoardElementTestCase` definition fence, since test classes carry no tag in the image.

Repairs and code changes made in passing: `GridFactory class >> emptyStandardGrid` gained a method
comment; two test helpers, `CellRendererTestCase >> testBlankCellElement` and
`TargetCellRendererTestCase >> rendererForTarget:`, declared a `grid` temporary that shadowed the
`grid` slot `setUp` fills, which `ReTempVarOverridesInstVarRule` reports, so the temporary is renamed
`oneCellGrid` in both; the bug chapter's two stale fences were repaired to the image. `Laser-Game-Tests`
is 306 tests, all passing, and `run_critics` is clean on both test classes.

Known interim duplication, removed by later phases: `Grid >> inspectionBoard:` and `inspectionBeam:`
still appear in `doc/section3/section3.md` around line 3524, with a stale
`testTheInspectorTabsOfAGridShowTheBoardAndTheBeam` that still borrows the board through
`self generateDemoGrid`, and the `LaserGameColors` palette trio with its test still appears in
`doc/section5/section5.md` at 4685. P6 and P8 delete the originals.

#### Steps as planned

1. *Rendering the cells*: `CellRendererExample openExample` replaces the core opener in the text.
2. *Drawing the mirror*: delete the "pick up `GridFactory` on the way" framing; the board is already
   an example. Per D3, the factory arrives with `emptyStandardGrid`. The `Cell` *Picture* view
   arrives here, at the first "did it draw what I meant" question.
3. *The game board*: the `Grid` *Board* view arrives; the two `LaserGameBoardExample` openers are
   promoted, and the three dangling method fences are fixed.
4. *Management of colours*: the `LaserGameColors` *Palette* view arrives, class-side, with no
   example, and the text says why a class-side view needs none.
5. *Drawing the target*: `openExampleWithLaserFired` promoted.
6. *Assembling the game window*: `LaserGameElementExample openExample` promoted; the stale fences at
   section2.md:1591, 1728 and 2209 fixed.
7. Rewrite the 22 `GridFactory demoGrid` fences; re-gate the section.

### P6 — Section 3 — book rewritten, 2026-10-07, awaiting commit

Section 3 is now the chapter where the geometry it argues about becomes a picture, a map and a
table. All six views the §5 audit assigns to the section are in place, each at the question it
answers: `CellClickRegion` *Regions* and *Map* in *Determine rotate regions*, `LaserGameShapes`
*Shapes* in *Curved arrows for rotation*, `GridDirection` *Directions* and `LaserPathElement`
*Step* in *Push a cell*, and `Grid` *Pushes* in *Push cells with the mouse*. The section's 46 stale
test fences are rewritten from the image, every `GridFactory demoGrid` in the text now reads
`GridExample demoGrid`, and the two fence gaps F8 and F10 are closed. The gate finds 250 gated
fences in `doc/section3/section3.md`, up from 227, and all 250 match the image; the 69 real fences
of `doc/section1/section1.md` match too, including the three heads repaired here and the two cell
tab tests added to it. No image code was written in P6: every fence was taken character-for-character
from a method that already existed. `Laser-Game-Tests` is 306 tests, all passing.

Eight deviations from the steps as planned.

**The §5 audit supersedes the step list above.** Steps 1–3 and 6 name chapters the audit later
moved: the *Regions* and *Map* views belong together in *Determine rotate regions*, not split
between *Detecting mirror cell click regions* and *Determine push regions*, because the map can only
be painted once every region exists; *Shapes* belongs in *Curved arrows for rotation*, which is where
the gallery is typed a second time, not in *Creating custom shapes*; and *Push a cell* earns two
views the step list does not mention, `GridDirection` *Directions* and `LaserPathElement` *Step*.
§5 is the authority for where each view lives.

**The 46 stale test fences were rewritten mechanically.** The section's test fences had drifted from
the image over the course of the port — different fixtures, renamed selectors, assertions the image
no longer makes. Rewriting them by hand invites exactly the kind of near-miss the gate exists to
catch, so a script replaced each gated fence body with the image source for its head, and the gate
then confirmed all 250 rows.

**`GridTestCase >> generateDemoGrid` is replaced with prose.** The helper does not exist in the
image: the tests take their board from `GridExample demoGrid` directly, which is the point D3 makes.
The fence that defined the helper is now a sentence saying where the board comes from.

**The section no longer introduces the views it uses.** *Rotate a mirror cell* and *Bug with target
cell* had been the home of the *Sides*, *Board*, *Beam* and *Cells* fences, all of which moved to
Section 1 and Section 2 in P4 and P5. Those fences are deleted, and the heading *What will not fit on
one line goes in an inspector tab* is replaced by a fence-free *The tabs we already have*, which
names the four tabs and the chapter each was written in. The *Model or drawing?* discussion keeps its
argument and loses its `Grid >> inspectionCells:` fence, which now lives in Section 1.

**`GridTestCase >> testTheCellsTabListsEveryCellWithItsState` stays in Section 3.** The *Cells* view
moved to Section 1, but its smoke test asserts against a fired beam, and `Grid >> fireLaser` is F11 —
not written until Section 2. The view is therefore introduced in Section 1 and tested in Section 3,
the same split the *Pushes* view needs below.

**F10 and F8 are repaired.** *Any size, from one set of numbers* had a sentence standing in for two
methods; `LaserGameShapes class >> southArrowElementOfExtent:` and `westArrowElementOfExtent:` are
now shown, with the paragraph that says why four methods differing by one word beat a loop over a
dictionary — the browser finds a selector by name, and a dictionary key is findable by nothing.
*Push a cell* likewise owed four fences: `adjacentInversionSymbol` on each of the four
`GridDirection` subclasses, which the beam needs rather than the push, and which the *Directions*
tab then tabulates.

**The `Grid` *Pushes* smoke test is placed in Section 5, not with its view.**
`GridTestCase >> testThePushesTabSaysWhichPushesTheRulesAllow` asserts the number of rows against
`grid numberOfMirrors`, and the grid does not learn to count its own mirrors until *Adding more game
stats*. The view and `Grid >> pushAnswerFor:fromLocation:` arrive with the push in Section 3, and the
test arrives in Section 5 with the counter it needs, under a sentence that says it settles the debt.
Noted in passing, for P7 to weigh: Section 4 already uses `numberOfMirrors` before Section 5 writes
it, which is a pre-existing gap and not one P6 created.

**Two cell tab tests were added to Section 1.** *Enhancing MirrorCell* now carries
`MirrorCellTestCase >> testTheSidesTabListsTheFourSidesOfTheCell` and
`testTheLeanTabComparesMyExitSidesWithTheWayILean` beside the views they exercise, which is where
§9's reachability gate is first stated.

Known interim duplication, removed by P8: every one of the six view blocks P6 inserted still has its
original copy in `doc/section5/section5.md` — *Pushes* at about 4150, `LaserPathElement >> inspectionStep:`
at about 4234, *Regions* and *Map* at about 4332–4500, *Directions* at about 4500, *Shapes* at about
4581 — along with the moved *Lean* test at about 4022 and the second copy of
`testThePushesTabSaysWhichPushesTheRulesAllow`. P8 deletes the originals.

#### Steps as planned

1. *Detecting mirror cell click regions* and *Determine push regions*: the `CellClickRegion`
   *Regions* view arrives, triggered by the geometry the book argues about for most of the section.
2. *Creating custom shapes*: the `LaserGameShapes` *Shapes* view arrives.
3. *Determine rotate regions*: the *Map* view arrives, once every region exists to be painted.
4. *Rotate a mirror cell*: the three views this chapter currently introduces have moved to Section 1
   and Section 2, so the chapter keeps only what it adds, and gains instead the one sentence that
   says the views it is using were written earlier.
5. *Bug with target cell*: same treatment — *Cells* has moved to Section 1; what stays is the bug.
6. *Push a cell*: the `Grid` *Pushes* view arrives.
7. Rewrite the 50 `GridFactory demoGrid` fences; re-gate the section.

### P7 — Section 4 — book rewritten, 2026-10-07, awaiting commit

Section 4 is the section where the game gets its counters, its dealt board and its beam, and it now
has the two views that make those three readable: `LaserGameLedElement` *Segments* in *Add a counter
and window colours*, and `GridFactory` *Boards* in *A bigger game board*. The three `GridExample`
boards and `LaserGameElementExample openStandardExample` are promoted with them, the two
`LaserGameLedExample` displays are promoted beside the *Segments* view, and the final gated
`Cell >> inspectionPicture:` — the one line *Drawing the mirror* promised this section — lands in
*Laser on blank cell*. The gate finds 176 gated fences in `doc/section4/section4.md`, up from 159,
and all 176 match the image. No image code was written in P7: every fence was taken
character-for-character from a method that already existed. `Laser-Game-Tests` is 306 tests, all
passing; both generic gates of `DEV-CYCLE.md` §9 hold, with sixteen examples building and no
instance-side view unreachable.

Five deviations from the steps as planned.

**Step 2 produces nothing.** The §5 audit moved the `GridFactory` *Counts* view out of *Add move
counter and randomizer* and into Section 5 *Adding more game stats*, because its Mirrors column asks
`Grid >> numberOfMirrors`, which Section 5 is the chapter that writes. The step list for P8 does not
mention *Counts* either, so **P8 must take it**: it belongs in *Adding more game stats*, after
S5:18.

**The 27 stale fences were rewritten mechanically.** Section 4's fences had drifted from the image
over the course of the port in the same way Section 3's had, so they were dumped out of the image and
rewritten character-for-character rather than edited by hand. Thirty of the 159 baseline rows were
stale: 27 drifted, and three named methods that no longer exist where the book put them.

**The three relocated openers are now pointers or example fences.** P2 and P5 moved the openers into
`Laser-Game-Examples`, so the old core fences could not be repaired, only replaced.
`LaserGameElement class >> openStandardExample` became
`LaserGameElementExample class >> openStandardExample`, quoted in *Handing the game a board* after
the `GridFactory class >> defaultGrid` fence, since `inspectionBoardFacts` needs both that selector
and `emptyStandardGrid` from Section 2. The other two are pointers rather than fences, because
Section 2 already owns them: `openExample` was promoted in *Assembling the game window*, and
`openExampleWithLaserFired` in *Drawing the target*. The lead-in to the chapter's new work therefore
reads "one line, twice over" rather than three times, and the sentence that listed what each opener
decides now names `defaultGrid` in place of `openStandardExample`. Every prose invocation in the
section was repointed with it: `LaserGameElement openExample` and `openStandardExample` to
`LaserGameElementExample`, `LaserGameBoardElement openExample` and `openExampleWithLaserFired` to
`LaserGameBoardExample`, and the eleven remaining `GridFactory demoGrid` sites to
`GridExample demoGrid`.

**Two fence gaps were closed on the way.** F9 named five methods of `LaserGameLedElement` the book
used but never showed: the class-side `digits:`, and `value`, `value:`, `digitCount` and
`digitCount:`. They are now quoted in *A display drawn from seven rectangles*, `digits:` and the
digit count before `rebuildDigits`, which setting the count calls, and the value pair before
`updateDigits`, which setting the value calls.

**A gap this phase did not close.** *A bigger game board* uses `Grid >> numberOfMirrors` in
`testTheMirrorsStandOneToACellAndAwayFromTheTarget`, and Section 5 is still the section that writes
it. The method predates the examples review, so repairing it is not P7's work, but P8 should decide
whether Section 5's introduction of `numberOfMirrors` moves earlier or the Section 4 test stops
asking for it.

Known interim duplication, removed by P8: the three view blocks P7 inserted still have their
original copies in `doc/section5/section5.md` — `Cell >> inspectionPicture:` and
`testThePictureTabShowsMeAsTheBoardDrawsMe` at about 3946 and 3975, *Segments* and
`inspectionShowsDigit:` at about 4857–4866, and *Boards* with `inspectionBoardsElement` and
`inspectionBoardFacts` at about 5023–5062. The *Boards* fences are the ones to read carefully before
deleting: Section 5 also shows a table of `inspectionBoardFacts` at about 5099, which is a different
view and stays. P8 deletes the originals.

#### Steps as planned


1. *Add a counter and window colours*: the `LaserGameLedElement` *Segments* view arrives; the two
   `LaserGameLedExample` examples are promoted.
2. *Add move counter and randomizer*: the `GridFactory` *Counts* view arrives, at the randomiser that
   needs to be checked by counting.
3. *A bigger game board*: `GridExample standardGrid`, `randomGrid` and `emptyStandardGrid` are
   promoted; `LaserGameElementExample openStandardExample` with them.
4. Rewrite the 35 fences; re-gate the section.

### P8 — Section 5

1. *Undo*: the `Grid` *Moves* view arrives, with its context method, and
   `GridExample gridAfterAMoveAndARotation` is promoted to open on it.
2. *Counters of one width*: the `LaserGameControlPanelElement` *Measures* view arrives, at the
   chapter that is already about measuring.
3. *Buttons of one width*: the *Labels* view arrives.
4. *Adding more game stats*: the `GridFactory` *Counts* view arrives, moved here from Section 4 by
   the §5 audit, after S5:18 writes `Grid >> numberOfMirrors`. Decide at the same time whether
   Section 4's `testTheMirrorsStandOneToACellAndAwayFromTheTarget`, which already asks for
   `numberOfMirrors`, moves the method earlier or stops asking for it.
5. *Looking at objects*: rewrite per D6 — the practice, the five lessons, how a view is tested, the
   two gates, the deletion rule, and *Which object to inspect* with all nineteen views mapped. Expect
   the chapter to fall from roughly 1,350 lines to 300.
6. Rewrite the 35 fences; re-gate the section, and delete the Section 5 duplicates P6 and P7 left
   behind, listed at the end of P6.

### P9 — Close

1. Full `run_tests` on `Laser-Game-Tests`; full `run_critics` on all three packages.
2. Walk every fence of all five files against the image again, 734 of them, and fix the stragglers.
3. Confirm `BaselineOfLaserGame` still loads `core`, `examples`, `tests` and `default` in a clean
   image, with `Laser-Game-Tests` requiring `Laser-Game-Examples` and `Laser-Game` requiring neither.
4. Update `PROJECT_MAP.md`: the counts, the package table, the chapter inventory, and a new short
   section pointing at `DEV-CYCLE.md`.
5. Commits, in the project's convention, one per phase step that changes code.

## 5. Where each view goes — audited, 2026-10-07

Tier is from `DEV-CYCLE.md` §7. "Trigger" is the reason the book will give for writing it there.
Every row was checked by the P3 audit: the view's own sends, the data method behind it, and the
example that opens on it, each against the chapter the row sends it to. A view may be quoted only in
a chapter where everything its fence names already exists, since a `smalltalk` fence matches the
image character for character. Nine rows moved; ten were confirmed.

| View | Side | New home | Earliest line | Tier | Trigger | Verdict |
|---|---|---|---|---|---|---|
| `Cell` *Sides* | instance | S1 *Enhancing MirrorCell* | after S1:1245 | 1 | four sides asked one at a time | moved: `Cell` itself is only born in this chapter (S1:890), and its two questions land at S1:999 and S1:1004 |
| `MirrorCell` *Lean* | instance | S1 *Enhancing MirrorCell* | after S1:1245 | 2 | four mappings held in the head | verified |
| `Grid` *Cells* | instance | S1 *Grid* | after S1:1713 | 1 | row and column confused in `at:put:` | verified, one subsection later than planned: the fixture the view is read on needs `Grid class >> newOfSize:` (S1:1713) |
| `Cell` *Picture* | instance | S2 *Drawing the mirror* | after S2:664 | 3 | did it draw what I meant | done in two halves: P5 put the version without `laserIsActive:` in an ungated `st` fence in S2 *A tab that draws one cell*, and P7 put the final gated one in S4 *Laser on blank cell*, with `MirrorCellTestCase >> testThePictureTabShowsMeAsTheBoardDrawsMe` |
| `Grid` *Board* | instance | S2 *The game board* | after S2:486 | 3 | first board on screen | verified |
| `LaserGameColors` *Palette* | class | S2 *Management of colours* | after S2:963 | 3 | which colour is which name | verified: the view reflects over `self selectors`, so later chapters add rows without touching it |
| `Grid` *Beam* | instance | S2 *Drawing the target* | after S2:1205 | 2 | the path walked by hand in the debugger | moved: the example it is read on fires the laser, and `grid fireLaser` is first evaluated at S2:1205 (F11) |
| `CellClickRegion` *Regions* | class | S3 *Determine rotate regions* | after S3:2828 | 2 | which rectangle a point falls in | moved: `inspectionColorFor:` names `CellClickRegionRotateClockwise` and `…CounterClockwise`, which arrive at S3:2761 and S3:2770 |
| `CellClickRegion` *Map* | class | S3 *Determine rotate regions* | after S3:2828 | 3 | the geometry argued about on paper | verified |
| `LaserGameShapes` *Shapes* | class | S3 *Curved arrows for rotation* | after S3:2649 | 3 | a shape checked by eye at three sizes | moved: `inspectionShapeSelectors` names all seven shapes, and the two rotate arrows arrive at S3:2590 and S3:2599. Two of the seven have no fence at all (F10) |
| `GridDirection` *Directions* | class | S3 *Push a cell* | after S3:5171 | 2 | a question about the whole hierarchy | moved from Section 1: the hierarchy is built at S3:5126. Needs the `adjacentInversionSymbol` fences of F8 |
| `LaserPathElement` *Step* | instance | S3 *Push a cell* | after S3:5171 | 1 | a step is two facts and prints as neither | moved from Section 1: the *Next location* row sends `GridDirection directionFor: … vector` |
| `Grid` *Pushes* | instance | S3 *Push cells with the mouse* | after S3:5458 | 2 | four push rules per mirror | moved: `pushAnswerFor:fromLocation:` asks `canPushCell:fromLocation:`, which arrives at S3:5439 |
| `LaserGameLedElement` *Segments* | instance | S4 *Add a counter and window colours* | after S4:1218 | 1 | seven segments, lit by a digit | done in P7: the five missing fences of F9 were written with it |
| `GridFactory` *Boards* | class | S4 *A bigger game board* | after S4:2697 | 3 | the boards the factory deals, side by side | done in P7, in its own section after the `GridFactory class >> defaultGrid` fence, which is the last of the two selectors `inspectionBoardFacts` sends |
| `Grid` *Moves* | instance | S5 *Undo* | after S5:1103 | 1 | an undo stack that prints as a size | verified |
| `GridFactory` *Counts* | class | S5 *Adding more game stats* | after S5:18 | 2 | the new stats counted on every board I deal | moved from Section 4: the Mirrors column asks `Grid >> numberOfMirrors`, which arrives at S5:18 |
| `LaserGameControlPanelElement` *Labels* | class | S5 *Buttons of one width* | after S5:3698 | 2 | a width stated from its labels | verified |
| `LaserGameControlPanelElement` *Measures* | class | S5 *Buttons of one width* | after the *Labels* view | 2 | a width that measured the wrong thing | moved one chapter later: `inspectionMeasureFacts` asks `buttonLabelMargin`, which arrives at S5:3669, in this chapter |

Where they land: three in Section 1, four in Section 2, six in Section 3, two in Section 4, four in
Section 5. The cap of `DEV-CYCLE.md` §7 — two views in flight at a time — holds in every chapter:
*Enhancing MirrorCell*, *Determine rotate regions*, *Push a cell* and *Buttons of one width* take
two each, and the other eleven chapters take one.

One view was considered for a split and did not need one. The *Step* view's *Next location* row is
the only part that wants `GridDirection`; splitting it would make a second view for one row of a
five-row table, which §11 of the method document tells us to garbage-collect rather than grow. The
whole view moves to *Push a cell* instead.

## 6. Example audit — promotions audited, 2026-10-07

Verdicts: **move** the body, **promote** at a new chapter, **delete**, **add**. The home chapter is
the chapter whose text introduces the example, which is also the earliest chapter that can quote it:
an example is a fence like any other, so every selector it sends must already exist there. P3
audited every row. Two dependencies move a group of rows later than first planned. `GridExample
demoGrid` builds its board with `Grid class >> newOfSize:`, which arrives at S1:1713 in *Grid*, so no
reader of the fixture can appear before that chapter. Six examples fire the laser, and `fireLaser` is
first evaluated at S2:1205 in *Drawing the target* (F11), so none of them can appear in Section 1.

| Example | Verdict | Home chapter | Trigger | Audit |
|---|---|---|---|---|
| `GridExample demoGrid` | moved out of `GridFactory` in P1 | S1 *Grid*, after 1713 | second test class wants the fixture | verified |
| `CellExample blankCell` | promote | S1 *Grid*, after `demoGrid` | the first cell read off the fixture | moved from *Improving our model*: reads `demoGrid` |
| `CellExample mirrorCell` | promote | S1 *Grid*, after `demoGrid` | typed twice | moved from *Enhancing MirrorCell*: reads `demoGrid` |
| `CellExample targetCell` | promote | S1 *Grid*, after `demoGrid` | typed twice | moved from *Enhancing TargetCell*: reads `demoGrid` |
| `CellExample mirrorOnNoBoard` | add | S1 *Enhancing MirrorCell* | pairs with *Sides* and *Lean*, which arrive before any board does | new in P3: the only cell you can build before a grid deals one |
| `GridExample gridWithTheLaserFiring` | promote | S2 *Drawing the target* | typed twice | moved from S1 *The path the beam takes*: sends `fireLaser` |
| `CellExample litMirrorCell` | promote | S2 *Drawing the target* | bug reproduction | moved from S1 *Enhancing MirrorCell*: sends `fireLaser` |
| `CellExample litTargetCell` | promote | S2 *Drawing the target* | bug reproduction | moved from S1 *Enhancing TargetCell*: sends `fireLaser` |
| `LaserPathExample firstStepOfTheBeam` | promote | S2 *Drawing the target* | pairs with *Step* | moved from S1 *The path the beam takes*: sends `fireLaser` |
| `LaserPathExample lastStepOfTheBeam` | promote | S2 *Drawing the target* | the end of the path asked for by itself | moved from S1 *Chasing the beam*: sends `fireLaser` |
| `CellRendererExample openExample` | added in P2, replacing the core opener | S2 *Rendering the cells* | screenshot | verified: builds its own space, no fixture |
| `LaserGameBoardExample openExample` | promote | S2 *The game board* | screenshot | verified |
| `LaserGameBoardExample openExampleWithLaserFired` | promote | S2 *Drawing the target* | screenshot | verified: the chapter that fires the laser |
| `LaserGameElementExample openExample` | promote | S2 *Assembling the game window* | screenshot | verified |
| `GridExample emptyStandardGrid` | promote | S4 *A bigger game board* | screenshot | done in P7, in *Three boards worth keeping* |
| `GridExample standardGrid` | promote | S4 *A bigger game board* | screenshot | done in P7 |
| `GridExample randomGrid` | promote | S4 *A bigger game board* | screenshot | done in P7 |
| `LaserGameElementExample openStandardExample` | promote | S4 *A bigger game board* | screenshot | done in P7, in *Handing the game a board*, replacing the dead core fence |
| `LaserGameLedExample ledShowingOneHundredAndEight` | promote | S4 *Add a counter and window colours* | pairs with *Segments* | done in P7, with the F9 fences |
| `LaserGameLedExample ledShowingEverySegmentLit` | promote | S4 *Add a counter and window colours* | bug reproduction | done in P7, with the F9 fences |
| `GridExample gridAfterAMoveAndARotation` | promote | S5 *Undo* | pairs with *Moves* | verified: the push and the rotation both arrive in Section 3 |
| `CellClickRegionExample clickRegions` | deleted in P2 | — | bookmark, class-side view | class deleted with it |
| `GridDirectionExample directions` | deleted in P2 | — | bookmark, class-side view | class deleted with it |
| `GridFactoryExample boardsTheFactoryDeals` | deleted in P2 | — | bookmark, class-side view | class deleted with it |
| `LaserGameColorsExample palette` | deleted in P2 | — | bookmark, class-side view | class deleted with it |
| `LaserGameControlPanelExample panelMeasures` | deleted in P2 | — | bookmark, class-side view | class deleted with it |
| `LaserGameShapesExample shapes` | deleted in P2 | — | bookmark, class-side view | class deleted with it, along with a duplicate instance-side `shapes` |

25 before, 21 now: six bookmarks deleted, `CellRendererExample openExample` added in P2 and
`CellExample mirrorOnNoBoard` added in P3. Seven example classes remain, since `GridFactoryExample`
and `LaserGameControlPanelExample` held nothing but a bookmark and went with it.

Where they land: five in Section 1, nine in Section 2, six in Section 4 and one in Section 5. Section
3 promotes no example of its own; it carries six of the nineteen views instead.

## 7. The fence and gating pass

- 144 fences name `GridFactory demoGrid` and become `GridExample demoGrid`, or `self grid` where D5
  puts the board in `setUp`. Mechanical, but every one is also a *gated* fence, so each must match
  the image character for character afterwards.
- About a dozen places quote an opener at a class it has left; three are full method fences.
- Every relocated view brings its method fence, its test fence and its prose to the new chapter, and
  leaves a single sentence behind where a later chapter uses it.
- The book's own conventions hold throughout: British spelling, one sentence per line, every fence
  language-tagged, code quoted from the image and never prettified.

## 8. Risks

1. **Scale.** Ten view relocations and twenty example promotions across five files and 65 chapters.
   The text is the work; the code is one afternoon. Sections 3 to 5 are 16,000 of the 21,000 lines.
2. **A relocation that will not compile at its new chapter.** P3 exists to catch this before text is
   written. The likely casualties are the picture views, which need an element the book may not have
   introduced yet, and *Map*, which needs the shapes.
3. **Section 1 getting heavy.** Four views, a new package, two generic gates and seven examples all
   land in a section written for a reader who may be new to programming. Mitigation: D4's option of
   deferring the gates, and a hard rule that a view arrives in at most two paragraphs and one fence.
4. **Re-gating drift.** 734 fences were gated once; this plan touches a quarter of them. P9's full
   walk is not optional.
5. **The 2007 page order.** D3 option B and the shrinking of *Looking at objects* both move further
   from the original structure than anything the port has done so far. D3 option A keeps the page
   anchor; D6 does not, and should be stated in the chapter itself.

## 9. Done when

- No method of `Laser-Game` names anything in `Laser-Game-Examples`, and no fixture lives in core.
- Every view is introduced in the chapter where a developer following `DEV-CYCLE.md` would have
  written it, with the trigger named in the prose.
- Every example is introduced at its promotion, with one of the four triggers named.
- No bookmark examples. No example without a sender or a `<sampleInstance>`.
- `LaserGameExamplesTestCase` gates instance-side coverage and exempts class-side views.
- 305 runs green, critics clean, baseline loads in a clean image.
- All 734 fences match the image.
- *Looking at objects* teaches the practice and maps the views, and teaches no view for the first
  time.
- `PROJECT_MAP.md` points at `DEV-CYCLE.md`, and `DEV-CYCLE.md` is unchanged by this plan except
  where the work proved it wrong.
