<!-- Tutorial Section 3 covers pages 074 to 129A of tut2007/html.
     This file starts at page 074, the first page of the section. -->

# Interacting With Cells

*Pages 074 to 077 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/074.html
     http://squeak.preeminent.org/tut2007/html/075.html
     http://squeak.preeminent.org/tut2007/html/076.html
     http://squeak.preeminent.org/tut2007/html/077.html -->

The board is on the screen and the laser fires, so the game can now be played with the mouse. Only mirror cells react: a mirror can be rotated, and it can be pushed to the next square along. That is two different actions on one cell, and the mouse has one button, so the cell has to decide from *where* it was clicked which of the two was meant.

The original divides a cell into three areas, one inside the next:

- an **inside** region, a square around the centre. A click here pushes the cell.
- an **outside** region, the ring around it. A click here rotates the cell.
- an **ignore** region, the margin along the four edges. A click here does nothing: someone clicking that close to an edge is probably aiming at the cell next door, and guessing would be worse than dropping the click.

This chapter builds the classification and its tests. Nothing is wired to the mouse yet — that is the next chapter — but by the end of this one a cell element can be handed a point and will say which region it fell in.

## The constants live with the cell size

Page 075 starts on the class side of `CellRenderer`, which already holds the size of a cell, and adds the numbers the regions need. The captured source has them, in a `constants` protocol as the page asks:

```smalltalk
CellRenderer class >> cellExtent
	^50@50
```

```smalltalk
CellRenderer class >> insideRegionExtent
	^self cellExtent - 20
```

```smalltalk
CellRenderer class >> ignoreRegionOffset
	^4
```

```smalltalk
CellRenderer class >> outsideRegionExtent
	^self cellExtent - (2 * self ignoreRegionOffset)
```

Only `cellExtent` and `ignoreRegionOffset` are numbers; the other two are derived from them, which is why the port has not had to touch any of this while changing how a cell is drawn. With the captured cell size of 50 by 50 the inside square is 30 by 30, the outside square is 42 by 42, and the ignore margin is 4 pixels all round.

> **Note on the sizes.** The 2007 text works with a 30 by 30 cell and a 14 by 14 inside region, and page 077 is a debugging session about exactly those two numbers. The source this port inherits is the finished game, where the author had already enlarged the cells — page 137 of the tutorial — and rewritten `insideRegionExtent` as `cellExtent - 20`. So the numbers in the screenshots of pages 075 to 077 do not match the image, while the reasoning does.

## A class per region

The regions are classes, not instances: the same shape for every cell, so there is nothing to carry. `CellClickRegion` is the abstract root and each region answers two things, its rectangle in cell coordinates and where it comes in the order regions are asked in:

```smalltalk
CellClickRegion class >> regionRectangle
	"Answer the rectangle, in cell coordinates, that I claim. Every concrete region answers one."

	^ self subclassResponsibility
```

```smalltalk
CellClickRegion class >> sortIndex
	"Answer where I come in the order regions are asked in. The innermost region answers the
	smallest number, so that it claims a point the wider regions also contain."

	^ self subclassResponsibility
```

Those two are the port's only addition to the hierarchy — the critics rightly asked for them, since every subclass implements both. Each concrete region then derives its rectangle from the constants:

```smalltalk
CellClickRegionInside class >> regionRectangle
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
```

```smalltalk
CellClickRegionOutside class >> regionRectangle
	"CellClickRegionOutside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer outsideRegionExtent.
	^outer insetBy: (delta // 2)
```

```smalltalk
CellClickRegionIgnore class >> regionRectangle
	^0@0 extent: CellRenderer cellExtent
```

## Priority decides, not geometry

Page 076 walks into the interesting part of this design. The three rectangles are nested, so a point near the centre of a cell is inside all three of them, and "which rectangle contains this point" has three right answers. The original's fix is to give the regions an order and take the first match — innermost first, ignore last:

```smalltalk
CellClickRegion class >> sortedSubclasses
	^self subclasses asSortedCollection: [:a :b | a sortIndex < b sortIndex]
```

```smalltalk
CellClickRegion class >> clickRegionForPoint: aPoint
	^self sortedSubclasses detect: [:cls | cls regionRectangle containsPoint: aPoint]
```

So `sortIndex` 1 for the inside region, 2 for the outside region, 3 for the ignore region, whose rectangle is the whole cell and therefore always matches. A point that no smaller region claimed lands there, which is precisely what "ignore" means.

## Page 077's measurement is already settled

The original then writes the tests, finds that the point 13 by 13 is claimed by the inside region when the test expected the outside one, and suspects the test. It writes a little workspace loop that prints the region of every point along a diagonal to the Transcript, works out that with a 30 by 30 cell and a 14 by 14 inside region the transition must be at 8 pixels, and concludes that the inside region was simply defined too big. It shrinks it and the tests pass.

The inherited code carries the end of that argument — the derived `insideRegionExtent` — and the inherited tests carry its lesson: not one of them names a pixel. They ask the rectangles where they are:

```smalltalk
CellClickRegionTestCase >> testClicksInIgnoreRegion

	| ignoreRect outsideRect |
	ignoreRect := CellClickRegionIgnore regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	"The ignore region is the margin of the cell left over once the outside region is inset."
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

The same shape covers the outside region, the ring between the ignore margin and the inside square:

```smalltalk
CellClickRegionTestCase >> testClicksInOutsideRegion

	| insideRect outsideRect |
	insideRect := CellClickRegionInside regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	"The outside region is the ring between the ignore margin and the inside region."
	self
		deny: (CellClickRegion clickRegionForPoint: outsideRect topLeft - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: insideRect topLeft - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect bottomRight - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		deny: (CellClickRegion clickRegionForPoint: insideRect center)
		equals: CellClickRegionOutside
```

and `testClicksInInsideRegion` does the third, checking that the inside region owns its top left corner, its centre and its last pixel, and owns nothing beyond them. Written that way the tests hold at any cell size, which is worth having: the cells in this image are already not the size the tutorial's screenshots show.

## The cell becomes the thing you click

Here the port leaves the original behind. In 2007 every cell was painted into one `Form` belonging to the board, so a click arrived as a point on that shared surface and had to be converted: divide by the cell size to get the grid location, subtract the cell offset to get a point within the cell, then classify it. The methods for that are all still in the package — `CellRenderer >> offsetWithinGridForm`, and the `cellForEvent:` and `cellPositionForEvent:` family on the `LaserGame` morph.

On Bloc a cell is its own element, it is already the target of a click, and Bloc hands an event handler the position in the coordinates of the element that received it. The conversion has nothing left to do. What is missing is the other direction: given the element, which cell of the model is it? So the port gives the cell element a class of its own, holding the renderer that built it:

```smalltalk
LaserGameCellElement >> cell
	"Answer the cell I show."

	^ self renderer cell
```

```smalltalk
LaserGameCellElement >> gridLocation
	"Answer where my cell sits in the grid, x being the column and y the row."

	^ self renderer cellLocation
```

```smalltalk
LaserGameCellElement >> clickRegionAt: aPoint
	"Answer the click region class aPoint falls in. aPoint is in my own coordinates, which is what
	Bloc hands to an event handler, so no board offset is subtracted first."

	^ CellClickRegion clickRegionForPoint: aPoint
```

`clickRegionAt:` is one line, and that one line is the whole of what this chapter needed to port: the point arrives in cell coordinates already.

The renderer builds that element instead of a plain one:

```smalltalk
CellRenderer >> newElement
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderContentsOn: element.
	^ element
```

and the board goes on building one per cell, in row order, letting the grid layout place them:

```smalltalk
LaserGameBoardElement >> rebuildCells
	"Replace my children with one element per cell of my grid, row by row. The grid layout
	places them, so no cell has to work out where it is on a shared surface."

	self removeChildren.
	self layout columnCount: self grid numberOfColumns.
	1 to: self grid numberOfRows do: [ :row |
		1 to: self grid numberOfColumns do: [ :column |
			| location |
			location := column @ row.
			self addChild: (CellRenderer
					 rendererFor: (self grid at: location)
					 grid: self grid) newElement ] ]
```

```smalltalk
LaserGameBoardElement >> cellElementAt: aPoint
	"Answer the element showing the cell at aPoint, x being the column and y the row."

	| index |
	index := aPoint y - 1 * self grid numberOfColumns + aPoint x.
	^ self children at: index
```

> **Porting note.** `LaserGameCellElement` holds the renderer rather than the cell, and answers `cell` by asking it. The renderer already knows the grid and the location, and it is what redraws the cell when the model changes, so keeping it is what lets a later chapter refresh a single cell in place instead of rebuilding the board.

One method leaves with this step: `CellRenderer >> mouseUpWithinBoardOffset:`, whose whole body was `^ self cell` — the old answer to "which cell was clicked", now answered by the element itself. Its only sender is the `LaserGame` morph's `mouseUp:forMorph:cell:`, which the next chapter replaces.

## Tests

Five tests, and they are about identity and coordinates rather than about drawing:

```smalltalk
LaserGameCellElementTestCase >> testACellElementKnowsTheCellItShows
	"A cell element carries its own cell, so nothing has to work back from a position on the
	board to a grid location."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 2 @ 3.
	self assert: element cell identicalTo: (board grid at: 2 @ 3).
	self assert: element gridLocation equals: 2 @ 3
```

```smalltalk
LaserGameCellElementTestCase >> testEveryChildOfTheBoardIsACellElement
	"The board holds one cell element per cell of its grid."

	| board grid |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	grid := board grid.
	self
		assert: board children size
		equals: grid numberOfColumns * grid numberOfRows.
	board children do: [ :each |
		self assert: each class equals: LaserGameCellElement ]
```

```smalltalk
LaserGameCellElementTestCase >> testEachCellElementCarriesTheRendererOfItsCell
	"The element is built by a renderer, and it keeps it: that is what redraws the cell later."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	board children do: [ :each |
		self assert: each renderer class modelClass equals: each cell class ]
```

```smalltalk
LaserGameCellElementTestCase >> testACellElementClassifiesAPointOfItsOwn
	"A point is classified in the coordinates of the cell element itself: the top left corner is in
	the ignore margin, the first pixel of the outside rectangle is in the outside region, and the
	centre is in the inside region."

	| element |
	element := (LaserGameBoardElement on: GridFactory demoGrid) cellElementAt: 1 @ 1.
	self
		assert: (element clickRegionAt: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (element clickRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (element clickRegionAt: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionInside
```

The last one is the point of the whole step. In the original, asking which region a click fell in required knowing where the cell was; here the far corner of the board answers exactly what the origin answers:

```smalltalk
LaserGameCellElementTestCase >> testTheSameLocalPointMeansTheSameRegionInEveryCell
	"Every cell classifies points in its own coordinates, so the cell in the far corner answers
	exactly what the cell at the origin answers. The original had to subtract the offset of the
	cell within the shared board form before it could ask this question."

	| board first last |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	first := board cellElementAt: 1 @ 1.
	last := board
		        cellElementAt: board grid numberOfColumns @ board grid numberOfRows.
	{ 0 @ 0.
	CellClickRegionOutside regionRectangle topLeft.
	CellClickRegionInside regionRectangle center } do: [ :point |
		self
			assert: (last clickRegionAt: point)
			equals: (first clickRegionAt: point) ]
```

## Checking it

```smalltalk
| board element |
board := LaserGameBoardElement on: GridFactory demoGrid.
element := board cellElementAt: 5 @ 5.
element clickRegionAt: CellClickRegionInside regionRectangle center
```

answers `CellClickRegionInside`, and `0 @ 0` on the same element answers `CellClickRegionIgnore`. The window itself looks exactly as it did at the end of Section 2 — this chapter changed what the cells *are*, not what they show. The next chapter gives them mouse events.

# Handle Mouse Events

*Pages 078 and 079 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/078.html
     http://squeak.preeminent.org/tut2007/html/079.html -->

The cells can classify a point. Now they have to be given one, which means the mouse.

## What the original had to build

In 2007 the board was a single `SketchMorph` holding one bitmap, so no cell could receive anything. The `LaserGame` morph registered interest in the events of that one morph and named it, so that it could be found again among the submorphs:

```
makeGameBoardMorph
	| boardMorph |
	boardMorph := SketchMorph withForm: self boardForm.
	boardMorph name: 'board'.
	boardMorph
		on: #mouseUp send: #mouseUp:forMorph: to: self;
		on: #mouseDown send: #mouseDown:forMorph: to: self;
		on: #mouseEnter send: #mouseEnter:forMorph: to: self;
		on: #mouseLeave send: #mouseLeave:forMorph: to: self;
		on: #mouseMove send: #mouseMoveWhileButtonDown:forMorph: to: self.
	^boardMorph
```

Five events, five handlers, all of them on the game rather than on the thing they happened to. Morphic only delivers mouse moves while a button is down, so the sixth event the page wants — the pointer moving over the board with no button pressed — is not there at all. The original gets it by asking the hand morph to report to it while the pointer is over the board:

```
mouseEnter: evt forMorph: aSketchMorph
	evt hand addMouseListener: self.

mouseLeave: evt forMorph: aSketchMorph
	evt hand removeMouseListener: self.
```

and a listener hears about every move anywhere, so the game then has to work out whether this one concerns it:

```
handleListenEvent: evt
	| pos unders boardMorph |
	((evt isMouse and: [evt isMove]) and: [evt isMouseDown not]) ifFalse: [^self].
	pos := evt hand position.
	unders := self morphsAt: pos.
	unders isEmpty ifTrue: [^self].
	boardMorph := unders detect: [:m | m knownName = 'board'] ifNone: [].
	boardMorph isNil ifTrue: [^self].
	self mouseMoveWhileButtonUp: evt forMorph: boardMorph
```

That is the point of the morph's name: the hand reports a position, the game looks at what is under it and keeps the event only when the morph named `'board'` is there. Once the event is accepted, three more methods turn it into a cell:

```
cellForEvent: evt
	| posn |
	posn := self cellPositionForEvent: evt.
	^self grid at: posn

cellPositionForEvent: evt
	| posn ext counts |
	posn := self boardRelativePositionFor: evt.
	ext := CellRenderer cellExtent.
	counts := posn // ext.
	counts := counts + (1@1).
	^counts

boardRelativePositionFor: evt
	| evtPosn |
	evtPosn := evt hand position.
	^evtPosn - self position - ((self gameMargin + self panelWidth) @ self gameMargin)
```

The last line is the whole difficulty in one expression: a hand position is in world coordinates, so the position of the game, the margin around it and the width of the control panel all have to come off before the division by the cell size means anything. Every one of those terms is a chance to be wrong, and every change to the window layout is a chance to break it.

The page ends by printing the cell under the pointer to the Transcript, checking that the right names scroll past, and then deleting the Transcript line again.

## What Bloc delivers instead

A cell is an element, an element is a mouse target, and Bloc sends the event to the element the pointer is actually over. There is no registration on a foreign morph, no hand listener, no search through what is under the pointer, and no coordinate arithmetic at all. The cell element installs its own handlers:

```smalltalk
LaserGameCellElement >> initialize
	"Listen to the mouse myself. In the original the LaserGame morph registered interest in the
	events of one board morph and then worked out which cell each event belonged to; here every
	cell is an element of its own, so Bloc delivers the event to the cell it happened in."

	super initialize.
	self addEventHandlerOn: BlMouseEnterEvent do: [ :anEvent | self mouseEnter: anEvent ].
	self addEventHandlerOn: BlMouseLeaveEvent do: [ :anEvent | self mouseLeave: anEvent ].
	self addEventHandlerOn: BlMouseMoveEvent do: [ :anEvent | self mouseMove: anEvent ].
	self addEventHandlerOn: BlClickEvent do: [ :anEvent | self click: anEvent ]
```

Each handler is one line, because there is nothing left to work out:

```smalltalk
LaserGameCellElement >> mouseEnter: anEvent
	"The pointer came over me: my board now hovers me."

	self board ifNotNil: [ :board | board hoverCellElement: self ]
```

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer."

	self board ifNotNil: [ :board | board unhoverCellElement: self ]
```

```smalltalk
LaserGameCellElement >> mouseMove: anEvent
	"The pointer moved inside me, so I am the cell it is over. This is the event the original
	watched on page 078 to report the cell under the pointer; from Section 3.3 on it also
	carries the point that decides which hint the cell shows."

	self board ifNotNil: [ :board | board hoverCellElement: self ]
```

```smalltalk
LaserGameCellElement >> click: anEvent
	"A click landed on me: a press and a release in the same cell, which the original checked by
	keeping the location of the press in activeCellLocation and comparing it on mouse up."

	self board ifNotNil: [ :board | board clickCellElement: self ]
```

A cell element reaches its board through its parent, and answers nil while it has none, which is what the tests build on:

```smalltalk
LaserGameCellElement >> board
	"Answer the board element I am a cell of, or nil while I have no parent."

	^ self hasParent ifTrue: [ self parent ] ifFalse: [ nil ]
```

## Click, not mouse down and mouse up

The original tracks a press and a release itself. `mouseDown:forMorph:` stores the grid location of the cell pressed in `activeCellLocation`, and `mouseUp:forMorph:` acts only if the release falls in the same cell — otherwise the player pressed on one cell, dragged off it and let go somewhere else, which is not a click and must do nothing.

`BlClickEvent` is exactly that rule, already written: Bloc sends it when a press and a release land on the same element. So the port keeps the behaviour and drops the bookkeeping, and `activeCellLocation` has no counterpart on the Bloc side.

## The board holds what the mouse is doing

The handlers report to the board, which is where the game will read them:

```smalltalk
LaserGameBoardElement >> hoverCellElement: aCellElement
	"Remember that the pointer is over aCellElement. A cell tells me this when the pointer
	enters it and while it moves inside it."

	hoveredCellElement := aCellElement
```

```smalltalk
LaserGameBoardElement >> unhoverCellElement: aCellElement
	"Forget the pointer position, but only when aCellElement is the cell I hover. Moving from
	one cell to the next can deliver the enter of the new cell before the leave of the old one."

	hoveredCellElement == aCellElement ifTrue: [ hoveredCellElement := nil ]
```

```smalltalk
LaserGameBoardElement >> clickCellElement: aCellElement
	"Record the cell of aCellElement as the one just clicked. A cell tells me this when a click
	lands on it, that is when a press and a release fall in the same cell."

	clickedCell := aCellElement cell
```

The guard in `unhoverCellElement:` is the one piece of event handling that still needs care. Moving the pointer from one cell to the next produces both a leave and an enter, and nothing promises which arrives first; if a leave arriving after the enter of the new cell cleared the hover unconditionally, the board would forget where the pointer is at every cell boundary.

What the board answers is what the original wrote to the Transcript:

```smalltalk
LaserGameBoardElement >> hoveredCellElement
	"Answer the cell element the pointer is over, or nil when the pointer is off the board."

	^ hoveredCellElement
```

```smalltalk
LaserGameBoardElement >> hoveredCell
	"Answer the cell the pointer is over, or nil when the pointer is off the board. This is what
	the original wrote to the Transcript on page 078, and it took a hand position, a board offset
	and a division by the cell size to find it."

	^ hoveredCellElement ifNotNil: [ :element | element cell ]
```

```smalltalk
LaserGameBoardElement >> clickedCell
	"Answer the cell of the last click, or nil while no cell has been clicked. Nothing acts on
	the click yet: the click regions decide what a click does from Section 3.5 on."

	^ clickedCell
```

Nothing acts on `clickedCell` yet. In the original the click went straight to `CellRenderer >> mouseUpWithinBoardOffset:`, which answered the cell to redraw; that method was deleted in the previous chapter, and what replaces it is the click region work of the chapters that follow.

## What leaves the LaserGame morph

The whole `events-processing` protocol of the morph goes, twelve methods: `mouseDown:forMorph:`, `mouseUp:forMorph:`, `mouseUp:forMorph:cell:`, `mouseEnter:forMorph:`, `mouseLeave:forMorph:`, `mouseMoveWhileButtonDown:forMorph:`, `mouseMoveWhileButtonUp:forMorph:`, `handleListenEvent:`, `cellForEvent:`, `cellPositionForEvent:`, `boardRelativePositionFor:` and `eventDiagnosticFor:tag:`, the last of them the Transcript diagnostic the page writes and removes. Eight lines of Bloc replace them.

`makeGameBoardMorph` stays for now, still naming five selectors that no longer exist. It builds a `SketchMorph` from a `Form`, so it belongs to the morph's own end, not to this chapter.

## Tests

Six tests, and they drive real events: a `BlElement` can be handed an event with `dispatchEvent:` outside any space, so the handlers are exercised rather than the methods they call.

```smalltalk
LaserGameCellElementTestCase >> testEnteringACellElementMakesItTheHoveredCell
	"The pointer entering a cell element is enough for the board to know which cell it is over.
	The original had to ask the hand for its position and divide it by the cell size."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	self assert: board hoveredCellElement identicalTo: element.
	self assert: board hoveredCell identicalTo: (board grid at: 2 @ 3)
```

```smalltalk
LaserGameCellElementTestCase >> testLeavingTheHoveredCellElementClearsTheHover
	"The pointer leaving the cell it hovers leaves the board hovering nothing."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: board hoveredCellElement isNil.
	self assert: board hoveredCell isNil
```

The awkward case has its own test, since it is the only thing here that could be written the obvious way and be wrong:

```smalltalk
LaserGameCellElementTestCase >> testLeavingACellElementThatIsNotHoveredKeepsTheHover
	"Moving from one cell to the next can deliver the enter of the new cell before the leave of
	the old one, so a leave only clears the hover when it comes from the cell that holds it."

	| board left entered |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	left := board cellElementAt: 1 @ 1.
	entered := board cellElementAt: 2 @ 1.
	left dispatchEvent: BlMouseEnterEvent new.
	entered dispatchEvent: BlMouseEnterEvent new.
	left dispatchEvent: BlMouseLeaveEvent new.
	self assert: board hoveredCellElement identicalTo: entered
```

```smalltalk
LaserGameCellElementTestCase >> testMovingOverACellElementMakesItTheHoveredCell
	"A mouse move over a cell is the event the original watched: it answers which cell the
	pointer is over. Bloc sends it to the cell itself, so the board learns it from the cell."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 2.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 10 @ 10;
			 yourself).
	self assert: board hoveredCellElement identicalTo: element
```

```smalltalk
LaserGameCellElementTestCase >> testClickingACellElementRecordsItsCell
	"A click reaches the cell element under the pointer, and the board records the cell that was
	clicked. The original checked that mouse down and mouse up fell in the same cell itself;
	BlClickEvent is that check."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 3 @ 5.
	element dispatchEvent: (BlClickEvent new
			 position: 25 @ 25;
			 yourself).
	self assert: board clickedCell identicalTo: (board grid at: 3 @ 5)
```

```smalltalk
LaserGameBoardElementTestCase >> testANewBoardHoversNothingAndHasNoClick
	"A board that no pointer has visited yet hovers no cell and holds no click."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	self assert: board hoveredCellElement isNil.
	self assert: board hoveredCell isNil.
	self assert: board clickedCell isNil
```

## Checking it

Open the game, hover over the board and ask it what it sees:

```smalltalk
| element |
element := LaserGameElement openExample.
element board hoveredCell
```

The answer follows the pointer — `a MirrorCell`, `a BlankCell`, `a TargetCell` — exactly the names page 078 watches scroll past in its Transcript, and it is nil as soon as the pointer leaves the board. Click a cell and `element board clickedCell` is that cell. Nothing on the screen moves yet: this chapter delivers the events, and the next one lets a cell answer back.

## Page 079, the World background

Page 079 is a diversion the tutorial itself calls optional: the author sets a gradient background on the Squeak World so that the edges of the game morph stand out against it, and shows the desktop with the Test Runner minimised in a corner. Nothing of the game changes. Pharo 13 has its own desktop and themes, the game opens in a window of its own rather than as a morph dropped on the World, and its background is `LaserGameColors gameWindowColor`, so there is nothing to port here.
