<!-- Tutorial Section 5 covers pages 174 to 204 of tut2007/html.
     This file starts at page 174, the first page of the section. -->

# A Missed Bug

*Pages 174 to 179 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/174.html
     http://squeak.preeminent.org/tut2007/html/175.html
     http://squeak.preeminent.org/tut2007/html/176.html
     http://squeak.preeminent.org/tut2007/html/177.html
     http://squeak.preeminent.org/tut2007/html/178.html
     http://squeak.preeminent.org/tut2007/html/179.html
     -->

Section 5 opens with the author noticing that the push hints and the pushes do not always agree, sitting down to think about it, and realising something else:

> I thought about that and realized we had not run the unit tests for a while. Sure enough. We have several failing unit tests. An error in our process is that we didn't run these tests each time before we saved the new package version.

Four tests are failing. Three of them are failing because they were written down for a cell of thirty pixels and the cell has been forty since page 137. The fourth is a real bug, and the tests had been red long enough that nobody knows when it arrived.

## What the original finds

Page 175 is the push table. Nine points were chosen by hand for a thirty pixel cell with a ten pixel border, and nine new points are chosen by hand for a forty pixel one: `20@10` becomes `30@10`, `15@15` becomes `20@20`, `14@16` becomes `19@21`. Page 176 does the same for the fifteen points of the rotate table. That test still fails.

Page 177 is the bug. The outside region of a cell turns the mirror clockwise in its upper half and counter clockwise in its lower half, and the two halves answer for themselves:

```
containsPoint: aPoint
    ^aPoint y <= (CellRenderer cellExtent y)

containsPoint: aPoint
    ^aPoint y > (CellRenderer cellExtent y)
```

Neither of them halves the cell, so the first one owns every point of it and the second owns none. The author asks the obvious question — "How was this ever working correctly?" — and adds the `// 2` to both.

Page 178 is the ignore region test, where `29@29` becomes `39@39`. Page 179 is `testCellOffsetCalculations`, where three expected offsets of `30` become `40`, and the page is careful to say each time that the code is right and the test is wrong. All green again, and the section ends on the lesson:

> The most important lesson here is that we should always run our unit tests before we version our packages. If the unit tests do not pass, we should not release a version of our code.

## Three of the four cannot happen here

The port has run `run_tests` on the package at the end of every subsection since Section 2, so nothing has been red for long. More to the point, the three failures of pages 175, 176 and 178 are failures of tests that write a cell size down, and the port has not written one down since Section 3.5. Its tables ask the regions where they are:

```
CellClickInsideRegionPushTestCase >> testClicksInPushRegions

	| pt regionClass pushRegion testTable cls rect |
	rect := CellClickRegionInside regionRectangle.
	pt := rect topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionInside.
	testTable := {
		             (rect topLeft -> CellClickRegionPushEast).
		             (rect topRight -> CellClickRegionPushWest).
		             (rect center -> CellClickRegionPushNorth).
		             (rect bottomLeft -> CellClickRegionPushNorth).
		             (rect bottomRight -> CellClickRegionPushNorth).
		             (rect topLeft + (1 @ 3) -> CellClickRegionPushEast).
		             (rect center + (-1 @ 1) -> CellClickRegionPushNorth).
		             (rect bottomRight + (-1 @ -3)
		              -> CellClickRegionPushWest).
		             (rect topCenter + (0 @ 1) -> CellClickRegionPushSouth) }.
	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self assert: pushRegion equals: cls ]
```
> **Note.** *A Less Brittle Unit Test Design*, the seventh chapter of this section, moves this table into `#assertPushRegionTable` so that the same nine rows can be run at three cell sizes.

Page 177's bug never existed either. The two `containsPoint:` methods were written at Section 3.8, from page 103, which says in words what the code has to do, and they say it with the cell:

```smalltalk
CellClickRegionRotateClockwise class >> containsPoint: aPoint
	"Answer whether aPoint is in the upper half of the cell. The line is half the height of the
	cell rather than a number of pixels, so it follows the cell size of page 138. A point exactly
	on the line is mine, which is what page 103 asks for."

	^aPoint y <= (CellRenderer cellExtent y // 2)
```

```smalltalk
CellClickRegionRotateCounterClockwise class >> containsPoint: aPoint
	"Answer whether aPoint is in the lower half of the cell. My sister takes the line itself, so
	I ask for a strictly greater y, and the two of us cover the region without overlapping."

	^aPoint y > (CellRenderer cellExtent y // 2)
```

Two tests hold them to it. One is the point on the line itself, which page 103 gives to the upper half:

```smalltalk
CellClickOutsideRegionRotateTestCase >> testAPointOnTheDividingLineTurnsTheMirrorClockwise
	"Page 103 puts the dividing line at half the height of the cell and says a point on it counts
	as belonging to the upper half. The line is the cell's, not the region's, so it is written
	here as the cell says it."

	| onTheLine |
	onTheLine := CellClickRegionOutside regionRectangle left
	             @ (CellRenderer cellExtent y // 2).
	self assert: (CellClickRegionRotateClockwise containsPoint: onTheLine).
	self deny:
		(CellClickRegionRotateCounterClockwise containsPoint: onTheLine).
	self
		assert: (CellClickRegionOutside rotateRegionForPoint: onTheLine)
		equals: CellClickRegionRotateClockwise.
	self
		assert:
		(CellClickRegionOutside rotateRegionForPoint: onTheLine + (0 @ 1))
		equals: CellClickRegionRotateCounterClockwise
```

The other walks the region instead of sampling it:

```smalltalk
CellClickOutsideRegionRotateTestCase >> testEveryPointOfTheOutsideRegionIsInExactlyOneRotateRegion
	"The dividing line of page 101 cuts the outside region into an upper and a lower half that
	cover it and do not overlap, so every point of it turns the mirror one way and not the other.
	The original checked fifteen points of a 30 pixel cell; this walks the whole region."

	| rect |
	rect := CellClickRegionOutside regionRectangle.
	rect left to: rect right do: [ :x |
		rect top to: rect bottom do: [ :y |
			| point matching |
			point := x @ y.
			matching := CellClickRegionOutside subclasses select: [ :each |
				            each containsPoint: point ].
			self assert: matching size equals: 1 ] ]
```

The first of those two fails on the original's code, since `onTheLine + (0 @ 1)` is answered clockwise there. The second does not: with both halves comparing against the whole height, every point of the cell still matches exactly one class. A test that counts the classes a point belongs to cannot see a line that is in the wrong place, and it took the point on the line to find it.

Page 179 has no counterpart at all. `testCellOffsetCalculations` asks `CellRenderer >> offsetWithinGridForm` where a cell starts within the shared board form, and the port has no shared board form: a cell is an element, and the grid layout puts it where it goes. The method is still in the image, with the rest of the 2007 painting husk, and nothing calls it.

## The same bug, in the port's own code

That is three pages of the original answered with "it cannot happen here", which is a claim worth checking rather than making. The cell size is one method, so the check is one experiment: give it another value and run the suite.

```smalltalk
CellRenderer class compile: 'cellExtent ^30@30' classified: 'constants'.
(TestSuite new addTests: LaserGameElementTestCase buildSuite tests; run) printString
```

Four tests fail at thirty pixels, and the same four fail at sixty-four. They are the port's own, from *A Window The Player Can Resize*, and they fail for exactly the reason pages 175 to 178 fail: a number that belongs to the model was written into the test.

```
testAGameScalesToFillTheWindowItIsGiven
	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game naturalExtent equals: 380 @ 270.
	game fitIn: 760 @ 540.
	self assert: (game scaleToFitIn: 760 @ 540) equals: 2.0.
```
> **Note.** This is the test as *A Window The Player Can Resize* wrote it, before this chapter. `380 @ 270` is the extent of a demo board of fifty pixel cells, and `760 @ 540` is twice it.

The game is asked for its natural extent instead, and the windows are multiples of that:

```smalltalk
LaserGameElementTestCase >> testAGameScalesToFillTheWindowItIsGiven
	"The game is drawn at the size the board asks for and scaled to whatever the window is, so a
	window of twice that extent shows the same game twice as big, filling it. The extent is read
	from the game and not written down, because the cell size decides it: pages 174 to 179 of the
	original are the tale of four tests that had been written down for a cell of thirty pixels."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural * 2.
	self assert: (game scaleToFitIn: natural * 2) equals: 2.0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game transformation matrix sy equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
```

```smalltalk
LaserGameElementTestCase >> testAGameShrinksWithASmallerWindow
	"A window smaller than the board scales the game down rather than cutting it off, so the whole
	board is always in view. Half the natural extent is half the game, whatever a cell measures."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural / 2.
	self assert: game transformation matrix sx equals: 0.5.
	self assert: game constraints position equals: 0 @ 0
```

```smalltalk
LaserGameElementTestCase >> testAGameIgnoresAWindowOfNoSize
	"A space announces its extent while it is being opened, and that extent can be nothing at all.
	Scaling by zero would take the game off the screen, so a window of no size is left alone."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural * 2.
	game fitIn: 0 @ 0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
```

The window of another shape is the one that says most, because the leftover it centres is half of whatever direction is loose:

```smalltalk
LaserGameElementTestCase >> testAGameKeepsItsShapeInAWindowOfAnotherShape
	"A board is as wide and as tall as it is. A window of another shape scales the game by the
	tighter of the two directions and centres what is left over, so the cells stay square and the
	game is never stretched. The window is twice the natural extent in one direction only, so the
	scale is one and the leftover is half the other direction, at any cell size."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural x * 2 @ natural y.
	self assert: (game scaleToFitIn: natural x * 2 @ natural y) equals: 1.0.
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: natural x / 2 @ 0.
	game fitIn: natural x @ (natural y * 2).
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: 0 @ (natural y / 2)
```

With those four repaired the suite is green at thirty, forty, sixty-four and a hundred pixels, and one more test fails at twenty-six. It moved the pointer four pixels down and expected to still be in the same push region, which stops being true once the inside region is smaller than eight pixels:

```smalltalk
LaserGameCellElementTestCase >> testTheCrossHairFollowsThePointerWithinOneRegion
	"The arrow is built once per region, since it does not change while the pointer stays in one,
	but the cross hair marks a point and moves with every event. The step down is a quarter of the
	inside region rather than four pixels, so the second point is in the same push region as the
	first at any cell size."

	| board element first second extent step |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	extent := CellRenderer crossHairExtent.
	step := CellClickRegionInside regionRectangle height // 4 max: 1.
	first := CellClickRegionInside regionRectangle center.
	second := first + (0 @ step).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: first;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: second;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	self
		assert: element crossHairElement constraints position + (extent // 2)
		equals: second
```

## Where the floor is

Below twenty-six pixels the suite fails whatever the tests do, and the reason is the original's own arithmetic:

```smalltalk
CellRenderer class >> insideRegionExtent
	"Answer the size of the square in the middle of a cell where a click asks for a push. Page
	138 of the original writes it as the cell less twenty pixels, so the ring around it keeps its
	width while the cell grows."

	^self cellExtent - 20
```

Twenty pixels of a cell belong to the ring around the push region, so a cell of twenty-four has a push region four pixels across, its corners and its centre are two pixels apart, and a table of nine points is no longer a table of nine different points. That is a limit of the design page 138 chose, not of the tests, and the port keeps it: a cell is at least twenty-six pixels.

## Checking it

The experiment is worth keeping as a habit rather than as a test, since a test cannot change the cell size under the suite it is part of. Run it by hand when a size is added:

```smalltalk
| source |
source := (CellRenderer class >> #cellExtent) sourceCode.
#( '^26@26' '^30@30' '^40@40' '^64@64' '^100@100' ) do: [ :each |
	CellRenderer class
		compile: (source copyReplaceAll: '^50@50' with: each)
		classified: 'constants'.
	Transcript showln: each , ' ' , (TestSuite new
			 addTests: ((('Laser-Game' asPackage classes select: [ :c |
					   c inheritsFrom: TestCase ]) collect: [ :c | c buildSuite ])
					  inject: OrderedCollection new
					  into: [ :all :suite | all addAll: suite tests; yourself ]);
			 run) printString ].
CellRenderer class compile: source classified: 'constants'
```

Two hundred and twenty-four tests, green at every one of those sizes. The original found its bug by playing the game and then remembering to run the tests; the port found its own by asking what the tests would say if the one number they all depend on were something else.


# Adding More Game Stats

*Pages 180 to 182 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/180.html
     http://squeak.preeminent.org/tut2007/html/181.html
     http://squeak.preeminent.org/tut2007/html/182.html
     -->

Two more numbers for the player: how many mirrors stand on the board, and how many of them the beam lights. The grid can answer both already; the work is in the panel.

## The grid knew the answer before the panel asked

Page 180 writes two stubs on `Grid`, then two unit tests, then the real methods. The port took the whole of the 2007 `Grid` in Section 1, so both methods and both tests came with it and have been green ever since:

```smalltalk
Grid >> numberOfMirrors
	^(self cells select: [:each | each class = MirrorCell]) size
```

```smalltalk
Grid >> numberOfActiveMirrors
	^(self cells select: [:each | (each class = MirrorCell) and: [each isOn]]) size
```

```smalltalk
GridTestCase >> testNumberOfMirrorsCounter

	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfMirrors.
	self assert: count equals: 10
```

```smalltalk
GridTestCase >> testNumberOfActiveMirrorsCounter

	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfActiveMirrors.
	self assert: count equals: 0.
	grid fireLaser.
	count := grid numberOfActiveMirrors.
	self assert: count equals: 3
```

The original writes its two assertions as `self should: [count = 10]`, which passes whatever the count is: `should:` answers the value of the block to its caller and fails only when the block raises. The port writes `assert:equals:`, which is the whole of the difference. The demo grid holds ten mirrors, three of which the beam reaches.

## What the original adds to the panel

Page 181 builds two more `LedMorph`s, each wrapped in a named panel:

```
makeMirrorsCounterMorph
    | count |
    count := LedMorph new
                digits: 3;
                extent: 3 * 10 @ 15;
                setBalloonText: ''.
    count color: (Color r: 0.674 g: 0.674 b: 0.96).
    count name: 'mirrors'.
    ^ self wrapPanel: count label: 'Mirrors'
```

```
makeActiveMirrorsCounterMorph
    | count |
    count := LedMorph new
                digits: 3;
                extent: 3 * 10 @ 15;
                setBalloonText: ''.
    count color: (Color r: 0.674 g: 0.674 b: 0.96).
    count name: 'activeMirrors'.
    ^ self wrapPanel: count label: 'Active Mirrors'
```

It places them with two more layout frames, counted in pixels from the top of the panel, forty-eight apart like the two before them:

```
addCountersToPanel: panel
    panel
        addMorph: self makeLaserPathCounterMorph
        fullFrame: (LayoutFrame
                fractions: (0 @ 0 corner: 1 @ 0)
                offsets: (4 @ 4 corner: -8 @ 44));

        addMorph: self makeMovesCounterMorph
        fullFrame: (LayoutFrame
                fractions: (0 @ 0 corner: 1 @ 0)
                offsets: (4 @ 48 corner: -8 @ 92));

        addMorph: self makeMirrorsCounterMorph
        fullFrame: (LayoutFrame
                fractions: (0 @ 0 corner: 1 @ 0)
                offsets: (4 @ 96 corner: -8 @ 140));

        addMorph: self makeActiveMirrorsCounterMorph
        fullFrame: (LayoutFrame
                fractions: (0 @ 0 corner: 1 @ 0)
                offsets: (4 @ 144 corner: -8 @ 188))
```

And page 182 finds them again, by name, among every morph of the game, to set them in `updateCounters`:

```
findMirrorsCounter
    ^self allMorphs detect: [:m | m knownName = 'mirrors'] ifNone: []

findActiveMirrorsCounter
    ^self allMorphs detect: [:m | m knownName = 'activeMirrors'] ifNone: []
```

```
updateCounters
    | led |
    led := self findLaserPathCounter.
    led notNil ifTrue: [
        self laserActive
            ifTrue: [led
                highlighted: true;
                value: self grid laserBeamPath size]
            ifFalse: [led
                highlighted: false;
                value: 0]
            ].
    led := self findMovesCounter.
    led notNil ifTrue: [
        led
            highlighted: false;
            value: self moves asString].
    led := self findMirrorsCounter.
    led notNil ifTrue: [
        led
            highlighted: false;
            value: self grid numberOfMirrors asString].
    led := self findActiveMirrorsCounter.
    led notNil ifTrue: [
        led
            highlighted: false;
            value: self grid numberOfActiveMirrors asString].
```

## The tests first

Two counters, so two tests for what they are and one for what they show. The panel holds them, so a test can ask for them by name:

```smalltalk
LaserGameControlPanelElementTestCase >> testMirrorsCounterIsThreeDigitsCaptionedMirrors
	"Page 181's first new counter: the same three digit display as the others, captioned Mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel mirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel mirrorsCounter led digitCount equals: 3.
	self assert: panel mirrorsCounter label text asString equals: 'Mirrors'
```

```smalltalk
LaserGameControlPanelElementTestCase >> testActiveMirrorsCounterIsThreeDigitsCaptionedActiveMirrors
	"Page 181's second new counter, captioned Active Mirrors. That caption is the longest of the
	four, and it is why the original widens its panel on the same page."

	| panel |
	panel := self newPanel.
	self assert: panel activeMirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel activeMirrorsCounter led digitCount equals: 3.
	self
		assert: panel activeMirrorsCounter label text asString
		equals: 'Active Mirrors'
```

The order of the column is page 181's order, and it is now four counters rather than two, so the test that asserted the pair is rewritten to assert the four:

```smalltalk
LaserGameControlPanelElementTestCase >> testCounterColumnHoldsTheFourCountersInOrder
	"Page 181 adds the mirror counters under the two the panel already had, in the order the
	layout frames of that page put them: the beam, the moves, the mirrors, then the active
	mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel counterColumn children asArray equals: {
			panel laserPathCounter.
			panel movesCounter.
			panel mirrorsCounter.
			panel activeMirrorsCounter }
```

```smalltalk
LaserGameControlPanelElementTestCase >> testMirrorCountersShowTheGridCountsAndAreNeverBright
	"Page 182 sets both mirror counters from the grid with #highlighted: false, like the move
	counter: only the beam counter says whether the laser is on. The demo grid holds ten mirrors,
	of which three are lit once the laser fires; the numbers are read from the grid, since
	GridTestCase is where they are written down."

	| panel |
	panel := self newPanel.
	self
		assert: panel mirrorsCounter value
		equals: panel game grid numberOfMirrors.
	self assert: panel activeMirrorsCounter value equals: 0.
	panel game grid fireLaser.
	panel updateCounters.
	self
		assert: panel mirrorsCounter value
		equals: panel game grid numberOfMirrors.
	self
		assert: panel activeMirrorsCounter value
		equals: panel game grid numberOfActiveMirrors.
	self assert: panel activeMirrorsCounter value > 0.
	self deny: panel mirrorsCounter highlighted.
	self deny: panel activeMirrorsCounter highlighted
```

## What the port adds

Two builders and two accessors, the same shape as the two counters that were already there:

> **Note.** The chapter *Counters Of One Width*, at the end of Section 5, sends `newCounterLabelled:digits:` here instead, which states the width every counter of the panel is given. The block below is the method as this page leaves it.

```
LaserGameControlPanelElement >> newMirrorsCounter
	"Answer the counter showing how many mirrors stand on the board: three digits, captioned as on
	page 181."

	^ LaserGameCounterElement labelled: 'Mirrors' digits: 3
```

> **Note.** The chapter *Counters Of One Width*, at the end of Section 5, sends `newCounterLabelled:digits:` here instead, which states the width every counter of the panel is given. The block below is the method as this page leaves it.

```
LaserGameControlPanelElement >> newActiveMirrorsCounter
	"Answer the counter showing how many mirrors the beam lights: three digits, captioned as on
	page 181. That caption is the longest of the four, and it is why the original widens its panel
	on the same page."

	^ LaserGameCounterElement labelled: 'Active Mirrors' digits: 3
```

```smalltalk
LaserGameControlPanelElement >> mirrorsCounter
	"Answer the counter showing how many mirrors stand on the board. I hold it, so nothing has to
	search for it: page 182 finds it by walking every morph of the game looking for the name
	'mirrors'."

	^ mirrorsCounter
```

```smalltalk
LaserGameControlPanelElement >> activeMirrorsCounter
	"Answer the counter showing how many mirrors the beam lights. I hold it, so nothing has to
	search for it: page 182 finds it by walking every morph of the game looking for the name
	'activeMirrors'."

	^ activeMirrorsCounter
```

The column stacks all four, and the layout puts them where the four layout frames of page 181 put theirs, without any of the offsets being counted:

```smalltalk
LaserGameControlPanelElement >> newCounterColumn
	"Answer the column of counters, at the top left corner of the panel, one gap away from both
	edges: the beam length, the move count, the number of mirrors, and the number of mirrors the
	beam lights. Page 143 places the second counter with a layout frame forty-four pixels below
	the first, which is the height of one counter and this gap, and page 181 places the other two
	forty-eight pixels apart again. Here the layout stacks them, so no offset is counted."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class counterGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignTop ].
	column margin: (BlInsets all: self class counterGap).
	column addChild: laserPathCounter.
	column addChild: movesCounter.
	column addChild: mirrorsCounter.
	column addChild: activeMirrorsCounter.
	^ column
```

And the two new numbers are set where the two old ones are. Page 182 has to find each display first; the panel holds all four, so there is nothing to find:

```smalltalk
LaserGameControlPanelElement >> updateCounters
	"Show how long the beam is while the laser fires, and nothing while it does not, show how many
	moves have been made, and show how many mirrors stand on the board and how many of them the
	beam lights. This is page 143's #updateCounters as page 182 extends it, which has to find each
	display among the morphs of the game first; I hold all four. Only the beam counter is ever
	bright: it alone says whether the laser is on."

	self game laserIsActive
		ifTrue: [
			self laserPathCounter
				highlighted: true;
				value: self game grid laserBeamPath size ]
		ifFalse: [
			self laserPathCounter
				highlighted: false;
				value: 0 ].
	self movesCounter
		highlighted: false;
		value: self game moves.
	self mirrorsCounter
		highlighted: false;
		value: self game grid numberOfMirrors.
	self activeMirrorsCounter
		highlighted: false;
		value: self game grid numberOfActiveMirrors
```

## The width the original widens

Page 181 raises `panelWidth` from its earlier value to a hundred and ten, "because of the larger tag in the active mirrors counter":

```
panelWidth
    ^110
```

The port has answered a hundred and ten since Section 3.13, and not because of a caption: it is the width of a row of two buttons and the three gaps around them, which `testARowOfTwoButtonsFitsInsideThePanel` has asserted since page 144. So the check runs the other way here — the widest caption has to fit in the width the buttons ask for:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryCounterFitsInsideThePanel
	"Page 181 widens the panel because the caption of the active mirrors counter is longer than
	the ones before it. Here the panel width is the width of a row of two buttons, so the check
	runs the other way: the widest counter has to fit in the width the buttons ask for, with the
	gap on both sides. A counter takes the size of its caption, so the column is asked to measure
	itself first; nothing is laid out, and no element is opened."

	| panel |
	panel := self newPanel.
	panel counterColumn measure: BlExtentMeasurementSpec unspecified.
	panel counterColumn children do: [ :counter |
		self
			assert:
				counter measuredExtent x
				+ (2 * LaserGameControlPanelElement counterGap)
			<= LaserGameElement panelWidth ]
```

`measure:` is how an element is asked for its size without a layout pass and without a space to show it in; the counters are `fitContent`, so their size is the size of their caption and cannot be read from a resizer. `Active Mirrors` comes to sixty-four pixels, and the panel is a hundred and ten.

## The panel that was too short

The height did not fit. Four counters are two hundred and twenty pixels of panel, the two rows of buttons are seventy, and the panel is exactly as tall as the board beside it — which for the demo grid of five rows of fifty pixel cells is two hundred and fifty. The New button was drawn over the caption of the active mirrors counter.

The original never meets this. Its example board is eight by ten cells of thirty pixels, three hundred pixels tall, and its last counter ends at a hundred and eighty-eight. A board short enough to reach the buttons would have overlapped there too, and page 181 says as much in passing when it warns to close every open game before the dimensions change.

The port states the height it needs, so it can be asked for before a panel exists:

```smalltalk
LaserGameControlPanelElement class >> counterCount
	"Answer how many counters I stack. Page 141 opens with one, page 143 adds the second, and page
	181 the last two."

	^ 4
```

```
LaserGameControlPanelElement class >> contentHeight
	"Answer the height, in pixels, of everything I hold: my counters, stacked with a gap between
	them and a gap above and below, and the two rows of buttons under them. A counter takes the
	size of its caption, so one is built and measured; nothing is laid out and nothing is opened.
	The original never needs this number, since it places its counters at fixed offsets from the
	top of a panel that is always taller than they are."

	| counter |
	counter := LaserGameCounterElement labelled: 'Active Mirrors' digits: 3.
	counter measure: BlExtentMeasurementSpec unspecified.
	^ ((self counterCount * counter measuredExtent y)
	   + ((self counterCount + 3) * self counterGap)
	   + (2 * self buttonHeight) + (3 * self buttonGap)) ceiling
```
> **Note.** *Reset (and a bug fix)*, the fifth chapter of Section 5, states this over #buttonRowCount, since a third row of buttons is added there.

```smalltalk
LaserGameControlPanelElement class >> heightForGrid: aGrid
	"Answer how tall I am beside a board showing aGrid: as tall as that board, or as tall as what I
	hold when the board is shorter than that. The original has the first half of this only: its
	board is never short enough for the counters to reach the buttons, and a board that was would
	have them overlap."

	^ (LaserGameBoardElement extentForGrid: aGrid) y max: self contentHeight
```

A number stated from constants is a number that can drift away from what is really there, so a test holds it to the measurement:

```smalltalk
LaserGameControlPanelElementTestCase >> testContentHeightIsWhatTheCountersAndButtonsMeasure
	"The height the panel falls back on is stated from the constants, so that it can be asked of
	the class before a panel exists. Here it is checked against what the two columns actually
	measure, which is the only thing that keeps the statement true."

	| panel counters buttons |
	panel := self newPanel.
	counters := panel counterColumn.
	buttons := panel buttonColumn.
	counters measure: BlExtentMeasurementSpec unspecified.
	buttons measure: BlExtentMeasurementSpec unspecified.
	self
		assert: LaserGameControlPanelElement contentHeight
		equals:
			counters measuredExtent y
			+ (2 * LaserGameControlPanelElement counterGap)
			+ buttons measuredExtent y.
	self
		assert: counters children size
		equals: LaserGameControlPanelElement counterCount
```

The panel takes that height, and so does the window around it. Two tests that said "as tall as the board" now say "as tall as the board, or as tall as what it holds":

```smalltalk
LaserGameControlPanelElementTestCase >> testPanelIsAPanelWideColumnAsTallAsTheBoardOrItsContents
	"The panel sizes itself: the original's panel width, and the height of the board beside it —
	unless the board is shorter than what the panel holds, which the demo grid of five rows is
	once page 181 has added the mirror counters. Then the panel keeps the height of its contents,
	so the counters never reach the buttons."

	| grid panel |
	grid := GridFactory demoGrid.
	panel := (LaserGameElement on: grid) controlPanel.
	self
		assert: panel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: panel constraints vertical resizer size
		equals: LaserGameControlPanelElement contentHeight.
	self
		assert: LaserGameControlPanelElement contentHeight
		> (LaserGameBoardElement extentForGrid: grid) y.
	self
		assert: (LaserGameControlPanelElement heightForGrid:
				 (GridFactory randomizedGridOfExtent: 8 @ 10))
		equals:
			(LaserGameBoardElement extentForGrid:
				 (GridFactory randomizedGridOfExtent: 8 @ 10)) y
```

```smalltalk
LaserGameElementTestCase >> testControlPanelIsAFixedColumnAsTallAsTheBoardOrItsContents
	"The panel keeps the original's width whatever the grid is, and it is as tall as the board
	beside it — or as tall as what it holds, when that is more, which is what a board of five rows
	comes to once page 181 has added the mirror counters. Sizes are read from the layout
	constraints, since nothing is laid out yet."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: (LaserGameControlPanelElement heightForGrid: grid).
	self
		assert: game controlPanel background paint color
		equals: LaserGameColors controlPanelColor
```

```smalltalk
LaserGameElement class >> extentForGrid: aGrid
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side. This is the original's calculatedExtent, with the board element
	standing in for the board form. The height is the taller of the board and the panel, since a
	board of few rows is shorter than everything the panel holds; the original has no such case
	and takes the board height alone."

	^ (LaserGameBoardElement extentForGrid: aGrid) x + self panelWidth
	  @ (LaserGameControlPanelElement heightForGrid: aGrid)
	  + (2 * self gameMargin)
```

> **Note.** The chapter *Buttons Of One Width*, at the end of Section 5, widens the panel to a hundred and thirty, and this test states that number. It is quoted here as it read before that.

```
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins
	"The game is as wide as the board, the panel beside it and a margin on each side, and as tall
	as the taller of the board and the panel, with a margin above and below. This is the
	original's calculatedExtent, which knows only the board height; the demo grid is short enough
	for the panel to decide instead."

	| grid expected |
	grid := GridFactory demoGrid.
	expected := (LaserGameBoardElement extentForGrid: grid) x
	            + LaserGameElement panelWidth
	            @ (LaserGameControlPanelElement heightForGrid: grid)
	            + (2 * LaserGameElement gameMargin).
	self assert: (LaserGameElement extentForGrid: grid) equals: expected.
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals:
			5 * CellRenderer cellExtent x + 110
			@ LaserGameControlPanelElement contentHeight + 20
```

The demo board is now three hundred and ten pixels tall instead of two hundred and seventy, and a strip of window sits under the board where the panel goes on. A board of eight by ten is unchanged, since there the board is the taller of the two.

## Ten variables is one too many

The four counters brought the panel to ten instance variables, which is where `ReExcessiveVariablesRule` speaks up. Two of them were not carrying anything: the two columns are the panel's two children, in the order `rebuild` adds them, and the rows of the button column were already read that way by `buttonRow` and `newGameRow`. So they are read the same way:

```smalltalk
LaserGameControlPanelElement >> counterColumn
	"Answer the column of counters at the top of me. It is my first child, since #rebuild adds the
	counters before the buttons; the rows of the button column are read by position in the same
	way."

	^ self children first
```

```smalltalk
LaserGameControlPanelElement >> buttonColumn
	"Answer the column of button rows at the bottom of me. It is my last child, since #rebuild
	adds it after the counters."

	^ self children last
```

```
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me, or the height
	of what I hold when that is more. The counter column goes in first and the button column
	second, which is the order #counterColumn and #buttonColumn read them back in."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	mirrorsCounter := self newMirrorsCounter.
	activeMirrorsCounter := self newActiveMirrorsCounter.
	self addChild: self newCounterColumn.
	self addChild: self newButtonColumn.
	self extent: LaserGameElement panelWidth
		@ (self class heightForGrid: self game grid).
	self updateCounters
```
> **Note.** *Undo*, the third chapter of Section 5, builds the Undo button here as well.

Eight variables, no critic, and every counter and every button still held rather than searched for — which is the whole point of the class beside pages 142 and 182.

Two hundred and twenty-nine tests, green.

# Undo

*Pages 183 to 187 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/183.html
     http://squeak.preeminent.org/tut2007/html/184.html
     http://squeak.preeminent.org/tut2007/html/185.html
     http://squeak.preeminent.org/tut2007/html/186.html
     http://squeak.preeminent.org/tut2007/html/187.html
     -->

A button that takes the last move back. Page 183 sets two rules for it: the stack has no upper bound, so every move of a game can be taken back one at a time, and an undo removes no count from the total number of moves the player has made. The second rule is what makes the moves counter honest: taking a move back is itself work, and the statistics are meant to stay interesting.

This is the section where the port has the least to write, and for the same reason as page 180 in the previous one: the whole model half of it was captured in Section 1 and has been sitting in the image, green, ever since. What is new here is the button, the game method behind it, and one test the original does not write.

## Another decision hierarchy

Page 183 adds seven classes: `ReverseLaserGameAction` and one subclass per action that can be undone, which is the four pushes and the two rotations. Firing the laser has no undo action, so there is no class for it. It is the third hierarchy of the project built on the same idea as `GridDirection` and `CellClickRegion`: the answer is a class, and the question is asked of the superclass.

Page 184 does something the two earlier hierarchies do not. The classes answer *selectors* — the name of the method that undoes an action — and the grid then sends that name with `perform:`:

```smalltalk
ReverseLaserGameAction class >> reverseActionClassFor: aSymbol
	^self subclasses detect: [:cls | cls actionSymbol = aSymbol]
```

```smalltalk
ReverseLaserGameAction class >> reverseActionSymbolFor: aSymbol
	| cls |
	cls := self reverseActionClassFor: aSymbol.
	^cls reverseActionSymbol
```

Each subclass answers the action it undoes and the selector that undoes it. Two of the six:

```smalltalk
ReversePushCellEastLaserGameAction class >> actionSymbol
	^#east
```

```smalltalk
ReversePushCellEastLaserGameAction class >> reverseActionSymbol
	^#pushCellWestFromLocation:
```

```smalltalk
ReverseRotateClockwiseLaserGameAction class >> actionSymbol
	^#clockwise
```

```smalltalk
ReverseRotateClockwiseLaserGameAction class >> reverseActionSymbol
	^#rotateCellCounterClockwiseAt:
```

The other four are the same two methods with the other four pairs:

| action | undone by |
| --- | --- |
| `#north` | `#pushCellSouthFromLocation:` |
| `#east` | `#pushCellWestFromLocation:` |
| `#south` | `#pushCellNorthFromLocation:` |
| `#west` | `#pushCellEastFromLocation:` |
| `#clockwise` | `#rotateCellCounterClockwiseAt:` |
| `#counterClockwise` | `#rotateCellClockwiseAt:` |

`reverseActionClassFor:` searches with `detect:` over `self subclasses`, and answers whichever class claims the symbol. Nothing registers, nothing is listed twice: adding a seventh action would mean adding a seventh subclass and nothing else. The price is that the search runs on every undo and raises `SubscriptOutOfBounds` — `detect:` without an `ifNone:` — for a symbol no class claims. Neither matters at six classes and one undo per click, and the port leaves both hierarchy and method exactly as the original wrote them.

## The stack was already being filled

Page 185 adds the `movesStack` instance variable to `Grid`, with a lazily initialized getter:

```smalltalk
Grid >> movesStack
	movesStack isNil ifTrue: [self movesStack: OrderedCollection new].
	^movesStack
```

```smalltalk
Grid >> movesStack: aCollection
	movesStack := aCollection
```

```smalltalk
Grid >> stackAction: aSymbol forCell: aCell
	self movesStack add: aSymbol->(aCell gridLocation)
```

An entry is an `Association`: the symbol of the action, and the location of the cell it acted on. The location is read before the move, which matters for a push, since the cell that is pushed ends up somewhere else.

Page 185 then refactors the four push methods to go through one parameterized method, so that every push writes its entry, and adds the same line to the two rotations. All of that is already in the port: the captured source of Section 1 carried those versions, so Section 3.14 quoted `pushCellAction:fromLocation:` and Section 3.12 the two rotations, each with the stacking line, and Section 3.14 wrote `testAPushThatMovesNothingRecordsNoMove` for the one rule the refactoring introduces — a push the rules refuse changes nothing, so it is not a move and goes on no stack.

## Undo

```smalltalk
Grid >> undo
	| actionAssociation symbol location reverseAction arguments |
	self movesStack isEmpty ifTrue: [^false].
	actionAssociation := self movesStack removeLast.
	symbol := actionAssociation key.
	location := actionAssociation value.
	reverseAction := ReverseLaserGameAction reverseActionSymbolFor: symbol.
	arguments := Array with: location.
	self perform: reverseAction withArguments: arguments.
	self movesStack removeLast.
	^true
```

It answers whether it did anything, which is how the caller knows an empty stack from a real undo. The line that surprises on a first reading is the second `removeLast`: performing the reverse action goes through the very methods that stack, so the undo pushes an entry of its own, and that entry is popped straight off again. Page 185 says so in as many words.

It is a load-bearing assumption rather than an invariant: the second `removeLast` is right only as long as every reverse action stacks exactly one entry. It does, for all six — a reverse push is a push the rules allow, since it puts the cell back where it just came from, and a reverse rotation is a rotation, which always stacks. The port keeps the method as written and holds the assumption with a test instead.

## The tests

Page 184 writes the first, before the subclasses exist, and says so: it is there to show where the design is going.

```smalltalk
GridTestCase >> testUndoActions
	"Page 184: every action symbol the stack can hold answers the selector that takes it back.
	The six pairs are the four pushes, each answering the push the other way, and the two
	rotations, each answering the other turn."

	| undoAction |
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #north.
	self assert: undoAction equals: #pushCellSouthFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #east.
	self assert: undoAction equals: #pushCellWestFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #south.
	self assert: undoAction equals: #pushCellNorthFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #west.
	self assert: undoAction equals: #pushCellEastFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor:
		              #clockwise.
	self assert: undoAction equals: #rotateCellCounterClockwiseAt:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor:
		              #counterClockwise.
	self assert: undoAction equals: #rotateCellClockwiseAt:
```

Page 186 writes the second:

```smalltalk
GridTestCase >> testUndoStackAfterPush
	"Page 186: a push puts one entry on the stack, the undo takes it off and answers true, and a
	second undo finds the stack empty and answers false."

	| grid |
	grid := self generateDemoGrid.
	self assert: grid movesStack isEmpty.
	grid pushCellEastFromLocation: 1 @ 2.
	self assert: grid movesStack size equals: 1.
	self assert: grid undo.
	self deny: grid undo
```

Both came over with the capture, and both were rewritten the way every other ported test has been. The original writes `self should: [undoAction = #pushCellSouthFromLocation:]`, which passes whatever the comparison answers, since `should:` fails only when its block raises; the port writes `assert:equals:`, which fails with both values printed. The last line of the second test is `self shouldnt: [grid undo]` in the original and `self deny: grid undo` here — the same assertion, without the block.

The original tests one push and one undo. The rule of page 183 is stronger than that: any run of moves, undone one at a time, has to give the grid back exactly as it was. That is worth a test of its own, and it is the one place in this section where the port writes something the tutorial does not:

```smalltalk
GridTestCase >> testUndoingEveryMoveGivesTheGridBackAsItWas
	"Page 185's undo takes one move off the stack and plays its reverse. A run of pushes and turns
	mixed together, undone one at a time, has to leave every cell of the grid where it was and
	facing the way it did, and leave the stack empty. The original tests one push and one undo.
	Only a move that changed something is stacked, so each move is checked to have been recorded
	before the run is undone."

	| grid before after reading |
	reading := [ :aGrid |
	            aGrid cells collect: [ :each |
		            | lean |
		            lean := (each isKindOf: MirrorCell)
			                    ifTrue: [ each leansLeft printString ]
			                    ifFalse: [ '' ].
		            each class name , ' ' , each gridLocation printString , ' '
		            , lean ] ].
	grid := self generateDemoGrid.
	before := reading value: grid.
	{
		(#pushCellEastFromLocation: -> (1 @ 2)).
		(#rotateCellClockwiseAt: -> (2 @ 2)).
		(#pushCellSouthFromLocation: -> (4 @ 1)).
		(#rotateCellCounterClockwiseAt: -> (3 @ 3)).
		(#pushCellWestFromLocation: -> (5 @ 3)) } doWithIndex: [ :each :index |
		grid perform: each key with: each value.
		self assert: grid movesStack size equals: index ].
	[ grid undo ] whileTrue.
	self assert: grid movesStack isEmpty.
	after := reading value: grid.
	self assert: after equals: before
```

Two details of it are worth the words. The grid is compared by reading every cell into a string — its class, where it says it sits, and which way a mirror leans — because that is the whole of what a move can change and `Cell` has no `=`. And every move is asserted to have been recorded as it is made, because a push is refused unless the cell is a mirror and its neighbour in that direction is blank: the first version of this test chose five moves, two of which the demo grid refuses, and it failed on a stack of three. A test of undo that silently undoes nothing is worse than no test at all.

## The button

Page 186 adds the button to the morph, and puts it in the panel by layout frame:

```
makeUndoButton
	^self makeButton: 'Undo' action: #undo state: nil

addButtonsToPanel: panel
	| layout |
	layout := self buttonLayoutFrameForRow: 1 column: 1.
	panel addMorph: self makeQuitGameButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 1 column: 2.
	panel addMorph: self makeFireLaserButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 2 column: 1.
	panel addMorph: self makeNewGameButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 2 column: 2.
	panel addMorph: self makeUndoButton fullFrame: layout.

	^panel
```

The port has no layout frames to compute: since page 144 the panel builds two rows of buttons and a vertical layout stacks them, so the fourth button is one more element in the row the New button already stands in. The builder is the same three lines every other button of the panel is built with:

```smalltalk
LaserGameControlPanelElement >> newUndoButton
	"Answer the button that takes the last move back: page 186's #makeUndoButton. The original
	passes action: #undo state: nil, the state being the block a toggling button reads its label
	from; Undo never changes its label, so only the action is left."

	^ self newButton: 'Undo' action: [ self game undo ]
```

```smalltalk
LaserGameControlPanelElement >> newNewGameRow
	"Answer the row above it, holding the New button on the left and Undo on its right. Page 144
	calls them row two, column one and page 186 adds row two, column two."

	^ self newRowOfButtons: {
			  newGameButton.
			  undoButton }
```

`state: nil` in the original is the block a toggling button reads its label from — the Fire button passes one, because its label alternates between `'Fire'` and `'Stop'`. Undo never changes its label, so nothing is left to pass.

The button is held in an instance variable like the other three, and `rebuild` builds it with them:

```smalltalk
LaserGameControlPanelElement >> undoButton
	"Answer the button that takes the last move back."

	^ undoButton
```

```smalltalk
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me, or the height
	of what I hold when that is more. The counter column goes in first and the button column
	second, which is the order #counterColumn and #buttonColumn read them back in."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	undoButton := self newUndoButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	mirrorsCounter := self newMirrorsCounter.
	activeMirrorsCounter := self newActiveMirrorsCounter.
	self addChild: self newCounterColumn.
	self addChild: self newButtonColumn.
	self extent: LaserGameElement panelWidth
		@ (self class heightForGrid: self game grid).
	self updateCounters
```

That is the ninth instance variable of the class, one below the limit `ReExcessiveVariablesRule` draws at ten — and the reason there is room for it is the previous section, where the two columns stopped being held and became `self children first` and `self children last`.

The panel test says where Undo stands:

```smalltalk
LaserGameControlPanelElementTestCase >> testUndoButtonSharesTheRowWithNewGame
	"Page 186 puts Undo in row two, column two: beside New, above Quit and Fire."

	| panel |
	panel := self newPanel.
	self assert: panel newGameRow children asArray equals: {
			panel newGameButton.
			panel undoButton }.
	self assert: panel undoButton class equals: ToButton.
	self assert: panel undoButton labelText asString equals: 'Undo'
```

The test written for page 144 asserted that the New row held exactly one button, which is no longer true, so it gives up that half of its assertion and keeps the half that is its own — that the New row is the upper of the two:

```
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers
	"Page 144 puts New in the second row from the bottom, first column: here the column of rows
	holds the New row first and the Quit and Fire row last, which is lowest. What else stands in
	that row is page 186's business, and #testUndoButtonSharesTheRowWithNewGame asserts it."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel newGameRow.
			panel buttonRow }.
	self assert: panel newGameRow children first equals: panel newGameButton.
	self assert: panel newGameButton labelText asString equals: 'New'
```
> **Note.** *Reset (and a bug fix)*, the fifth chapter of Section 5, rewrites this to read the rows by index, since Reset takes a row above them.

## What the game does with it

Page 186:

```
undo
	| completed |
	completed := self grid undo.
	completed ifTrue: [
		self incrementMoves.
		self updateGameBoardAndControls]
```

```smalltalk
LaserGameElement >> undo
	"Take the last move back, and count the undo as a move of its own: page 183 says an undo must
	not remove any count from the player's total, so the counter goes up, not down. The grid
	answers whether it undid anything, and on an empty stack there is nothing to draw again. This
	is page 186's #undo, with #refresh for #updateGameBoardAndControls."

	self grid undo ifFalse: [ ^ self ].
	self incrementMoves.
	self refresh
```

`refresh` is this port's name for `updateGameBoardAndControls`, and it does the three things page 142 left it doing:

```smalltalk
LaserGameElement >> refresh
	"Show what the model says now: redraw the cells, put the right label on the fire button and
	set the counters. This is the original's #updateGameBoardAndControls, and page 142 adds the
	counters to it."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel.
	self controlPanel updateCounters
```

And the move that an undo costs is counted by the same method a move costs:

```smalltalk
LaserGameElement >> incrementMoves
	"Count one more move. Page 143's #incrementMoves."

	self moves: self moves + 1
```

So a push followed by its undo leaves the board where it started and the moves counter at two. That is page 183's rule, and the game test says it in those terms:

```smalltalk
LaserGameElementTestCase >> testUndoTakesTheLastMoveBackAndCountsAsAMove
	"Page 186: the Undo button asks the grid to undo, and when the grid says it did, the game
	counts a move and draws itself again. The count is not taken back — page 183 says an undo
	must not remove any count from the player's total — so a move and its undo are two moves."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game grid pushCellEastFromLocation: 1 @ 2.
	game incrementMoves.
	self assert: (game grid at: 2 @ 2) class equals: MirrorCell.
	game undo.
	self assert: (game grid at: 1 @ 2) class equals: MirrorCell.
	self assert: game grid movesStack isEmpty.
	self assert: game moves equals: 2.
	self
		assert: game controlPanel movesCounter value
		equals: game moves
```

```smalltalk
LaserGameElementTestCase >> testUndoOnABoardNobodyHasTouchedDoesNothing
	"An empty stack answers false on page 185, and the game does nothing with it: no move is
	counted and the board is left as it stands."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self deny: game grid undo.
	game undo.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0
```

The second is the reason `undo` asks the grid first and returns early: a click on Undo with nothing to undo must not count a move, and must not redraw a board that has not changed.

## Checking it

```
233 run, 233 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

Page 187 opens the game and tries the button, which is what the port did too: the fourth button stands beside New, the board takes the moves back one at a time, and the moves counter climbs while it does.

# Modify Package Definition

*Page 187A of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/187A.html -->

One page, and it changes no code. Its point is distribution: the graphics, the model and the unit tests are all in one Monticello package, and somebody who wants to play the game should not have to take the tests with it. The original renames the system category of the tests to `LaserGame-Tests`, declares a Monticello package of that name, saves it as version 1, and saves `Laser-Game` — now without the tests — as version 14.

## A tag is not a package

Squeak has one level of grouping: the system category, and a Monticello package is the set of categories whose name starts with the package name. Renaming the category is therefore the whole of the work: the tests fall out of `Laser-Game` and into `LaserGame-Tests` by the naming rule alone.

Pharo has two levels. A *package* is the unit that is loaded, committed and versioned; a *tag* groups classes within a package and is what the old system category became when the image was migrated. Since Section 1 this port has been one package, `Laser-Game`, with three tags — `Model`, `Graphics` and `Tests` — which reads like the original's three categories and behaves quite differently: a tag cannot be loaded on its own, cannot be left out, and does not exist in the baseline. Section 3.16 wrote that the concerns were kept apart, and they were, but only in the browser.

So the port does what the page asks for rather than what it says: the 22 test classes of the `Tests` tag become a package of their own. In the image that is one line per class,

```smalltalk
aClass package: (Smalltalk packageOrganizer ensurePackage: 'Laser-Game-Tests')
```

and the `Tests` tag disappears with its last class. On disk the 22 Tonel files move from `src/Laser-Game/` to `src/Laser-Game-Tests/`, which is the whole of the diff of this section outside the baseline. The name is `Laser-Game-Tests`, not the original's `LaserGame-Tests`: Pharo's convention is that a test package is the package name with `-Tests` appended, and the tools rely on it.

## The baseline

The original saves two Monticello versions. This port has no version numbers to give — every numbered section of the book is a commit — but it does have the file the original has no equivalent of, the baseline, and that is where the split has to be said:

```smalltalk
BaselineOfLaserGame >> baseline: spec

	<baseline>
	spec for: #common do: [
		spec
			baseline: 'Bloc'
			with: [ spec repository: 'github://pharo-graphics/Bloc:dev/src' ].
		spec
			baseline: 'Toplo'
			with: [ spec repository: 'github://pharo-graphics/Toplo:dev/src' ].
		spec package: 'Laser-Game' with: [ spec requires: #( 'Bloc' 'Toplo' ) ].
		spec
			package: 'Laser-Game-Tests'
			with: [ spec requires: #( 'Laser-Game' ) ].
		spec group: 'core' with: #( 'Laser-Game' ).
		spec group: 'tests' with: #( 'Laser-Game-Tests' ).
		spec group: 'default' with: #( 'core' 'tests' ) ]
```

Three things are new in it.

The two packages, with the tests requiring the game. The groups: `core` loads the game alone, which is the page's whole purpose, `tests` loads the tests, and `default` — what `Metacello ... load` takes when no group is named — loads both. Somebody who wants to play writes `load: 'core'`.

And Toplo, which should have been declared since Section 4.1: the control panel's buttons are `ToButton`s, and the baseline named only Bloc, which does not load Toplo. An image that loaded this baseline into a fresh Pharo would have compiled the panel against a class it did not have. It was never noticed because the development image had Toplo loaded before the port began. The original meets nothing of this kind — Squeak 3.9 has its widgets in the image — but the bug is exactly of the kind page 187A is about: what a package needs, stated where a loader can read it.

The baseline was checked by asking Metacello to resolve it, which needs no network and loads nothing:

```smalltalk
BaselineOfLaserGame project version spec packageSpecsInLoadOrder
"an Array('Bloc' 'Toplo' 'Laser-Game' 'Laser-Game-Tests' 'default' 'tests' 'core')" 
```

## A critic that went quiet

Every test class of this port has carried one Renraku critique since the day it was written:

```
ReTestClassNotInPackageWithTestEndingNameRule
Test class not in a package with name ending with '-Tests'
```

Twenty-two classes, twenty-two critiques, accepted as pre-existing and reported as such after every section. They are all gone: the package the rule asks for is the package page 187A asks for. The rule was right all along, and the tutorial and the linter turn out to want the same thing for the same reason — that what you ship and what you test with are two different things.

## Checking it

The suite is run on the test package now, and answers what it answered before:

```
233 run, 233 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

`Laser-Game` holds 49 classes and `Laser-Game-Tests` 22. Nothing was renamed, nothing was deleted, and no method changed: the game the previous chapter left running is the same game.

# Reset (and a bug fix)

*Page 188 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/188.html -->

Reset puts the board back the way it was dealt. The page says it is straightforward once Undo is written, and it is: Reset is Undo repeated until there is nothing left to undo. The page opens with something else, though — a bug the author noticed while playing with the previous section's code — so this chapter starts there.

## The bug the port cannot have

Open a fresh game in the original and the Mirrors counter reads zero, although the board in front of you is full of mirrors. The count is right the moment you touch anything and wrong until then. The cause is that the original writes its counters only when something happens: `#updateCounters` is called from the move handlers, and the morph that has just been built has not handled a move yet. The fix is one line at the end of the method that builds it:

```
initializeForGrid: aGrid
	super initialize.
	self moves: 0.
	self grid: aGrid.
	self boardForm: (Form extent: (self class boardExtentFor: self grid) depth: Display depth).
	self boardForm fillColor: LaserGameColors gameBoardBackgroundColor.
	self setExtent.
	self setupMorphs.
	self drawGameBoard.
	self updateCounters.
```

The port has no such method and cannot have the bug. Its counters live in the control panel, and the panel writes them at the end of `#rebuild` — the method that builds its children — so a panel that exists has counted. That was not foresight: Section 5.2 put the call there because `#rebuild` runs again whenever the game is refreshed, and a panel rebuilt in the middle of a game would otherwise show the counts of the game before it.

```smalltalk
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me, or the height
	of what I hold when that is more. The counter column goes in first and the button column
	second, which is the order #counterColumn and #buttonColumn read them back in."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	undoButton := self newUndoButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	mirrorsCounter := self newMirrorsCounter.
	activeMirrorsCounter := self newActiveMirrorsCounter.
	self addChild: self newCounterColumn.
	self addChild: self newButtonColumn.
	self extent: LaserGameElement panelWidth
		@ (self class heightForGrid: self game grid).
	self updateCounters
```

Still, a bug the page went to the trouble of noticing deserves a test rather than a claim, and the port had none: every counter test so far made a move first. So this one makes no move at all.

```smalltalk
LaserGameElementTestCase >> testAGameShowsItsCountsBeforeAnythingHappens
	"Page 188 opens with a bug of the original's: a game just opened shows zero mirrors, because
	the counters are only written to when something happens, and the page fixes it by updating
	them at the end of #initializeForGrid:. The port cannot have that bug, since the panel sets
	its counters at the end of #rebuild, which is what building it does; this test says so, here
	and after a new board is dealt."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self
		assert: game controlPanel mirrorsCounter value
		equals: game grid numberOfMirrors.
	self assert: game controlPanel mirrorsCounter value > 0.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0.
	game newGame.
	self
		assert: game controlPanel mirrorsCounter value
		equals: game grid numberOfMirrors.
	self assert: game controlPanel mirrorsCounter value > 0
```

It passed the first time it was run, which is the answer wanted. Its second half deals a new board, since `#newGame` is the other way a game arrives in front of a player with counts that nothing has yet updated.

## The stub, and the test before the method

Now Reset. The page writes the method on `Grid` twice: first an empty one,

```
reset
```

then the test, then the body. The port has no stub to write and no test to fail: like the whole of the undo machinery, `Grid >> #reset` and `#testResetGrid` came with the 2007 source captured in Section 1, and both have been green since. What Section 1 captured is exactly what page 188 arrives at:

```smalltalk
Grid >> reset
	[self undo] whileTrue: []
```

One line, and every word of it is doing something. `#undo` answers whether it undid anything —

```smalltalk
Grid >> undo
	| actionAssociation symbol location reverseAction arguments |
	self movesStack isEmpty ifTrue: [^false].
	actionAssociation := self movesStack removeLast.
	symbol := actionAssociation key.
	location := actionAssociation value.
	reverseAction := ReverseLaserGameAction reverseActionSymbolFor: symbol.
	arguments := Array with: location.
	self perform: reverseAction withArguments: arguments.
	self movesStack removeLast.
	^true
```

— so `[self undo] whileTrue: []` is a loop with its work in the condition: undo, ask whether there was anything to undo, and go round again while the answer is yes. When the stack is empty `#undo` answers `false` without touching anything and the loop ends. The board is then in the state it was dealt in, because every move that was ever made has been taken back, in the reverse of the order it was made in.

The test the page writes is two pushes, a reset, and the cell that moved back where it started. It was ported with the rest of the file, and this section added only its comment:

```smalltalk
GridTestCase >> testResetGrid
	"Page 188: two pushes, then a reset, and the cell that moved is back where it was with an
	empty stack behind it. Reset is the undo stack unwound to the end, so this is the same rule
	#testUndoingEveryMoveGivesTheGridBackAsItWas states one move at a time."

	| grid cell |
	grid := self generateDemoGrid.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: BlankCell.
	grid pushCellEastFromLocation: 3 @ 3.
	grid pushCellSouthFromLocation: 4 @ 3.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: MirrorCell.
	self assert: grid movesStack size equals: 2.
	grid reset.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: BlankCell.
	self assert: grid movesStack isEmpty
```

The assertions are `#assert:equals:` where the original writes `#should:`, which is the substitution Section 1 made everywhere: `should:` takes a block and reports only that it was false, `assert:equals:` reports both values when they differ.

## The button

The page adds a fifth button. The original builds it the way it builds the other four,

```
makeResetButton
	^self makeButton: 'Reset' action: #reset state: nil
```

and places it by extending the method that lays the panel out. Its frames count rows from the bottom, so the new button is row three, column one — above New and Undo, on the left:

```
addButtonsToPanel: panel
	| layout |
	layout := self buttonLayoutFrameForRow: 1 column: 1.
	panel addMorph: self makeQuitGameButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 1 column: 2.
	panel addMorph: self makeFireLaserButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 2 column: 1.
	panel addMorph: self makeNewGameButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 2 column: 2.
	panel addMorph: self makeUndoButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 3 column: 1.
	panel addMorph: self makeResetButton fullFrame: layout.

	^panel
```

The port's panel is a column of rows, so the new button is a new row at the top of the column. The button itself is made the way the other four are:

```smalltalk
LaserGameControlPanelElement >> newResetButton
	"Answer the button that puts the board back where it started: page 188's #makeResetButton.
	Like Undo it takes no state block, its label never changing."

	^ self newButton: 'Reset' action: [ self game reset ]
```

```smalltalk
LaserGameControlPanelElement >> newResetRow
	"Answer the top row of buttons, holding Reset alone. Page 188 calls it row three, column one.
	Its button is built here and not kept in an instance variable: a tenth would trip
	ReExcessiveVariablesRule, whose limit is ten, and #resetButton reads it back from the row the
	way #buttonRow and #newGameRow read the rows from the column."

	^ self newRowOfButtons: { self newResetButton }
```

and the row goes in first, the column reading from the top:

```
LaserGameControlPanelElement >> newButtonColumn
	"Answer the column of button rows: the bottom left corner of the panel, one gap from both
	edges, the rows one gap apart, the last row against the bottom. Page 144 places each button
	itself with #buttonLayoutFrameForRow:column:, which counts rows from the bottom and columns
	from the left; a column of rows says the same thing, and the third row, page 188's, falls in
	above the other two. The cell spacing of a linear layout is added around the cells as well as
	between them, so it is the whole of the gap: a margin here would double the gap on the left
	and push the last button of the bottom row against the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class buttonGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	column addChild: self newResetRow.
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
```
> **Note.** *Minor Cosmetic Tweaks*, the ninth chapter of Section 5, adds page 201's divider bar as the first child of this column.

Reset is the first button of this port that the panel does not keep in an instance variable. Section 5.2 met the reason: `ReExcessiveVariablesRule` allows exactly ten, and the panel has nine. A tenth would break the rule and gain nothing, since the row it is the only button of can answer it:

```
LaserGameControlPanelElement >> resetRow
	"Answer the top row of buttons. Page 144 counts rows from the bottom and this is the third of
	them, so it is the first child of the column, which reads from the top."

	^ self buttonColumn children first
```
> **Note.** *Minor Cosmetic Tweaks* puts the divider bar in front of the rows, so this row is read as the second child.

```smalltalk
LaserGameControlPanelElement >> resetButton
	"Answer the button that puts the board back where it started. It is the only button of its
	row, and the only one I do not hold."

	^ self resetRow children first
```

The other two rows are read the same way, and were already:

```
LaserGameControlPanelElement >> newGameRow
	"Answer the middle row of buttons, holding New and Undo. Page 144 calls it row two, so it is
	the second child of the column, which reads from the top."

	^ self buttonColumn children second
```
> **Note.** *Minor Cosmetic Tweaks* puts the divider bar in front of the rows, so this row is read as the third child.

```smalltalk
LaserGameControlPanelElement >> buttonRow
	"Answer the bottom row of buttons. Page 144 counts rows from the bottom, so it is the last row
	of the column."

	^ self buttonColumn children last
```

## A third row makes the panel taller

Section 5.2 found that four counters and two rows of buttons are taller than the demo board, and gave the panel a height of its own to fall back on. A third row of buttons makes it taller again, and the arithmetic has to know how many rows there are rather than assume two:

```smalltalk
LaserGameControlPanelElement class >> buttonRowCount
	"Answer how many rows of buttons I stack. Page 144 opens with two, and page 188 adds the row
	Reset has to itself."

	^ 3
```

```
LaserGameControlPanelElement class >> contentHeight
	"Answer the height, in pixels, of everything I hold: my counters, stacked with a gap between
	them and a gap above and below, and the rows of buttons under them, spaced the same way. A
	counter takes the size of its caption, so one is built and measured; nothing is laid out and
	nothing is opened. The original never needs this number, since it places its counters at fixed
	offsets from the top of a panel that is always taller than they are."

	| counter |
	counter := LaserGameCounterElement labelled: 'Active Mirrors' digits: 3.
	counter measure: BlExtentMeasurementSpec unspecified.
	^ ((self counterCount * counter measuredExtent y)
	   + ((self counterCount + 3) * self counterGap)
	   + (self buttonRowCount * self buttonHeight)
	   + ((self buttonRowCount + 1) * self buttonGap)) ceiling
```
> **Note.** *Minor Cosmetic Tweaks* counts the divider bar of page 201 into this height.

That answers 320 where it answered 290 before, and since the demo board is 250 tall the panel takes the larger of the two:

```smalltalk
LaserGameControlPanelElement class >> heightForGrid: aGrid
	"Answer how tall I am beside a board showing aGrid: as tall as that board, or as tall as what I
	hold when the board is shorter than that. The original has the first half of this only: its
	board is never short enough for the counters to reach the buttons, and a board that was would
	have them overlap."

	^ (LaserGameBoardElement extentForGrid: aGrid) y max: self contentHeight
```

so the demo game grew from 380@310 to 380@340 with no other change. The eight-by-ten board of Section 4.6 is 460 tall, more than 320, and stayed at 530@520. The original never meets this: its panel is a fixed 100 pixels wide and as tall as the window, and its counters sit at fixed offsets from the top with room to spare.

The test that holds the arithmetic to the measurement is Section 5.2's, unchanged — which is the point of writing it against the columns rather than against the number:

```smalltalk
LaserGameControlPanelElementTestCase >> testContentHeightIsWhatTheCountersAndButtonsMeasure
	"The height the panel falls back on is stated from the constants, so that it can be asked of
	the class before a panel exists. Here it is checked against what the two columns actually
	measure, which is the only thing that keeps the statement true."

	| panel counters buttons |
	panel := self newPanel.
	counters := panel counterColumn.
	buttons := panel buttonColumn.
	counters measure: BlExtentMeasurementSpec unspecified.
	buttons measure: BlExtentMeasurementSpec unspecified.
	self
		assert: LaserGameControlPanelElement contentHeight
		equals:
			counters measuredExtent y
			+ (2 * LaserGameControlPanelElement counterGap)
			+ buttons measuredExtent y.
	self
		assert: counters children size
		equals: LaserGameControlPanelElement counterCount
```

## A test that had to be narrowed again

Adding the row broke a test for the second section running:

```
testNewGameButtonHasTheRowAboveTheOthers
```

It was written in Section 4.5, when New was in the top row of two, and asserted that. Section 5.3 put Undo beside New and it was rewritten to assert the row's contents rather than its being alone. Now the row is no longer the top one, and what page 144 actually says — New is in the second row from the bottom — has to be said in a way that a row added above it cannot break:

```smalltalk
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers
	"Page 144 puts New in the second row from the bottom, first column: the Quit and Fire row is
	the lowest of the column and the New row sits directly above it. What else stands in the row,
	and what rows a later page adds above it, is asserted by
	#testUndoButtonSharesTheRowWithNewGame and #testResetButtonHasTheTopRowToItself."

	| panel rows |
	panel := self newPanel.
	rows := panel buttonColumn children asArray.
	self assert: rows last equals: panel buttonRow.
	self
		assert: (rows indexOf: panel newGameRow) + 1
		equals: (rows indexOf: panel buttonRow).
	self assert: panel newGameRow children first equals: panel newGameButton.
	self assert: panel newGameButton labelText asString equals: 'New'
```

It reads the rows by index instead of by position from the top: the button row is last, and the New row is the one directly before it. Whatever is stacked above stays somebody else's business, which is what a test for page 144 should have said the first time.

The new row gets its own test, which is where the count of rows and their order is now asserted:

```
LaserGameControlPanelElementTestCase >> testResetButtonHasTheTopRowToItself
	"Page 188 puts Reset in row three, column one, which is the row above New and Undo and the
	topmost of the three. Its button is the one thing the panel does not hold in an instance
	variable, so it is read from its row."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel resetRow.
			panel newGameRow.
			panel buttonRow }.
	self assert: panel resetRow children asArray equals: { panel resetButton }.
	self assert: panel resetButton class equals: ToButton.
	self assert: panel resetButton labelText asString equals: 'Reset'
```
> **Note.** *Minor Cosmetic Tweaks* adds the divider bar to the column this test reads back.

## What the game does with it

The button's action sends `#reset` to the game, and the game does what page 188's `#reset` does:

```
reset
	self grid reset.
	self grid stopLaser.
	self moves: 0.
	self activeCellLocation: nil.
	self initializeDirty.	
	self updateGameBoardAndControls
```

```smalltalk
LaserGameElement >> reset
	"Put the board back where the game started: page 188 unwinds the whole undo stack, stops the
	laser and sets the move count to zero. The original's two other lines have no counterpart —
	#activeCellLocation: nil is the mouse press it remembers by hand, which Bloc delivers instead,
	and #initializeDirty is the repaint bookkeeping of a shared board form, where every cell here
	draws itself."

	self grid reset.
	self grid stopLaser.
	self moves: 0.
	self refresh
```

Two of the original's six lines have no counterpart here, and they are the same two that `#newGame` dropped in Section 4.5. `#activeCellLocation: nil` forgets the cell a mouse press landed in, which the original tracks by hand because one morph receives every event; in the port each cell is an element and Bloc delivers the click to it. `#initializeDirty` empties the dictionary of cells that need repainting, which exists because the original draws every cell into one shared `Form`; here each cell draws itself and `#refresh` redraws them all.

What remains lines up with `#newGame` closely enough that the two are worth reading together:

```smalltalk
LaserGameElement >> newGame
	"Start again on a fresh random grid: page 146's #newGame. Its two other lines have no
	counterpart. The dirty dictionary it initializes is the repaint bookkeeping of a shared board
	form, and every cell here is an element that draws itself; the active cell location it clears
	is the mouse press the original remembers by hand, and Bloc delivers the click instead. The
	stack of moves the grid keeps is left alone: it is emptied where Undo and Reset are added."

	self grid initializeCells.
	self grid stopLaser.
	self moves: 0.
	GridFactory randomizeGrid: self grid.
	self refresh
```

Both stop the laser, both zero the move count, both refresh. They differ in what they do to the grid: New deals a fresh random board and leaves the stack of moves as it finds it, Reset unwinds the stack and so keeps the board it was dealt. A player who wants this board again presses Reset; a player who wants another one presses New.

The test makes two moves of different kinds, fires the laser, and asks for everything back:

```smalltalk
LaserGameElementTestCase >> testResetPutsEveryCellBackAndZeroesTheMoves
	"Page 188: Reset unwinds the whole undo stack, stops the laser and sets the move count back to
	zero, so the player can start the same board again."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game grid fireLaser.
	game grid pushCellEastFromLocation: 1 @ 2.
	game incrementMoves.
	game grid rotateCellClockwiseAt: 2 @ 2.
	game incrementMoves.
	self assert: game grid movesStack size equals: 2.
	game reset.
	self assert: game grid movesStack isEmpty.
	self assert: (game grid at: 1 @ 2) class equals: MirrorCell.
	self deny: game laserIsActive.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0
```

The last two assertions are what the move counter and the laser path counter read, not what the game holds: the panel is refreshed by `#refresh` and its counters have to follow. Page 188's bug was exactly a counter that did not, which is a fitting thing to assert in the section that fixed it.

## Checking it

Five buttons, three rows, a panel 320 pixels tall, and:

```
236 run, 236 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

The original ends the page by saving `Laser-Game` as version 15 and `LaserGame-Tests` as version 2 — the first page to save both, the split of the previous page having made that necessary.

# Showing Laser Home Visually

*Page 189 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/189.html -->

A small thing, and the page says so: a mark showing where the laser comes from. The beam has been drawn since Section 4.7, and it appears at the bottom of the first column as though out of nowhere. The mark says the laser lives there.

## Where the laser comes from

The grid has said it since Section 1, and nothing had to draw it:

```smalltalk
Grid >> startingCell
	| pt |
	pt := 1@(self numberOfRows).
	^self at: pt
```

Column one, last row, and `#calculatePath` starts the beam with `#south` as the side it enters that cell by — so it comes in from below, through the bottom edge of the bottom left cell. The mark goes under that edge.

## What the original adds

A `Form` one cell wide and one margin tall, filled with the colour the beam splatters the board with, wrapped in a `SketchMorph`:

```
makeLaserHomeMorph
	| form |
	form := Form
		extent: CellRenderer cellExtent x @ self gameMargin 
		depth: self boardForm depth.
	form fillColor: LaserGameColors laserBeamSplatterColor.
	^SketchMorph withForm: form
```

and a third `addMorph:fullFrame:` in `#setupMorphs` to place it. The frame is worth reading, because it is what the port has to reproduce by other means:

```
self
	addMorph: self makeLaserHomeMorph
	fullFrame: (LayoutFrame
			fractions: (0 @ 1 corner: 0 @ 1)
			offsets: ((self gameMargin + self panelWidth + 1)@(self gameMargin negated) 
				corner: (self gameMargin + self panelWidth + CellRenderer cellExtent x - 2)@0)).
```

Both fractions are `0 @ 1`, the bottom left corner of the window, and the offsets measure from there: the left edge is one margin and one panel to the right of it, the top edge one margin above the bottom. That is the band between the last row of cells and the bottom edge of the window — the margin itself. The `+ 1` and the `- 2` pull the bar a pixel clear of the outline the original draws around its board.

## The same band, without a layout frame

The port has no absolute frames. A game is a horizontal row of two children, the panel and the board, with the margin as padding; and a linear layout places every child it is given, so a third one cannot simply be dropped into the padding.

What can be done is to give the board a column of its own, with the mark under it:

```smalltalk
LaserGameElement >> newBoardColumn
	"Answer the column standing where the board stands: the board itself, and under its first
	column of cells the bar marking where the laser enters. The bar is the last child, so it
	falls under the bottom row, and it is as tall as my bottom margin, which is why I have no
	bottom padding: the column ends where I end and the bar fills the band under the board. The
	original places the same rectangle with a layout frame pinned to the bottom of the window."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: BlLinearLayout vertical.
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	column addChild: board.
	column addChild: laserHome.
	^ column
```

and to take the bottom margin out of the padding, so that the column ends where the game ends and the mark fills the band the original's layout frame names:

```smalltalk
LaserGameElement >> initialize
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it. There is none at the bottom: page 189 puts
	the mark of the laser's home in that band, so the bottom margin is the panel's and the board
	column's own, and they carry it as a margin instead. No move has been made yet."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets
			 top: self class gameMargin
			 left: self class gameMargin
			 bottom: 0
			 right: self class gameMargin).
	moves := 0
```

The margin has not gone anywhere: it has moved from the game to the two things standing in it. The board column carries it as the mark, and the panel carries it as a margin of its own, which `#rebuild` gives it:

```smalltalk
LaserGameElement >> rebuild
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. Page 139 moves the panel to the left of the
	board, which here is the order the two are added in. The board tells me when a move changed the
	grid, so the counters follow a click as well as the fire button. Since page 189 the board goes
	in inside a column that also holds the mark of the laser's home, and the panel carries the
	bottom margin that mark stands in."

	self removeChildren.
	confirmation := nil.
	board := LaserGameBoardElement on: self grid.
	laserHome := self newLaserHome.
	controlPanel := self newControlPanel.
	controlPanel margin: (BlInsets bottom: self class gameMargin).
	self addChild: controlPanel.
	self addChild: self newBoardColumn.
	board whenMoveMadeDo: [ self moveMade ].
	self extent: (self class extentForGrid: self grid)
```

The arithmetic comes out the same as before. The game is one margin, then the taller of the panel and its margin and the board and its mark, and `#extentForGrid:` is untouched: the demo game is 380@340 as it was, and the eight-by-ten board 530@520. Laid out, the mark of the big board stands at `(120.0@510.0) corner: (170.0@520.0)`, which is exactly the rectangle the original's offsets describe.

The mark itself is an element with a background where the original has a form with a fill:

```smalltalk
LaserGameElement >> newLaserHome
	"Answer the bar that marks where the laser comes from: one cell wide, one margin tall, in the
	colour the beam splatters the board with. Page 189 makes a Form of that size, fills it and
	wraps it in a SketchMorph; an element with a background says the same thing and scales with
	the rest of the game."

	^ BlElement new
		  background: LaserGameColors laserBeamSplatterColor;
		  extent: self class laserHomeExtent;
		  yourself
```

```smalltalk
LaserGameElement class >> laserHomeExtent
	"Answer the size, in pixels, of the bar marking where the laser enters the board: one cell
	wide and one margin tall. Page 189's Form has the same two numbers, less a pixel on the left
	and two on the right, which keep it clear of the outline the original draws around its board;
	nothing is drawn around this one."

	^ CellRenderer cellExtent x @ self gameMargin
```

It is held, like the board and the panel, and answered by an accessor:

```smalltalk
LaserGameElement >> laserHome
	"Answer the bar that marks where the laser enters the board."

	^ laserHome
```

The sixth instance variable, four below the limit that Section 5.2 ran into on the panel.

## The tests

Two are new. The first says what the mark is and where it stands in the tree:

```smalltalk
LaserGameElementTestCase >> testGameShowsWhereTheLaserComesFrom
	"Page 189 marks where the laser enters the board: a bar one cell wide and one margin tall, in
	the colour of the beam's splatter. It belongs under the bottom left corner of the board, which
	is where the beam starts — Grid >> startingCell is column one of the last row, and the beam
	enters it from the south. The original adds a SketchMorph over a filled Form; here it is a
	plain element with a background, standing under the board in a column of its own."

	| game column |
	game := LaserGameElement on: GridFactory demoGrid.
	column := game board parent.
	self assert: column children asArray equals: {
			game board.
			game laserHome }.
	self
		assert: game laserHome constraints horizontal resizer size
		equals: CellRenderer cellExtent x.
	self
		assert: game laserHome constraints vertical resizer size
		equals: LaserGameElement gameMargin.
	self
		assert: game laserHome background paint color
		equals: LaserGameColors laserBeamSplatterColor
```

The second is the one that matters, because the whole of this section is an arrangement that has to leave the size alone:

```smalltalk
LaserGameElementTestCase >> testTheLaserHomeSitsInTheMarginAndCostsNoSize
	"The bar stands in the margin under the board, not in a row of its own, so the game is the
	size it was before page 189. That is arranged by taking the bottom margin out of the padding
	and giving it to the panel instead: the column under the board then ends where the game ends,
	and the bar fills the band between the last row of cells and the bottom edge. The original
	places the morph in the margin with a layout frame and has nothing to arrange."

	| game column |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	column := game board parent.
	column measure: BlExtentMeasurementSpec unspecified.
	self
		assert: column measuredExtent
		equals: (LaserGameBoardElement extentForGrid: game grid)
			+ (0 @ LaserGameElement gameMargin).
	self
		assert: game padding
		equals: (BlInsets
				 top: LaserGameElement gameMargin
				 left: LaserGameElement gameMargin
				 bottom: 0
				 right: LaserGameElement gameMargin).
	self
		assert: game controlPanel margin
		equals: (BlInsets bottom: LaserGameElement gameMargin).
	self
		assert:
		LaserGameElement gameMargin + (column measuredExtent y
			 max: LaserGameControlPanelElement contentHeight
				 + LaserGameElement gameMargin)
		equals: (LaserGameElement extentForGrid: game grid) y
```

It measures the board column rather than laying the game out, the way Section 5.2's height test does, and then repeats the addition the game does: one margin at the top, and under it the taller of the panel with its margin and the column with its mark. When that equals what `#extentForGrid:` answers, nothing has moved.

Three older tests had to say the same thing about a tree one element deeper. The board is reached through `#board` as it always was, but it is no longer the game's second child:

```smalltalk
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel
	"A game is a row of two children: the control panel first, the board beside it. Page 139 moves
	the panel to the left of the board. Since page 189 the board is wrapped in a column, which
	holds the mark of the laser's home under it; the board is reached through the same accessor
	as before."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game children size equals: 2.
	self assert: game children first equals: game controlPanel.
	self assert: game children second equals: game board parent.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
```

`#testAnsweringNoLeavesTheGameAsItWas` changed the same way, and the padding assertion of the extent test moved to the three sides that still have padding:

```smalltalk
LaserGameElementTestCase >> testGameTakesTheExtentItCalculates
	"The game asks for exactly the size its own arithmetic gives, and the margin around its two
	children is padding, so the window ramp shows through it. The bottom margin is the one
	exception, kept free for the mark of page 189 and asserted by
	#testTheLaserHomeSitsInTheMarginAndCostsNoSize."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: grid) x.
	self
		assert: game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: grid) y.
	self assert: game padding top equals: LaserGameElement gameMargin.
	self assert: game padding left equals: LaserGameElement gameMargin.
	self assert: game padding right equals: LaserGameElement gameMargin
```

## Checking it

The page changes no model code and says to run the tests anyway, which is the habit it is in by now:

```
238 run, 238 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

The original saves the game package as version 16 and leaves the test package alone, having changed no test. This port changed four, all of them about the shape of the element tree and none about the game.

# A Less Brittle Unit Test Design

*Pages 190 to 196 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/190.html -->
<!-- http://squeak.preeminent.org/tut2007/html/191.html -->
<!-- http://squeak.preeminent.org/tut2007/html/192.html -->
<!-- http://squeak.preeminent.org/tut2007/html/193.html -->
<!-- http://squeak.preeminent.org/tut2007/html/194.html -->
<!-- http://squeak.preeminent.org/tut2007/html/195.html -->
<!-- http://squeak.preeminent.org/tut2007/html/196.html -->

Seven pages, and not one line of the game changes in any of them. The author means to go on tuning the numbers that decide what a click does, and the tests that check those numbers are written in a way that makes tuning painful: they name the pixels of a thirty pixel cell. Page 137 already showed what that costs, when raising the cell to forty broke tests that were right about the game. So before touching another dimension he rewrites the tables to say what they mean, and then raises the cell size a second time to prove the rewrite worked.

## The brittleness

Here is the test as page 075 left it, beside the table it was written from. The table labels nine points of a cell, A to I, and says which push each one asks for:

```
Label   Point    Push
  A     10@10    East
  B     30@10    West
  C     20@20    North
  D     10@30    North
  E     30@30    North
  F     11@13    East
  G     19@21    North
  H     29@27    West
  I     20@1     South
```

```
testClicksInPushRegions
    | pt regionClass pushRegion testTable cls |
    pt := 11@11.
    regionClass := CellClickRegion clickRegionForPoint: pt.
    self should: [regionClass = CellClickRegionInside].
    testTable := {
        10@10->CellClickRegionPushEast.
        30@10->CellClickRegionPushWest.
        20@20->CellClickRegionPushNorth.
        10@30->CellClickRegionPushNorth.
        30@30->CellClickRegionPushNorth.
        11@13->CellClickRegionPushEast.
        19@21->CellClickRegionPushNorth.
        29@27->CellClickRegionPushWest.
        20@1->CellClickRegionPushSouth
        }.
    testTable do: [:assoc |
        pt := assoc key.
        cls := assoc value.
        pushRegion := regionClass pushRegionForPoint: pt.
        self should: [pushRegion = cls]]
```

The page's own diagnosis is the best sentence of the section: A, B, D and E *are* the corners of the inside region, and those corners come straight out of `#regionRectangle`. The test is not there to check that `#regionRectangle` is right. It is there to check that a point of the region is decoded into the right push. Writing the corner as `10@10` states a fact about the rectangle in a test about decoding, and that is the whole of the brittleness.

It also hid a bug. The table gives point I as `20@1`, which is not in the inside region at all, and the method copies the table faithfully. The author spots it against the diagram and calls it a typo. Rewritten relative to the rectangle, the row can only be the top centre of the region, one pixel down, and the test becomes correct as a side effect of becoming readable:

```
Label   Point                          Push
  A     rect topLeft                   East
  B     rect topRight                  West
  C     rect center                    North
  D     rect bottomLeft                North
  E     rect bottomRight               North
  F     rect topLeft + (1@3)           East
  G     rect center + (-1@1)           North
  H     rect bottomRight + (-1@-3)     West
  I     rect topCenter + (0@1)         South
```

and the method the page writes from it:

```
testClicksInPushRegions
    | pt regionClass pushRegion testTable cls rect |
    rect := CellClickRegionInside regionRectangle.
    pt := rect topLeft + (1@1).
    regionClass := CellClickRegion clickRegionForPoint: pt.
    self should: [regionClass = CellClickRegionInside].
    testTable := {
        (rect topLeft)                ->    CellClickRegionPushEast.
        (rect topRight)               ->    CellClickRegionPushWest.
        (rect center)                 ->    CellClickRegionPushNorth.
        (rect bottomLeft)             ->    CellClickRegionPushNorth.
        (rect bottomRight)            ->    CellClickRegionPushNorth.
        (rect topLeft + (1@3))        ->    CellClickRegionPushEast.
        (rect center + (-1@1))        ->    CellClickRegionPushNorth.
        (rect bottomRight + (-1@-3))  ->    CellClickRegionPushWest.
        (rect topCenter + (0@1))      ->    CellClickRegionPushSouth
        }.
    testTable do: [:assoc |
        pt := assoc key.
        cls := assoc value.
        pushRegion := regionClass pushRegionForPoint: pt.
        self should: [pushRegion = cls]]
```

## What the port already had, and what it was missing

The source this port started from is the author's finished image, so the rewritten tables arrived with it, in `#assert:equals:` form. Every table this section produces was already green here before the section began, exactly as page 188's `Grid >> #reset` was. Reading the pages changes nothing in them.

What the port was missing is the proof. A table written relative to a rectangle *claims* to survive a change of cell size, and the tutorial pays for that claim on page 196 by raising the cell to fifty pixels and running everything again -- by hand, once. The port can spend the claim in a test instead, and it already owns the tool: Section 5.1 wrote `#withCellExtent:do:` to hunt for hard coded sizes inside `CellRenderer`.

## A test case for the sizes

The tool lived on `CellRendererTestCase`, and three more test classes now need it. It moves up into a new abstract test case, which is the only class this section adds:

```
LaserGameTestCase                    (abstract)
    CellRendererTestCase
    CellClickRegionTestCase
    CellClickInsideRegionPushTestCase
    CellClickOutsideRegionRotateTestCase
```

```
LaserGameTestCase >> withCellExtent: anExtent do: aBlock
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Page 137 of the original raises the cell size and then looks by eye for the
	sizes that were written down instead of derived from it; this runs that experiment from the
	test suite. Pages 190 to 196 ask the same question of the click tables, so the method lives
	here, where every test that has to ask it can reach it."

	| previous |
	previous := CellRenderer class >> #cellExtent.
	[
	CellRenderer class
		compile: 'cellExtent' , String cr , String tab , '^ ' , anExtent printString
		classified: 'constants'.
	aBlock value ] ensure: [
		CellRenderer class compile: previous sourceCode classified: 'constants' ]
```
> **Note.** *Better Hint Arrows Alignment*, the next chapter, moves the body of this method to the class side and leaves this one passing the question on.

```smalltalk
LaserGameTestCase class >> isAbstract
	"Answer whether I am abstract. I hold what my subclasses share and no test of my own."

	^ self = LaserGameTestCase
```

It recompiles `CellRenderer class >> #cellExtent`, runs the block and puts the old method back in an `#ensure:`, so a failing assertion inside the block cannot leave the image with a forty pixel cell. Nothing else belongs in the class: a test that never asks about a cell size has no reason to inherit from it.

One consequence is worth naming, because it shows up in the numbers at the end. Pharo builds the suite of an abstract test case out of its subclasses, so running the whole package runs the four subclasses twice: once from their own suites and once from their superclass's. 241 test methods are reported as 269 tests. They are the same tests, and they pass either way.

## The push table, proved

The table moves into a method of its own, so that more than one test can run it. This is the port's only change to what page 190 wrote, and the table itself is the page's, line for line, including the corrected point I:

```smalltalk
CellClickInsideRegionPushTestCase >> assertPushRegionTable
	"Check the table of page 190: a point of the inside region, and the push a click there asks
	for. Every point is written relative to the rectangle the region answers, so the table holds
	at any cell size, which is what that page is about. The page writes the point of its last row
	as 20@1, a point of the cell and not of the region; the row means the top centre of the
	region one pixel down, which is what it says here."

	| pt regionClass pushRegion testTable cls rect |
	rect := CellClickRegionInside regionRectangle.
	pt := rect topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionInside.
	testTable := {
		             (rect topLeft -> CellClickRegionPushEast).
		             (rect topRight -> CellClickRegionPushWest).
		             (rect center -> CellClickRegionPushNorth).
		             (rect bottomLeft -> CellClickRegionPushNorth).
		             (rect bottomRight -> CellClickRegionPushNorth).
		             (rect topLeft + (1 @ 3) -> CellClickRegionPushEast).
		             (rect center + (-1 @ 1) -> CellClickRegionPushNorth).
		             (rect bottomRight + (-1 @ -3)
		              -> CellClickRegionPushWest).
		             (rect topCenter + (0 @ 1) -> CellClickRegionPushSouth) }.
	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self assert: pushRegion equals: cls ]
```

The test the tutorial rewrites is now one call:

```smalltalk
CellClickInsideRegionPushTestCase >> testClicksInPushRegions
	"Run the table of page 190 at the cell size of the package. This is the test the tutorial
	rewrites on that page, and the port inherited it already rewritten with the captured source,
	so the table lives in a method of its own and this test is one call of it."

	self assertPushRegionTable
```

and the new test is the one page 190 exists for:

```smalltalk
CellClickInsideRegionPushTestCase >> testThePushRegionTableHoldsAtEveryCellSize
	"Run the same table at three cell sizes. This is what pages 190 to 194 are for: a row that
	names a point of the rectangle the region answers cannot go stale when the cell grows, where
	the thirty pixel numbers of page 075 went stale on page 137. The port proves the claim instead
	of resting on it."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [ self assertPushRegionTable ] ]
```

Thirty, forty and eighty. Thirty is the size the old table was written at, forty is the size that broke it on page 137, and eighty is a size nobody has ever opened the game at. The inside region is the cell less twenty pixels, so at thirty it is a ten pixel square -- small enough that a row written `+ (1@3)` from a corner has to land in the right triangle by geometry and not by luck. All nine rows hold at all three.

## The rotate table

Page 191 does the same to `CellClickOutsideRegionRotateTestCase`, with fifteen rows instead of nine and two rectangles instead of one, since the rotate regions are the ring between them. Its only awkward row is M, which the page flags itself: a point that takes its x from the outer rectangle and its y from the inner one.

```smalltalk
CellClickOutsideRegionRotateTestCase >> assertRotateRegionTable
	"Check the table of page 191: a point of the outside region, and the rotation a click there
	asks for. The rows name the corners, the edge centres and a few points near them of both the
	inside and the outside rectangle, so the table says the same thing at any cell size."

	| pt regionClass testTable cls rotateRegion inRect outRect |
	inRect := CellClickRegionInside regionRectangle.
	outRect := CellClickRegionOutside regionRectangle.
	pt := outRect topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionOutside.
	testTable := {
		             (inRect topLeft -> CellClickRegionRotateClockwise).
		             (inRect topRight -> CellClickRegionRotateClockwise).
		             (inRect leftCenter -> CellClickRegionRotateClockwise).
		             (inRect rightCenter -> CellClickRegionRotateClockwise).
		             (inRect bottomLeft
		              -> CellClickRegionRotateCounterClockwise).
		             (inRect bottomRight
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect topLeft -> CellClickRegionRotateClockwise).
		             (outRect topRight -> CellClickRegionRotateClockwise).
		             (outRect leftCenter -> CellClickRegionRotateClockwise).
		             (outRect rightCenter -> CellClickRegionRotateClockwise).
		             (outRect bottomCenter
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect bottomRight
		              -> CellClickRegionRotateCounterClockwise).
		             (outRect topLeft x + 2 @ inRect topLeft y
		              -> CellClickRegionRotateClockwise).
		             (inRect rightCenter + (2 @ -2)
		              -> CellClickRegionRotateClockwise).
		             (inRect bottomLeft + (2 @ 2)
		              -> CellClickRegionRotateCounterClockwise) }.
	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		rotateRegion := regionClass rotateRegionForPoint: pt.
		self assert: rotateRegion equals: cls ]
```

```smalltalk
CellClickOutsideRegionRotateTestCase >> testClicksInRotateRegions
	"Run the table of page 191 at the cell size of the package."

	self assertRotateRegionTable
```

```smalltalk
CellClickOutsideRegionRotateTestCase >> testTheRotateRegionTableHoldsAtEveryCellSize
	"Run the rotate table at three cell sizes. The dividing line of the outside region is the
	diagonal of a square, so a table written in corners and edge centres holds wherever the square
	starts and however wide it is."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [ self assertRotateRegionTable ] ]
```

## The three boundaries

Pages 192, 193 and 194 take the three tests that say where one region stops and the next begins. They are shorter and blunter than the tables, and the brittleness is the same. The ignore test, as it stood:

```
testClicksInIgnoreRegion
    | pt regionClass |
    pt := 1@1.
    regionClass := CellClickRegion clickRegionForPoint: pt.
    self should: [regionClass = CellClickRegionIgnore].
    pt := 39@39.
    regionClass := CellClickRegion clickRegionForPoint: pt.
    self should: [regionClass = CellClickRegionIgnore].
    pt := 3@3.
    regionClass := CellClickRegion clickRegionForPoint: pt.
    self should: [regionClass = CellClickRegionIgnore].
    pt := 10@10.
    regionClass := CellClickRegion clickRegionForPoint: pt.
    self shouldnt: [regionClass = CellClickRegionIgnore].
```

`39@39` is the last pixel of a forty pixel cell, `3@3` the last pixel of a four pixel margin, `10@10` the corner of the inside region. Three facts about three rectangles, written as six numbers. The page replaces each one with the expression that produced it -- `CellRenderer cellExtent - (1@1)`, `CellRenderer ignoreRegionOffset - (1@1)`, `CellClickRegionOutside regionRectangle topLeft` -- and adds a fourth check while it is there. Pages 193 and 194 do the same for the inside and outside regions, and the author remarks each time that the tests still pass.

In the port the three bodies become three helpers, for the same reason the tables did:

```smalltalk
CellClickRegionTestCase >> assertIgnoreRegionBoundaries
	"Check where the ignore region begins and ends. It is the margin of the cell left over once
	the outside region is inset, so the corner of the cell belongs to it and the centre of the
	inside region does not. Page 192 writes both points relative to a rectangle a region answers,
	so neither goes stale when the cell size changes."

	| ignoreRect outsideRect |
	ignoreRect := CellClickRegionIgnore regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	self
		assert: (CellClickRegion clickRegionForPoint: ignoreRect topLeft)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: ignoreRect bottomRight - (1 @ 1))
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect topLeft - (1 @ 1))
		equals: CellClickRegionIgnore.
	self
		deny: (CellClickRegion clickRegionForPoint: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionIgnore
```

each test calling one of them:

```smalltalk
CellClickRegionTestCase >> testClicksInIgnoreRegion
	"Check the boundaries of the ignore region at the cell size of the package."

	self assertIgnoreRegionBoundaries
```

and one test running all three at all three sizes:

```smalltalk
CellClickRegionTestCase >> testTheRegionBoundariesHoldAtEveryCellSize
	"Run the three boundary tables at three cell sizes. The three regions are concentric squares
	derived from the cell size, one of them by a margin that stays four pixels wide and one by a
	ring that stays ten pixels wide, so the smallest size of the sweep is the one that could break
	them. None of the three loses a pixel to another."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [
			self assertIgnoreRegionBoundaries.
			self assertInsideRegionBoundaries.
			self assertOutsideRegionBoundaries ] ]
```

The smallest size of the sweep is the interesting one. The ignore margin is four pixels at every cell size and the outside ring is ten, so a thirty pixel cell is a ten pixel inside region inside a twenty two pixel outside region inside a thirty pixel cell -- three squares with nothing to spare. No pixel changes hands.

## The offset test with no counterpart

Page 195 finds one more brittle test, on `CellRendererTestCase`. It builds a `Form` the size of the board, asks four renderers where their cell sits inside it, and compares the answer with `40@0`, `0@40` and `40@40`. The rewrite replaces those numbers with `CellRenderer cellExtent`:

```
    cellLoc := 2@1.
    cell := grid at: cellLoc.
    renderer := CellRenderer rendererFor: cell grid: grid form: form.
    offset := renderer offsetWithinGridForm.
    self should: [offset = ((CellRenderer cellExtent x)@0)].
```

The port has no such test, and cannot have one, because the question it asks stopped existing at Section 2.12. A cell is an element there, the board is a layout, and where a cell sits is decided by the layout rather than computed by the renderer; a click arrives in the coordinates of the cell it happened in, so nothing ever divides a board offset by a cell size. The method the page tests was still in the image at this point, unsent by anything a player can reach:

> **Note.** The chapter *The 2007 Code Leaves The Package*, at the end of this section, deletes this method with the rest of its island. It is quoted here as it read before that.

```
CellRenderer >> offsetWithinGridForm
	| delta xCount yCount offset |
	delta := CellRenderer cellExtent.
	xCount := (self cellLocation x) - 1.
	yCount := (self cellLocation y) - 1.
	offset := delta * (xCount@yCount).
	^offset
```

It is part of a closed island of 2007 drawing code on `CellRenderer` -- `#targetForm`, `#fillBackground`, `#backgroundRectangle`, `#renderBorder` and the four `#renderBorderLeft` and friends -- which nothing outside the island calls. The island dies with the `LaserGame` morph, in one deletion, not piecemeal here.

## Fifty pixels, already

Page 196 is the payment. Close any open game, raise the cell:

```
cellExtent
    ^50@50
```

run everything, open an 8 by 10 game at a new position because the board no longer fits where it did, and play it. It works.

```
(LaserGame randomizedGridOfExtent: 8@10)
    position: 20@230;
    openInWorld
```

The port has been at fifty since Section 3.1, for the same reason the tables were already rewritten: it inherited the finished image. The comment on the constant carries both pages that changed it:

```smalltalk
CellRenderer class >> cellExtent
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere: page 137 of the original
	raises it from thirty pixels to forty and then goes looking for the sizes that had been
	written down instead. The port has been at fifty since Section 3.1, because the source it
	inherits is the finished game, where the author had already enlarged the cells a second time
	on page 196."

	^50@50
```

And Section 5.1's sweep has been making the same point about the renderer ever since, at four sizes the game has never been opened at:

```smalltalk
CellRendererTestCase >> testEverySizeInACellFollowsTheCellSize
	"Page 137 of the original raises the cell size, and page 138 then finds the sizes that do not
	follow: the inside region, the line between the two rotate regions and one of the two
	diagonals. The port derives all of them from the cell size already, so this section proves
	that rather than changing it. At any cell size the two nested regions stay centred in the
	cell, every point of the cell still falls in a region, the four push regions still divide the
	inside square between them without overlapping, the ring of a target still fits in the cell,
	and a board is still the grid times the cell."

	| grid |
	grid := GridFactory demoGrid.
	#( 30 40 80 ) do: [ :side |
		self withCellExtent: side @ side do: [
			| cell inside outside middle renderer |
			cell := 0 @ 0 extent: side @ side.
			inside := CellClickRegionInside regionRectangle.
			outside := CellClickRegionOutside regionRectangle.
			self assert: inside extent equals: CellRenderer insideRegionExtent.
			self assert: outside extent equals: CellRenderer outsideRegionExtent.
			self assert: inside center equals: cell center.
			self assert: outside center equals: cell center.

			middle := side // 2.
			self assert: (CellClickRegionRotateClockwise containsPoint: 0 @ middle).
			self deny: (CellClickRegionRotateClockwise containsPoint: 0 @ (middle + 1)).
			self assert:
				(CellClickRegionRotateCounterClockwise containsPoint: 0 @ (middle + 1)).

			0 to: side - 1 do: [ :x |
				0 to: side - 1 do: [ :y |
					self assert: (CellClickRegion clickRegionForPoint: x @ y) notNil ] ].
			inside left to: inside right do: [ :x |
				inside top to: inside bottom do: [ :y |
					self
						assert: (CellClickRegionInside subclasses count: [ :each |
								 each containsPoint: x @ y ])
						equals: 1 ] ].

			renderer := CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid.
			self assert: renderer radius > 0.
			self assert: renderer innerRadius > 0.
			self assert: renderer radius * 2 <= side.

			self
				assert: (LaserGameBoardElement extentForGrid: grid)
				equals: side * grid numberOfColumns @ (side * grid numberOfRows) ] ]
```

Between that test and the three added here, every number the click code and the cell code depend on is now checked at more than one cell size. The next section starts moving the hint arrows, which is precisely the tuning these pages were clearing the way for.

## Checking it

```
269 run, 269 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

241 test methods, 269 runs, for the reason given above. Four of the methods are new, one class is new, and no code outside the test package changed -- which is what the original says too: it saves the test package and leaves the game package alone.

# Better Hint Arrows Alignment

*Pages 197 to 199 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/197.html -->
<!-- http://squeak.preeminent.org/tut2007/html/198.html -->
<!-- http://squeak.preeminent.org/tut2007/html/199.html -->

The hint arrows have never sat where the author expects them, and the fifty pixel cells of the previous section have made it plain: the arrow is visibly off-centre in its mirror. He traces the fault back to the very first days of the game. The arrows were drawn into white forms that were made big enough to hold whatever shape came out, nobody measured where the black ended up inside that white, and the forms were then saved as they were. Every offset computed afterwards was an offset of the white rectangle, not of the arrow. The cure is in two parts: trim each cached form down to the ink, and then centre what is left.

## Measuring the ink

Page 197 adds seven methods to `Form`, in a protocol named `*Laser-Game` so that they travel with the package. Four of them scan for a colour, and the last builds the rectangle from the four edges it finds:

```
anyOfColor: aColor inColumn: int
| color |
1 to: self height do: [:row |
color := self colorAt: int@row.
color = aColor ifTrue: [^true]].
^false

firstColumnOfColorFromLeft: aColor
| x |
x := 1.
[self anyOfColor: aColor inColumn: x] whileFalse: [
x := x + 1.
x >= self width ifTrue: [^nil]].
^x

tightRectangleAroundColor: aColor
| left right top bottom |
left := self firstColumnOfColorFromLeft: aColor.
right := self firstColumnOfColorFromRight: aColor.
top := self firstRowOfColorFromTop: aColor.
bottom := self firstRowOfColorFromBottom: aColor.
^left@top corner: right@bottom
```

Page 198 then uses it at the end of the method that bakes an arrow, so that what gets cached is the ink and nothing else:

```
arrowFormFromPointsArray: pts
"LaserGameForms initializeCachedForms"
| form fillForm index startPoint nextIndex endPoint line offset |
offset := 2@2.
form := Form extent: 330@330 depth: 1.
form fillColor: Color white.
...
form floodFill: Color black at: 1@1.
form reverse.
^form copy: (form tightRectangleAroundColor: Color black)
```

This is a pixel search over a 330 by 330 bitmap, run once per arrow and cached, to recover a number the drawing code knew and threw away. It is the price of having drawn the arrows as pictures.

## The port has no margin to trim

Here an arrow is not a picture. It is a polygon, and its points are scaled onto the rectangle the caller asks for, which Section 3.4 built:

```smalltalk
LaserGameShapes class >> pointsOf: anArrayOfPoints scaledToExtent: anExtent
	"Answer anArrayOfPoints moved to the origin and stretched to fill anExtent exactly. The
	vertex arrays are written at the size the original drew them at, around 260 pixels, and every
	user asks for the size it needs. The original could not do this: it drew one 330 pixel bitmap
	per arrow, cached it, and scaled the pixels afterwards."

	| bounds scale |
	bounds := Rectangle encompassing: anArrayOfPoints.
	scale := anExtent x / bounds width @ (anExtent y / bounds height).
	^ anArrayOfPoints collect: [ :each |
		  ((each - bounds origin) * scale) asFloatPoint ]
```

`Rectangle encompassing:` is the tight rectangle of page 197, computed on four vertices instead of searched for over a hundred thousand pixels, and the scaling puts it on the requested extent exactly. Every arrow reaches its element through that method:

```smalltalk
LaserGameShapes class >> eastArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points east."

	^ self arrowElementFromPoints: self eastArrowPoints ofExtent: anExtent
```

So the ink of an arrow *is* the rectangle it was asked for, at every size, and there is nothing left over to cut off. That is the claim, and a claim in a port is worth what its test is worth:

```smalltalk
LaserGameShapesTestCase >> testEveryArrowFillsTheRectangleItIsGiven
	"Page 197 of the original is about white space: an arrow was drawn into a form big enough to
	hold it, so the black shape sat somewhere inside a white margin nobody measured, and the seven
	Form methods of that page go looking for the tight rectangle around the black so page 198 can
	cut it out. Here an arrow is a polygon whose points are scaled onto the rectangle asked for,
	so the ink is the rectangle and there is no margin to trim. Six arrows are asked at three
	sizes and every one of them is checked."

	#( 24 30 48 ) do: [ :size |
		#( #northArrowElementOfExtent: #southArrowElementOfExtent:
		   #eastArrowElementOfExtent: #westArrowElementOfExtent:
		   #clockwiseArrowElementOfExtent:
		   #counterClockwiseArrowElementOfExtent: ) do: [ :selector |
			| element |
			element := LaserGameShapes perform: selector with: size @ size.
			self
				assert: (Rectangle encompassing: element geometry vertices)
				equals: (0 @ 0 corner: size @ size) ] ]
```

## Seven methods deleted, not ported

The seven `Form` methods of page 197 were already in the image. They came in with the Section 1 capture of the finished 2007 code, in the `*Laser-Game` protocol the page tells the reader to make, together with `LaserGameForms`, the class that cached the arrow bitmaps. Nothing in the port could ever call them: `tightRectangleAroundColor:` was sent by `LaserGameForms class >> arrowFormFromPointsArray:` alone, `LaserGameForms` was named by its own `initialize` alone, and the cell that shows a hint has asked `LaserGameShapes` for a polygon since Section 3.4. A dead island, in other words, and the port's second rule says what becomes of the captured display classes: they are deleted rather than ported, because no class here may depend on `Form`.

So this section removes the seven `Form` extension methods and the whole of `LaserGameForms` -- twenty one class side methods, the six cached forms, the pen drawing of the two rotate arrows and the arc code they used. The package that was fifty classes wide in Section 1 is forty seven now, and `Form` carries no extension of ours at all.

## Centring what is left

With a trimmed form in hand the original can finally centre it. Page 198 changes the inside region to work out the offset from the two extents:

```
scaledHintArrowAndOffsetFromWithinCell: aPoint
| pushRegion arrow tinyArrow offset |
pushRegion := self pushRegionForPoint: aPoint.
arrow := pushRegion arrowForm.
tinyArrow := arrow scaledToSize: CellRenderer cellExtent - 2.
offset := (CellRenderer cellExtent - tinyArrow extent) // 2.
^offset->tinyArrow
```

The port wrote those two lines in Section 3.6, as a pair of constants on the renderer, and has drawn every hint from them since:

```smalltalk
CellRenderer class >> hintArrowExtent
	"Answer the size a hint arrow is drawn at: a couple of pixels smaller than a cell, which is
	the size page 094 scales its arrow form to."

	^ self cellExtent - 2
```

```smalltalk
CellRenderer class >> hintArrowOffset
	"Answer where a hint arrow sits within its cell: centred, as page 094 computes it from the
	two extents."

	^ (self cellExtent - self hintArrowExtent) // 2
```

```smalltalk
LaserGameCellElement >> updateHintElement
	"Show the picture of the hint I hold, and no other, in the colour of what a click there would
	do. The original drew its arrow straight onto the board form, which is why page 093 warns
	that old arrows have to be cleaned off; here the arrow is a child of mine, so the previous
	one goes when it is removed. The colour comes from page 130: my renderer answers green when
	the move is allowed and red when it is refused. A region without a picture, such as the
	ignore margin, answers nothing and leaves me with no hint at all. The cross hair of page 134
	is shown exactly when the arrow is, and is dropped here so that it is added after the arrow
	and stays the child on top of it."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each
			background: (self renderer hintColorAt: hintPosition);
			position: CellRenderer hintArrowOffset.
		self addChild: each ].
	crossHairElement ifNotNil: [ :each |
		self removeChild: each.
		crossHairElement := nil ].
	self updateCrossHairElement
```

There is a difference worth naming. The original computes `(cellExtent - tinyArrow extent) // 2` because it cannot know what size the trimmed form came out at -- `scaledToSize:` is a request, and the bitmap that comes back is whatever the scaling produced. Here `hintArrowExtent` is the size, not a request for one, so the subtraction is between two numbers the class states, and the arrow is one pixel in from each side of the cell.

The claim of page 198 is that the arrow ends up centred. Two tests make it, one at the arithmetic and one at the arrow that a hovered mirror really shows:

```smalltalk
CellRendererTestCase >> testTheHintArrowIsCentredInItsCellAtEveryCellSize
	"Page 197 complains that the hint arrows are never where the player expects them: the arrow
	forms were drawn into rectangles big enough to hold them, the black shape sits wherever it
	landed in that rectangle, and the offset the renderer adds cannot know about the white margin
	around it. Pages 197 and 198 trim the form to its ink and then centre what is left. In this
	port an arrow is a polygon scaled onto the rectangle it is given, so its ink is its extent
	and centring is arithmetic on two constants. Both halves are checked here, at three cell
	sizes."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [
			| offset |
			offset := CellRenderer hintArrowOffset.
			self
				assert: (offset * 2) + CellRenderer hintArrowExtent
				equals: CellRenderer cellExtent.
			self assert: offset x equals: offset y.
			#( #northArrowElementOfExtent: #southArrowElementOfExtent:
			   #eastArrowElementOfExtent: #westArrowElementOfExtent:
			   #clockwiseArrowElementOfExtent:
			   #counterClockwiseArrowElementOfExtent: ) do: [ :selector |
				| element |
				element := LaserGameShapes
					           perform: selector
					           with: CellRenderer hintArrowExtent.
				self
					assert: (Rectangle encompassing: element geometry vertices)
					equals: (0 @ 0 corner: CellRenderer hintArrowExtent) ] ] ]
```

```smalltalk
LaserGameCellElementTestCase >> testTheHintArrowSitsCentredInTheCellAtEveryCellSize
	"Page 198 of the original recentres the hint arrow: it cuts the white margin off the cached
	form and then offsets what is left by half of what the cell has to spare. The port never had
	a margin, since an arrow is a polygon scaled onto the rectangle it is given, but the second
	half of the claim still has to hold. A mirror cell is hovered at three cell sizes, and the
	arrow it shows is measured where it really sits: the space it leaves on the left is the space
	it leaves on the right, and the space above is the space below."

	#( 30 40 80 ) do: [ :size |
		LaserGameTestCase withCellExtent: size @ size do: [
			| element arrow position margin |
			element := (LaserGameBoardElement on: GridFactory demoGrid)
				           cellElementAt: 4 @ 1.
			element dispatchEvent: (BlMouseMoveEvent new
					 position: CellClickRegionInside regionRectangle center;
					 yourself).
			arrow := element hintElement.
			self deny: arrow isNil.
			position := arrow constraints position.
			margin := CellRenderer cellExtent
			          - CellRenderer hintArrowExtent - position.
			self assert: margin equals: position.
			self assert: position x equals: position y ] ]
```

The second of those wants the cell size sweep that the previous section put on `LaserGameTestCase`, and `LaserGameCellElementTestCase` has no reason to be a `LaserGameTestCase`. Rather than move a class under a superclass to reach one method, the method moved to the class side, where anything can ask it:

```smalltalk
LaserGameTestCase class >> withCellExtent: anExtent do: aBlock
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. The method is on the class side as well as on the instance side because a
	test case that has no reason to inherit from me still has reason to ask this question: page
	198 of the original moves the hint arrow, and the test that checks where it lands belongs
	with the other cell element tests."

	| previous |
	previous := CellRenderer class >> #cellExtent.
	[
	CellRenderer class
		compile: 'cellExtent' , String cr , String tab , '^ ' , anExtent printString
		classified: 'constants'.
	aBlock value ] ensure: [
		CellRenderer class compile: previous sourceCode classified: 'constants' ]
```

```smalltalk
LaserGameTestCase >> withCellExtent: anExtent do: aBlock
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Page 137 of the original raises the cell size and then looks by eye for the
	sizes that were written down instead of derived from it; this runs that experiment from the
	test suite. Pages 190 to 196 ask the same question of the click tables, and page 198 asks it
	of the hint arrow, so the answer lives on my class side and this method passes it on."

	^ self class withCellExtent: anExtent do: aBlock
```

## The rest of page 198

Three more changes on that page have no counterpart here.

`CellRenderer >> backgroundRectangle` and `fillBackground` are a refactoring of the form painting: they name the rectangle the cell fills so that the arrow can be clipped to it. Both belong to the island of `CellRenderer` methods that still draw into `targetForm`, unreachable except from `LaserGame >> drawGameBoard`, and that island goes in one piece when the morph does.

```
backgroundRectangle
| offset |
offset := self offsetWithinGridForm + 1.
^offset extent: CellRenderer cellExtent - 2
```

`MirrorCellRenderer >> hintArrowColorFor: regionClass offset: offsetWithinCell` is new to the original at page 198, but it is the method the port wrote in Section 4.1, under the name the port uses for a question asked at a point:

```smalltalk
MirrorCellRenderer >> hintColorAt: aPoint
	"Answer the colour of the hint arrow at aPoint, in the coordinates of my cell: page 130 wants
	the arrow to say whether the move it offers could actually be made. The region the point
	falls in knows — the outside region always allows a turn, and the inside region asks the
	push region whether the cell beside mine would let my cell through."

	^ ((CellClickRegion clickRegionForPoint: aPoint)
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [ LaserGameColors allowActionArrowColor ]
		  ifFalse: [ LaserGameColors denyActionArrowColor ]
```

And `showPositionHintFromWithinBoardOffset:`, which page 198 rewrites around all of the above, went when the board form went. The cell knows the point in its own coordinates, asks its renderer for a region, asks the region for a picture and its renderer for a colour, and adds the result as a child. There is no board offset to subtract and no clipping box to pass.

## Checking it

Page 199 opens a new game, moves the pointer about, sees the arrows centred, re-runs the tests and saves version 18. The same here, minus the version: the game opens, the arrow sits in the middle of the mirror under the pointer, and

```
273 run, 273 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

Three test methods are new and one support method moved to a class side. The code that changed outside the tests is a deletion: a class and seven extension methods that the port had carried since Section 1 without ever calling them.

# Minor Cosmetic Tweaks

*Pages 200 to 204 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/200.html -->
<!-- http://squeak.preeminent.org/tut2007/html/200A.html -->
<!-- http://squeak.preeminent.org/tut2007/html/201.html -->
<!-- http://squeak.preeminent.org/tut2007/html/202.html -->
<!-- http://squeak.preeminent.org/tut2007/html/203.html -->
<!-- http://squeak.preeminent.org/tut2007/html/204.html -->

Three small changes, taken one after the other: a wider margin so the window can be picked up by its edge, a shadow under the board and a divider bar in the control panel, and a default board worth playing on.

## A margin wide enough to grab

The first is a Morph problem with a Morph answer. Clicking the board picks up nothing, because the board acts on the click itself; the only part of the window that can be dragged is the margin around it, and five pixels of margin is a thin target. Page 200A widens it:

```
gameMargin
^10
```

The port has had that number since the game was built, because it inherited the finished 2007 source:

```smalltalk
LaserGameElement class >> gameMargin
	"Answer the margin, in pixels, between the edge of the game and what it holds. The original's
	number."

	^ 10
```

The page then warns of what the wider margin breaks. The mark showing where the laser enters was pinned to the bottom edge of the window by a layout frame written in pixels from that edge, and a margin of ten instead of five moves the edge without moving the mark, so `setupMorphs` is rewritten to place all three morphs against the new number. There is nothing to rewrite here: the mark is the last child of the column the board stands in, laid out under the last row of cells, and the game has no bottom padding at all so that the column ends where the game ends. That was the whole point of the arrangement in *Showing Laser Home Visually*, and it costs this page nothing.

## A shadow under the board

Page 201 gives the board a drop shadow. In Morphic it is three messages to the morph that holds the board form:

```
boardMorph
    hasDropShadow: true;
    shadowOffset: 3@3;
    shadowColor: (Color r: 0.25 g: 0.25 b: 0.254).
```

Bloc says the same thing with an effect, which is drawn under the element by Alexandrie and takes no part in the layout, so the board keeps exactly the size its cells give it -- the size every piece of the game's arithmetic is written from:

```smalltalk
LaserGameColors class >> boardShadowColor
	"Answer the colour of the shadow the board casts. Page 201 gives it as the shadow colour of
	the SketchMorph holding the board form."

	^ Color r: 0.25 g: 0.25 b: 0.254
```

```smalltalk
LaserGameBoardElement class >> shadowOffset
	"Answer how far the board casts its shadow, in pixels. Page 201 gives the SketchMorph holding
	the board form a shadow offset of three pixels down and to the right."

	^ 3 @ 3
```

```smalltalk
LaserGameBoardElement >> initialize
	"A board lays its cells out in a grid, one column per grid column, and takes exactly the
	size of the cells it holds. It casts a shadow down and to the right, which is page 201's
	drop shadow: the original asks its SketchMorph for one, and here it is an element effect,
	drawn under the board by Alexandrie and costing no layout space."

	super initialize.
	self background: LaserGameColors gameBoardBackgroundColor.
	self effect: (BlSimpleShadowEffect
			 color: LaserGameColors boardShadowColor
			 offset: self class shadowOffset).
	self layout: BlGridLayout horizontal.
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
```

```smalltalk
LaserGameBoardElementTestCase >> testTheBoardCastsADropShadow
	"Page 201 gives the board a drop shadow: three pixels down and to the right, in a dark grey.
	The original asks the SketchMorph holding the board form for it; here it is an element
	effect, so the shadow is drawn under the board and the board keeps the size its cells give
	it, which is what the game's arithmetic counts on."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	self assert: board effect class equals: BlSimpleShadowEffect.
	self
		assert: board effect color
		equals: LaserGameColors boardShadowColor.
	self
		assert: board effect offset
		equals: LaserGameBoardElement shadowOffset.
	board measure: BlExtentMeasurementSpec unspecified.
	self
		assert: board measuredExtent
		equals: (LaserGameBoardElement extentForGrid: GridFactory demoGrid)
```

## A divider bar in the panel

The second half of page 201 puts a thin bar across the control panel, above the buttons. The original builds a `RectangleMorph` with a raised border and a gradient fill, and then places it:

```
addDividerBarToPanel: panel
    | layout offset |
    offset := -105.
    layout := LayoutFrame
        fractions: (0 @ 1 corner: 0 @ 1)
        offsets: (10@offset corner: (self panelWidth - 10)@(offset + 5)).
    panel addMorph: self makePanelDividerMorph fullFrame: layout.
    ^panel
```

`-105` is the bar's distance from the bottom edge of the panel, and it is exactly the kind of number this port has been replacing since Section 4: it was found by eye against three rows of buttons, and a fourth row would move the buttons up through it. Here the bar is a child of the column of button rows, added first, so it stands above whatever rows that column holds:

```smalltalk
LaserGameColors class >> panelDividerDarkColor
	"Answer the darker end of the bar page 201 draws across the control panel above the buttons.
	The original fills a RectangleMorph with a gradient between two near whites."

	^ Color r: 0.847 g: 0.847 b: 0.85
```

```smalltalk
LaserGameColors class >> panelDividerLightColor
	"Answer the lighter end of the bar page 201 draws across the control panel above the buttons."

	^ Color r: 0.972 g: 0.972 b: 0.976
```

```smalltalk
LaserGameControlPanelElement class >> dividerHeight
	"Answer the height, in pixels, of the bar page 201 draws across me above the buttons. The
	original states it as the five pixels between the two offsets of the layout frame it places
	the RectangleMorph with."

	^ 5
```

```smalltalk
LaserGameControlPanelElement >> newPanelDivider
	"Answer the bar that separates my counters from my buttons: as wide as I am but for a gap on
	each side, five pixels tall, filled with the gradient of page 201. The original builds a
	RectangleMorph with a raised border and a GradientFillStyle, and hangs it off the bottom edge
	of the panel at an offset counted in pixels from there; here it is a child of the button
	column, so it stands above the buttons wherever they end up."

	| divider |
	divider := BlElement new.
	divider background: (BlLinearGradientPaint vertical stops: {
					 (0 -> LaserGameColors panelDividerDarkColor).
					 (1 -> LaserGameColors panelDividerLightColor) }).
	divider constraintsDo: [ :aConstraints |
		aConstraints horizontal exact:
			LaserGameElement panelWidth - (2 * self class buttonGap).
		aConstraints vertical exact: self class dividerHeight ].
	^ divider
```

```smalltalk
LaserGameControlPanelElement >> newButtonColumn
	"Answer the column of button rows: the bottom left corner of the panel, one gap from both
	edges, the rows one gap apart, the last row against the bottom. Page 144 places each button
	itself with #buttonLayoutFrameForRow:column:, which counts rows from the bottom and columns
	from the left; a column of rows says the same thing, and the third row, page 188's, falls in
	above the other two. Page 201's divider bar is the first child, so it sits above every row
	of buttons, which is where the original's offset from the bottom edge puts it. The cell
	spacing of a linear layout is added around the cells as well as between them, so it is the
	whole of the gap: a margin here would double the gap on the left and push the last button of
	the bottom row against the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class buttonGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	column addChild: self newPanelDivider.
	column addChild: self newResetRow.
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
```

The gradient is the original's two near whites, from the darker at the top to the lighter at the bottom. The raised border of the `RectangleMorph` has no counterpart: `BorderStyle complexRaised` is a Morphic bevel drawn in two greys, and a five pixel bar with a gradient already reads as a groove.

The bar costs height, and the panel states its own height for the case where the board beside it is shorter than what it holds -- the bug found in *Adding More Game Stats*, where a counter was drawn over a button. So the new cell is counted:

```smalltalk
LaserGameControlPanelElement class >> contentHeight
	"Answer the height, in pixels, of everything I hold: my counters, stacked with a gap between
	them and a gap above and below, and under them the divider bar and the rows of buttons,
	spaced the same way. A counter takes the size of its caption, so one is built and measured;
	nothing is laid out and nothing is opened. The original never needs this number, since it
	places its counters at fixed offsets from the top of a panel that is always taller than they
	are, and it hangs the divider of page 201 off the bottom edge at an offset of its own."

	| counter |
	counter := LaserGameCounterElement labelled: 'Active Mirrors' digits: 3.
	counter measure: BlExtentMeasurementSpec unspecified.
	^ ((self counterCount * counter measuredExtent y)
	   + ((self counterCount + 3) * self counterGap)
	   + (self buttonRowCount * self buttonHeight)
	   + self dividerHeight
	   + ((self buttonRowCount + 2) * self buttonGap)) ceiling
```

The panel's content height goes from 320 to 335, and a game on the demo board from 380 by 340 to 380 by 355. The eight by ten board is taller than the panel either way, so the standard game stays 530 by 520.

Three methods read a row of buttons back out of the column by its position, and the divider is now the child in front of them:

```smalltalk
LaserGameControlPanelElement >> panelDivider
	"Answer the bar page 201 draws across me above the buttons. It is the first child of the
	button column, which reads from the top."

	^ self buttonColumn children first
```

```smalltalk
LaserGameControlPanelElement >> resetRow
	"Answer the top row of buttons. Page 144 counts rows from the bottom and this is the third of
	them, so it is the second child of the column, which reads from the top and starts with page
	201's divider bar."

	^ self buttonColumn children second
```

```smalltalk
LaserGameControlPanelElement >> newGameRow
	"Answer the middle row of buttons, holding New and Undo. Page 144 calls it row two, so it is
	the third child of the column, which reads from the top and starts with page 201's divider
	bar."

	^ self buttonColumn children third
```

```smalltalk
LaserGameControlPanelElementTestCase >> testThePanelShowsADividerAboveItsButtons
	"Page 201 draws a bar across the panel above the buttons, a gap in from each edge and five
	pixels tall. The original hangs it off the bottom edge of the panel at a fixed offset, which
	is a number that has to be found again whenever a row of buttons is added; here it is the
	first child of the column of button rows, so it stands above them wherever they stand."

	| panel divider |
	panel := self newPanel.
	divider := panel panelDivider.
	self assert: (panel buttonColumn children includes: divider).
	self assert: panel buttonColumn children first equals: divider.
	self
		assert: divider constraints horizontal resizer size
		equals:
		LaserGameElement panelWidth
		- (2 * LaserGameControlPanelElement buttonGap).
	self
		assert: divider constraints vertical resizer size
		equals: LaserGameControlPanelElement dividerHeight.
	self
		assert: divider background paint stops first value
		equals: LaserGameColors panelDividerDarkColor.
	self
		assert: divider background paint stops last value
		equals: LaserGameColors panelDividerLightColor
```

And the test that reads the whole column back, which has now been rewritten by three sections running -- page 188 added a row, page 189 changed what the game holds, and this page adds the bar:

```smalltalk
LaserGameControlPanelElementTestCase >> testResetButtonHasTheTopRowToItself
	"Page 188 puts Reset in row three, column one, which is the row above New and Undo and the
	topmost of the three. Its button is the one thing the panel does not hold in an instance
	variable, so it is read from its row. Since page 201 the column starts with the divider bar,
	so the three rows follow it."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel panelDivider.
			panel resetRow.
			panel newGameRow.
			panel buttonRow }.
	self assert: panel resetRow children asArray equals: { panel resetButton }.
	self assert: panel resetButton class equals: ToButton.
	self assert: panel resetButton labelText asString equals: 'Reset'
```

## A default board worth playing on

Pages 203 and 204 are a guided tour of Squeak: open a `LaserGame` from the World menu's alphabetical list, find it too small to play, and go looking for the reason. The tour ends in `TheWorldMenu >> newMorphOfClass:event:`, whose first line is `m := morphClass new`, and so in `LaserGame >> initialize`, which builds the five by five demo board. The fix is a new default:

```
defaultGrid
^self randomizedGridOfExtent: 8@10

initialize
self initializeForGrid: GridFactory defaultGrid
```

`GridFactory class >> defaultGrid` came with the 2007 source and has been in the package since Section 1:

```smalltalk
GridFactory class >> defaultGrid
	^self randomizedGridOfExtent: 8@10
```

The menu has no counterpart. Pharo opens no morph from an alphabetical list, and a Bloc element is not something the environment instantiates behind your back; what this image offers instead is the `<sampleInstance>` pragma, which is why the game has carried its own openers since Section 2:

```smalltalk
LaserGameElement class >> openStandardExample
	"Open the standard board of page 148: eight columns by ten rows, dealt. The demo board of
	#openExample is the five by five one the earlier sections play on.

	LaserGameElement openStandardExample"

	<sampleInstance>
	^ self openOn: GridFactory defaultGrid
```

But the substance of the page survives the loss of the menu. A game built with no grid at all should be a game worth looking at, and here it was not: `grid` answered nil and the element stayed empty. So the default moves into the accessor, where it is dealt when it is first asked for -- a game that is handed a grid never deals a board it would throw away:

```smalltalk
LaserGameElement >> grid
	"Answer the grid the game plays on. A game built with no grid at all plays the standard
	board, which is page 204: the world menu opens a morph by sending #new, so #new has to answer
	something worth looking at, and the original changes LaserGame >> initialize to ask
	GridFactory for a defaultGrid of eight columns by ten rows instead of the five by five demo
	board. The board is dealt when it is first asked for, so a game that is given a grid never
	deals one it would throw away."

	^ grid ifNil: [
		  self grid: GridFactory defaultGrid.
		  grid ]
```

```smalltalk
LaserGameElementTestCase >> testAGameMadeWithNoGridPlaysTheStandardBoard
	"Page 203 opens a LaserGame from the world menu and finds it too small to play: the menu
	sends #new, and #initialize builds the five by five demo board. Page 204 answers with
	GridFactory defaultGrid, eight columns by ten rows, dealt. Here a game takes its grid from
	outside, so the default is what it falls back on when nobody gave it one, and it is dealt
	when it is first asked for rather than in #initialize, so a game that is given a grid deals
	no board it would throw away."

	| game |
	game := LaserGameElement new.
	self assert: game grid numberOfColumns equals: 8.
	self assert: game grid numberOfRows equals: 10.
	self assert: game board grid equals: game grid.
	self
		assert: game constraints horizontal resizer size
			@ game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: game grid).
	self
		assert: (LaserGameElement on: GridFactory demoGrid) grid numberOfColumns
		equals: 5
```

## Checking it

Page 202 opens the game, looks at the shadow and the bar, re-runs the tests and saves version 19; page 204 does the same for the default board and saves version 20. Here:

```
276 run, 276 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

247 test methods, three of them new, one rewritten for the new child, and 276 runs for the reason given in *A Less Brittle Unit Test Design*.

# The 2007 Code Leaves The Package

*An addition of the port, after page 204.*

Every page of the original that this port follows has now been followed, and the last thing left in the package that no page asks for is the original itself. The 2007 code was captured whole into `Laser-Game` at the very beginning so that each chapter could read it before rewriting it. Section by section it lost its readers, and what is left is a closed island: code that nothing in the game calls, nothing in the tests names, and nothing outside itself refers to.

## What goes

Five classes and thirteen methods.

`LaserGame` is the original's `Morph`: forty five instance methods and sixteen class methods covering the window, the control panel, the counters, the undo stack and the mouse handling. Every one of its pages has a Bloc counterpart now — `LaserGameElement`, `LaserGameBoardElement`, `LaserGameControlPanelElement`, `LaserGameCellElement`, `LaserGameCounterElement` and `LaserGameLedElement` between them — and the only senders of `LaserGame` left in the image were two of its own class methods, `addApplication` and `clearApplication`, which registered it in a Squeak world menu that does not exist in Pharo 13.

`MorphPath`, a subclass of `DisplayObject`, and its subclasses `Arc`, `Circle` and `Line` are copies of Squeak display infrastructure that came in with the capture. They draw by sending `displayOn:at:clippingBox:rule:fillColor:` to a `Form`. Their replacements have been in the package since Section 2: `BlLineGeometry`, `BlCircleGeometry` and `BlPolygonGeometry`, drawn by Alexandrie, sized in whatever extent they are given.

And `CellRenderer` kept an island of its own, reachable only from `LaserGame >> drawGameBoard`: the instance variable `targetForm` with its two accessors, `offsetWithinGridForm`, `backgroundRectangle`, `fillBackground`, `renderBorder` and the four `renderBorderTop`, `renderBorderBottom`, `renderBorderLeft` and `renderBorderRight` that drew into it — the four that were the last senders of `Line` in the package — plus `renderContents` on `CellRenderer` and on `BlankCellRenderer`, and the class method `rendererFor:grid:form:` that handed a renderer the board form to paint on. A renderer answers an element now. It paints nothing.

The definition loses its third instance variable:

```smalltalk
Object << #CellRenderer
	slots: { #cellLocation . #grid };
	tag: 'Graphics';
	package: 'Laser-Game'
```

## What that settles

Rule two of this port says that no class may depend on `Morph` or `Form`. Until now that was true of everything the port had written and false of what it had inherited. It is true of the whole package now: `Laser-Game` is forty two classes wide where it was fifty at the start of Section 1 and forty seven after *Better Hint Arrows Alignment*, no class in it descends from `Morph` or from `DisplayObject`, and the words `Form`, `BitBlt`, `SketchMorph`, `Display`, `World`, `Cursor` and `DisplayObject` appear in it only inside comments, where they say what page of the original a method replaces.

Nothing else changed, and nothing needed to. The test suite is the proof: 247 test methods, 276 runs, all green before the deletion and all green after it, with no test touched. A dead island is exactly the thing you can remove without a single test noticing, and the way to be sure an island is dead is to have written a test for everything that is alive.

## What is still on the list

Two things that are not 2007 code and are not display code, left as they are because they are outside this clean-up:

* Twelve classes in the package have no class comment: `GridDirection` with its four subclasses, and `ReverseLaserGameAction` with its six. Seventeen class-side methods of the same two hierarchies are unclassified.
* `GridDirection` and its subclasses answer four constants each, `directionSymbol`, `vector`, `adjacentInversionSymbol` and `adjacentInVersionSymbol`, with no `subclassResponsibility` on the superclass to declare them. The last two differ only in one capital letter and look very much like the same method written twice.

`run_critics` on the two packages reports forty four critiques, and every one of them is in that list.

# Counters Of One Width

*An addition of the port, after page 204.*

Reported by the user on 2026-09-29, looking at the finished game: the four counter boxes are not the same width, their right edges are ragged, and what each box holds sits against its left border.

## What the panel actually measured

The fault is the original's design, faithfully ported. Page 141 gives a counter no width of its own: it is a frame around a column, and it takes the size of what it holds. Its display is three digits, thirty four pixels, the same in every counter; its caption is a string, and the four strings are four lengths. Asking the column to measure itself says so:

```
Laser Path      counter 53   led 34   label 43
Moves           counter 44   led 34   label 26
Mirrors         counter 44   led 34   label 27
Active Mirrors  counter 64   led 34   label 54
```

Four boxes of three widths, all starting at the same left edge, none ending at the same right one, in a panel a hundred and ten pixels wide. Inside each box a vertical linear layout places its two children at the start of the cross axis, which is the left, so the display and the caption both sit against the left border with the slack on the right -- and the slack is a different size in every box.

The original does not look like this, and not because it does anything better: its panel is wider than its widest caption and its boxes are drawn where page 141 and page 181 say, so the ragged right edges are there too, in a corner of a window nobody measured. This port fills the panel with the counters, so the raggedness is the first thing the eye lands on.

## One width, stated once

The panel owns the column, so the panel states the width. It is the panel's own width less the gap the column stands in on each side -- a hundred and two pixels -- so the four boxes fill the panel between its margins:

```smalltalk
LaserGameControlPanelElement class >> counterWidth
	"Answer the width, in pixels, of every counter: my own width, less the gap the column of
	counters stands in on each side. Page 141 gives a counter no width at all and lets it take
	the size of its caption, which leaves the four boxes of the original four different widths;
	stating one width for all four lines their edges up under each other and fills the panel."

	^ LaserGameElement panelWidth - (2 * self counterGap)
```

A counter is built through one method now, rather than four calls to `LaserGameCounterElement class >> labelled:digits:`, and that method is where the width is given:

```smalltalk
LaserGameControlPanelElement >> newCounterLabelled: aString digits: anInteger
	"Answer a counter of anInteger digits captioned aString, as wide as every other counter I
	hold. A counter takes the size of its caption when it is not told otherwise, which is what
	page 141 leaves it at, so each of my four counters would be a different width; stating the
	width here is what lines their edges up, and the counter centres its display and its caption
	in whatever width it is given."

	| counter |
	counter := LaserGameCounterElement labelled: aString digits: anInteger.
	counter constraintsDo: [ :aConstraints |
		aConstraints horizontal exact: self class counterWidth ].
	^ counter
```

so the four builders are one line each:

```smalltalk
LaserGameControlPanelElement >> newActiveMirrorsCounter
	"Answer the counter showing how many mirrors the beam lights: three digits, captioned as on
	page 181. That caption is the longest of the four, and it is why the original widens its panel
	on the same page; here every counter is the width of the panel less its gaps, so the longest
	caption decides nothing."

	^ self newCounterLabelled: 'Active Mirrors' digits: 3
```

`newLaserPathCounter`, `newMovesCounter` and `newMirrorsCounter` are the same line with their own captions and are not repeated here.

## Centred, not left

A width wider than the caption is a fault of its own unless what the box holds moves to the middle of it. A linear layout places a child across its cross axis where the child's own constraints say, so the display and the caption each ask for the centre. The counter does it when it builds them, since both are replaceable:

```smalltalk
LaserGameCounterElement >> digits: anInteger
	"Show anInteger digits. The display is narrower than I am, since my width is stated for all
	four counters of the panel and their captions, so it is centred rather than left against my
	border."

	led ifNotNil: [ :each | self removeChild: each ].
	led := LaserGameLedElement digits: anInteger.
	led constraintsDo: [ :aConstraints |
		aConstraints linear horizontal alignCenter ].
	self addChild: led
```

```smalltalk
LaserGameCounterElement >> labelText: aString
	"Caption me aString. The caption is added last, so it is drawn under the display, and it is
	centred like the display: every caption is a different length and my width is the same for
	all four counters of the panel."

	label ifNotNil: [ :each | self removeChild: each ].
	label := BlTextElement new text: (aString asRopedText
			         fontSize: self class labelFontSize;
			         foreground: LaserGameColors counterLabelColor;
			         yourself).
	label constraintsDo: [ :aConstraints |
		aConstraints linear horizontal alignCenter ].
	self addChild: label
```

Nothing else in the counter changes. It is still a transparent rounded frame with a two pixel border and a five pixel inset, it still fits its content vertically, and it still takes the width of its caption when nobody states one -- which is what `LaserGameCounterElement class >> labelled:digits:` answers on its own, and what `LaserGameControlPanelElement class >> contentHeight` measures when it asks one counter how tall a counter is.

Laid out in the finished panel, the four boxes now read:

```
Laser Path      (0.0@4.0) corner: (102.0@52.0)      display and caption centred on 51.0
Moves           (0.0@56.0) corner: (102.0@104.0)    display and caption centred on 51.0
Mirrors         (0.0@108.0) corner: (102.0@156.0)   display and caption centred on 51.0
Active Mirrors  (0.0@160.0) corner: (102.0@208.0)   display and caption centred on 51.0
```

in a panel that is still 110 by 335, with the divider bar still ninety pixels wide between its own gaps. No size of the game changed: a counter's height is what it always was, and `contentHeight` counts heights.

## Tests

Two tests, one on each side of the decision. The panel's says that the four boxes are one width and what that width is stated from:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryCounterIsAsWideAsThePanelLessAGapOnEachSide
	"Page 141 lets every counter take the width of its own caption, so the four boxes of the
	original are four different widths with their right edges ragged. Here they are all given the
	width of the panel less the gap the column stands in, so the four boxes are the same width
	and their edges line up under each other."

	| panel widths |
	panel := self newPanel.
	panel counterColumn measure: BlExtentMeasurementSpec unspecified.
	widths := (panel counterColumn children collect: [ :each |
		           each measuredExtent x ]) asSet.
	self assert: widths size equals: 1.
	self
		assert: widths anyOne
		equals: LaserGameControlPanelElement counterWidth.
	self
		assert: LaserGameControlPanelElement counterWidth
		equals:
		LaserGameElement panelWidth
		- (2 * LaserGameControlPanelElement counterGap)
```

The counter's says that what it holds is aligned to the centre:

```smalltalk
LaserGameCounterElementTestCase >> testACounterCentresWhatItHolds
	"Every counter of the panel is given the same width, wider than any of the four captions, so
	what a counter holds has to be centred in it: left against the border, the display of one
	counter and the display of the next would line up but the captions would not, and every box
	would have a ragged margin on its right. Both children are aligned to the centre of the
	column, which is what a linear layout reads to place them across itself. Where they land is
	Bloc's arithmetic and is not repeated here: nothing is laid out, and no element is opened."

	| counter |
	counter := LaserGameCounterElement labelled: 'Moves' digits: 3.
	self assert: counter layout class equals: BlLinearLayout.
	self
		assert: counter led constraints linear horizontal alignment
		equals: BlElementAlignment horizontal center.
	self
		assert: counter label constraints linear horizontal alignment
		equals: BlElementAlignment horizontal center
```

That second test asserts the constraint and not the position, which deserves a word. The position is the honest assertion -- the display's centre falls on the middle of the box -- and `BlElement >> forceLayout` would give it without a space, which is exactly what the method's own comment says it is for. Renraku disagrees: `ReBlocDoNotSendForceLayoutRule` reports every send of it, and this port keeps the critics clean on what it writes. The layout was run by hand instead, in a workspace, and it is the numbers printed above; the test keeps the part of the claim that is the port's own decision, and leaves the arithmetic to Bloc.

278 test runs, all green, and `run_critics` reports nothing on `LaserGameCounterElement`, `LaserGameControlPanelElement` or either test class.

# Buttons Of One Width

*An addition of the port, after page 204.*

Reported by the user on 2026-09-29, in the same look at the finished game that found the counters: the labels of the *Reset* and *Undo* buttons run into the right edge of their buttons. The text should stand in the middle of a button, it should fit inside it, and every button should be the same width.

## What a button actually measured

Every button was already the same width. Page 144 states forty pixels for a button and twenty for its height, and `newButton:action:` gives every one of them that extent, so the third part of the report held before anything was changed. The first two parts are one fault, and it is the label and not the button.

A `ToButton` holds its label in a container of its own, and lays that container out with a linear layout. A linear layout aligns its children to the start of its axis unless it is told otherwise, and the start of the horizontal axis is the left. So every label sat against the left border of its button, with all of the slack on the right. Measuring the six labels a panel can show, against the forty pixels they stand in:

```
Quit    25      Fire    22      Stop    28
New     26      Undo    33      Reset   33

```

Thirty three pixels of label in a forty pixel button, hard against the left border, leaves seven pixels of nothing on the right and a word that ends a hair before the border it is painted against. That is what the report saw. The original is no better off -- page 144 is the source of the forty -- but it paints its labels with a `StringMorph` centred by `PluggableButtonMorph`, so its slack is split between the two sides and three pixels on each side reads as a tight button rather than a broken one. A font a little wider than the one this theme gives a button paints *Reset* and *Undo* over the edge in either design.

## Centred, not left

The fix is one line, and finding which line took some looking. A `ToButton` has three things that sound like they would centre a label, and two of them do nothing:

```
button alignCenter                              label container still at x 0
button label constraintsDo: [ :c | ... ]        label container still at x 0
button labelContainer constraintsDo: [ :c | ... ]   label container still at x 0
button layout alignCenter                       label container at 3.5 .. 36.5

```

The constraints of the label and of its container already say centre; they are read by the layout of whatever holds them, and what holds the container is the button's own layout, which had no alignment of its own. Telling that layout to centre is what moves the label:

```smalltalk
LaserGameControlPanelElement >> newButton: aLabel action: aBlock
	"Answer a labelled button of the original's size that evaluates aBlock when it is clicked. The
	original builds a PluggableButtonMorph with a StringMorph label and paints its colors by hand;
	Toplo gives the look and the click, so only the label, the size and the action are left. A
	Toplo button lays its label out with a linear layout, which aligns to the start unless it is
	told otherwise, so the label is centred here: a button is wider than any of its labels."

	| button |
	button := ToButton labelText: aLabel.
	button layout alignCenter.
	button extent: self class buttonWidth @ self class buttonHeight.
	button clickAction: aBlock.
	^ button

```

## A width stated from its labels

Centring a label does not make it fit. Forty pixels holds thirty three with three on each side, and the report is about a label that is too close to its border, so the button is widened until its longest label has a margin worth the name. The margin is stated rather than left to the reader of the number:

```smalltalk
LaserGameControlPanelElement class >> buttonLabels
	"Answer every label a button of mine can show: the five buttons, and the second label the
	fire button takes while the laser is firing. They are what my button width has to hold."

	^ #( 'Quit' 'Fire' 'Stop' 'New' 'Undo' 'Reset' )

```

```smalltalk
LaserGameControlPanelElement class >> buttonLabelMargin
	"Answer the space, in pixels, my button width keeps on each side of its longest label. It is
	what makes the width a statement about the labels rather than a number that happens to fit."

	^ 6

```

```smalltalk
LaserGameControlPanelElement class >> buttonWidth
	"Answer the width, in pixels, of a control panel button. Page 144's number is forty, which is
	three pixels wider than the word Reset and leaves nothing on either side of it; a font a
	little wider than this one paints the longest labels over the edge of their buttons. Fifty
	holds every label of #buttonLabels with #buttonLabelMargin to spare on each side, which
	#testEveryButtonLabelFitsInsideTheButton is what checks. The panel width follows from this
	number, so widening a button widens the panel and not the space the buttons stand in."

	^ 50

```

Six labels, and only five buttons: the fire button shows *Fire* or *Stop* depending on what a click will do, so both of its labels have to fit.

The width could have been measured instead of stated -- ask every label of `#buttonLabels` how wide it is, take the widest, add two margins -- and the method for measuring one is written anyway, because the test needs it:

```smalltalk
LaserGameControlPanelElement class >> widthOfButtonLabel: aString
	"Answer the width, in pixels, a button captioned aString needs for its label: a button is
	built and measured, and nothing is laid out and nothing is opened. Toplo measures the label
	with the font its theme gives a button, which is the only thing that knows how wide the text
	is going to be."

	| button |
	button := ToButton labelText: aString.
	button measure: BlExtentMeasurementSpec unspecified.
	^ button measuredExtent x

```

Building and measuring six buttons costs about a millisecond and a half, and `panelWidth` has twelve senders, some of them in the arithmetic that sizes a window. A number that is read that often should not build anything. So the width is stated, at fifty, and the test measures the six labels against it: a theme with a wider font breaks a test rather than the picture.

## The panel follows the buttons

Page 066's panel is a hundred and ten pixels wide, and page 144's button is forty. Those two numbers are not independent: two buttons and the three gaps a row of two stands in come to exactly a hundred and ten, which is why a row of two buttons fills the panel and a row of three does not fit. `testARowOfTwoButtonsFitsInsideThePanel` states that identity. Widening a button while leaving the panel alone would break it, so the panel is stated from the button instead of beside it:

```smalltalk
LaserGameElement class >> panelWidth
	"Answer the width, in pixels, of the control panel beside the board. The original's number is
	a hundred and ten, which is exactly two of its forty pixel buttons and the three gaps a row
	of two stands in; the identity is what makes a row of two fill the panel and a row of three
	not fit. The buttons are wider here, so that their labels fit inside them, and the panel is
	stated from them rather than beside them."

	^ (2 * LaserGameControlPanelElement buttonWidth)
	  + (3 * LaserGameControlPanelElement buttonGap)

```

Four numbers move with it, and all four are the window growing by twenty pixels of width:

```
panel width      110  ->  130
counter width    102  ->  122
demo game        380@355  ->  400@355
eight by ten     530@520  ->  550@520

```

The counters keep the width the previous chapter gave them -- the panel less a gap on each side -- so they widen with the panel and stay flush with each other.

Measured afterwards, every button is fifty wide with its label in the middle of it; the widest label, *Reset*, lands at `(8.5@1.0) corner: (41.5@19.0)`, which is eight and a half pixels of margin on each side of a fifty pixel button.

## Tests

Two tests were written before the fix, and both were red. The first measures the labels, which is the part of the claim the port owns:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryButtonLabelFitsInsideTheButton
	"Page 144 states forty pixels for a button and never asks whether its labels fit; the longest
	of them, Reset and Undo, fill all but a few pixels of that, and a font a little wider than
	this one paints them over the edge. The width is stated here too, but the six labels the
	panel can show are measured against it, with a margin on each side of the longest."

	LaserGameControlPanelElement buttonLabels do: [ :each |
		self
			assert:
				(LaserGameControlPanelElement widthOfButtonLabel: each)
				+ (2 * LaserGameControlPanelElement buttonLabelMargin)
			<= LaserGameControlPanelElement buttonWidth
			description: each , ' does not fit inside a button' ]

```

The second states that every button centres what it holds. It asserts the alignment and not the position, for the reason the counters chapter gave: `BlElement >> forceLayout` is what would give a position without a space, and `ReBlocDoNotSendForceLayoutRule` reports every send of it. The positions above were read by hand in a workspace:

```smalltalk
LaserGameControlPanelElementTestCase >> testEveryButtonCentresItsLabel
	"A button is wider than any of its labels, so the label has to stand in the middle of it. A
	Toplo button lays its label container out with a linear layout, and that layout aligns to the
	start unless it is told otherwise, which leaves every label against the left edge of its
	button. Where the label lands is Bloc's arithmetic and is not repeated here: nothing is laid
	out, and no element is opened."

	| panel |
	panel := self newPanel.
	panel buttonColumn children do: [ :row |
		row children do: [ :button |
			self
				assert: button layout alignment horizontal
				equals: BlElementAlignment horizontal center ] ]

```

One older test knew the panel's width as a literal, and now knows the new one:

```smalltalk
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins
	"The game is as wide as the board, the panel beside it and a margin on each side, and as tall
	as the taller of the board and the panel, with a margin above and below. This is the
	original's calculatedExtent, which knows only the board height; the demo grid is short enough
	for the panel to decide instead. The second assertion states the numbers rather than the
	constants: the panel is a hundred and thirty, two fifty pixel buttons and the three gaps a
	row of two stands in, where the original's panel is a hundred and ten around its forty pixel
	buttons."

	| grid expected |
	grid := GridFactory demoGrid.
	expected := (LaserGameBoardElement extentForGrid: grid) x
	            + LaserGameElement panelWidth
	            @ (LaserGameControlPanelElement heightForGrid: grid)
	            + (2 * LaserGameElement gameMargin).
	self assert: (LaserGameElement extentForGrid: grid) equals: expected.
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals:
			5 * CellRenderer cellExtent x + 130
			@ LaserGameControlPanelElement contentHeight + 20

```

280 test runs, all green, and `run_critics` reports nothing on `LaserGameControlPanelElement`, `LaserGameElement` or either test class.
