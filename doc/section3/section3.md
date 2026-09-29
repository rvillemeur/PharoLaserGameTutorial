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

```
CellRenderer class >> cellExtent
	^50@50
```

This is the method as this chapter writes it; Section 4.3 gives it the comment that says every other size in the package is derived from it.

```
CellRenderer class >> insideRegionExtent
	^self cellExtent - 20
```

This is the method as this chapter writes it; Section 4.3 gives it a comment, where page 138 of the original arrives at the same body.

```
CellRenderer class >> ignoreRegionOffset
	^4
```

This is the method as this chapter writes it; Section 4.3 gives it a comment.

```
CellRenderer class >> outsideRegionExtent
	^self cellExtent - (2 * self ignoreRegionOffset)
```

This is the method as this chapter writes it; Section 4.3 gives it a comment.

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

```
CellClickRegion class >> clickRegionForPoint: aPoint
	^self sortedSubclasses detect: [:cls | cls regionRectangle containsPoint: aPoint]
```

This is the method as this chapter writes it; Section 4.3 gives it a comment and an `ifNone:`, since a point outside the cell falls in no region at all.

So `sortIndex` 1 for the inside region, 2 for the outside region, 3 for the ignore region, whose rectangle is the whole cell and therefore always matches. A point that no smaller region claimed lands there, which is precisely what "ignore" means.

## Page 077's measurement is already settled

The original then writes the tests, finds that the point 13 by 13 is claimed by the inside region when the test expected the outside one, and suspects the test. It writes a little workspace loop that prints the region of every point along a diagonal to the Transcript, works out that with a 30 by 30 cell and a 14 by 14 inside region the transition must be at 8 pixels, and concludes that the inside region was simply defined too big. It shrinks it and the tests pass.

The inherited code carries the end of that argument — the derived `insideRegionExtent` — and the inherited tests carry its lesson: not one of them names a pixel. They ask the rectangles where they are:

```
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
> **Note.** *A Less Brittle Unit Test Design*, the seventh chapter of Section 5, moves this body into `#assertIgnoreRegionBoundaries` so that a second test can run it at three cell sizes; the test itself becomes one call of that method.

The same shape covers the outside region, the ring between the ignore margin and the inside square:

```
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
> **Note.** *A Less Brittle Unit Test Design*, the seventh chapter of Section 5, moves this body into `#assertOutsideRegionBoundaries` and leaves the test as one call of it.

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

```
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
> **Note.** *Laser On Blank Cell*, in Section 4, adds one line to this method, so that a lit cell draws the beam, and *Laser On Target Cell* puts that line before the contents.


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

```
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer."

	self board ifNotNil: [ :board | board unhoverCellElement: self ]
```

```
LaserGameCellElement >> mouseMove: anEvent
	"The pointer moved inside me, so I am the cell it is over. This is the event the original
	watched on page 078 to report the cell under the pointer."

	self board ifNotNil: [ :board | board hoverCellElement: self ]
```

Those last two are the methods as this chapter writes them. The next chapter gives each of them a second line, for the hint the pointer position decides. The same holds for the click, shown here as this chapter writes it; Section 3.10 adds the line that lets the click act on the cell.

```
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

The handlers report to the board, which is where the game will read them. The first of them is shown as this chapter writes it; Section 3.11 adds one line to it, for the hint of the cell the pointer left:

```
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

# Detecting Mirror Cell Click Regions

*Page 080 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/080.html -->

The events arrive and the regions can classify a point. This page joins the two: while the pointer moves over the board, the cell under it works out which of its regions the pointer is in. That answer becomes a visual hint a few chapters later; here it is only computed and looked at.

## One message, sent to every renderer

The original adds a line to its mouse-move handler:

```
mouseMoveWhileButtonUp: evt forMorph: aSketchMorph
	| cell renderer pixelPositionWithinBoard |
	cell := self cellForEvent: evt.
	renderer := CellRenderer rendererFor: cell grid: self grid form: self boardForm.
	pixelPositionWithinBoard := self boardRelativePositionFor: evt.
	renderer showPositionHintFromWithinBoardOffset: pixelPositionWithinBoard.
```

and the page makes a point of *how* that message is handled: it goes to whatever renderer the cell has, and each renderer decides for itself what to do with it. The superclass gets an empty method, so that every cell answers the message and almost every cell does nothing:

```
showPositionHintFromWithinBoardOffset: aPoint
```

Only the mirror has anything to say, because a click only ever acts on a mirror. Its version starts by undoing the board arithmetic — the point arrived relative to the board, and the regions are defined relative to a cell — and then logs what it found:

```
showPositionHintFromWithinBoardOffset: aPoint
	| cellPosn offsetWithinCell regionClass |
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell.
	Transcript show: offsetWithinCell printString, '  ', regionClass name; cr.
```

Hovering across a cell then prints a column of positions and region names, and the regions can be watched changing as the pointer crosses their boundaries.

> **Note.** The version of `showPositionHintFromWithinBoardOffset:` in the captured source is not this one: it is the finished method from much later in the tutorial, which draws a hint arrow into the board form and swaps the cursor. It stays in the package as the text Section 3.6 ports; only its first three lines belong to this page.

## What the port keeps and what it drops

The three lines of coordinate arithmetic go: a mouse move reaches the cell element, and `localPosition` is already the point within the cell. The polymorphism stays, since it is the design the page is teaching. It moves to a question rather than a command: the renderer is asked what hint applies, and does not itself go drawing.

```smalltalk
CellRenderer >> hintRegionAt: aPoint
	"Answer the click region whose hint applies at aPoint, in the coordinates of my cell, or nil
	when my cell offers no hint at all. Every renderer is asked, and all but the mirror answer
	nothing: a click acts on mirrors only."

	^ nil
```

```
MirrorCellRenderer >> hintRegionAt: aPoint
	"Answer the click region aPoint falls in: a mirror reacts to a click, and which of its two
	actions is meant depends on where in the cell the pointer is. The original had to subtract
	the offset of my cell within the board form before it could ask this."

	^ CellClickRegion clickRegionForPoint: aPoint
```

Section 3.5 rewrites this method: a region is asked what hint applies at the point, and the inside region answers one of its four push regions rather than itself. The version above is the one this page leaves in the image.

The element keeps the answer:

```
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates. My renderer
	decides: a mirror answers the region the point falls in, every other cell answers nothing."

	hintRegion := self renderer hintRegionAt: aPoint
```

Section 3.6 adds two lines to this method: it compares the new region with the one held and, when it differs, draws the arrow of the hint.

```
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me."

	hintRegion := nil
```

Section 3.6 has this method take the arrow away with the hint.

```smalltalk
LaserGameCellElement >> hintRegion
	"Answer the click region the pointer is in, or nil when the pointer is not in me or my cell
	offers no hint. Section 3.6 draws an arrow from this; for now it is what the original wrote
	to the Transcript on page 080."

	^ hintRegion
```

and the two handlers of the previous chapter each gain a line:

```smalltalk
LaserGameCellElement >> mouseMove: anEvent
	"The pointer moved inside me, so I am the cell it is over, and the point it carries decides
	which hint I show. The original reached the same two facts from a hand position, a board
	offset and a division by the cell size."

	self board ifNotNil: [ :board | board hoverCellElement: self ].
	self showPositionHintAt: anEvent localPosition
```

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
```

That is the whole step. The Transcript logging has no counterpart: `hintRegion` holds what the original printed, and an inspector on the element shows it changing as the pointer moves — which is what the page uses its Transcript for.

The empty `CellRenderer >> showPositionHintFromWithinBoardOffset:` is deleted, since `hintRegionAt:` is now the method every renderer answers and only the mirror overrides.

## Tests

The mirror answers a region for a point of its cell:

```
MirrorCellRendererTestCase >> testAMirrorAnswersTheClickRegionOfAPoint
	"A mirror is the only cell a click acts on, so it is the only renderer that answers a hint
	region. The point is in cell coordinates, so the regions classify it directly."

	| renderer |
	renderer := self rendererLeaning: #left.
	self
		assert: (renderer hintRegionAt: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionInside.
	self
		assert: (renderer hintRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self assert: (renderer hintRegionAt: 0 @ 0) equals: CellClickRegionIgnore
```

This test is replaced in Section 3.5 by one that expects a push region, since that is what a mirror answers once the inside region refines its hint.

and the polymorphism itself is worth a test, because "every renderer answers, and all but one answer nothing" is the claim the design rests on:

```
CellRendererTestCase >> testOnlyAMirrorAnswersAHintRegion
	"Every renderer is asked for a hint region, and all but the mirror answer nothing. That is
	the polymorphism the original page points at: the message goes to every cell renderer, and
	each one decides what to do with it."

	| grid point |
	grid := GridFactory demoGrid.
	point := CellClickRegionInside regionRectangle center.
	self
		assert: ((CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid)
				 hintRegionAt: point)
		equals: CellClickRegionInside
```

The expectation of the last assertion becomes `CellClickRegionPushNorth` in Section 3.5; the claim the test makes does not change.

Then the same thing through a real event, which is what ties the two halves together:

```
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellRecordsItsHintRegion
	"A mouse move carries a point, and the cell keeps the region that point falls in. The
	original computed the same thing by subtracting the offset of the cell within the board form
	from a board-wide position, and wrote the answer to the Transcript."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionInside.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionIgnore
```

Here too Section 3.5 moves the expectation from `CellClickRegionInside` to `CellClickRegionPushNorth`.

```
LaserGameCellElementTestCase >> testMovingOverACellThatIsNotAMirrorRecordsNoHint
	"Blank and target cells answer no hint region, so moving over them records nothing."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	#( 1 5 ) do: [ :column |
		| element |
		element := board cellElementAt: column @ 1.
		element dispatchEvent: (BlMouseMoveEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		self assert: element hintRegion isNil ]
```

Section 3.6 adds two assertions here, for the arrow those cells do not draw.

```smalltalk
LaserGameCellElementTestCase >> testLeavingACellClearsItsHintRegion
	"The pointer leaving a cell takes its hint with it, so no cell keeps a hint the pointer is
	no longer in. The original cleared the temporary cursor at the same moment."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: element hintRegion isNil
```

## Checking it

Open the game and inspect a mirror cell while the pointer is over it:

```smalltalk
| element |
element := LaserGameElement openExample.
element board hoveredCellElement hintRegion
```

Evaluated while hovering near the middle of a mirror it answers `CellClickRegionInside`, near its edge `CellClickRegionOutside`, and in the four-pixel margin `CellClickRegionIgnore`; over a blank or target cell it answers nil, and the board answers nil for `hoveredCellElement` as soon as the pointer leaves. That is page 080's Transcript column, one line at a time.

Nothing is drawn yet. The arrow that will make the hint visible needs shapes to draw it with, which is the next chapter.

# Creating Custom Shapes

*Pages 081 to 085 of the 2007 tutorial, where the chapter is called "Creating Custom Forms".*

<!-- http://squeak.preeminent.org/tut2007/html/081.html -->
<!-- http://squeak.preeminent.org/tut2007/html/082.html -->
<!-- http://squeak.preeminent.org/tut2007/html/083.html -->
<!-- http://squeak.preeminent.org/tut2007/html/084.html -->
<!-- http://squeak.preeminent.org/tut2007/html/085.html -->

The previous chapter left a cell able to say which of its regions the pointer is in. To turn that answer into something the player can see, the game needs pictures to show: an arrow per push direction, and a cross hair to mark the point the pointer is at. The original draws them as bitmaps and stores them in a cache. This port keeps the drawings and drops the bitmaps, which is why the chapter is called Creating Custom Shapes here.

## Drawing an arrow in a workspace

Page 081 does its drawing in a workspace, not in a class. An arrow is described as a ring of points, and a pen walks from each point to the next, drawing the outline into a white form:

```
pts := {0@80. 150@80. 150@0. 260@100. 150@200. 150@120. 0@120}.
offset := 20@20.
form := Form extent: 330@240 depth: 1.
form fillColor: Color white.
penForm := Form extent: 1@1 depth: 1.
penForm fillColor: Color black.
index := 1.
[index <= pts size] whileTrue: [
	startPoint := pts at: index.
	nextIndex := index = pts size
		ifTrue: [1]
		ifFalse: [index + 1].
	endPoint := pts at: nextIndex.
	startPoint := startPoint + offset.
	endPoint := endPoint + offset.
	line := Line from: startPoint to: endPoint withForm: penForm.
	line displayOn: form.
	index := index + 1].
form displayAt: 300@300.
```

That draws the outline only. The next three steps fill it and make it usable as a stamp. A flood fill from the top left corner paints everything *outside* the outline black, which leaves a white arrow on a black field; `reverse` then exchanges black and white; and the form is finally painted onto the display with `Form oldPaint`, a rule that paints only the black pixels, in whatever colour the fill colour says:

```
form floodFill: Color black at: 1@1.
form reverse.
form displayAt: 100@80.
form
	displayOn: Display
	at: 100@340
	clippingBox: (100@340 extent: form extent)
	rule: Form oldPaint
	fillColor: Color gray
```

The result is a grey arrow with no rectangle around it. Getting there costs a flood fill, a reversal and a paint rule, and it is all in aid of one thing: a filled shape with a transparent background, drawn in a colour chosen at the moment of drawing.

## Four arrays of seven points

Page 082 repeats the exercise for the other three directions. The west arrow is the east one written backwards, and for north and south the target form becomes square, since those arrows are taller than they are wide:

```
eastPts := {0@80. 150@80. 150@0. 260@100. 150@200. 150@120. 0@120}.
westPts := {260@80. 110@80. 110@0. 0@100. 110@200. 110@120. 260@120}.
northPts := {100@0. 200@110. 120@110. 120@260. 80@260. 80@110. 0@110}.
southPts := {100@260. 0@150. 80@150. 80@0. 120@0. 120@150. 200@150}.
```

Those four arrays are the lasting result of the chapter. Everything else on these two pages is machinery for turning them into pixels.

## The original's repository of forms

Page 083 gives the drawings a home: `LaserGameForms`, a subclass of `Object` with no instance variables and one class variable, `CachedForms`. The workspace code becomes a class method, the four arrays become four class methods, and a fifth method fills the cache:

```
LaserGameForms class >> arrowFormFromPointsArray: pts
	"LaserGameForms initializeCachedForms"
	| form fillForm index startPoint nextIndex endPoint line offset |
	offset := 2@2.
	form := Form extent: 330@330 depth: 1.
	form fillColor: Color white.
	fillForm := Form extent: 1@1 depth: 1.
	fillForm fillColor: Color black.
	index := 1.
	[index <= pts size] whileTrue: [
		startPoint := pts at: index.
		nextIndex := index = pts size
			ifTrue: [1]
			ifFalse: [index + 1].
		endPoint := pts at: nextIndex.
		startPoint := startPoint + offset.
		endPoint := endPoint + offset.
		line := Line from: startPoint to: endPoint withForm: fillForm.
		line displayOn: form.
		index := index + 1].
	form floodFill: Color black at: 1@1.
	form reverse.
	^form copy: (form tightRectangleAroundColor: Color black)
```
```
LaserGameForms class >> northArrowPoints
	^{100@0. 200@110. 120@110. 120@260. 80@260. 80@110. 0@110}
```
```
LaserGameForms class >> initializeCachedForms
	"LaserGameForms initializeCachedForms"
	| form |
	CachedForms := Dictionary new.
	form := self arrowFormFromPointsArray: self northArrowPoints.
	CachedForms at: #north put: form.
	form := self arrowFormFromPointsArray: self eastArrowPoints.
	CachedForms at: #east put: form.
	form := self arrowFormFromPointsArray: self southArrowPoints.
	CachedForms at: #south put: form.
	form := self arrowFormFromPointsArray: self westArrowPoints.
	CachedForms at: #west put: form.
	form := self drawCounterClockwiseArrow.
	CachedForms at: #counterClockwise put: form.
	form := self drawClockwiseArrow.
	CachedForms at: #clockwise put: form.
	form := self drawCrossHair.
	CachedForms at: #crossHair put: form.
	form := self drawLaserBeamForm.
	CachedForms at: #laserBeam put: form.
	form := self drawCenterLaserBeamMask.
	CachedForms at: #centerBeamMask put: form.
	form := self drawSplatterLaserBeamMask.
	CachedForms at: #splatterBeamMask put: form.
```

Each accessor then builds the whole cache the first time anything is asked for:

```
LaserGameForms class >> northArrow
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #north
```

The cross hair is drawn the same way, as two crossing lines in a form the size of one cell:

```
LaserGameForms class >> drawCrossHair
	"LaserGameForms initializeCachedForms"
	| form pen startPoint endPoint line lineLength inset |
	lineLength := 10.
	form := Form extent: CellRenderer cellExtent depth: 32.
	form fillColor: Color transparent.
	pen := Form extent: 1@1 depth: 1.
	pen fillColor: Color black.
	inset := ((form width - lineLength) // 2)@((form height - lineLength) // 2).
	startPoint := (inset x)@(form height // 2).
	endPoint := (form width - (inset x))@(form height // 2).
	line := Line from: startPoint to: endPoint withForm: pen.
	line displayOn: form.
	startPoint := (form width // 2)@(inset y).
	endPoint := (form width // 2)@(form height - (inset y)).
	line := Line from: startPoint to: endPoint withForm: pen.
	line displayOn: form.
	^form
```

> **Note.** `LaserGameForms` is in the captured package, with the bitmaps of the laser beam stored inside it, and it is still what the rotate regions and the beam rendering of Section 4 ask for their pictures. It stays there until the last of those senders is ported, and then it goes, with `Line`, `Arc`, `Circle` and the `Form` extension.

## What the port does instead

A form is a rectangle of pixels of a fixed size, so the original has to draw large, cache, and shrink at the point of use — `scaledToSize:` on a bitmap, which is why the small hint arrows of the original look ragged. Bloc has no such constraint: a `BlPolygonGeometry` is a list of vertices, and the renderer fills it at whatever size the element has. So the flood fill, the reversal, the paint rule and the cache all go, and what stays is the numbers.

`LaserGameShapes` is the port's counterpart. Like the original it is a class-side repository, and it keeps the four arrays exactly as page 082 typed them:

```smalltalk
LaserGameShapes class >> northArrowPoints
	"Answer the outline of an arrow that points north, as the original typed it into a workspace
	on page 082. The numbers are the ones LaserGameForms holds."

	^ { 100 @ 0. 200 @ 110. 120 @ 110. 120 @ 260. 80 @ 260. 80 @ 110. 0 @ 110 }
```

```smalltalk
LaserGameShapes class >> eastArrowPoints
	"Answer the outline of an arrow that points east, as the original typed it into a workspace
	on page 081."

	^ { 0 @ 80. 150 @ 80. 150 @ 0. 260 @ 100. 150 @ 200. 150 @ 120. 0 @ 120 }
```

```smalltalk
LaserGameShapes class >> southArrowPoints
	"Answer the outline of an arrow that points south, as the original typed it into a workspace
	on page 082."

	^ { 100 @ 260. 0 @ 150. 80 @ 150. 80 @ 0. 120 @ 0. 120 @ 150. 200 @ 150 }
```

```smalltalk
LaserGameShapes class >> westArrowPoints
	"Answer the outline of an arrow that points west, as the original typed it into a workspace
	on page 082."

	^ { 260 @ 80. 110 @ 80. 110 @ 0. 0 @ 100. 110 @ 200. 110 @ 120. 260 @ 120 }
```

One method does the work the original could not do at all. The arrays are written at the size they were drawn at, a little over 260 pixels, and every caller wants its own size, so the points are moved to the origin and stretched onto the rectangle that was asked for:

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

The shape itself is then an element with a polygon geometry:

```smalltalk
LaserGameShapes class >> arrowElementFromPoints: anArrayOfPoints ofExtent: anExtent
	"Answer an element of anExtent whose geometry is the outline anArrayOfPoints describes. The
	outline is a polygon, so it is drawn at whatever size it is given and needs no flood fill:
	the original drew the outline line by line, filled the inside with black and reversed the
	form, which is what pages 081 and 082 spend their workspace code on."

	^ BlElement new
		  geometry: (BlPolygonGeometry vertices:
					   (self pointsOf: anArrayOfPoints scaledToExtent: anExtent));
		  extent: anExtent;
		  background: self arrowColor;
		  yourself
```

and one accessor per direction, each naming its own array:

```smalltalk
LaserGameShapes class >> northArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points north."

	^ self arrowElementFromPoints: self northArrowPoints ofExtent: anExtent
```

```smalltalk
LaserGameShapes class >> eastArrowElementOfExtent: anExtent
	"Answer an arrow of anExtent that points east."

	^ self arrowElementFromPoints: self eastArrowPoints ofExtent: anExtent
```

`southArrowElementOfExtent:` and `westArrowElementOfExtent:` are the same line with their own arrays.

The colour is a default rather than a decision. Page 081 paints its arrow grey at the moment of drawing, and that is what an arrow gets here when nobody says otherwise; a caller that knows whether the move it is hinting at is allowed sets the background of the element it is given:

```smalltalk
LaserGameShapes class >> arrowColor
	"Answer the colour an arrow is painted in when nobody says otherwise: the grey of page 081.
	A caller that knows more sets its own, as the hints do from Section 4 on."

	^ Color gray
```

## Why the shapes carry their own arithmetic

A reader who knows Bloc will object twice here, and both objections are worth answering, because the answer is the same both times and it is the reason `LaserGameShapes` looks the way it does.

The first objection: a `BlElement` can be scaled. `anElement transformation` takes a matrix, `scaleBy:` is one line, so why does `pointsOf:scaledToExtent:` exist at all? The second: the four arrays are one array. Rotating the north arrow a quarter turn gives the east one exactly -- map each point `x @ y` to `260 - y @ x` and `northArrowPoints` becomes `eastArrowPoints`, the same seven points in the same cycle -- and Bloc rotates elements as happily as it scales them. Three of the four arrays, and three of the four accessors, look like copies of the first.

The answer to the first is that a polygon in Bloc does not follow the extent of the element that holds it. Some geometries are written in normalized coordinates and stretch to whatever element they are given; `BlPolygonGeometry` is not one of them. Its vertices are element-local coordinates and they are absolute. The class does not implement `adjustExtent:`, and an element proves it in one evaluation:

```
| element |
element := BlElement new
	geometry: (BlPolygonGeometry vertices: { 0@0. 100@0. 100@100 });
	extent: 10@10;
	yourself.
element geometryBounds   "(0.0@0.0) corner: (100.0@100.0)"
```

The element was asked for ten pixels and draws a hundred. Somebody has to bring the numbers of page 082, written at a little over 260 pixels, down to the size the caller wants, and Bloc will not do it for a polygon. `pointsOf:scaledToExtent:` is not a second implementation of something Bloc already has; it is the step Bloc leaves to the shape.

The answer to the second is what a transformation is: a matrix applied when the element is painted, and when a point is hit-tested against it. It does not change the element's `extent`. That is exactly what makes it the right tool for the whole game -- `LaserGameElement >> fitIn:`, the resizing addition of Section 4, scales the finished tree with one matrix and the click code needs no adjustment, because Bloc hit-tests through the same transformation it draws through -- and exactly what makes it the wrong tool for one arrow. An arrow is a child of a cell, laid out by the cell. A layout measures `extent`, not the matrix: an arrow authored at `200@260` and scaled by a matrix into a thirty pixel cell still tells the layout it is 200 by 260, and `hintArrowExtent` and `hintArrowOffset`, which decide where in the cell the arrow sits, would each have to divide it back out. Rotation is worse than scaling here, because a quarter turn swaps the two numbers: the east arrow is 260 wide and 200 tall where the north one is 200 wide and 260 tall, and a rotated element keeps the extent it started with.

So the rule the port follows is: **a transformation scales a finished tree, and arithmetic on vertices builds a shape at the size it was asked for.** Inside `LaserGameShapes` an element's extent is always the ink it actually covers, which is what lets a cell place an arrow by asking for a rectangle, and what lets a test assert the claim directly. Section 5.8 makes that assertion: `testEveryArrowFillsTheRectangleItIsGiven` takes all six arrows at three sizes and compares the bounds of the vertices with the extent asked for.

Keeping the four arrays rather than rotating one is a smaller decision, and it is about this book rather than about Bloc. The arrays are page 082's own numbers, printed above as the original typed them, and a reader comparing the two listings should find the same seven points. A `northArrowPoints rotatedBy:` would save twenty-one typed points and cost that comparison. Where the port does derive one shape from another it is because the original does too: page 099 makes its clockwise arrow by flipping the anticlockwise one, so `clockwiseArrowPoints` flips `counterClockwiseArrowPoints` in the same way, in the chapter *Using "Halt Once"*.

## The cross hair

The cross hair is two bars crossing at the centre, not a polygon, so it is an element with two children. The original fixed the arms at ten pixels in a cell of thirty; here the arms are a third of the shape and the bars a fifth of that, so the figure holds its proportions at any size:

```smalltalk
LaserGameShapes class >> crossHairElementOfExtent: anExtent
	"Answer a cross hair of anExtent: two bars crossing at the centre. Page 083 drew the same
	figure as two lines in a form of one cell, and Section 4.2 puts it under the pointer while
	the pointer is over a hint of a mirror."

	| span thickness |
	span := (anExtent x min: anExtent y) // 3.
	thickness := (span // 5) max: 1.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self crossHairBarOfExtent: span @ thickness within: anExtent);
		  addChild: (self crossHairBarOfExtent: thickness @ span within: anExtent);
		  yourself
```

```smalltalk
LaserGameShapes class >> crossHairBarOfExtent: aBarExtent within: anExtent
	"Answer one bar of a cross hair, centred in a shape of anExtent."

	^ BlElement new
		  extent: aBarExtent;
		  position: (anExtent - aBarExtent) / 2;
		  background: self crossHairColor;
		  yourself
```

```smalltalk
LaserGameShapes class >> crossHairColor
	"Answer the colour of a cross hair: the black page 083 drew it in."

	^ Color black
```

## Tests

The tests are about the numbers and about size, since those are the two things that decide whether a shape is right. First, the arrays are the ones the original typed, and each arrow points where its name says: exactly one vertex reaches the far edge, and it is centred on the other axis.

```smalltalk
LaserGameShapesTestCase >> testEachArrowIsSevenVerticesWideEnoughToBeAnArrow
	"The four vertex arrays are the ones the original typed into a workspace on pages 081 and
	082: seven points each, an outline drawn as a closed polygon."

	{ LaserGameShapes northArrowPoints.
	LaserGameShapes eastArrowPoints.
	LaserGameShapes southArrowPoints.
	LaserGameShapes westArrowPoints } do: [ :points |
		self assert: points size equals: 7.
		points do: [ :each | self assert: each isPoint ] ]
```

```smalltalk
LaserGameShapesTestCase >> testEachArrowHasOneTipAndItIsCentredOnTheOtherAxis
	"An arrow points where its name says: exactly one vertex reaches the far edge, and it sits in
	the middle of the other axis."

	| bounds |
	{ LaserGameShapes northArrowPoints -> [ :point :box | point y = box top and: [ point x = box center x ] ].
	LaserGameShapes southArrowPoints -> [ :point :box | point y = box bottom and: [ point x = box center x ] ].
	LaserGameShapes eastArrowPoints -> [ :point :box | point x = box right and: [ point y = box center y ] ].
	LaserGameShapes westArrowPoints -> [ :point :box | point x = box left and: [ point y = box center y ] ] }
		do: [ :each |
			bounds := Rectangle encompassing: each key.
			self
				assert: (each key select: [ :point | each value value: point value: bounds ]) size
				equals: 1 ]
```

Then the scaling, which is the method with arithmetic in it, and the elements built from it:

```smalltalk
LaserGameShapesTestCase >> testPointsScaleToFillTheRequestedExtent
	"Scaling maps the vertex array onto the rectangle the caller asks for, so the same array
	serves a 12 pixel hint and a 200 pixel drawing. The original had one fixed 330 pixel form and
	shrank the bitmap afterwards with scaledToSize:."

	{ 12 @ 12. 48 @ 48. 200 @ 120 } do: [ :extent |
		| scaled |
		scaled := LaserGameShapes
			          pointsOf: LaserGameShapes northArrowPoints
			          scaledToExtent: extent.
		self assert: scaled size equals: 7.
		self
			assert: (Rectangle encompassing: scaled)
			equals: (0 @ 0 corner: extent) ]
```

```smalltalk
LaserGameShapesTestCase >> testAnArrowElementIsAPolygonOfTheSizeAsked
	"An arrow is an element with a polygon geometry, not a bitmap: its vertices are the scaled
	points, and it asks for the extent the caller named. The size is read from the resizer, since
	an element measures itself only in a layout pass."

	| extent element |
	extent := 40 @ 40.
	element := LaserGameShapes eastArrowElementOfExtent: extent.
	self assert: element geometry class equals: BlPolygonGeometry.
	self assert: (self requestedExtentOf: element) equals: extent.
	self
		assert: element geometry vertices asArray
		equals:
			(LaserGameShapes
				 pointsOf: LaserGameShapes eastArrowPoints
				 scaledToExtent: extent) asArray
```

```smalltalk
LaserGameShapesTestCase >> testEveryArrowElementUsesTheVerticesOfItsDirection
	"Each of the four accessors builds from its own vertex array."

	| extent |
	extent := 30 @ 30.
	{ (LaserGameShapes northArrowElementOfExtent: extent) -> LaserGameShapes northArrowPoints.
	(LaserGameShapes eastArrowElementOfExtent: extent) -> LaserGameShapes eastArrowPoints.
	(LaserGameShapes southArrowElementOfExtent: extent) -> LaserGameShapes southArrowPoints.
	(LaserGameShapes westArrowElementOfExtent: extent) -> LaserGameShapes westArrowPoints }
		do: [ :each |
			self
				assert: each key geometry vertices asArray
				equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) asArray ]
```

```smalltalk
LaserGameShapesTestCase >> testACrossHairIsTwoBarsCrossingAtTheCentre
	"The cross hair of page 083 is two crossing lines. Here it is an element holding two bars,
	one wide and one tall, both centred in it."

	| extent element horizontal vertical |
	extent := 60 @ 60.
	element := LaserGameShapes crossHairElementOfExtent: extent.
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	horizontal := element children detect: [ :each |
		              (self requestedExtentOf: each) x
		              > (self requestedExtentOf: each) y ].
	vertical := element children detect: [ :each |
		            (self requestedExtentOf: each) y
		            > (self requestedExtentOf: each) x ].
	element children do: [ :each |
		self
			assert:
				each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ].
	self
		assert: (self requestedExtentOf: horizontal) x
		equals: (self requestedExtentOf: vertical) y
```

```smalltalk
LaserGameShapesTestCase >> testShapesAreBuiltAtWhateverSizeIsAsked
	"Vertices scale, so no shape has a size of its own. The original drew every arrow into a 330
	pixel form once, cached the bitmap and scaled it down on use, which is why its small arrows
	were ragged."

	{ 12 @ 12. 50 @ 50. 200 @ 200 } do: [ :extent |
		{ LaserGameShapes northArrowElementOfExtent: extent.
		LaserGameShapes crossHairElementOfExtent: extent } do: [ :element |
			self assert: (self requestedExtentOf: element) equals: extent ] ]
```

An element measures itself only when it is laid out, so a freshly built element answers zero for its extent. The size it was asked for is in its resizers, and one helper reads it:

```smalltalk
LaserGameShapesTestCase >> requestedExtentOf: anElement
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
```

## Checking it

Page 081 puts its arrow on the Squeak display. The same check here is a space with every shape in it, at three sizes:

```smalltalk
| row space |
row := BlElement new
	layout: (BlLinearLayout horizontal cellSpacing: 10);
	constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
	padding: (BlInsets all: 10);
	background: Color white;
	yourself.
#( #northArrowElementOfExtent: #eastArrowElementOfExtent: #southArrowElementOfExtent: #westArrowElementOfExtent: ) do: [ :selector |
	#( 24 60 120 ) do: [ :size |
		row addChild: (LaserGameShapes perform: selector with: size @ size) ] ].
#( 24 60 120 ) do: [ :size |
	row addChild: (LaserGameShapes crossHairElementOfExtent: size @ size) ].
space := BlSpace new.
space root addChild: row.
space extent: 1500 @ 200.
space title: 'LaserGameShapes'.
space show
```

The twelve arrows are the same drawing at three sizes, each one as clean as the largest, which is the point of the change: the original could only have shown this by drawing each size from scratch.

## Pages 084 and 085: dividing the inside region

The last two pages of the chapter ask a question rather than write much code: which arrow should a hint show? A cell has an outside region and an inside region, and the page makes the game design decision that settles it — a click in the outer ring rotates a mirror, a click near the middle pushes it. A push needs a direction, so the inside region has to be divided further, and the page divides it along the two diagonals into four triangles, one per push direction.

The technique is the one page 075 already used for the regions themselves: a subclass per case, and a selector that asks them.

```smalltalk
CellClickRegionInside class >> pushRegionForPoint: aPoint
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
```

The page then has each of the four subclasses answer `true` to `containsPoint:`, as a placeholder, and leaves the geometry for the next chapter. In this port the four classes — `CellClickRegionPushNorth`, `CellClickRegionPushEast`, `CellClickRegionPushSouth` and `CellClickRegionPushWest` — are already in the package, carried over with the captured source, and their `containsPoint:` is the finished one. The next chapter is where that geometry is explained and tested, and where a push region is asked for its arrow, which is now one of the shapes this chapter builds.

# Determine Push Regions

*Pages 086 to 092 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/086.html -->
<!-- http://squeak.preeminent.org/tut2007/html/087.html -->
<!-- http://squeak.preeminent.org/tut2007/html/088.html -->
<!-- http://squeak.preeminent.org/tut2007/html/089.html -->
<!-- http://squeak.preeminent.org/tut2007/html/090.html -->
<!-- http://squeak.preeminent.org/tut2007/html/091.html -->
<!-- http://squeak.preeminent.org/tut2007/html/092.html -->

The last chapter divided the inside region of a cell into four triangles, one per push direction, and left every one of them answering `true` to `containsPoint:`. This chapter works out the geometry that tells them apart, checks it with unit tests, and then uses it: a cell asked what hint applies at a point answers the push region the point falls in.

## The region, and the points that test it

Page 086 starts in a workspace, inspecting the rectangle the inside region occupies:

```smalltalk
CellClickRegionInside class >> regionRectangle
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
```

The cells of the original are 30 by 30, its inside region is 20 by 20, and the rectangle runs from `10@10` to `20@20`. This port keeps the same arithmetic with a larger cell:

```
CellRenderer class >> cellExtent
	^50@50
```

This is the method as this chapter writes it; Section 4.3 gives it the comment that says every other size in the package is derived from it.
```
CellRenderer class >> insideRegionExtent
	^self cellExtent - 20
```

This is the method as this chapter writes it; Section 4.3 gives it a comment, where page 138 of the original arrives at the same body.

so the rectangle here runs from `10@10` to `40@40`. Every number below that comes from the original's diagram belongs to its 30-pixel cell; nothing in the code repeats one, which is the point of the next few pages.

The page then draws the subdivided region and names the nine points it wants to test. Note the coordinate system: *x* grows to the right, *y* grows **downwards**, which is the opposite of the way the lines are usually drawn on paper. The page also settles a piece of game design with a picture: hovering over the left triangle shows an arrow pointing east. You push away from the edge you are nearest.

| Label | Point | Push |
| --- | --- | --- |
| A | `10@10` | East |
| B | `20@10` | South |
| C | `15@15` | East |
| D | `10@20` | East |
| E | `20@20` | North |
| F | `11@13` | East |
| G | `14@16` | North |
| H | `19@17` | West |
| I | `15@1` | South |

Several of those points sit exactly on a corner or on a line, and the page says so: the answers for them are an arbitrary decision, made here and checked later. The test it writes is one method over a table of associations:

```
testClicksInPushRegions
	| pt regionClass pushRegion testTable cls |
	pt := 11@11.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self should: [regionClass = CellClickRegionInside].
	testTable := {
		10@10->CellClickRegionPushEast.
		20@10->CellClickRegionPushSouth.
		15@15->CellClickRegionPushEast.
		10@20->CellClickRegionPushEast.
		20@20->CellClickRegionPushNorth.
		11@13->CellClickRegionPushEast.
		14@16->CellClickRegionPushNorth.
		19@17->CellClickRegionPushWest.
		15@1->CellClickRegionPushSouth
		}.
	testTable do: [:assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self should: [pushRegion = cls]]
```

It cannot pass yet: every push region still answers `true`, so `pushRegionForPoint:` answers whichever subclass `detect:` reaches first.

## Two lines

Page 087 does the arithmetic. The inside region is cut by two diagonals. One starts in its lower left corner and heads up and to the right — the *heading-up* line — and one starts in its upper left corner and heads down and to the right — the *heading-down* line. With `y = mx + b` and the corner points of a 30-pixel cell, `(10,10)` and `(20,20)` give

```
m = (20 - 10) / (20 - 10) = 1
10 = 1(10) + b, so b = 0
y = x
```

and `(10,20)` with `(20,10)` give

```
m = (10 - 20) / (20 - 10) = -1
20 = -1(10) + b, so b = 30
y = 30 - x
```

The two equations are written as class methods of `CellClickRegionInside`. The original typed the second one as `^30 - x`; the version in the package asks the cell for its size, so the lines follow the cell instead of a literal:

```
CellClickRegionInside class >> yForHeadingUpLineWith: x
	^x
```

This is the method as this chapter writes it; Section 4.3 gives it a comment, where the cell size is raised to see whether the two diagonals follow it.
```
CellClickRegionInside class >> yForHeadingDownLineWith: x
	^CellRenderer cellExtent x - x
```

This is the method as this chapter writes it; Section 4.3 gives it a comment, where the cell size is raised to see whether the two diagonals follow it.

Page 089 adds the two tests that place a point against a line. Both ask `<`, so a point *on* a line is not under it — a detail that costs two pages further on:

```smalltalk
CellClickRegionInside class >> pointIsUnderHeadingUpLine: aPoint
	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingUpLineWith: realX.
	^realY < lineY
```
```smalltalk
CellClickRegionInside class >> pointIsUnderHeadingDownLine: aPoint

	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingDownLineWith: realX.
	^ realY < lineY
```

## The truth table

A point is over or under each of the two lines, which is four combinations, which is exactly the four push regions. Page 088 writes them out. Remember that *y* grows downwards, so "under" means nearer the top of the screen:

| Line | Push North | Push East | Push South | Push West |
| --- | --- | --- | --- | --- |
| heading-up | Over | Over | Under | Under |
| heading-down | Over | Under | Under | Over |

Each of the four classes answers one row. This is the same shape as the region classes themselves: no conditional anywhere decides the direction, each class states its own case and `pushRegionForPoint:` asks them all.

```smalltalk
CellClickRegionInside class >> pushRegionForPoint: aPoint
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
```
```smalltalk
CellClickRegionPushNorth class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^(underHeadingDown not) and: [underHeadingUp not]
```
```smalltalk
CellClickRegionPushEast class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp not]
```
```smalltalk
CellClickRegionPushSouth class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp]
```
```smalltalk
CellClickRegionPushWest class >> containsPoint: aPoint
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown not and: [underHeadingUp]
```

The superclass gets a `containsPoint:` of its own, so that asking the question of `CellClickRegionInside` itself says who should have answered it rather than failing with a doesNotUnderstand:

```smalltalk
CellClickRegionInside class >> containsPoint: aPoint
	"Answer whether aPoint falls in me. Each of my four push subclasses answers one line of the
	truth table of page 088, written against the two diagonals I hold."

	^ self subclassResponsibility
```

## When the test is the thing that is wrong

Page 090 runs the tests and one of them fails: point `20@10` answers `CellClickRegionPushWest` where the test expects `CellClickRegionPushSouth`. The page stops to ask which of the two is wrong, the code or the test, and that is the lesson of the page.

`20@10` is the top right corner of the original's inside region. It is under the heading-up line, since `10 < 20`. Is it under the heading-down line? At `x = 20` that line is at `y = 30 - 20 = 10`, and the test asks `10 < 10`, which is false. So the point is under the heading-up line only, and the truth table says west. The code is right and the test is wrong. Page 091 corrects it, and also the other points that sit on a line:

```
testClicksInPushRegions
	| pt regionClass pushRegion testTable cls |
	pt := 11@11.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self should: [regionClass = CellClickRegionInside].
	testTable := {
		10@10->CellClickRegionPushEast.
		20@10->CellClickRegionPushWest.
		15@15->CellClickRegionPushNorth.
		10@20->CellClickRegionPushNorth.
		20@20->CellClickRegionPushNorth.
		11@13->CellClickRegionPushEast.
		14@16->CellClickRegionPushNorth.
		19@17->CellClickRegionPushWest.
		15@1->CellClickRegionPushSouth
		}.
	testTable do: [:assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self should: [pushRegion = cls]]
```

The corrected table records a decision rather than a measurement: a point on both lines, like the centre, is under neither, so it pushes north.

## Tests

The port asks for the same properties, but not through a table of nine points of a 30-pixel cell. Every one of those points is a number this cell no longer has, and hand-picked points also leave the gaps between them unchecked. The tests below derive what they need from `regionRectangle`, so they hold at any cell size and say what the table was trying to say.

The first one is the property the four triangles exist for — they cover the inside region, and they do not overlap:

```smalltalk
CellClickInsideRegionPushTestCase >> testEveryPointOfTheInsideRegionIsInExactlyOnePushRegion
	"The two diagonals cut the inside region into four triangles that cover it and do not
	overlap, so every point of it belongs to one push region and to no other. The original
	checked nine points by hand; this walks the whole region, which is what makes the test hold
	at any cell size."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	rect left to: rect right do: [ :x |
		rect top to: rect bottom do: [ :y |
			| point matching |
			point := x @ y.
			matching := CellClickRegionInside subclasses select: [ :each |
				            each containsPoint: point ].
			self assert: matching size equals: 1 ] ]
```

The second is the game design decision of page 086's picture, which no assertion on a corner point can state as plainly:

```smalltalk
CellClickInsideRegionPushTestCase >> testThePushRegionIsTheOneOfTheEdgeThePointIsNearest
	"A point near an edge of the inside region pushes away from that edge: near the left edge the
	cell is pushed east, near the top edge it is pushed south. That is the arrow page 086 draws
	in its diagram, and it is why the region names read the way they do."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> CellClickRegionPushEast).
	(rect rightCenter - (1 @ 0) -> CellClickRegionPushWest).
	(rect topCenter + (0 @ 1) -> CellClickRegionPushSouth).
	(rect bottomCenter - (0 @ 1) -> CellClickRegionPushNorth) } do: [ :each |
		self
			assert: (CellClickRegionInside pushRegionForPoint: each key)
			equals: each value ]
```

The third is pages 090 and 091 themselves, kept as an assertion rather than as a corrected table: a point on a line is not under it, and that is what sends the centre north and the top right corner west.

```smalltalk
CellClickInsideRegionPushTestCase >> testAPointOnALineIsNotUnderIt
	"Pages 090 and 091: the first run of the original's test failed on a point that sits exactly
	on a line, and the fault was in the test, not in the code. Both line tests ask <, so a point
	on a line is not under it, and the truth table then sends the corner points the way the
	region names say."

	| rect onBoth onHeadingDown |
	rect := CellClickRegionInside regionRectangle.
	onBoth := rect center.
	onHeadingDown := rect topRight.
	self deny:
		(CellClickRegionInside pointIsUnderHeadingUpLine: onBoth).
	self deny:
		(CellClickRegionInside pointIsUnderHeadingDownLine: onBoth).
	self
		assert: (CellClickRegionInside pushRegionForPoint: onBoth)
		equals: CellClickRegionPushNorth.
	self deny:
		(CellClickRegionInside pointIsUnderHeadingDownLine: onHeadingDown).
	self assert:
		(CellClickRegionInside pointIsUnderHeadingUpLine: onHeadingDown).
	self
		assert: (CellClickRegionInside pushRegionForPoint: onHeadingDown)
		equals: CellClickRegionPushWest
```

The fourth is the reason the first three can be written without numbers: the lines are equations of the cell, and they still arrive exactly at the corners of the inside region.

```smalltalk
CellClickInsideRegionPushTestCase >> testTheLinesRunThroughTheCornersOfTheInsideRegion
	"The two diagonals are written as equations of the cell, y = x and y = cellExtent x - x, and
	no number of the inside region appears in them. They still meet its corners, which is what
	makes the arithmetic of page 087 hold at any cell size."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionInside yForHeadingUpLineWith: rect left)
		equals: rect top.
	self
		assert: (CellClickRegionInside yForHeadingUpLineWith: rect right)
		equals: rect bottom.
	self
		assert: (CellClickRegionInside yForHeadingDownLineWith: rect left)
		equals: rect bottom.
	self
		assert: (CellClickRegionInside yForHeadingDownLineWith: rect right)
		equals: rect top
```

All four pass as soon as they are written, since the arithmetic they check came with the captured source. That is worth saying plainly: they are not a red bar turned green, they are the pages of the original written down as properties.

## Asking a region for its hint

Page 092 puts the new knowledge to work. The pointer moves inside a mirror cell, and the game wants to show the hint that belongs where it is. The page adds a message to `CellClickRegion`, which ignores it:

```
showPositionHintFromWithinCell: aPoint
	^nil
```

and lets the inside region answer it, printing to the Transcript until there are arrows to draw:

```
showPositionHintFromWithinCell: aPoint
	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	Transcript show: aPoint printString, ' ', pushRegion name; cr.
```

with the hook in the mirror renderer:

```
showPositionHintFromWithinBoardOffset: aPoint
	| cellPosn offsetWithinCell regionClass |
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell.
	regionClass showPositionHintFromWithinCell: offsetWithinCell.
```

Section 3.3 already ported the hook: a mirror answers `hintRegionAt:` with the region a point falls in, and the cell element keeps the answer. What that method did not do was refine it. `CellClickRegionInside` is not a hint — there are four hints inside it — so the port turns the page's command into the same question one level down. Every region answers what hint applies at a point, and answers itself by default:

```smalltalk
CellClickRegion class >> hintRegionForPoint: aPoint
	"Answer the region whose hint applies at aPoint, which I already contain. I have nothing
	finer to say than my own name, so I answer myself; the inside region answers one of its four
	push regions."

	^ self
```

The inside region is the one that has something better to say:

```smalltalk
CellClickRegionInside class >> hintRegionForPoint: aPoint
	"Answer the push region aPoint falls in. A click here pushes a cell, and which way it pushes
	is what the hint has to show, so the inside region is the one region that refines its answer."

	^ self pushRegionForPoint: aPoint
```

and the mirror renderer asks the question it gets:

```smalltalk
MirrorCellRenderer >> hintRegionAt: aPoint
	"Answer the region whose hint applies at aPoint: a mirror reacts to a click, and which of its
	actions is meant depends on where in the cell the pointer is. The region that contains the
	point has the last word, so a point near the middle answers one of the four push regions.
	The original had to subtract the offset of my cell within the board form before it could ask
	this."

	^ (CellClickRegion clickRegionForPoint: aPoint) hintRegionForPoint: aPoint
```

Nothing else changes. The three lines of offset arithmetic stayed behind in Section 3.3, the Transcript line has no counterpart — `hintRegion` on the cell element holds what the original printed — and the page's own `showPositionHintFromWithinCell:` is deleted from the package, having no sender left.

The first test is the polymorphism of the page: one message, every region answers, one of them refines:

```
CellClickRegionTestCase >> testOnlyTheInsideRegionRefinesTheHintItAnswers
	"Page 092 gives every region the hint message and lets the inside region alone do something
	with it: it answers the push region of the point. The others answer themselves, since they
	have nothing finer to say yet."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: 
				 CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegionIgnore hintRegionForPoint: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegionInside hintRegionForPoint: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast
```

Section 3.8 gives the outside region a refinement of its own, so this test is rewritten there as `testTheInsideAndOutsideRegionsRefineTheHintTheyAnswer`.

and the second is what the page watched in its Transcript window, a mirror asked about a point of its cell:

```
MirrorCellRendererTestCase >> testAMirrorAnswersThePushRegionOfAPointInsideIt
	"A mirror asks the region of a point what hint applies there, so a point in the inside region
	answers a push region rather than the inside region itself. That is what page 092 wrote to
	the Transcript."

	| renderer rect |
	renderer := self rendererLeaning: #left.
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (renderer hintRegionAt: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast.
	self
		assert: (renderer hintRegionAt: rect topCenter + (0 @ 1))
		equals: CellClickRegionPushSouth.
	self
		assert: (renderer hintRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionOutside.
	self assert: (renderer hintRegionAt: 0 @ 0) equals: CellClickRegionIgnore
```

Its expectation for the outside region changes in Section 3.8, where a point of that region answers the direction the mirror turns.

It replaces `testAMirrorAnswersTheClickRegionOfAPoint` of Section 3.3, which asserted the unrefined answer. Two more tests of that chapter move with it, since the answer for a point in the middle of a mirror cell is now a push region:

```smalltalk
CellRendererTestCase >> testOnlyAMirrorAnswersAHintRegion
	"Every renderer is asked for a hint region, and all but the mirror answer nothing. That is
	the polymorphism the original page points at: the message goes to every cell renderer, and
	each one decides what to do with it. The mirror answers the push region of the point, since
	the middle of a cell is where a push is asked for."

	| grid point |
	grid := GridFactory demoGrid.
	point := CellClickRegionInside regionRectangle center.
	self
		assert: ((CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid)
				 hintRegionAt: point)
		equals: CellClickRegionPushNorth
```
```smalltalk
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellRecordsItsHintRegion
	"A mouse move carries a point, and the cell keeps the region that point falls in. In the
	middle of the cell that is a push region, since the push regions divide the inside region
	between them. The original computed the same thing by subtracting the offset of the cell
	within the board form from a board-wide position, and wrote the answer to the Transcript."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionIgnore
```

## Checking it

The original's check is its Transcript window: move the pointer around inside a mirror cell and watch the push direction change, and note that blank cells and the target print nothing. The same walk is one expression here, without a window:

```smalltalk
| grid renderer rect |
grid := GridFactory demoGrid.
renderer := CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid.
rect := CellClickRegionInside regionRectangle.
{ rect leftCenter + (1 @ 0). rect topCenter + (0 @ 1). rect rightCenter - (1 @ 0).
  rect bottomCenter - (0 @ 1). rect center. 0 @ 0 } collect: [ :each |
	each -> (renderer hintRegionAt: each) ]
```

which answers east, south, west, north, north and the ignore region, and the same expression on the blank cell at `1@1` or the target at `5@1` answers `nil` six times.

The hint is still only a class. Section 3.6 gives it a picture: the arrows built in the last chapter, drawn in the cell the pointer is over.

# Drawing Push Hints On The Game Board

*Pages 093 and 094 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/093.html -->
<!-- http://squeak.preeminent.org/tut2007/html/094.html -->

The pointer moves inside a mirror cell and the game knows which way that cell would be pushed. This chapter shows the player: the arrow of the push region appears in the cell under the pointer, and goes when the pointer does.

Page 093 lists four things to settle first:

- the arrow forms are not to scale for the board;
- the exact place to draw the arrow has to be known;
- the arrow has to be drawn over the correct cell;
- old arrows must not be left cluttering the board.

Two of them are gone before the chapter starts. The arrows have been polygons since Section 3.4, so scale is not a problem to solve but a number to pass; and "the correct cell" is the element the pointer is in, since the event was delivered to it. What is left is where in the cell the arrow sits, and what removes the previous one.

## The original's scaling experiment

Page 093 tries the scaling in a workspace, painting an arrow straight onto the display:

```
pt := 100@320.
form := LaserGameForms eastArrow.
form := form scaledToSize: CellRenderer cellExtent.
ext := form extent.
form
	displayOn: Display
	at: pt
	clippingBox: (pt extent: ext)
	rule: Form oldPaint
	fillColor: Color gray.
```

`scaledToSize:` gives a small copy of the 330 pixel mask, and it looks right. Drawing a second arrow without restoring the display first does not: the new mask paints over the old one and the two arrows are seen at once. The page reads that as a warning — the cell will have to be redrawn before a new hint is added — and Section 3.7 is spent on the bug it predicts.

There is nothing to rehearse here. A polygon is drawn at whatever size its element has, and an element that is removed leaves nothing behind it.

## Asking the region for its picture

The original asks the push region for its arrow, which is the cached form of its direction:

```
arrowForm
	^LaserGameForms eastArrow
```

The port asks the same question and gets an element, built at the size the caller wants. Every region answers it, and all but the four push regions answer nothing:

```
CellClickRegion class >> hintElementOfExtent: anExtent
	"Answer an element drawing my hint at anExtent, or nil when I have no picture to show. Only
	the four push regions have one here; the rotate regions get theirs in Section 3.8."

	^ nil
```

The comment is rewritten in Section 3.8, once the two rotate regions answer a picture as well.
```smalltalk
CellClickRegionPushNorth class >> hintElementOfExtent: anExtent
	"Answer the north arrow at anExtent. The original answered a 330 pixel bitmap mask from the
	forms cache and scaled it down; a polygon is drawn at the size it is given."

	^ LaserGameShapes northArrowElementOfExtent: anExtent
```
```smalltalk
CellClickRegionPushEast class >> hintElementOfExtent: anExtent
	"Answer the east arrow at anExtent."

	^ LaserGameShapes eastArrowElementOfExtent: anExtent
```
```smalltalk
CellClickRegionPushSouth class >> hintElementOfExtent: anExtent
	"Answer the south arrow at anExtent."

	^ LaserGameShapes southArrowElementOfExtent: anExtent
```
```smalltalk
CellClickRegionPushWest class >> hintElementOfExtent: anExtent
	"Answer the west arrow at anExtent."

	^ LaserGameShapes westArrowElementOfExtent: anExtent
```

## How big, and where

Page 094 settles both numbers in two lines: the arrow is scaled to a couple of pixels less than a cell, and centred in it by halving the difference. They are the only part of the original's method the port keeps, and they belong with the other cell measurements:

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

## One arrow at a time

The cell element holds the picture of the hint it holds, and replacing it is what keeps the board clean — the fourth consideration of page 093, which the original has to solve by redrawing the cell:

```
LaserGameCellElement >> updateHintElement
	"Show the picture of the hint I hold, and no other. The original drew its arrow straight onto
	the board form, which is why page 093 warns that old arrows have to be cleaned off; here the
	arrow is a child of mine, so the previous one goes when it is removed."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each position: CellRenderer hintArrowOffset.
		self addChild: each ]
```

This is the method as this chapter writes it; Section 4.1 adds the colour the arrow is painted in.

The two methods of Section 3.3 that set and clear the hint now each end in it. Both start by comparing, so a pointer moving within one region does not rebuild anything: a mouse move arrives for every pixel crossed, and only a move into another region is a change.

```
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing, so the arrow is built once."

	| region |
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self ].
	hintRegion := region.
	self updateHintElement
```

This is the method as this chapter writes it; Section 3.14 adds the line that keeps the point the hint was read at, so that a redraw can ask the question again.
```
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me, so the arrow goes too."

	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
```

This is the method as this chapter writes it; Section 3.14 adds the line that forgets that point as well.
```smalltalk
LaserGameCellElement >> hintElement
	"Answer the element drawing my hint, or nil when I show none."

	^ hintElement
```

`mouseLeave:` is unchanged and needs no change: it already clears the hint, and clearing it now takes the arrow away.

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
```

## What the page's own method becomes

This is the method pages 093 and 094 build, in the finished form the captured source holds:

```
showPositionHintFromWithinBoardOffset: aPoint
	| cellPosn offsetWithinCell regionClass pushRegionClass arrow tinyArrow offset |
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell.
	pushRegionClass := regionClass showPositionHintFromWithinCell: offsetWithinCell.
	pushRegionClass isNil ifTrue: [^self].
	arrow := pushRegionClass arrowForm.
	tinyArrow := arrow scaledToSize: CellRenderer cellExtent - 2.
	offset := self offsetWithinGridForm.
```

Every line of it has a home now. The first three are the coordinate arithmetic Bloc does when it delivers the event; the fourth and fifth are `hintRegionAt:` from Section 3.5; the sixth is the `ifNil:` in `updateHintElement`; the seventh is `hintElementOfExtent:`; and the last two are the two constants above. It is deleted, and with it `CellClickRegionInside class >> scaledHintArrowAndOffsetFromWithinCell:`, which existed to pair a scaled form with its offset, and the four `arrowForm` methods of the push regions.

`LaserGameForms` still answers `northArrow`, `eastArrow`, `southArrow` and `westArrow`, and nothing sends them any more. The class stays until the rotate arrows of Section 3.8 and the beam masks of Section 4 have moved too, and goes whole when they have.

## Tests

A push region answers an arrow of the direction it is named for, at the size asked for, and no other region answers anything:

```
CellClickRegionTestCase >> testOnlyAPushRegionAnswersAHintElement
	"Page 094 asks a push region for its arrow. Here it answers an element, built at the size
	asked for, and every other region answers nothing: the outside region gets its rotate arrows
	in Section 3.8, and the ignore region never has a picture."

	| extent |
	extent := 48 @ 48.
	self assert: (CellClickRegionOutside hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionIgnore hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionInside hintElementOfExtent: extent) isNil.
	{ (CellClickRegionPushNorth -> LaserGameShapes northArrowPoints).
	(CellClickRegionPushEast -> LaserGameShapes eastArrowPoints).
	(CellClickRegionPushSouth -> LaserGameShapes southArrowPoints).
	(CellClickRegionPushWest -> LaserGameShapes westArrowPoints) } do: [ :each |
		| element |
		element := each key hintElementOfExtent: extent.
		self
			assert: element geometry vertices
			equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) ]
```

Section 3.8 adds the two rotate regions to the table and renames the test `testEachRegionWithAPictureAnswersTheArrowOfItsDirection`.

A pointer inside a mirror cell puts that arrow in the cell, centred:

```smalltalk
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellShowsTheArrowOfItsPushRegion
	"Page 093 draws the arrow of the hint onto the board. Here the cell adds it as a child, a
	few pixels smaller than the cell and centred in it, and its vertices are the ones of the
	direction the pointer asks for."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	self assert: element hintElement isNil.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: (element children includes: element hintElement).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes northArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent).
	self
		assert: element hintElement constraints position
		equals: CellRenderer hintArrowOffset
```

Moving on to another push region replaces it rather than adding to it, which is the page's fourth consideration stated as an assertion on the number of children:

```
LaserGameCellElementTestCase >> testAMirrorCellShowsOneArrowAtATime
	"The fourth design consideration of page 093: old arrows must not clutter the board. The
	original had to redraw the cell before drawing the new arrow; here the cell has one hint
	child, and moving to another push region replaces it."

	| board element rect childCount |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> LaserGameShapes eastArrowPoints).
	(rect topCenter + (0 @ 1) -> LaserGameShapes southArrowPoints).
	(rect rightCenter - (1 @ 0) -> LaserGameShapes westArrowPoints) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element children size equals: childCount + 1.
		self
			assert: element hintElement geometry vertices
			equals: (LaserGameShapes
					 pointsOf: each value
					 scaledToExtent: CellRenderer hintArrowExtent) ]
```

This is the test as this chapter writes it; Section 4.2 counts two children per hint, since the cross hair comes with the arrow.

and the arrow goes when the hint does, whether the pointer leaves the cell or only reaches a region that has no picture:

```smalltalk
LaserGameCellElementTestCase >> testTheArrowGoesWhenThePointerLeavesOrReachesARegionWithoutOne
	"A hint lasts as long as the pointer is in a region that has one. Leaving the cell takes the
	arrow with it, and so does moving out to the margin, where the ignore region has no picture."

	| board element childCount |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: element hintElement isNil.
	self assert: element children size equals: childCount.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: element hintElement isNil.
	self assert: element children size equals: childCount
```

The test of Section 3.3 for cells that are not mirrors gains the same two assertions, since a blank or target cell draws nothing either:

```smalltalk
LaserGameCellElementTestCase >> testMovingOverACellThatIsNotAMirrorRecordsNoHint
	"Blank and target cells answer no hint region, so moving over them records nothing and draws
	nothing."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	#( 1 5 ) do: [ :column |
		| element childCount |
		element := board cellElementAt: column @ 1.
		childCount := element children size.
		element dispatchEvent: (BlMouseMoveEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		self assert: element hintRegion isNil.
		self assert: element hintElement isNil.
		self assert: element children size equals: childCount ]
```

## Checking it

```smalltalk
LaserGameElement openExample
```

Move the pointer around inside a mirror cell: a grey arrow appears in it, pointing the way that cell would be pushed, and it changes as the pointer crosses a diagonal. Move out to the rim of the cell, or off it, and the arrow goes. Blank cells and the target show nothing at all.

The original could not do this yet. Its arrow was painted onto the board form, the cell under it was not repainted, and pages 095 to 100 are spent finding out why the board fills up with arrows. That is the next chapter, and in this port it is a chapter about a bug that cannot happen.

# Using "Halt Once"

*Pages 095 to 100 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/095.html -->
<!-- http://squeak.preeminent.org/tut2007/html/096.html -->
<!-- http://squeak.preeminent.org/tut2007/html/097.html -->
<!-- http://squeak.preeminent.org/tut2007/html/098.html -->
<!-- http://squeak.preeminent.org/tut2007/html/099.html -->
<!-- http://squeak.preeminent.org/tut2007/html/100.html -->

This chapter of the original is two chapters wearing one title. The first half debugs the hint drawing of the last chapter, with a tool worth knowing about; the second half goes back to the workspace and draws the curved arrows the rotate regions will need. Only the second half leaves code behind in this port.

## The tool

A mouse move arrives for every pixel the pointer crosses, so the drawing code of page 094 runs dozens of times a second. To look at it while it runs, the page wants to stop the first time and then never again. `self halt` is no use: it stops every time, including the next thirty times, while the debugger is being read.

Page 095 uses `self haltOnce` instead, an enhancement its author wrote for Smalltalk/V in the late 1980s, published for Squeak in 2004, and found built into Squeak 3.9. It halts once and turns itself off, so the code carries on afterwards at full speed. It is still in Pharo 13, on `Object` alongside `halt`, `haltOnce:`, `haltIf:` and the rest, and it is worth remembering for exactly the case that this page is about: code that runs too often to stop in.

```smalltalk
self haltOnce
```

Pages 095 and 096 then do the work in the debugger — edit the method in the stack frame, save, step over each line, and watch the arrow appear on the board once the window is next repainted. None of that is repeatable, and none of it becomes code.

The port has nothing to trap. `hintRegionAt:` and `hintElementOfExtent:` are questions with answers, so the tests of the last two chapters ask them directly and read the answer, without a game window, without a debugger and without a trick to make the code stop. That is the difference the whole port is built on, and it is worth noticing where the original feels it: the page is trying to see a value that the code never returns.

## The drawing bugs, and where they went

Page 097 finds the first one: the arrow does not appear until something else repaints the window. One line fixes it.

```
mouseMoveWhileButtonUp: evt forMorph: aSketchMorph
	| cell renderer pixelPositionWithinBoard |
	cell := self cellForEvent: evt.
	renderer := CellRenderer rendererFor: cell grid: self grid form: self boardForm.
	pixelPositionWithinBoard := self boardRelativePositionFor: evt.
	renderer showPositionHintFromWithinBoardOffset: pixelPositionWithinBoard.
	self changed
```

The second is the one page 093 predicted: arrows accumulate. Drawing an arrow over a cell that still holds the last arrow leaves both, so the cell has to be blanked and re-rendered before each one. The page extracts that into a method of its own,

```
MirrorCellRenderer >> redrawCell

	| offset backgroundRect |
	offset := self offsetWithinGridForm.
	backgroundRect := offset extent: CellRenderer cellExtent - 2.
	self targetForm
		fill: backgroundRect
		fillColor: LaserGameColors gameBoardBackgroundColor.
	self render
```

and page 098 calls it on the way in rather than on the way out: redraw the cell first, always, and then draw the hint if there is one. It also has to widen the redraw to the whole cell, borders included, because blanking only the inside left the borders missing.

All of that is bookkeeping around a bitmap that is painted in place, and the port has none of it. The arrow is a child element of the cell it belongs to, added and removed by `updateHintElement`; Bloc repaints what changed, so there is no `self changed`; nothing was ever painted over the cell, so there is nothing to blank and nothing to re-render; and the borders cannot go missing because they were never overwritten. Section 3.6 is where this port answers pages 097 and 098, one chapter before they are asked.

## The curved arrows

Pages 099 and 100 are a workspace session like page 081, and they leave real work behind: the game needs an arrow with an arc for the two rotate regions, which Section 3.8 uses.

The drawing is built in pieces. An arrow head like the south arrow of page 082, but with almost no stem:

```
LaserGameForms class >> drawCounterClockwiseArrowHeadOn: form withPen: penForm
	| arrowPts index offset startPoint nextIndex endPoint line |
	arrowPts := {100@260. 40@150. 80@150. 80@141. 120@141. 120@150. 160@150}.
	index := 1.
	offset := 2@100.
	[index <= arrowPts size] whileTrue: [
		startPoint := arrowPts at: index.
		nextIndex := index = arrowPts size
			ifTrue: [1]
			ifFalse: [index + 1].
		endPoint := arrowPts at: nextIndex.
		startPoint := startPoint + offset.
		endPoint := endPoint + offset.
		line := Line from: startPoint to: endPoint withForm: penForm.
		line displayOn: form.
		index := index + 1].
	form floodFill: Color black at: 100@255.
```

then the ring, drawn as two arcs about one centre — `Arc` draws a quadrant at a time, so each radius is drawn twice — closed off on the right by a line from the centre to the corner of the form, flood filled black, and the line painted out again with a pen 100 pixels wide:

```
LaserGameForms class >> drawCounterClockwiseArcsOn: form withPen: penForm
	| center outsideCircle insideCircle line bigPen |
	center := 282@240.
	outsideCircle := Arc new.
	outsideCircle quadrant: 2.
	outsideCircle form: penForm.
	outsideCircle radius: 200.
	outsideCircle center: center.
	outsideCircle displayOn: form.
	outsideCircle quadrant: 1.
	outsideCircle displayOn: form.
	insideCircle := Arc new.
	insideCircle quadrant: 2.
	insideCircle form: penForm.
	insideCircle radius: 160.
	insideCircle center: center.
	insideCircle displayOn: form.
	insideCircle quadrant: 1.
	insideCircle displayOn: form.
	line := Line from: center to: (form extent x@0) withForm: penForm.
	line displayOn: form.
	form floodFill: Color black at: 100@235.
	bigPen := Form extent: 100@100 depth: 1.
	bigPen fillColor: Color white.
	line form: bigPen.
	line displayOn: form.
```

with the two halves assembled into a 450 pixel form,

```
LaserGameForms class >> drawCounterClockwiseArrow
	| form penForm |
	form := Form extent: 450@450 depth: 1.
	form fillColor: Color white.
	penForm := Form extent: 1@1 depth: 1.
	penForm fillColor: Color black.
	self drawCounterClockwiseArrowHeadOn: form withPen: penForm.
	self drawCounterClockwiseArcsOn: form withPen: penForm.
	^form
```

and the clockwise arrow obtained by flipping it:

```
LaserGameForms class >> drawClockwiseArrow
	^self drawCounterClockwiseArrow flipBy: #horizontal centerAt: 0@0
```

Page 100 adds both to the `CachedForms` dictionary and writes the two accessors, with a warning in bold that the cache has to be re-initialized by hand after the change.

## The same arrow as an outline

The port draws the same shape, and keeps the numbers of page 099: the centre the arcs turn about, the two radii, and the arrow head array with its offset.

```smalltalk
LaserGameShapes class >> rotateArrowCenter
	"Answer the centre both arcs of the curved arrow turn about, as page 099 typed it into its
	workspace."

	^ 282 @ 240
```
```smalltalk
LaserGameShapes class >> rotateArrowOuterRadius
	"Answer the radius of the outer arc of the curved arrow, the 200 of page 099."

	^ 200
```
```smalltalk
LaserGameShapes class >> rotateArrowInnerRadius
	"Answer the radius of the inner arc of the curved arrow, the 160 of page 099."

	^ 160
```
```smalltalk
LaserGameShapes class >> rotateArrowHeadPoints
	"Answer the arrow head of the curved arrow: the array page 099 types into its workspace,
	moved by the offset the page adds to it. It is the south arrow of page 082 with almost no
	stem, since the ring is the stem. The two points in the middle, at the top of the stem, are
	where the ring begins, so the outline replaces them with the ends of the two arcs."

	^ { 100 @ 260. 40 @ 150. 80 @ 150. 80 @ 141. 120 @ 141. 120 @ 150. 160 @ 150 }
		  collect: [ :each | each + (2 @ 100) ]
```

The line that closes the arc leaves one number behind it, the angle at which it crosses:

```smalltalk
LaserGameShapes class >> rotateArrowCutAngle
	"Answer where the ring stops, in degrees measured anticlockwise from east. Page 099 draws a
	line from the centre of the arcs to the top right corner of its 450 pixel form, fills the
	shape the line closes, and then paints the line out again with a very wide white pen. The
	angle of that line is all the port keeps of it."

	| corner |
	corner := 450 @ 0 - self rotateArrowCenter.
	^ (corner y negated arcTan: corner x) radiansToDegrees
```

An arc has to become corners, since the shape is a polygon. How many is a choice the original never had to make, the arc being drawn pixel by pixel:

```smalltalk
LaserGameShapes class >> rotateArrowArcSteps
	"Answer how many segments an arc of the curved arrow is drawn with. The original had a pixel
	arc and no choice to make; a polygon has as many corners as it is given, and two dozen are
	enough for the largest cell the game uses."

	^ 24
```
```smalltalk
LaserGameShapes class >> arcPointsFromAngle: startDegrees toAngle: stopDegrees radius: aRadius
	"Answer the points of an arc of aRadius about my rotate arrow centre, running from
	startDegrees to stopDegrees. Angles are measured anticlockwise from east, and the sine is
	subtracted because y grows downwards."

	| center step |
	center := self rotateArrowCenter.
	step := stopDegrees - startDegrees / self rotateArrowArcSteps.
	^ (0 to: self rotateArrowArcSteps) collect: [ :each |
		  | angle |
		  angle := (startDegrees + (each * step)) degreesToRadians.
		  (center x + (aRadius * angle cos))
		  @ (center y - (aRadius * angle sin)) ]
```

and then the outline is walked once: down the head, out along the outer arc, across the cut, back along the inner arc, and down the other side of the head. What the original obtained with two arcs, a line, a flood fill and a wide white pen is the order the points are listed in.

```smalltalk
LaserGameShapes class >> counterClockwiseArrowPoints
	"Answer the outline of the arrow that turns a mirror anticlockwise: the head of page 099,
	then the outer arc from the head round to the cut, the cut itself, and the inner arc back.
	The original drew the same shape as two arcs, a line and a flood fill."

	| head |
	head := self rotateArrowHeadPoints.
	^ { head first. head second. head third }
	  , (self
			   arcPointsFromAngle: 180
			   toAngle: self rotateArrowCutAngle
			   radius: self rotateArrowOuterRadius)
	  , (self
			   arcPointsFromAngle: self rotateArrowCutAngle
			   toAngle: 180
			   radius: self rotateArrowInnerRadius)
	  , { head sixth. head seventh }
```
```smalltalk
LaserGameShapes class >> clockwiseArrowPoints
	"Answer the outline of the arrow that turns a mirror clockwise, which page 099 makes by
	flipping the other one horizontally."

	^ self counterClockwiseArrowPoints collect: [ :each |
		  each x negated @ each y ]
```

The elements are built exactly like the four straight arrows, by the method Section 3.4 wrote:

```smalltalk
LaserGameShapes class >> counterClockwiseArrowElementOfExtent: anExtent
	"Answer an element drawing the anticlockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self counterClockwiseArrowPoints
		  ofExtent: anExtent
```
```smalltalk
LaserGameShapes class >> clockwiseArrowElementOfExtent: anExtent
	"Answer an element drawing the clockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self clockwiseArrowPoints
		  ofExtent: anExtent
```
```smalltalk
LaserGameShapes class >> arrowElementFromPoints: anArrayOfPoints ofExtent: anExtent
	"Answer an element of anExtent whose geometry is the outline anArrayOfPoints describes. The
	outline is a polygon, so it is drawn at whatever size it is given and needs no flood fill:
	the original drew the outline line by line, filled the inside with black and reversed the
	form, which is what pages 081 and 082 spend their workspace code on."

	^ BlElement new
		  geometry: (BlPolygonGeometry vertices:
					   (self pointsOf: anArrayOfPoints scaledToExtent: anExtent));
		  extent: anExtent;
		  background: self arrowColor;
		  yourself
```

`LaserGameForms` keeps its two curved forms and its cache for one more chapter: `CellClickRegionRotateClockwise class >> arrowForm` and its counterpart still ask for them, and those go at Section 3.8.

## Tests

The shape is checked by what it is made of, not by looking at it. Every point of the outline is either a point of the head or a point of one of the two circles:

```smalltalk
LaserGameShapesTestCase >> testTheRotateArrowIsARingBetweenTwoCirclesWithAHeadOnIt
	"Page 099 draws the curved arrow as two arcs about one centre, cut off by a line, with the
	straight arrow head of the earlier pages stuck on the end. Every point of the outline is
	therefore either a point of that head or a point of one of the two circles."

	| center head |
	center := LaserGameShapes rotateArrowCenter.
	head := LaserGameShapes rotateArrowHeadPoints.
	LaserGameShapes counterClockwiseArrowPoints do: [ :each |
		| radius |
		radius := (each - center) r.
		self assert: ((head includes: each) or: [
				 (radius closeTo: LaserGameShapes rotateArrowInnerRadius) or: [
					 radius closeTo: LaserGameShapes rotateArrowOuterRadius ] ]) ]
```

and the ring meets the head because the two radii differ by exactly the width of the stem, which is what made the original's flood fill produce one shape rather than two:

```smalltalk
LaserGameShapesTestCase >> testTheRingOfTheRotateArrowIsAsWideAsTheStemOfItsHead
	"The two radii of page 099 are 160 and 200, and the stem of its arrow head is 40 wide and
	sits at the left end of the ring. That is why the flood fill of the original made one shape
	out of the two drawings, and it is what keeps the outline of the port closed."

	| head ring |
	head := LaserGameShapes rotateArrowHeadPoints.
	ring := LaserGameShapes rotateArrowOuterRadius
	        - LaserGameShapes rotateArrowInnerRadius.
	self assert: ring equals: (head sixth x - head third x).
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowOuterRadius
		equals: head third x.
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowInnerRadius
		equals: head sixth x
```

The flip of page 099 is one assertion:

```smalltalk
LaserGameShapesTestCase >> testTheClockwiseArrowIsTheCounterClockwiseOneMirrored
	"Page 099 makes the clockwise arrow by flipping the other one horizontally, which is one
	step there and one line here."

	| left right |
	left := LaserGameShapes counterClockwiseArrowPoints.
	right := LaserGameShapes clockwiseArrowPoints.
	self assert: right size equals: left size.
	left with: right do: [ :each :mirrored |
		self assert: mirrored x equals: each x negated.
		self assert: mirrored y equals: each y ]
```

and the arrows scale like every other shape in the class:

```smalltalk
LaserGameShapesTestCase >> testTheRotateArrowElementsArePolygonsOfTheSizeAsked
	"Like the four straight arrows, a rotate arrow is a polygon scaled into the extent asked
	for, so the 450 pixel form of page 099 and the cache it went into have no counterpart."

	{ (#counterClockwiseArrowElementOfExtent:
	 -> LaserGameShapes counterClockwiseArrowPoints).
	(#clockwiseArrowElementOfExtent: -> LaserGameShapes clockwiseArrowPoints) }
		do: [ :each |
			#( 30 48 120 ) do: [ :size |
				| element extent |
				extent := size @ size.
				element := LaserGameShapes perform: each key with: extent.
				self assert: (self requestedExtentOf: element) equals: extent.
				self
					assert: element geometry vertices
					equals:
					(LaserGameShapes pointsOf: each value scaledToExtent: extent) ] ]
```

## Checking it

```smalltalk
| row space |
row := BlElement new
	       layout: (BlLinearLayout horizontal cellSpacing: 10);
	       constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
	       padding: (BlInsets all: 10);
	       background: Color white;
	       yourself.
#( #counterClockwiseArrowElementOfExtent: #clockwiseArrowElementOfExtent: ) do: [ :selector |
	#( 30 60 120 ) do: [ :size |
		row addChild: (LaserGameShapes perform: selector with: size @ size) ] ].
space := BlSpace new.
space root addChild: row.
space extent: 700 @ 200.
space title: 'Rotate arrows'.
space show
```

Six curved arrows, three turning one way and three the other, each one clean at its own size. The original's answer to "is it right?" was to look at a 450 pixel form in a workspace; here it is four unit tests, and the window is only for the pleasure of it.

# Determine Rotate Regions

*Pages 101 to 106 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/101.html -->
<!-- http://squeak.preeminent.org/tut2007/html/102.html -->
<!-- http://squeak.preeminent.org/tut2007/html/103.html -->
<!-- http://squeak.preeminent.org/tut2007/html/104.html -->
<!-- http://squeak.preeminent.org/tut2007/html/105.html -->
<!-- http://squeak.preeminent.org/tut2007/html/106.html -->

A click in the inside region pushes a cell. A click in the outside region turns a mirror, clockwise or counter clockwise, and this chapter decides which. It is the same walk as Sections 3.5 and 3.6, one ring further out: divide the region, name the halves, give each a hint, and delete the bitmap code the hint replaces.

## One line, two halves

Page 101 takes the easy decision, and says so: imagine the outside region cut in half by a horizontal line, the upper half turns the mirror one way and the lower half the other. Which way the mirror leans makes no difference, exactly as it made none for the push regions.

The two classes are already in the package, with their question written as an expression of the cell rather than of the region:

```
CellClickRegionRotateClockwise class >> containsPoint: aPoint
	^aPoint y <= (CellRenderer cellExtent y // 2)
```

This is the method as this chapter writes it; Section 4.3 gives it a comment, where page 138 of the original rewrites the line against the cell size.
```
CellClickRegionRotateCounterClockwise class >> containsPoint: aPoint
	^aPoint y > (CellRenderer cellExtent y // 2)
```

This is the method as this chapter writes it; Section 4.3 gives it a comment, where page 138 of the original rewrites the line against the cell size.

The line is at half the height of the cell, so it holds at any cell size, and page 103 settles its own boundary the way page 091 settled the diagonals: a point exactly on the line belongs to the upper half. `<=` on one side and `>` on the other is that decision, and the two halves therefore cover the region without overlapping.

Asking which half a point is in is `rotateRegionForPoint:`, the counterpart of `pushRegionForPoint:`:

```smalltalk
CellClickRegionOutside class >> rotateRegionForPoint: aPoint
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
```

and since both halves answer `containsPoint:` and their superclass did not, the superclass now says whose question it is:

```smalltalk
CellClickRegionOutside class >> containsPoint: aPoint
	"Answer whether aPoint falls in me. My two subclasses split the region between them, so each
	of them answers it; I only say that the question belongs to them."

	^ self subclassResponsibility
```

## The hint

Page 102 gives each rotate class its own arrow, fetched from the cache the last chapter filled,

```
CellClickRegionRotateClockwise class >> arrowForm
	^LaserGameForms clockwiseArrow
```

and page 105 pairs the arrow with an offset, scaled down to the cell, in the same shape as the inside region's method of page 093:

```
CellClickRegionOutside class >> scaledHintArrowAndOffsetFromWithinCell: aPoint
	| arrow tinyArrow offset rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	arrow := rotateRegion arrowForm.
	tinyArrow := arrow scaledToSize: CellRenderer cellExtent.
	offset := 0.
	^offset->tinyArrow
```

The port already has both halves of that method, because Section 3.5 split the question in two: which region applies, and what picture it has. The outside region answers the first the way the inside region has since page 092 — not itself, but the region of the point:

```smalltalk
CellClickRegionOutside class >> hintRegionForPoint: aPoint
	"Answer the rotate region aPoint falls in. A click here turns a mirror, and which way it turns
	is what the hint has to show, so the outside region refines its answer just as the inside one
	does. Page 105 of the original."

	^ self rotateRegionForPoint: aPoint
```

and each half answers the second with the shape Section 3.7 built:

```smalltalk
CellClickRegionRotateClockwise class >> hintElementOfExtent: anExtent
	"Answer an element drawing the clockwise curved arrow at anExtent. Page 102 of the original
	answers a cached 450 pixel Form here, and page 105 scales it down; the shape of Section 3.7 is
	drawn at whatever size it is given."

	^ LaserGameShapes clockwiseArrowElementOfExtent: anExtent
```
```smalltalk
CellClickRegionRotateCounterClockwise class >> hintElementOfExtent: anExtent
	"Answer an element drawing the counter clockwise curved arrow at anExtent. Page 102 of the
	original answers a cached 450 pixel Form here, and page 105 scales it down; the shape of
	Section 3.7 is drawn at whatever size it is given."

	^ LaserGameShapes counterClockwiseArrowElementOfExtent: anExtent
```

Nothing else changes. `LaserGameCellElement >> updateHintElement` has asked the hint region for an element since Section 3.6 and does not care which region it is talking to, so the curved arrows appear in the cells with no further code. Two regions more can now answer a picture, which the comment on the superclass says:

```smalltalk
CellClickRegion class >> hintElementOfExtent: anExtent
	"Answer an element drawing my hint at anExtent, or nil when I have no picture to show. The four
	push regions answer a straight arrow and the two rotate regions a curved one; the inside and
	outside regions never answer this themselves, since each refines itself first, and the ignore
	region shows nothing."

	^ nil
```

## What page 106 refactors, and what the port deletes

Page 106 is a refactoring chapter. It reads `MirrorCellRenderer >> showPositionHintFromWithinBoardOffset:` again, observes that the temporary called `pushRegionClass` is misnamed now that it also answers rotate regions, that fetching the arrow and then scaling it and computing an offset is three steps where one would do, and that `showPositionHintFromWithinCell:` is not named after what it does. Its answer is to ask the region for a scaled arrow and its offset together, returned as an `Association`, written once on the superclass and once on each of the inside and outside regions, and then to delete the three old implementors.

The port made that move in Section 3.5, for a different reason: a region is asked what applies, not told to draw. Its `hintRegionForPoint:` has the three implementors page 106 ends with, its `hintElementOfExtent:` needs no offset in the answer because the element carries its own position, and nothing pairs two values in an `Association` because nothing scales a bitmap. The method the page rereads was deleted in Section 3.6, line by line into its new homes.

So this section deletes what is left of the bitmap hints:

- `CellClickRegionRotateClockwise class >> arrowForm` and its counter clockwise counterpart, replaced by `hintElementOfExtent:`;
- `CellClickRegionOutside class >> scaledHintArrowAndOffsetFromWithinCell:`, replaced by the pair of methods above;
- `CellClickRegion class >> scaledHintArrowAndOffsetFromWithinCell:`, the `^nil` on the superclass, which now has no implementor under it and no sender.

With those gone, nothing in the game asks `LaserGameForms` for an arrow or a cross hair. What still asks it anything are the four laser beam methods of `CellRenderer`, which are Section 4's work:

```
LaserGameForms -> #(CellRenderer>>renderLaserHorizontalCenter
                    CellRenderer>>renderLaserHorizontalSplatter
                    CellRenderer>>renderLaserVerticalCenter
                    CellRenderer>>renderLaserVerticalSplatter)
```

so the class survives one section more than the tutorial's own plan for it, and goes whole when the beam moves.

## Tests

Page 102 starts a test class for the outside region, and pages 103 and 104 fill it with fifteen points of a 30 pixel cell read off a diagram, labelled A to O. The table is the page's own reasoning, so the port keeps it, with every point derived from the two region rectangles instead of written as a literal:

```
CellClickOutsideRegionRotateTestCase >> testClicksInRotateRegions

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
> **Note.** *A Less Brittle Unit Test Design*, the seventh chapter of Section 5, moves this table into `#assertRotateRegionTable` so that the same fifteen rows can be run at three cell sizes.

Beside it go the properties the table is a sample of. Every point of the region turns the mirror one way and not both, which is the test of Section 3.5 one ring out:

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

and the line itself belongs to the upper half, which is the sentence page 103 adds under its table:

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

The hint of page 105 is two tests. The outside region refines what it answers,

```smalltalk
CellClickOutsideRegionRotateTestCase >> testTheOutsideRegionRefinesTheHintToARotateRegion
	"Page 105 gives the outside region a hint of its own. It answers it the way the inside region
	has since Section 3.5: not itself, but the region of the point, which here is the direction
	the mirror turns."

	| rect |
	rect := CellClickRegionOutside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: rect topLeft)
		equals: CellClickRegionRotateClockwise.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: rect bottomLeft)
		equals: CellClickRegionRotateCounterClockwise
```

and the renderer test of Section 3.5 now expects a direction where it expected the outside region itself:

```smalltalk
MirrorCellRendererTestCase >> testAMirrorAnswersThePushRegionOfAPointInsideIt
	"A mirror asks the region of a point what hint applies there, so a point in the inside region
	answers a push region rather than the inside region itself, and since page 105 a point in the
	outside region answers a rotate region. That is what page 092 wrote to the Transcript."

	| renderer rect |
	renderer := self rendererLeaning: #left.
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (renderer hintRegionAt: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast.
	self
		assert: (renderer hintRegionAt: rect topCenter + (0 @ 1))
		equals: CellClickRegionPushSouth.
	self
		assert: (renderer hintRegionAt: CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionRotateClockwise.
	self assert: (renderer hintRegionAt: 0 @ 0) equals: CellClickRegionIgnore
```

Two tests of the last two chapters were written around the outside region having nothing to say, and say so in their names. Both are rewritten here. Each region with a picture answers the arrow of its own direction:

```smalltalk
CellClickRegionTestCase >> testEachRegionWithAPictureAnswersTheArrowOfItsDirection
	"Page 094 asks a push region for its arrow and page 105 asks a rotate region for its own. Here
	each answers an element built at the size asked for, and the regions that have no picture
	answer nothing: the inside and outside regions always refine themselves first, and the ignore
	region never shows anything."

	| extent |
	extent := 48 @ 48.
	self assert: (CellClickRegionOutside hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionIgnore hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionInside hintElementOfExtent: extent) isNil.
	{ (CellClickRegionPushNorth -> LaserGameShapes northArrowPoints).
	(CellClickRegionPushEast -> LaserGameShapes eastArrowPoints).
	(CellClickRegionPushSouth -> LaserGameShapes southArrowPoints).
	(CellClickRegionPushWest -> LaserGameShapes westArrowPoints).
	(CellClickRegionRotateClockwise
	 -> LaserGameShapes clockwiseArrowPoints).
	(CellClickRegionRotateCounterClockwise
	 -> LaserGameShapes counterClockwiseArrowPoints) } do: [ :each |
		| element |
		element := each key hintElementOfExtent: extent.
		self
			assert: element geometry vertices
			equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) ]
```

and two regions, not one, refine the hint they answer:

```smalltalk
CellClickRegionTestCase >> testTheInsideAndOutsideRegionsRefineTheHintTheyAnswer
	"Page 092 gives every region the hint message. The inside region answers the push region of
	the point, and since page 105 the outside region answers the rotate region of the point. The
	ignore region answers itself, having nothing finer to say and no picture to show."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: 
				 CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionRotateClockwise.
	self
		assert: (CellClickRegionIgnore hintRegionForPoint: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegionInside hintRegionForPoint: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast
```

Last, the cell shows the curved arrow when the pointer is in the outside region, which is the screenshot of page 105:

```smalltalk
LaserGameCellElementTestCase >> testMovingInTheOutsideRegionOfAMirrorCellShowsARotateArrow
	"Page 105 hovers the outside region and gets the curved arrows. The cell adds one as a child
	exactly as it adds a push arrow, and the upper half of the region shows the clockwise one. The
	last row of the region belongs to the ignore margin, as `Rectangle >> containsPoint:` leaves
	its bottom edge out, so the lower point is taken one pixel above it."

	| board element rect |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	rect := CellClickRegionOutside regionRectangle.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: rect topLeft;
			 yourself).
	self assert: (element children includes: element hintElement).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes clockwiseArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: rect bottomLeft - (0 @ 1);
			 yourself).
	self
		assert: element hintElement geometry vertices
		equals: (LaserGameShapes
				 pointsOf: LaserGameShapes counterClockwiseArrowPoints
				 scaledToExtent: CellRenderer hintArrowExtent)
```

## Checking it

```smalltalk
| row space rect |
rect := CellClickRegionOutside regionRectangle.
row := BlElement new
	       layout: (BlLinearLayout horizontal cellSpacing: 20);
	       constraintsDo: [ :c | c horizontal fitContent. c vertical fitContent ];
	       padding: (BlInsets all: 20);
	       background: Color white;
	       yourself.
{ rect topLeft. rect bottomLeft - (0 @ 1). CellClickRegionInside regionRectangle center } do: [ :point |
	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	element showPositionHintAt: point.
	row addChild: board ].
space := BlSpace new.
space root addChild: row.
space extent: 900 @ 160.
space title: 'Rotate hints'.
space show
```

Three copies of the demo board, the mirror of each hinted at a different point: the clockwise arrow, the counter clockwise one, and the north arrow of the inside region for comparison. Page 105 ends by saying the cosmetics need work and the names in the renderer are wrong; the names were dealt with in Section 3.5, and the cosmetics are pages 130 onward.

# Rotate A Mirror Cell

*Pages 107 to 110 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/107.html -->
<!-- http://squeak.preeminent.org/tut2007/html/108.html -->
<!-- http://squeak.preeminent.org/tut2007/html/109.html -->
<!-- http://squeak.preeminent.org/tut2007/html/110.html -->

The board knows which region a click falls in. This chapter makes a mirror turn, and page 107 says where to start: *focus on the model first, then the GUI*. Nothing here touches an element or an event; the clicking itself is Section 3.10.

The four pages are one story. Page 107 writes the rotation and a test for it, page 108 fires the laser at a turned mirror and the test fails, pages 108 and 109 walk a debugger through the failure, and page 110 fixes it with three lines. The bug is worth the walk: a mirror that turns its picture and forgets to turn its behaviour.

## The hook

Page 107 writes the message before deciding what it does, so that the test can decide:

```
rotateClockwise
```

An empty method on `MirrorCell`, in a protocol called *actions*, and a second one for the other direction. The port puts the empty pair one class higher, on `Cell`:

```smalltalk
Cell >> rotateClockwise
	"Turn me clockwise, which for a cell in general is nothing at all. Page 107 of the original
	puts the two rotate messages here so that a click in the outside region can send one without
	asking what kind of cell it hit; only a mirror has anything to turn."
```
```smalltalk
Cell >> rotateCounterClockwise
	"Turn me counter clockwise, which for a cell in general is nothing at all. See
	`rotateClockwise`."
```

because the outside region of any cell answers a rotate region, mirror or not, and Section 3.10 will send `rotateClockwise` to whatever cell was clicked. A blank cell that quietly ignores the message is simpler than a caller that asks first:

```smalltalk
BlankCellTestCase >> testRotatingACellThatIsNotAMirrorDoesNothing
	"Page 107 puts the two rotate messages on Cell, where they do nothing, so a click in the
	outside region of any cell can send them without asking what kind of cell it is. Only a mirror
	has anything to turn."

	| cell |
	cell := BlankCell new.
	cell gridLocation: 2 @ 3.
	cell laserEntersFrom: #north.
	cell rotateClockwise.
	cell rotateCounterClockwise.
	self assert: cell gridLocation equals: 2 @ 3.
	self assert: cell isOn.
	self assert: (cell exitSideFor: #north) equals: #south
```

Page 107 then notices that the two directions do the same thing to a mirror — a diagonal has two positions, and a quarter turn either way lands on the other one — and keeps the two methods anyway, in case the turn is ever animated, with one method underneath doing the work:

```smalltalk
MirrorCell >> rotateClockwise
	"Turn me clockwise. A quarter of a turn either way leaves my mirror on the same diagonal, so
	both directions do the same thing to me; page 107 keeps them apart anyway, in case the turn is
	ever animated, and lets one method do the work."

	self rotate
```
```smalltalk
MirrorCell >> rotateCounterClockwise
	"Turn me counter clockwise, which does the same to me as turning me clockwise. See
	`rotateClockwise`."

	self rotate
```

The work itself, as page 107 writes it, is one line:

```
rotate
	self leansLeft: self isLeft not
```

and the test of page 107 agrees with it:

```
testCellRotate
	| cell |
	cell := MirrorCell new.
	cell leanLeft.
	self should: [cell isLeft].
	cell rotateClockwise.
	self should: [cell isRight].
	cell rotateCounterClockwise.
	self should: [cell isLeft].
```

Green, and wrong. The test asks the mirror which way it leans, which is the question `rotate` answers, and never asks it where a beam goes.

## Where it breaks

Page 108 fires the laser at the demo grid, turns the mirror at 4@1 that the beam passes through, and expects the target to go dark. It stays lit. The two grid tests that page writes are in the package already, captured with the rest of Section 2's model:

```smalltalk
GridTestCase >> testFireLaserAfterMirrorRotation

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid stopLaser.
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 4 @ 1.
	self assert: cell isOff.
	grid rotateCellClockwiseAt: cell gridLocation.
	grid fireLaser.
	cell := grid at: 4 @ 1.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

with `testFireLaserDuringMirrorRotation` doing the same to a laser that is left on while the mirror turns. The demo grid sends its beam east along the top row into the mirror at 4@1, which leans right and turns the beam south into the target at 5@1; turn that mirror and the beam should go west instead, leaving the target dark.

## Making the model say more

The debugger of page 108 shows a temporary variable holding `a MirrorCell` and nothing else, which is where the page stops to fix its tools rather than its bug. It adds a *printing* protocol and a method:

```
printOn: aStream
	super printOn: aStream.
	aStream
		cr;
		nextPutAll: '   location = ', self gridLocation asString;
		cr;
		nextPutAll: '   ';
		nextPutAll: (self isOn ifTrue: ['ON'] ifFalse: ['OFF'])
```

and the same for a path element:

```
printOn: aStream
	super printOn: aStream.
	aStream
		cr;
		nextPut: $(..
	self cell printOn: aStream.
	aStream
		cr;
		nextPutAll: 'entrySide = ', self entrySide asString;
		nextPut: $)
```

Three lines read well in the one place the page looks at them, the bottom pane of a Squeak debugger. Pharo prints an object in many more places — the header of an inspector, a row of a list, the result of a code pane, the failure message of a test — and a newline in any of those is noise. So the port says the same facts on one line, and splits the method in two so that a subclass adds its own detail without rewriting the frame:

```smalltalk
Cell >> printOn: aStream
	"Say where I am and whether the laser lights me, on one line. Page 108 of the original says the
	same on three, which reads well in a Squeak debugger pane and badly everywhere Pharo prints an
	object: a list, an inspector header, a code pane. What the page wanted from those extra lines
	is in my inspector tab instead."

	super printOn: aStream.
	aStream nextPut: $(.
	self printDetailsOn: aStream.
	aStream
		nextPutAll: ', ';
		nextPutAll: (self isOn ifTrue: [ 'on' ] ifFalse: [ 'off' ]);
		nextPut: $)
```
```smalltalk
Cell >> printDetailsOn: aStream
	"Print what distinguishes me from another cell of my kind at the same place. There is nothing
	but my location, so a mirror adds the way it leans. `Point >> printOn:` puts brackets round
	itself, which would read badly inside my own, so the two coordinates are printed by hand."

	aStream
		print: self gridLocation x;
		nextPut: $@;
		print: self gridLocation y
```
```smalltalk
MirrorCell >> printDetailsOn: aStream
	"Add the way I lean, which is the fact pages 109 and 110 are about."

	super printDetailsOn: aStream.
	aStream nextPutAll:
		(self isLeft ifTrue: [ ' leans left' ] ifFalse: [ ' leans right' ])
```

A blank cell prints `a BlankCell(2@3, off)`, and the mirror the next pages are about prints `a MirrorCell(4@1 leans right, off)` — which already says, on one line, both facts whose disagreement is the bug.

```smalltalk
BlankCellTestCase >> testPrintStringSaysWhereTheCellIsAndWhetherItIsOn
	"A cell that is not a mirror has no lean to report, so it prints its location and its state.
	Page 108 of the original prints the same two facts over three lines."

	| cell |
	cell := BlankCell new.
	cell gridLocation: 2 @ 3.
	self assert: cell printString equals: 'a BlankCell(2@3, off)'.
	cell laserEntersFrom: #north.
	self assert: cell printString equals: 'a BlankCell(2@3, on)'
```
```smalltalk
MirrorCellTestCase >> testPrintStringSaysWhereTheCellIsHowItLeansAndWhetherItIsOn
	"Page 108 of the original improves what a cell shows in a debugger. Pharo prints objects on
	one line, in lists, in inspector headers and in the code pane, so the port says the same
	things in one line and lets the inspector show the rest."

	| cell |
	cell := MirrorCell leanLeft.
	cell gridLocation: 4 @ 1.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans left, off)'.
	cell rotate.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans right, off)'.
	cell laserEntersFrom: #north.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans right, on)'
```

A path element names its cell and the side the beam comes in by:

```smalltalk
LaserPathElement >> printOn: aStream
	"Name the cell this step of the beam is about and the side the beam enters it from. Page 108 of
	the original prints the same over three lines."

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: self cell;
		nextPutAll: ' from ';
		nextPutAll: self entrySide asString;
		nextPut: $)
```
```smalltalk
LaserPathElementTestCase >> testPrintStringNamesTheCellAndTheSideTheBeamEntersFrom
	"Page 108 gives a path element a printOn: of its own, so a debugger says which cell the step is
	about. One line here, since that is where Pharo shows it."

	| element |
	element := LaserPathElement
		           cell: (MirrorCell leanRight gridLocation: 4 @ 1; yourself)
		           entrySide: #south.
	self
		assert: element printString
		equals:
		'a LaserPathElement(a MirrorCell(4@1 leans right, off) from south)'
```

## What the inspector can show

`printOn:` carries one line, and page 108 wanted more than one line: the state of the cell, its sides, the contents of `exitSides`. In Pharo that goes in an inspector tab, which is a method with a pragma and costs about as much as the print method did. A cell shows its four sides, where a beam entering by each of them leaves, and whether that side is lit:

```smalltalk
Cell >> inspectionSides: aBuilder
	"Show one row per side of me: where a beam entering there leaves, and whether that side is lit.
	Page 108 of the original wants this in a debugger and gets as far as printOn: can carry it;
	pages 109 and 110 then hunt a bug that is an exit side left unchanged, which is exactly what
	this table shows."

	<inspectorPresentationOrder: 1 title: 'Sides'>
	^ aBuilder newTable
		  items: #( #north #east #south #west );
		  addColumn: (SpStringTableColumn title: 'Enters from' evaluated: [ :each |
					   each asString ]);
		  addColumn: (SpStringTableColumn title: 'Leaves by' evaluated: [ :each |
					   (self exitSideFor: each)
						   ifNil: [ 'nowhere' ]
						   ifNotNil: [ :side | side asString ] ]);
		  addColumn: (SpStringTableColumn title: 'Lit' evaluated: [ :each |
					   (self isSegmentOnFor: each)
						   ifTrue: [ 'yes' ]
						   ifFalse: [ '' ] ]);
		  yourself
```
```smalltalk
MirrorCellTestCase >> testTheSidesTabListsTheFourSidesOfTheCell
	"Page 108 of the original wants a cell to say more about itself while it is being debugged. In
	Pharo that belongs in an inspector tab, and the tab has one row per side, which is where the
	bug of page 110 becomes visible: the exit sides of a rotated mirror."

	| cell table |
	cell := MirrorCell leanRight.
	cell gridLocation: 4 @ 1.
	table := cell inspectionSides:
		         (SpPresenterBuilder new
			          application: SpApplication new;
			          yourself).
	self assert: table items asArray equals: #( #north #east #south #west ).
	self assert: table columns size equals: 3
```

That table is the bug of page 109 in one view: rotate a mirror in an inspector, look at the tab again, and the lean has changed while the *Leaves by* column has not.

A grid can do better than describe itself, since Section 2 gave it an element that draws it. One tab is the board as a picture, the other is the beam, one row per step:

```smalltalk
Grid >> inspectionBoard: aBuilder
	"Show me as the board the player sees. Page 108 of the original opens a browser beside its
	debugger to make a cell say more about itself; a grid can do better than say anything, since
	Section 2 gave it an element that draws it."

	<inspectorPresentationOrder: 1 title: 'Board'>
	^ aBuilder newMorph
		  morph: (LaserGameBoardElement on: self) asPreviewMorph;
		  yourself
```
```smalltalk
Grid >> inspectionBeam: aBuilder
	"Show the path the laser takes, one row per step, which is the collection pages 108 and 109
	step through in a debugger."

	<inspectorPresentationOrder: 2 title: 'Beam'>
	^ aBuilder newTable
		  items: (self laserBeamPath ifNil: [ #(  ) ]);
		  addColumn: (SpStringTableColumn title: 'Cell' evaluated: [ :each |
					   each cell printString ]);
		  addColumn:
			  (SpStringTableColumn title: 'Enters from' evaluated: [ :each |
					   each entrySide asString ]);
		  yourself
```
```smalltalk
GridTestCase >> testTheInspectorTabsOfAGridShowTheBoardAndTheBeam
	"Where page 108 improves what a cell prints in a debugger, a grid can show the board itself and
	the path the laser takes, since Section 2 gave it an element that draws it. One row per step of
	the beam, and the board as a picture."

	| grid builder |
	grid := self generateDemoGrid.
	grid fireLaser.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	self
		assert: (grid inspectionBeam: builder) items size
		equals: grid laserBeamPath size.
	self assert: (grid inspectionBoard: builder) class equals: SpMorphPresenter
```

Page 108 opens a browser beside its debugger and steps through `fireLaser`, `activateCellsInPath` and `calculatePath` to see the path being built. Inspecting the grid shows the finished path without stepping into anything.

## The step that shows the bug

Page 109 steps into the method that answers the next step of the beam, which is where the wrong answer appears:

```smalltalk
LaserPathElement >> nextElementIn: aGrid
	| loc dirSym direction vector newLoc nextCell |
	loc := self cell gridLocation.
	dirSym := self cell exitSideFor: self entrySide.
	dirSym isNil ifTrue: [^nil].
	direction := GridDirection directionFor: dirSym.
	vector := direction vector.
	newLoc := loc + vector.
	nextCell := aGrid at: newLoc.
	^nextCell isNil
		ifTrue: [nil]
		ifFalse: [self class cell: nextCell entrySide: direction adjacentInversionSymbol]
```

`dirSym` comes back `#east` for the turned mirror where it should be `#west`. The page steps once more, into `exitSideFor:`, sees the `exitSides` dictionary in the bottom pane of the debugger, and has its clue: *when we rotate a mirror cell we have to adjust the exitSides dictionary*.

A debugger is how the original found that. Having found it, the port asks the same question as a test, at the same place:

```smalltalk
LaserPathElementTestCase >> testTheNextElementFollowsTheMirrorAfterItIsRotated
	"Pages 109 and 110: the beam kept leaving the rotated mirror on the side it left before,
	because rotating the cell did not touch its exit sides. This is the step the original stepped
	into, asked directly: the mirror at 4@1 of the demo grid sends a beam that enters from the
	south out to the east, and once it is turned, out to the west."

	| grid mirror element |
	grid := GridFactory demoGrid.
	mirror := grid at: 4 @ 1.
	element := LaserPathElement cell: mirror entrySide: #south.
	self assert: mirror isRight.
	self
		assert: (element nextElementIn: grid) cell
		equals: (grid at: 5 @ 1).
	mirror rotate.
	self
		assert: (element nextElementIn: grid) cell
		equals: (grid at: 3 @ 1)
```

It fails against page 107's `rotate` exactly as the grid test does, in three lines instead of a whole fired laser, and it names the fact that is wrong instead of the symptom two objects away.

## The improved test, and the fix

Page 109 rewrites the mirror test to ask the question it should have asked the first time. The version in the package is that test, with `assert:equals:` in place of `should:`, which reports the two sides when it fails:

```smalltalk
MirrorCellTestCase >> testCellRotate

	| cell |
	cell := MirrorCell new.
	cell leanLeft.
	self assert: cell isLeft.
	self assert: (cell exitSideFor: #south) equals: #west.
	cell rotateClockwise.
	self assert: cell isRight.
	self assert: (cell exitSideFor: #south) equals: #east.
	cell rotateCounterClockwise.
	self assert: cell isLeft.
	self assert: (cell exitSideFor: #south) equals: #west
```

Two tests are now red, and page 110 makes them green. The mirror already has two methods that set the lean and the four exit sides together, written back in Section 2 and used by `GridFactory` ever since:

```smalltalk
MirrorCell >> leanLeft
	self leansLeft: true.
	self exitSides at: #north put: #east.
	self exitSides at: #east put: #north.
	self exitSides at: #south put: #west.
	self exitSides at: #west put: #south.
```
```smalltalk
MirrorCell >> leanRight
	self leansLeft: false.
	self exitSides at: #north put: #west.
	self exitSides at: #east put: #south.
	self exitSides at: #south put: #east.
	self exitSides at: #west put: #north.
```

so `rotate` has only to use them:

```smalltalk
MirrorCell >> rotate
	"Turn me a quarter of a turn, which puts my mirror on the other diagonal. Page 107 of the
	original writes this as `leansLeft: self isLeft not`, and pages 108 to 110 spend three pages
	finding out why the laser then leaves me on the side it left before: the lean changed and my
	exit sides did not. `leanLeft` and `leanRight` set both, so the fix of page 110 is to use them."

	self isLeft
		ifTrue: [ self leanRight ]
		ifFalse: [ self leanLeft ]
```

That is the whole fix. The bug was a second copy of one fact — which way the mirror leans, written once in `leansLeft` and once in `exitSides` — and the cure is to let the one method that keeps both in step do the writing.

Two tidies come with it, both of them things this chapter's reading of the model turned up. The class-side constructors sent `super new`, which reaches past `MirrorCell class` for no reason:

```smalltalk
MirrorCell class >> leanLeft
	"Answer a mirror on the diagonal from my top left corner to my bottom right one."

	^ self new leanLeft
```

and `Cell`, which has never been meant to be instantiated, now says so where every subclass answers differently:

```smalltalk
Cell >> initializeExitSides
	"Fill exitSides with the side a beam leaves by for each side it can enter from. Every
	subclass answers this differently, which is what makes a cell blank, a mirror or a target,
	so I am abstract here."

	^ self subclassResponsibility
```

`Cell`, `MirrorCell`, `Grid` and `LaserPathElement` also get the class comments they have been missing since 2007 — page 108's own screenshot of the `Cell` definition says THIS CLASS HAS NO COMMENT in red.

## Checking it

```smalltalk
| grid |
grid := GridFactory demoGrid.
grid fireLaser.
grid inspect
```

The *Board* tab shows the beam crossing the top row into the target, and the *Beam* tab lists the path a step at a time, each row printing its cell. Rotate the mirror from the code pane of the inspector,

```smalltalk
| grid |
grid := GridFactory demoGrid.
grid fireLaser.
grid rotateCellClockwiseAt: 4 @ 1.
grid inspect
```

and the board redraws with the beam going west and the target dark, which is what pages 108 to 110 were trying to see.

Next is page 111, which finally connects a mouse click to the turn.

# Click And Rotate A Cell

*Pages 111 to 115 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/111.html -->
<!-- http://squeak.preeminent.org/tut2007/html/112.html -->
<!-- http://squeak.preeminent.org/tut2007/html/113.html -->
<!-- http://squeak.preeminent.org/tut2007/html/114.html -->
<!-- http://squeak.preeminent.org/tut2007/html/115.html -->

A mirror knows how to turn and the board knows which region a click falls in. This chapter joins the two, and at the end of it the game is playable with a mouse.

The original spends the five pages on three things: deciding that the action belongs to the mouse *up* event and only when the press and the release fall in the same cell, recapping the pattern the hint code already follows, and then walking the mouse up down that same chain — morph, renderer, click region, cell.

## A click is a press and a release in the same cell

Page 111 logs the raw events and reads the log. Moving with the button down carries the pointer from one cell into the next, so a release is not by itself a click on the cell it happens in: *if you exit the cell you click-down on while still holding the button, you expect the click to be ignored*.

Page 112 implements that. The morph gets an instance variable, `activeCellLocation`, set on mouse down:

```
mouseDown: evt forMorph: aSketchMorph
	| cell |
	cell := self cellForEvent: evt.
	cell isNil
		ifTrue: [self activeCellLocation: nil]
		ifFalse: [self activeCellLocation: cell gridLocation].
```

and compared on mouse up, which then clears it again:

```
mouseUp: evt forMorph: aSketchMorph
	| cell |
	cell := self cellForEvent: evt.
	cell isNil ifFalse: [
		self activeCellLocation = cell gridLocation
			ifTrue: [self eventDiagnosticFor: evt tag: 'Mouse Up MATCHED']
			ifFalse: [self eventDiagnosticFor: evt tag: 'Mouse Up UNMATCHED']
		].
	self activeCellLocation: nil
```

That rule is `BlClickEvent`. Bloc raises it on the element the press started in, and only when the release lands in the same element, so the port has nothing to record and nothing to compare. The cell element has listened for the event since Section 3.2:

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

What the handler does with the event is all this section changes about it: the position of the click inside the cell decides what the click means, exactly as the position of the pointer decides which hint is drawn.

```smalltalk
LaserGameCellElement >> click: anEvent
	"A click landed on me: a press and a release in the same cell, which the original checked by
	keeping the location of the press in activeCellLocation and comparing it on mouse up. The
	point the event carries is in my own coordinates, and it decides what the click does."

	self clickAt: anEvent localPosition
```

and the board has recorded the clicked cell since then too:

```smalltalk
LaserGameBoardElement >> clickCellElement: aCellElement
	"Record the cell of aCellElement as the one just clicked. A cell tells me this when a click
	lands on it, that is when a press and a release fall in the same cell."

	clickedCell := aCellElement cell
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

So this section deletes `LaserGame >> activeCellLocation`, its setter and the instance variable behind it, together with the two sends left in `reset` and `newGame`. Page 112's bookkeeping has no work to do here.

## The same walk, one event later

Page 113 stops to read the path a hint takes: the morph finds the cell under the pointer, asks `CellRenderer` for the renderer of that cell, and hands it a board relative position; the renderer subtracts the offset of its cell, asks `CellClickRegion` which region the remaining point is in, and asks that region for a picture. Its conclusion is the design note of the whole section: *a combination of renderer and click-region hierarchies were used to resolve the "case statement" decision logic*. There is almost no `ifTrue:`/`ifFalse:` in any of it.

Page 114 sends the mouse up down the same chain. The morph gets a second `mouseUp:forMorph:` that takes the cell it belongs to,

```
mouseUp: evt forMorph: aSketchMorph cell: aCell
	| renderer pixelPositionWithinBoard |
	renderer := CellRenderer rendererFor: aCell grid: self grid form: self boardForm.
	pixelPositionWithinBoard := self boardRelativePositionFor: evt.
	renderer mouseUpWithinBoardOffset: pixelPositionWithinBoard.
```

the renderer superclass answers it with an empty method, and only the mirror renderer does anything with it.

The port has the same pair, named after what the element hands over — a point already in the coordinates of the cell — and answering the cell that was acted on, or nil when nothing happened:

```smalltalk
CellRenderer >> mouseUpAt: aPoint
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when nothing happened. Nothing happens here: only a mirror answers a click, which is
	page 114 of the original — the renderer superclass does nothing, and only the mirror renderer
	deals with the request."

	^ nil
```
```smalltalk
MirrorCellRenderer >> mouseUpAt: aPoint
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when the region aPoint falls in can do nothing. The region decides both questions: the
	outside region turns my mirror one way or the other, the inside region pushes it when there
	is room, and the ignore margin does nothing. Page 114 of the original passes the cell and the
	grid down to the region for exactly this reason: a region knows what a click means, and
	nothing else does."

	| region |
	region := CellClickRegion clickRegionForPoint: aPoint.
	^ (region
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [
		  region
			  mouseUpWithinCellAtPoint: aPoint
			  cell: self cell
			  withinGrid: self grid ]
		  ifFalse: [ nil ]
```

This is the shape `hintRegionAt:` has had since Section 3.6, one event later: every renderer is asked, all but the mirror answer nothing, and the mirror asks the region.

The region side is page 114's too. It writes the handler on the superclass first, where it does nothing,

```
mouseUpWithinCellAtPoint: aPoint cell: aCell
```

and on the outside region, which refines the point to one of its two halves and passes the cell on:

```
mouseUpWithinCellAtPoint: aPoint cell: aCell
	| rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	rotateRegion mouseUpForCell: aCell
```

The captured source takes the grid along as well, since a push and a rotation are both recorded on it, and the three methods in the image read:

```smalltalk
CellClickRegion class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	^aCell
```
```smalltalk
CellClickRegionOutside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	| rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	^rotateRegion mouseUpForCell: aCell withinGrid: aGrid
```
```smalltalk
CellClickRegionInside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^pushRegion mouseUpForCell: aCell withinGrid: aGrid
```

Page 114 explains why the cell travels down with the message: *the MirrorCellRenderer knows about the cell object. The click-region classes do not.* A region is a piece of geometry with an opinion about what a click there means, and it is given everything it needs to act.

One method is new here. A region is also the right place to ask whether a click can do anything at all, and the ignore margin has to answer that question without a special case around it:

```smalltalk
CellClickRegion class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	"Answer whether a click at aPoint can do anything to aCell. Nothing can be done in me: the
	ignore margin is a region where a click is a click on nothing, and the inside and outside
	regions each answer for the region the point really falls in. Page 114 of the original says
	the same of the mouse up handler it writes here: this guy will do nothing."

	^ false
```

The two refining regions already answered it — the outside region always can, since a mirror always turns, and the inside region asks the push region whether there is room:

```smalltalk
CellClickRegionOutside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	^true
```
```smalltalk
CellClickRegionInside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion canPushCell: aCell withinGrid: aGrid
```

so with `^ false` on the superclass the ignore region answers too, and `mouseUpAt:` needs no test of its own for it.

## Turning the mirror

Page 115 finishes the chain. The two rotate regions have the easiest methods in the section, because Section 3.9 already gave the mirror everything:

```
mouseUpForCell: aCell
	aCell rotateClockwise
```

The captured versions send the turn to the grid instead of to the cell, so that the move is recorded for the undo of Section 5:

```smalltalk
CellClickRegionRotateClockwise class >> mouseUpForCell: aCell withinGrid: aGrid
	aGrid rotateCellClockwiseAt: aCell gridLocation.
	^aCell
```
```smalltalk
CellClickRegionRotateCounterClockwise class >> mouseUpForCell: aCell withinGrid: aGrid
	aGrid rotateCellCounterClockwiseAt: aCell gridLocation.
	^aCell
```

What is left is drawing the result. The original adds `self redrawCell` to the mirror renderer and `self changed` to the morph,

```
mouseUpWithinBoardOffset: aPoint
	| cellPosn offsetWithinCell regionClass |
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell.
	regionClass mouseUpWithinCellAtPoint: offsetWithinCell cell: self cell.
	self redrawCell
```

which repaints one cell of the board form. That is not enough for a mirror that stands on the beam: turning it moves the beam, and the cells the beam has left are still painted as lit — a bug the original meets later, under the pushing of a cell. The port draws every cell again after an action, and lets the cheapness of an element tree pay for it:

```
LaserGameCellElement >> clickAt: aPoint
	"Act on a click at aPoint, in my own coordinates. My board records that I was clicked, my
	renderer decides whether my cell acts and which region handles it, and the board draws itself
	again when something changed. The original walked the same chain from the morph to the
	renderer to the click region; it started from a board offset, where this starts from a point
	Bloc already expressed in the cell."

	self board ifNotNil: [ :board | board clickCellElement: self ].
	(self renderer mouseUpAt: aPoint) ifNil: [ ^ self ].
	self board ifNotNil: [ :board | board redrawCells ]
```

This is the method as this chapter writes it; Section 4.4 has it tell the board that a move was made instead of asking it to redraw, so that the counters of page 142 hear about the move too.
```smalltalk
LaserGameBoardElement >> redrawCells
	"Draw every cell again. One action on one cell changes more than that cell: a turned mirror
	sends the beam somewhere else, and a pushed mirror leaves its old place empty, so nothing
	tries to work out which cells are affected."

	self children do: [ :each | each redraw ]
```
```
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again; my hint is
	kept, because the pointer has not moved. The original repainted a rectangle of the board form
	and called it redrawCell."

	| grid location region |
	grid := self renderer grid.
	location := self gridLocation.
	region := hintRegion.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	hintRegion := region.
	self updateHintElement
```

This is the method as this chapter writes it; Section 3.14 changes the two lines about the hint, which is read again from the cell that stands here rather than kept.

A cell element keeps its identity through a redraw: the pointer is still in it, so its hint is kept, but the renderer is chosen again, because a push swaps the cell at this location for another one and the drawing depends on the class of that cell. What the original needed `redrawCell` and `self changed` for, Bloc does from the change to the children.

Page 115 ends with an accessor the renderer needs, `cell`. The port has had it since Section 2.9, where it was already written as a question to the grid:

```smalltalk
CellRenderer >> cell
	^self grid at: self cellLocation.
```

## The push that comes with it

Page 114 deliberately leaves one message unsent: *the inside region. We'll leave off the sending of the #mouseUpForCell: message here since we're not ready to deal with cell push just yet.* The port cannot leave it unsent. The captured source has `mouseUpForCell:withinGrid:` on all six leaf regions and `canPushCell:withinGrid:` on the four push ones,

```smalltalk
CellClickRegionPushNorth class >> canPushCell: aCell withinGrid: aGrid
	^aGrid canPushCellNorthFromLocation: aCell gridLocation
```
```smalltalk
CellClickRegionPushNorth class >> mouseUpForCell: aCell withinGrid: aGrid
	^aGrid pushCellNorthFromLocation: aCell gridLocation
```

and the inside region's `mouseUpWithinCellAtPoint:cell:withinGrid:`, quoted above, already passes the click on to them. The same three methods that make a click turn a mirror therefore make a click push one, four pages before page 122 gets there. The guard keeps it honest — a push into an occupied cell or off the board cannot happen, because the region says the action is impossible before the click is passed on. Pages 122 to 126 still have their own work: the push hints, the counters, and the visual bug of page 127.

## Tests

A click in the upper half of the outside region turns the mirror clockwise, and in the lower half counter clockwise. Both leave the mirror on the other diagonal, so the direction is read from the move the grid recorded:

```smalltalk
LaserGameCellElementTestCase >> testClickingTheUpperOutsideRegionOfAMirrorTurnsItClockwise
	"Page 115 of the original: a click in the outside region turns the mirror, and the upper half
	turns it clockwise. The click carries a point in the coordinates of the cell, which is the
	whole of what the region needs."

	| board element mirror |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	self assert: mirror isRight.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: mirror isLeft.
	self assert: board grid movesStack last key equals: #clockwise
```
```smalltalk
LaserGameCellElementTestCase >> testClickingTheLowerOutsideRegionOfAMirrorTurnsItCounterClockwise
	"The other half of page 115. The mirror ends up on the same diagonal either way, so the
	direction is read from the move the grid records. The last row of the outside rectangle
	belongs to the ignore margin, as `Rectangle >> containsPoint:` leaves its bottom edge out,
	so the point is taken one pixel above it."

	| board element mirror |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle bottomLeft - (0 @ 1);
			 yourself).
	self assert: mirror isLeft.
	self assert: board grid movesStack last key equals: #counterClockwise
```

Nothing happens in the ignore margin, and nothing happens on a cell that is not a mirror, wherever it is clicked:

```smalltalk
LaserGameCellElementTestCase >> testClickingTheIgnoreRegionOfAMirrorDoesNothing
	"The margin around the outside region shows no hint and does nothing when it is clicked.
	The superclass of the regions answers that no action is possible, which is where the ignore
	region gets its answer from."

	| board element mirror |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	mirror := element cell.
	element dispatchEvent: (BlClickEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: mirror isRight.
	self assert: board grid movesStack isEmpty.
	self assert: board clickedCell identicalTo: mirror
```
```smalltalk
LaserGameCellElementTestCase >> testClickingACellThatIsNotAMirrorDoesNothing
	"Only a mirror acts on a click. A blank cell and the target answer nothing wherever they are
	clicked, which is page 114's rule that the renderer superclass does nothing."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	#( 1 5 ) do: [ :column |
		| element |
		element := board cellElementAt: column @ 1.
		element dispatchEvent: (BlClickEvent new
				 position: CellClickRegionInside regionRectangle center;
				 yourself).
		element dispatchEvent: (BlClickEvent new
				 position: CellClickRegionOutside regionRectangle topLeft;
				 yourself).
		self assert: board clickedCell identicalTo: element cell ].
	self assert: board grid movesStack isEmpty
```

One click changes more than one cell, which is what the redraw of the whole board is for:

```
LaserGameCellElementTestCase >> testTurningAMirrorOnTheBeamRedrawsTheWholeBoard
	"One click changes more than one cell: the mirror at 4@1 sends the beam into the target at
	5@1, and turning it sends the beam west instead. Every cell is drawn again after an action,
	so the target goes dark without anything working out which cells the beam left."

	| grid board target |
	grid := GridFactory demoGrid.
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	target := board cellElementAt: 5 @ 1.
	self
		assert: target children fourth background paint color
		equals: LaserGameColors targetCenterColorActive.
	(board cellElementAt: 4 @ 1) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self
		assert: (board cellElementAt: 5 @ 1) children fourth background paint color
		equals: LaserGameColors targetCenterColorIdle
```
> **Note.** *Laser On Target Cell*, in Section 4, draws the beam under the picture of the target, so this test reads the disc as the last child of the cell and its comment says so.

and a click inside a mirror pushes it, which is the part that runs ahead of the original:

```smalltalk
LaserGameCellElementTestCase >> testClickingTheInsideRegionOfAMirrorPushesIt
	"The inside region pushes, which page 114 leaves unsent until page 122. The port cannot leave
	it unsent: the click regions came with `mouseUpForCell:withinGrid:` already written on all six
	of them, so the same wiring that turns a mirror also pushes one. A push region is named after
	the side the cell is pushed from, so the lower triangle pushes north; the mirror at 1@2 has a
	blank cell above it, and after the click each of the two cell elements draws what now stands
	in it."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 1 @ 2.
	self assert: element cell class equals: MirrorCell.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: (board grid at: 1 @ 1) class equals: MirrorCell.
	self assert: (board grid at: 1 @ 2) class equals: BlankCell.
	self
		assert: (board cellElementAt: 1 @ 1) renderer class
		equals: MirrorCellRenderer.
	self
		assert: (board cellElementAt: 1 @ 2) renderer class
		equals: BlankCellRenderer
```

## Checking it

```smalltalk
| grid space board |
grid := GridFactory demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space root addChild: board.
space extent: 300 @ 300.
space title: 'Click and rotate'.
space show
```

Click the edge of a mirror and it turns; click near its middle and it moves, if there is room. Page 115 says the same of its own morph — *try clicking in the rotate regions of mirror cells. It works* — and then lists what is still wrong: hint arrows left behind when the pointer leaves a cell quickly, and cells that stay lit after a mirror moves. The first of those is page 116 and the next chapter; the second is page 127.

# Clean Up Left-Over Hints

*Pages 116 to 117 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/116.html -->
<!-- http://squeak.preeminent.org/tut2007/html/117.html -->

*There are "ghost" rotation arrows being left on cells.* The screenshot on page 116 shows four of them at once, on cells the cursor passed over and left long ago. The push arrows are never left behind, only the rotation ones, which is what makes the author call it a subtle bug.

## Reading the log

Page 116 first suspects the geometry: a cursor that enters the ignore margin after being in the outside region, perhaps, leaving an arrow with no event to clean it. The hint drawing code says otherwise, since it repaints the cell before it decides whether to draw anything:

```
showPositionHintFromWithinBoardOffset: aPoint
	| cellPosn offsetWithinCell regionClass arrow offset arrowAndOffset |
	self redrawCell.
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell.
	arrowAndOffset := regionClass scaledHintArrowAndOffsetFromWithinCell: offsetWithinCell.
	arrowAndOffset isNil ifTrue: [^self].
	arrow := arrowAndOffset value.
	offset := arrowAndOffset key.
	offset := self offsetWithinGridForm + offset.
	arrow
		displayOn: self targetForm
		at: offset
		clippingBox: self targetForm computeBoundingBox
		rule: Form oldPaint
		fillColor: Color gray.
```

So the author writes the diagnostics instead, extracting `offsetWithinCellFromWithinBoardOffset:` onto `CellRenderer` first so that both implementors can log the same two facts, and moves the cursor quickly down a column with a Transcript open. The log is the answer. Starting on the target cell at 5@1 and moving south, it reports the ignore region of 5@2, then the outside region of 5@2 — and then the **inside** region of 5@3. Two cells, five region transitions, nothing in between.

Page 116 draws the conclusion in one sentence: *mouse move events can be pretty far apart when the cursor is traveling quickly*. The operating system samples the mouse, the image processes what it is given, and no intermediate event is promised. A cell can be entered and left without the game ever hearing about it, and whatever was painted on it stays.

## Two strategies

Page 117 weighs two fixes. The simple one is to redraw every cell of the board before any hint is drawn, at the cost of repainting cells nothing ever touched. The elaborate one keeps a dirty flag per cell, set when a hint is drawn on it, and sweeps the flagged cells clean just before the next hint. The author picks the second, and puts the flags on the `LaserGame` morph, *since it's managing the events anyway* — not on the cells, which are model objects, and not on the renderers, which are made on the fly and keep no state.

That is a `Dictionary` on the morph, three methods around it,

```
setDirty: aCell
	self dirty at: aCell gridLocation put: true

setClean: aCell
	self dirty removeKey: aCell gridLocation ifAbsent: []

isDirty: aCell
	^self dirty at: aCell gridLocation ifAbsent: [false]
```

the sweep itself,

```
sweepDirtyCells
	| cell renderer |
	1 to: self grid numberOfColumns do: [:x |
		1 to: self grid numberOfRows do: [:y |
			cell := self grid at: x@y.
			(self isDirty: cell) ifTrue: [
				renderer := CellRenderer rendererFor: cell grid: self grid form: self boardForm.
				renderer redrawCell.
				self setClean: cell
				]]].
```

and two lines around the hint drawing:

```
mouseMoveWhileButtonUp: evt forMorph: aSketchMorph
	| cell renderer pixelPositionWithinBoard |
	cell := self cellForEvent: evt.
	renderer := CellRenderer rendererFor: cell grid: self grid form: self boardForm.
	pixelPositionWithinBoard := self boardRelativePositionFor: evt.
	self sweepDirtyCells.
	renderer showPositionHintFromWithinBoardOffset: pixelPositionWithinBoard.
	self setDirty: cell.
	self changed
```

`redrawCell` then moves from the mirror renderer up to `CellRenderer`, since the sweep repaints cells of any kind, the diagnostics come out again, and the repaint at the top of the hint method goes, because the sweep has done it. One ghost survives all this — the cursor leaving the grid entirely, which no cell hears — and page 117 adds a sweep on the way out of the morph for it.

## What the port keeps of this

The port cannot have the bug in the same shape. An arrow here is a child element of the cell that shows it, not paint on a shared form, so nothing needs cleaning off: when the hint of a cell goes, the element goes with it. The question left is the one page 116 really uncovered, and it is about events, not drawing: **is a cell always told that the pointer left it?**

Bloc answers yes. The mouse processor hit-tests each move it is given and works out the enter and leave events from the change, so a pointer that jumps from one cell to a far one still produces the leave of the first. There is no need to guess which cells were crossed, because the only thing that matters is which cell was under the pointer before and which is under it now. That is why the port has needed no sweep so far:

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
```
```
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me, so the arrow goes too."

	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
```

This is the method as this chapter writes it; Section 3.14 adds the line that forgets that point as well.

Relying on that alone would leave the port resting on a promise from the event system, which is exactly the kind of assumption page 116 punishes. So the board takes page 117's strategy, in the smallest form it has here. The board knows which cell it hovers, and at most one cell holds a hint, so its dictionary of dirty cells is one variable and its sweep is one line:

```smalltalk
LaserGameBoardElement >> hoverCellElement: aCellElement
	"Remember that the pointer is over aCellElement. A cell tells me this when the pointer enters
	it and while it moves inside it. The cell I hovered before loses its hint here: page 116 shows
	that mouse moves are samples, so cells the pointer crossed quickly are never told they were
	left, and page 117 answers that with a sweep over the cells marked dirty. One cell can hold a
	hint at a time, so the sweep is this one line."

	hoveredCellElement == aCellElement ifTrue: [ ^ self ].
	hoveredCellElement ifNotNil: [ :each | each clearPositionHint ].
	hoveredCellElement := aCellElement
```

A cell tells its board that it is hovered on every enter and on every move inside it, so this runs before any hint is shown, in the same place the original's `sweepDirtyCells` ran. If the leave arrived, the previous cell is already clean and `clearPositionHint` returns at once; if it did not, this is where the arrow goes. The counterpart is unchanged, and still guards against the enter of the new cell arriving before the leave of the old one:

```smalltalk
LaserGameBoardElement >> unhoverCellElement: aCellElement
	"Forget the pointer position, but only when aCellElement is the cell I hover. Moving from
	one cell to the next can deliver the enter of the new cell before the leave of the old one."

	hoveredCellElement == aCellElement ifTrue: [ hoveredCellElement := nil ]
```

Page 117's last ghost, the cursor leaving the grid, needs nothing: leaving the board means leaving a cell of it, and the cell is told.

## Tests

The first test is the skipped event of page 116, written directly: one cell is given a move, then another one is, and no leave is ever delivered. This is the test that fails without the line added to `hoverCellElement:`.

```smalltalk
LaserGameCellElementTestCase >> testHoveringAnotherCellClearsTheHintOfTheOneLeftBehind
	"Page 116: the pointer moves fast, the mouse moves are sampled, and cells are skipped, so a
	cell can be left without ever being told. The board hovers one cell at a time, so the cell it
	hovered before loses its hint when another one takes its place, whatever events were missed."

	| board first second |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	first := board cellElementAt: 4 @ 1.
	second := board cellElementAt: 1 @ 2.
	first dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: (first children includes: first hintElement).
	second dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: first hintRegion isNil.
	self assert: first hintElement isNil.
	self assert: (second children includes: second hintElement)
```

The second and the third leave the events to Bloc. They run in a real space on a headless host, so the enter and leave events come from the mouse processor, and the moves are simulated with `BlEventSimulator`, which speaks in space coordinates:

```smalltalk
LaserGameHintEventTestCase >> setUp
	"Open a headless space on a board of the demo grid. The space is what makes the mouse
	processor of Bloc deliver the enter and leave events my tests rely on."

	| aSpace |
	super setUp.
	board := LaserGameBoardElement on: GridFactory demoGrid.
	aSpace := self newTestingSpace.
	aSpace root addChild: board.
	aSpace settle
```
```smalltalk
LaserGameHintEventTestCase >> positionInCellAt: aGridLocation offset: aPoint
	"Answer the position in space coordinates of the point aPoint of the cell at aGridLocation.
	The event simulator speaks in space coordinates; a renderer and a click region speak in the
	coordinates of one cell, which is what aPoint is in."

	^ (board cellElementAt: aGridLocation) bounds inSpace bounds origin + aPoint
```
```smalltalk
LaserGameHintEventTestCase >> cellElementsShowingAHint
	"Answer the cell elements of my board that hold a hint arrow."

	^ board children select: [ :each | each hintElement notNil ]
```

Two moves, far apart, are all the space is given — the log of page 116 with everything in between missing — and one arrow only is on the board afterwards:

```smalltalk
LaserGameHintEventTestCase >> testMovingQuicklyToADistantCellLeavesNoArrowBehind
	"Page 116 moves the cursor swiftly down a column and finds in the log that whole cells were
	skipped: the game is told about 5@2 and then about 5@3, with nothing in between. Here the two
	moves are the only ones the space is given, and the mirror that was left keeps no arrow."

	| first second |
	first := board cellElementAt: 4 @ 1.
	second := board cellElementAt: 1 @ 2.
	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 4 @ 1 offset: CellClickRegionInside regionRectangle center).
	self assert: first hintElement notNil.
	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 1 @ 2 offset: CellClickRegionInside regionRectangle center).
	self assert: first hintElement isNil.
	self assert: second hintElement notNil.
	self assert: self cellElementsShowingAHint asArray equals: { second }
```

and the cursor that leaves the board entirely takes its arrow with it:

```smalltalk
LaserGameHintEventTestCase >> testMovingOffTheBoardClearsTheArrow
	"Page 117 ends with one last ghost: the cursor leaves the grid entirely, so no cell is told to
	clean itself. Bloc sends the leave of the cell under the pointer whatever is under it next, so
	the arrow goes and the board hovers nothing."

	board eventSimulator mouseMoveAt:
		(self positionInCellAt: 4 @ 1 offset: CellClickRegionInside regionRectangle center).
	self assert: (board cellElementAt: 4 @ 1) hintElement notNil.
	board eventSimulator mouseMoveAt: board bounds inSpace bounds bottomRight + (20 @ 20).
	self assert: self cellElementsShowingAHint isEmpty.
	self assert: board hoveredCellElement isNil
```

## What this deletes

The dirty machinery is captured in `LaserGame` from the original, and the port has no use for it: `dirty`, `dirty:`, `initializeDirty`, `setDirty:`, `setClean:`, `isDirty:`, `sweepDirtyCells` and `redrawCell:` are deleted, with the instance variable behind them and the two sends left in `reset` and `newGame`. `redrawCell` goes with them, from `CellRenderer` and from `MirrorCellRenderer` both: it repainted a rectangle of the board form, and `LaserGameCellElement >> redraw` of the previous section replaced it. Nothing sends any of them afterwards.

## Checking it

```smalltalk
| grid space board |
grid := GridFactory demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space root addChild: board.
space extent: 300 @ 300.
space title: 'Ghost arrows'.
space show
```

Move the pointer across the board as fast as you can, in and out of the mirrors, and off the board and back. One arrow at a time, and none left behind. The next bug is the one page 118 opens with: a target that stays lit after the mirror feeding it has been turned away.

# Bug With Target Cell

*Pages 118 to 121 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/118.html -->
<!-- http://squeak.preeminent.org/tut2007/html/119.html -->
<!-- http://squeak.preeminent.org/tut2007/html/120.html -->
<!-- http://squeak.preeminent.org/tut2007/html/121.html -->

Fire the laser, let the target light up, then turn the mirror that feeds it. The beam goes somewhere else, and the target stays lit.

Page 118 states the rule the game will need one day — *my own preference would be to inhibit the modification of cells on the grid while the laser is active* — and then puts it aside: the target being lit by nothing is wrong whatever the rule turns out to be.

## Where the wrong answer lives

The first question of page 118 is whether the fault is in the model or in the drawing. The original answers it with the tools of a Squeak image: cover the morph with a Workspace and uncover it, so that it repaints. The target is still lit, so it is not a stale picture. Then command-click for the halos, take the wrench menu, *explore morph*, and walk the explorer down through `grid` to `cells`. There it is, in a list of every cell: `5@1: a TargetCell location = 5@1 ON`.

The port reads the same list from a tab, because Section 3.9 put the board and the beam in the inspector already, and the cells are the third view of the same object:

```smalltalk
Grid >> inspectionCells: aBuilder
	"Show one row per cell of me, in the order the board lays them out, with what the cell is and
	whether it is lit. Page 118 of the original reaches the same list through the halos of the
	morph, an object explorer and two clicks on the arrow beside `cells` — and reads in it that
	the target is on while nothing lights it."

	<inspectorPresentationOrder: 3 title: 'Cells'>
	| everyCell |
	everyCell := OrderedCollection new.
	1 to: self numberOfRows do: [ :row |
		1 to: self numberOfColumns do: [ :column |
			everyCell add: (self at: column @ row) ] ].
	^ aBuilder newTable
		  items: everyCell;
		  addColumn: (SpStringTableColumn title: 'Cell' evaluated: [ :each |
					   each printString ]);
		  addColumn: (SpStringTableColumn title: 'Lit' evaluated: [ :each |
					   each isOn
						   ifTrue: [ 'yes' ]
						   ifFalse: [ '' ] ]);
		  yourself
```

```smalltalk
| grid |
grid := GridFactory demoGrid.
grid fireLaser.
grid rotateCellCounterClockwiseAt: 4 @ 1.
grid inspect
```

Turn the mirror at 4@1 with the laser on, and the Cells tab says in one row what page 118 needed halos, an explorer and two clicks on an arrow to reach. Page 119 adds a warning worth keeping: the author had changed two things — turned a mirror *and* stopped the laser — and notes that a bug seen after two changes may belong to either.

## The test that reproduces it

Page 119 then does the right thing, which is to stop looking at the screen. There is a test for rotation already:

```smalltalk
GridTestCase >> testFireLaserAfterMirrorRotation

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid stopLaser.
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 4 @ 1.
	self assert: cell isOff.
	grid rotateCellClockwiseAt: cell gridLocation.
	grid fireLaser.
	cell := grid at: 4 @ 1.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

but read what it does: `stopLaser` comes before the rotation, and `fireLaser` after it. *The test rotates the mirror while the laser beam is off. That's not what we did.* So the page writes the missing one, which turns the mirror with the beam running:

```smalltalk
GridTestCase >> testFireLaserDuringMirrorRotation

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	cell := grid at: 4 @ 1.
	grid rotateCellCounterClockwiseAt: cell gridLocation.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

*And the good news is that this unit test produces a failure.* The bug is now a red test, and the screen is no longer needed.

## The fix, and where it belongs

Page 120 steps into `rotate` in the debugger and finds it does exactly what it says and no more: the mirror turns. Nothing recalculates the beam, because *the design of a Cell doesn't include any awareness of the Grid* — and it should not; a cell that knew its grid could not be pushed from one place to another without telling it.

The answer is to give the grid the rotation, and let the cell keep the turn:

```smalltalk
Grid >> rotateCellClockwiseAt: aPoint
	"Turn the cell at aPoint clockwise. The beam is taken off the board first and put back
	afterwards if the laser is on, so the cells it lit before the turn go dark and the cells on the
	new path light up. The turn is recorded for the undo of Section 5."

	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateClockwise.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	self stackAction: #clockwise forCell: cell
```
```smalltalk
Grid >> rotateCellCounterClockwiseAt: aPoint
	"Turn the cell at aPoint counter clockwise. See `rotateCellClockwiseAt:`; only the action
	recorded for the undo differs."

	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateCounterClockwise.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	self stackAction: #counterClockwise forCell: cell
```

`clearCellsInPath` takes the beam off the cells it lights, the cell turns, and `activateCellsInPath` puts the beam back on the cells the new path reaches — both of them recalculating the path first:

```smalltalk
Grid >> clearCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe clearCell]
```
```smalltalk
Grid >> activateCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe activateCell]
```

The last line of each is this port's own: the turn is recorded on the stack Section 5 undoes from. The original's methods are the first four lines exactly.

Page 120 also puts an empty `rotateClockwise` and `rotateCounterClockwise` on `Cell`, so that the grid can send the turn to whatever stands at a location without asking what it is, and only the mirror does anything with it:

```smalltalk
Cell >> rotateClockwise
	"Turn me clockwise, which for a cell in general is nothing at all. Page 107 of the original
	puts the two rotate messages here so that a click in the outside region can send one without
	asking what kind of cell it hit; only a mirror has anything to turn."
```
```smalltalk
Cell >> rotateCounterClockwise
	"Turn me counter clockwise, which for a cell in general is nothing at all. See
	`rotateClockwise`."
```

and it changes the two grid tests to go through the new protocol — which is why `grid rotateCellCounterClockwiseAt:` reads in the test quoted above where page 119 first wrote `cell rotateClockwise`. Page 120 ends with everything green.

## Sending the grid down the chain

Page 121 spends itself on plumbing that this port has already laid. The click has to reach `rotateCellClockwiseAt:`, which lives on the grid, and the click regions know nothing about grids, so the grid has to travel with the message: `mouseUpWithinCellAtPoint:cell:` becomes `mouseUpWithinCellAtPoint:cell:withinGrid:` on its three implementors, `mouseUpForCell:` becomes `mouseUpForCell:withinGrid:` on the two rotate regions, and the old ones are deleted once nothing sends them.

The captured source is the state *after* that page, and Section 3.10 wired it up, so the chain reads here as it does there:

```smalltalk
CellClickRegionRotateClockwise class >> mouseUpForCell: aCell withinGrid: aGrid
	aGrid rotateCellClockwiseAt: aCell gridLocation.
	^aCell
```

Page 121's own last change is `self changed` on the whole morph instead of one repainted cell, *since we're not impacting other cells on the board* — the same conclusion Section 3.10 reached for `redrawCells`, and for the same reason.

## Tests

The model side of this section came captured with the fix, tests included, so nothing was written here to make it pass. What this section adds is the check that the picture cannot drift from the model again. After a turn made through a click, with the laser on, every cell element is asked whether it still shows its own cell:

```smalltalk
LaserGameCellElementTestCase >> testEveryCellElementAgreesWithItsCellAfterATurn
	"Page 118 asks the question this test answers once and for all: after a mirror is turned while
	the laser is on, is what the board shows still what the grid holds? The original had to cover
	its morph with a window, uncover it, and then walk an object explorer down to the cells to
	find out. Here every cell is asked: the renderer is the one of the cell standing there, and
	the target is drawn lit exactly when its cell is on."

	| grid board |
	grid := GridFactory demoGrid.
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	(board cellElementAt: 4 @ 1) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			| location element cell |
			location := column @ row.
			cell := grid at: location.
			element := board cellElementAt: location.
			self assert: element renderer class modelClass equals: cell class.
			cell class = TargetCell ifTrue: [
				self
					assert: element children fourth background paint color
					equals: (cell isOn
							 ifTrue: [ LaserGameColors targetCenterColorActive ]
							 ifFalse: [ LaserGameColors targetCenterColorIdle ]) ] ] ]
```

That is page 118's investigation as an assertion: the renderer of each element is the one of the cell standing at that location, and the target is drawn lit exactly when its cell is on. And the Cells tab gets a test of its own, since it is the tool the chapter offers in place of the explorer:

```smalltalk
GridTestCase >> testTheCellsTabListsEveryCellWithItsState
	"Page 118 opens an object explorer on the morph and walks down to the cells dictionary to
	find out that the target at 5@1 is on when it should not be. The same question is one tab
	away here: one row per cell, with what the cell is and whether it is lit."

	| grid builder table |
	grid := self generateDemoGrid.
	grid fireLaser.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := grid inspectionCells: builder.
	self
		assert: table items size
		equals: grid numberOfColumns * grid numberOfRows.
	self assert: (table items includes: (grid at: 5 @ 1)).
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Cell' 'Lit' )
```

## Checking it

```smalltalk
| grid space board |
grid := GridFactory demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space root addChild: board.
space extent: 300 @ 300.
space title: 'Target cell'.
space show
```

Turn the mirror next to the target and the target goes dark; turn it back and it lights again. Page 121 suggests the same experiment on the bottom row, where the beam starts, and it is the better one: every mirror along the path moves the beam, and the target follows.

The rule page 118 put aside — whether a player may rotate and push at all while the laser is running — is still open, and the original returns to it much later. Page 122 starts the pushing.

# Push A Cell

*Pages 122 to 124 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/122.html -->
<!-- http://squeak.preeminent.org/tut2007/html/123.html -->
<!-- http://squeak.preeminent.org/tut2007/html/124.html -->

Turning a mirror is one of the two moves of the game. This section writes the other one: pushing a mirror sideways into the empty square beside it.

Page 122 gives the rules before any code:

- only mirror cells move;
- the target never moves;
- one cell moves at a time, so two mirrors standing side by side do not travel together;
- and nothing is really pushed. A mirror and the blank cell beside it trade places.

That last line is the whole of the logic. *If the adjacent cell where we want to push is a blank cell, we trade places. Otherwise nothing happens.* Whether the neighbour is a mirror, the target, or the edge of the board with no cell at all, the answer is the same: nothing happens.

Neighbours are what the rule talks about, so the work belongs to `Grid`, which is the only object that knows what sits next to what.

## The four stubs

Page 122 writes one method per direction on `Grid`, with nothing in them, so that the test of the next page has something to call:

```
pushCellNorthFromLocation: aPoint

pushCellEastFromLocation: aPoint

pushCellSouthFromLocation: aPoint

pushCellWestFromLocation: aPoint
```

The port has no stub stage here. The source Section 2 started from is the finished 2007 game, so the four methods, the two they call and the tests of page 123 all arrived with it, in the shape the tutorial reaches at the end of page 124 — and with two later additions this section points out as it meets them. What is left to do is what the original does with them: read them against the rules, and check that the rules hold.

## The tests of page 123

Page 123 works from the demo grid, the one drawn on page 060: a mirror on its own at 1@2, a block of mirrors around 2@3, 3@3, 2@4 and 3@4, mirrors on the edges at 4@1 and 1@5, and the target at 5@1.

The first test takes the blank corner at 1@1 and pushes it four ways. A blank cell is not a mirror, so nothing may happen:

```smalltalk
GridTestCase >> testPushBlankCell

	| grid cell |
	grid := self generateDemoGrid.
	cell := grid at: 1 @ 1.
	grid pushCellSouthFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellNorthFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellWestFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellEastFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell
```

The original writes its assertions as `self should: [cell class = BlankCell]`; the port writes `assert:equals:`, as everywhere else in this port, because a failure then prints both classes instead of just `false`.

Note what the test does between pushes: it fetches the cell again. *In the above test we re-fetch the cell each time right after the push because, for mirror cells, we expect the cell to be different.* A location is a place in the grid, not a cell, and a push changes which cell lives there. Every push test of the page follows the pattern.

The target gets the same treatment at 5@1, and must stay a `TargetCell` after four pushes:

```smalltalk
GridTestCase >> testPushTargetCell

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellSouthFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellNorthFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellWestFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellEastFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell
```

Then the mirrors, which is where the rules actually bite. Page 123 writes six: `testPushIsolatedMirrorCellNorthCase1` and `Case2`, `testPushIsolatedMirrorCellEastCase1` and `Case2`, `testPushIsolatedMirrorCellSouth` and `testPushIsolatedMirrorCellWest`. Each pushes once and then asks about the location pushed from, the location pushed into, and the neighbours that must not have moved. The first one takes the lone mirror at 1@2 and pushes it up into the empty corner:

```smalltalk
GridTestCase >> testPushIsolatedMirrorCellNorthCase1

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 1 @ 2.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 1 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 1 @ 3.
	self assert: cell class equals: BlankCell
```

and the second takes a mirror out of the block, where the cell above is free but the neighbours left and below are mirrors that must stay where they are:

```smalltalk
GridTestCase >> testPushIsolatedMirrorCellNorthCase2

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 3 @ 3.
	cell := grid at: 3 @ 2.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 4.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell
```

*And of course if we run our unit tests now, they will fail for these mirror push test cases. Actually, only the unit test cases where the mirror was expected to move will fail.* The four tests that push a mirror into a mirror pass against empty methods, for the same reason a broken clock is right twice a day — page 123 says so itself, and keeps them, because they must still pass once the code is written.

## The push, in the model

Page 124 writes the north push in full first: fetch the cell, leave unless it is a mirror, take the vector of the direction, look at the neighbour it points to, leave unless that neighbour exists and is blank, and otherwise swap. Then it notices that only one line of that is about north, and splits the method in two — a direction method that names its direction, and one method that holds the rules:

```smalltalk
Grid >> pushCell: aGridDirection fromLocation: aPoint
	"Push the cell at aPoint one step in aGridDirection and answer the cell that ended up where
	it started. Page 122: only a mirror cell moves, the target never does, and the move happens
	only when the neighbour in that direction is a blank cell, which includes there being a
	neighbour at all. Nothing is really pushed — the mirror and the blank trade places. The beam
	is taken off the board first and put back afterwards if the laser is on, as in
	rotateCellClockwiseAt:, so the cells lit before the push go dark and the new path lights up.
	Page 127 is where the original adds those two lines, after a push under a running beam left
	the target lit by nothing."

	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [ ^ cell ].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [ ^ cell ].
	swapCell class = BlankCell ifFalse: [ ^ cell ].
	self clearCellsInPath.
	self swapCell: cell with: swapCell.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	^ swapCell
```

The port's version has one pair of lines the original does not have at this page: `clearCellsInPath` before the swap and `activateCellsInPath` after it, when the laser is on. That is the same treatment `rotateCellClockwiseAt:` gets — a move made under a running beam takes the beam off the board and puts it back along the new path — and it is the answer to the bug Section 3.12 chased, arriving here for the push. `GridTestCase >> testFireLaserDuringMirrorPush` is the test that holds it.

`swapCell:with:` is the trade of places:

```smalltalk
Grid >> swapCell: aCell with: anotherCell
	"Trade the places of two cells. Page 122: a pushed mirror is never moved, it changes places
	with the blank cell beside it. at:put: writes the new location into the cell, so both cells
	know where they are afterwards, and the copies are taken before the first write because that
	write already changes one of the two locations."

	| oldLocation newLocation |
	oldLocation := aCell gridLocation copy.
	newLocation := anotherCell gridLocation copy.
	self at: newLocation put: aCell.
	self at: oldLocation put: anotherCell
```

The two copies matter. `at:put:` writes the new location into the cell it stores, so by the time the second line runs, the location read from `aCell` would already be the new one.

```smalltalk
Grid >> at: aPoint put: aCell
	"TODO sbw 05/21/2007 - We should add a more meaningful accessing technique here.  x@y is confusing."
	aCell gridLocation: aPoint.
	self cells at: aPoint put: aCell
```

The four direction methods are then what page 124 promises — *easy to write*:

```smalltalk
Grid >> pushCellNorthFromLocation: aPoint
	"Push the cell at aPoint one row up. Page 122 asks for one method per direction, page 124
	leaves them with nothing to say but their direction."

	^ self pushCellAction: #north fromLocation: aPoint
```
```smalltalk
Grid >> pushCellEastFromLocation: aPoint
	"Push the cell at aPoint one column to the right."

	^ self pushCellAction: #east fromLocation: aPoint
```
```smalltalk
Grid >> pushCellSouthFromLocation: aPoint
	"Push the cell at aPoint one row down."

	^ self pushCellAction: #south fromLocation: aPoint
```
```smalltalk
Grid >> pushCellWestFromLocation: aPoint
	"Push the cell at aPoint one column to the left."

	^ self pushCellAction: #west fromLocation: aPoint
```

Here is the second addition the captured source carries over the tutorial's page: the four methods do not call `pushCell:fromLocation:` directly, they go through one more method, which pushes and then writes the move down for the undo of Section 5.

```smalltalk
Grid >> pushCellAction: aDirectionSymbol fromLocation: aPoint
	"Push the cell at aPoint towards aDirectionSymbol and record the move for the undo of
	Section 5. Page 124 turns the four direction methods into one by looking the direction up
	from its symbol; the undo entry is the port's own addition, and it is written only when the
	cell really moved, which is what the comparison of the two locations asks."

	| direction cell swappedCell |
	cell := self at: aPoint.
	direction := GridDirection directionFor: aDirectionSymbol.
	swappedCell := self pushCell: direction fromLocation: aPoint.
	swappedCell gridLocation = cell gridLocation ifFalse: [
		self stackAction: aDirectionSymbol forCell: cell ].
	^ swappedCell
```

It decides whether anything moved by comparing locations, and it can, because of what `pushCell:fromLocation:` answers: the cell that ended up at the location pushed from. When the push is refused, that is the cell that was already there, so the comparison finds the same location twice and nothing is recorded.

The direction itself comes from the class hierarchy Section 2 built:

```smalltalk
GridDirection class >> directionFor: aSymbol
	^self subclasses detect: [:cls | cls directionSymbol = aSymbol]
```
```smalltalk
GridDirectionNorth class >> vector
	^0@(-1)
```

`0 @ -1` is up because row 1 is the top row. This is the same lookup the beam uses to walk from cell to cell, which is what page 124 means by *the direction code should look familiar*.

## What page 123 leaves open

The tests of page 123 ask which class sits at which location. That is enough to catch a mirror that fails to move, and not enough for three questions the rules raise. Section 3.13 adds one test each.

The edge of the board is the case with no cell to look at, and the `nil` check is the only line of `pushCell:fromLocation:` that page 123 never exercises:

```smalltalk
GridTestCase >> testPushingAMirrorOffTheEdgeOfTheGridDoesNothing
	"There is no cell beyond the border, so the push finds nothing to trade places with. Page 122
	states the rule as a rule about the adjacent cell; the demo grid has a mirror on the left
	edge at 1@2 and one on the bottom edge at 1@5."

	| grid |
	grid := self generateDemoGrid.
	grid pushCellWestFromLocation: 1 @ 2.
	self assert: (grid at: 1 @ 2) class equals: MirrorCell.
	grid pushCellSouthFromLocation: 1 @ 5.
	self assert: (grid at: 1 @ 5) class equals: MirrorCell
```

The second is page 122's pair of pictures — one mirror with a blank beside it moves, two mirrors do not move together — and the target as a neighbour, which the page never separates from the target as a cell being pushed:

```smalltalk
GridTestCase >> testPushingAMirrorAgainstANonBlankNeighbourDoesNothing
	"Page 122 shows two pictures side by side: a mirror with a blank cell beside it moves, two
	mirrors beside each other do not move together. The target is no different from a mirror
	here — it is simply not blank, so a mirror cannot be pushed into it either."

	| grid |
	grid := self generateDemoGrid.
	grid pushCellEastFromLocation: 2 @ 3.
	self assert: (grid at: 2 @ 3) class equals: MirrorCell.
	self assert: (grid at: 3 @ 3) class equals: MirrorCell.
	grid pushCellEastFromLocation: 4 @ 1.
	self assert: (grid at: 4 @ 1) class equals: MirrorCell.
	self assert: (grid at: 5 @ 1) class equals: TargetCell
```

The third is about identity. A push that built a fresh `MirrorCell` at the new location and a fresh `BlankCell` at the old one would satisfy every test of page 123, and would quietly drop the lean of the mirror — which is the only thing that makes a mirror worth pushing:

```smalltalk
GridTestCase >> testAPushedMirrorIsTheSameCellInItsNewPlace
	"The push tests of page 123 ask which class sits where. That leaves room for a push that
	builds a fresh mirror: the classes would still be right and the lean of the mirror, or
	anything else the cell carries, would be lost. Both cells are the ones that were there
	before, and both know their new location."

	| grid mirror blank |
	grid := self generateDemoGrid.
	mirror := grid at: 3 @ 3.
	blank := grid at: 3 @ 2.
	grid pushCellNorthFromLocation: 3 @ 3.
	self assert: (grid at: 3 @ 2) identicalTo: mirror.
	self assert: (grid at: 3 @ 3) identicalTo: blank.
	self assert: mirror gridLocation equals: 3 @ 2.
	self assert: blank gridLocation equals: 3 @ 3.
	self deny: mirror leansLeft
```

And since the port records moves, a refused push must record nothing:

```smalltalk
GridTestCase >> testAPushThatMovesNothingRecordsNoMove
	"A push that the rules refuse is not a move, so nothing goes on the stack the undo of
	Section 5 reads. This is what pushCellAction:fromLocation: asks when it compares the two
	locations."

	| grid |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 1 @ 1.
	grid pushCellWestFromLocation: 1 @ 2.
	grid pushCellEastFromLocation: 2 @ 3.
	grid pushCellSouthFromLocation: 5 @ 1.
	self assert: grid movesStack isEmpty.
	grid pushCellNorthFromLocation: 3 @ 3.
	self assert: grid movesStack size equals: 1
```

## Checking it

```
147 run, 147 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

The push works in the model, and no pointer can reach it yet. That is the next section: page 125 sends the mouse-up of the four push regions down to these four methods, and the arrows drawn since Section 3.6 start to mean something.

# Push Cells With The Mouse

*Pages 125 to 126 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/125.html -->
<!-- http://squeak.preeminent.org/tut2007/html/126.html -->

The model can push a mirror, the board has been drawing push arrows since Section 3.6, and nothing joins the two. Page 125 joins them, and page 126 goes looking for what the joining broke.

## The click reaches the push

The hook has been in place since page 114: the inside region of a cell asks which push region the point falls in, and sends it a mouse-up.

```smalltalk
CellClickRegionInside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^pushRegion mouseUpForCell: aCell withinGrid: aGrid
```
```smalltalk
CellClickRegionInside class >> pushRegionForPoint: aPoint
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
```

The four push regions answer it by pushing, each in its own direction:

```smalltalk
CellClickRegionPushNorth class >> mouseUpForCell: aCell withinGrid: aGrid
	^aGrid pushCellNorthFromLocation: aCell gridLocation
```
```smalltalk
CellClickRegionPushEast class >> mouseUpForCell: aCell withinGrid: aGrid
	^aGrid pushCellEastFromLocation: aCell gridLocation
```
```smalltalk
CellClickRegionPushSouth class >> mouseUpForCell: aCell withinGrid: aGrid
	^aGrid pushCellSouthFromLocation: aCell gridLocation
```
```smalltalk
CellClickRegionPushWest class >> mouseUpForCell: aCell withinGrid: aGrid
	^aGrid pushCellWestFromLocation: aCell gridLocation
```

A push region is named after the side of the cell it covers, and pushes the cell away from that side: the lower triangle pushes north. Section 3.10 already sent a click all the way down this chain, so the port has had working pushes since then, with `LaserGameCellElementTestCase >> testClickingTheInsideRegionOfAMirrorPushesIt` to say so:

```smalltalk
LaserGameCellElementTestCase >> testClickingTheInsideRegionOfAMirrorPushesIt
	"The inside region pushes, which page 114 leaves unsent until page 122. The port cannot leave
	it unsent: the click regions came with `mouseUpForCell:withinGrid:` already written on all six
	of them, so the same wiring that turns a mirror also pushes one. A push region is named after
	the side the cell is pushed from, so the lower triangle pushes north; the mirror at 1@2 has a
	blank cell above it, and after the click each of the two cell elements draws what now stands
	in it."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 1 @ 2.
	self assert: element cell class equals: MirrorCell.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: (board grid at: 1 @ 1) class equals: MirrorCell.
	self assert: (board grid at: 1 @ 2) class equals: BlankCell.
	self
		assert: (board cellElementAt: 1 @ 1) renderer class
		equals: MirrorCellRenderer.
	self
		assert: (board cellElementAt: 1 @ 2) renderer class
		equals: BlankCellRenderer
```

## The hunt of page 126

Page 126 does not stop there, and the reason it gives is worth keeping:

> Before we get too carried away, and since I'm fairly certain we will have graphics clean-up code to write just like we did with mirror cell rotation, let's put a `self halt` inside one of the push methods and then carefully single-step through the code to see if we discover anything we may not be handling quite correctly.

So a halt goes into the push, the mirror at 1@2 is pushed north in the running game, and the debugger opens. Stepping over the swap, the cells look right. Stepping out of it, the walk arrives back in the `MirrorCellRenderer` that started the whole thing, and there is the finding:

> That `#redrawCell` method is being issued to the mirror cell renderer. But if you inspect the `cellLocation` variable you can see that this is a mirror cell renderer that still thinks it's for a mirror cell at location 1@2. That's where we used to be.

The renderer was made for a mirror and is now pointed at a blank cell. A push is the only move that can do that — a turned mirror is still a mirror in the same place — and the fix the original writes is a long one. Every mouse-up in the chain has to answer the cell the action ended up involving: the base region answers its cell, the inside and outside regions answer whatever the region below them answers, the six leaf regions answer the result of their operation, `mouseUpWithinBoardOffset:` hands it up, and `LaserGame >> mouseUp:forMorph:cell:` catches it and calls a new `redrawCell:` on it.

```
mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid

    ^aCell
```

The port has none of that plumbing left to write, and for two different reasons.

The answers are already there. The captured source has them on all six leaf regions and on the three `mouseUpWithinCellAtPoint:cell:withinGrid:` implementors, because it is the finished 2007 game. The base class answers its cell, the rotate regions answer the cell they turned, and the push regions answer whatever `pushCell:fromLocation:` answered.

```smalltalk
CellClickRegion class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	^aCell
```
```smalltalk
CellClickRegionRotateClockwise class >> mouseUpForCell: aCell withinGrid: aGrid
	aGrid rotateCellClockwiseAt: aCell gridLocation.
	^aCell
```

And the Morph half of the fix was deleted as the Bloc half landed: `LaserGame >> mouseUp:forMorph:cell:`, `mouseUpWithinBoardOffset:` on both renderers and `redrawCell:` went in Sections 3.10 and 3.11. A cell element does not repaint a rectangle of a shared form, it builds itself from the cell that stands at its location, and one action redraws the whole board rather than a guessed set of cells:

```smalltalk
LaserGameBoardElement >> redrawCells
	"Draw every cell again. One action on one cell changes more than that cell: a turned mirror
	sends the beam somewhere else, and a pushed mirror leaves its old place empty, so nothing
	tries to work out which cells are affected."

	self children do: [ :each | each redraw ]
```

What the port kept the answer for is the question *did anything happen*. `mouseUpAt:` answers nil when a click asked for something the cell cannot do, and the cell element then leaves the board alone:

```smalltalk
CellRenderer >> mouseUpAt: aPoint
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when nothing happened. Nothing happens here: only a mirror answers a click, which is
	page 114 of the original — the renderer superclass does nothing, and only the mirror renderer
	deals with the request."

	^ nil
```
```smalltalk
MirrorCellRenderer >> mouseUpAt: aPoint
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when the region aPoint falls in can do nothing. The region decides both questions: the
	outside region turns my mirror one way or the other, the inside region pushes it when there
	is room, and the ignore margin does nothing. Page 114 of the original passes the cell and the
	grid down to the region for exactly this reason: a region knows what a click means, and
	nothing else does."

	| region |
	region := CellClickRegion clickRegionForPoint: aPoint.
	^ (region
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [
		  region
			  mouseUpWithinCellAtPoint: aPoint
			  cell: self cell
			  withinGrid: self grid ]
		  ifFalse: [ nil ]
```
```
LaserGameCellElement >> clickAt: aPoint
	"Act on a click at aPoint, in my own coordinates. My board records that I was clicked, my
	renderer decides whether my cell acts and which region handles it, and the board draws itself
	again when something changed. The original walked the same chain from the morph to the
	renderer to the click region; it started from a board offset, where this starts from a point
	Bloc already expressed in the cell."

	self board ifNotNil: [ :board | board clickCellElement: self ].
	(self renderer mouseUpAt: aPoint) ifNil: [ ^ self ].
	self board ifNotNil: [ :board | board redrawCells ]
```

This is the method as this chapter writes it; Section 4.4 has it tell the board that a move was made instead of asking it to redraw, so that the counters of page 142 hear about the move too.

## The same bug, one layer up

Page 126 is really about a view that goes on believing in a cell that has moved away, and the port has one of those left. It is not the renderer — `redraw` chooses that again from the model — it is the arrow drawn over it.

Push a mirror with the pointer resting on it. The mirror leaves, a blank cell takes its place, and the cell under the pointer keeps showing the push arrow of the mirror that is no longer there. A blank cell offers no push, and the pointer has not moved, so nothing asks the question again. Here is the test for it:

```smalltalk
LaserGameCellElementTestCase >> testTheArrowGoesWhenAPushEmptiesTheCellUnderThePointer
	"Page 126 single-steps a push and finds a renderer that still believes it draws the mirror
	cell at 1@2, the place the mirror has just left. The port chooses the renderer again when a
	cell is drawn again, so the picture of the cell is right — but the hint drawn over it would
	be the one of the cell that moved away. The pointer has not moved, and a blank cell offers
	no push, so the arrow goes and the emptied cell looks like any other blank cell."

	| board element blank |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 1 @ 2.
	blank := board cellElementAt: 2 @ 2.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: (element children includes: element hintElement).
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle bottomCenter - (0 @ 1);
			 yourself).
	self assert: element cell class equals: BlankCell.
	self assert: element hintRegion isNil.
	self assert: element hintElement isNil.
	self assert: element children size equals: blank children size.
	self assert: (board cellElementAt: 1 @ 1) hintElement isNil
```

The fix is the port's version of the original's: know which cell you are dealing with, at the moment you draw. A hint is read from a renderer at a point, so the point is what has to be kept. `LaserGameCellElement` gains one slot for it:

```smalltalk
BlElement << #LaserGameCellElement
	slots: { #renderer . #hintRegion . #hintElement . #hintPosition };
	tag: 'Graphics';
	package: 'Laser-Game'
```

The point is written where the pointer is heard from, and forgotten when the pointer leaves:

```
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing, so the arrow is built once. The point
	itself is kept, because a redraw has to ask the question again for the cell that stands in me
	then."

	| region |
	hintPosition := aPoint.
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self ].
	hintRegion := region.
	self updateHintElement
```

This is the method as this chapter writes it; Section 4.2 moves the cross hair on the path that returns early here.
```smalltalk
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me, so the arrow goes too, and so does the point
	it was read at."

	hintPosition := nil.
	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
```

and `redraw`, which already chose the renderer again, now asks for the hint again too — from the cell that stands there after the action, which is the whole lesson of page 126:

```
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because page 126 of the original is the
	tale of a view that went on believing in the cell that had moved away. A blank cell offers no
	push, so the arrow of the mirror that left goes with it. The original repainted a rectangle
	of the board form and called it redrawCell."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```

This is the method as this chapter writes it; Section 4.2 forgets the cross hair here as well.

The other half of the rule needs a test of its own, or the fix could as well have been to drop every hint on every redraw: a turn leaves the mirror in place, so the arrow under the pointer is still the right one and must survive.

```
LaserGameCellElementTestCase >> testTheArrowStaysWhenTheCellUnderThePointerStillOffersIt
	"The other half of the same rule: a turn leaves the mirror where it is, so the hint under the
	pointer is still the right one and the arrow survives the redraw. The hint is read from the
	cell that stands there after the action, not kept and not dropped."

	| board element childCount |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element cell class equals: MirrorCell.
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	self assert: (element children includes: element hintElement).
	self assert: element children size equals: childCount + 1
```

This is the test as this chapter writes it; Section 4.2 counts two children per hint, since the cross hair comes with the arrow.

## Checking it

```
149 run, 149 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

```smalltalk
| grid board space |
grid := GridFactory demoGrid.
grid fireLaser.
board := LaserGameBoardElement on: grid.
space := BlSpace new.
space title: 'Push with the mouse'.
space extent: (LaserGameBoardElement extentForGrid: grid) + 40.
space root
	background: Color veryLightGray;
	addChild: board.
board position: 20 @ 20.
space show
```

Mirrors move where the arrow points, the beam follows them, and the target lights up and goes dark as the path reaches it or misses it — which is where page 126 ends, and where page 127 says *you may have noticed there's a bug*.

# Visual Bug With Push

*Page 127 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/127.html -->

> You may have noticed there's a bug with the visual presentation when pushing cells while the laser beam is active.

Fire the laser, then push the mirror at 4@5 one square west. The beam no longer reaches the target, and the target is still drawn lit. It is the bug of Section 3.12 again, in the other move: *it's a lot like what we saw with cell rotation while the beam was active.*

Page 127 also repeats the question page 118 left open — whether a player should be allowed to move cells at all while the beam is running — and answers it the same way: *we still may want to go back and change the overall idea so that this isn't possible, at a later time in our development. However, I want to go back and fix this bug right now.*

## Ask the model first

The lesson of Section 3.12 is used straight away here: close the game window, and ask the model whether the fault is its own. Page 127 writes two tests, one for each side of the question. Pushing a mirror and then firing the laser is the case that was never broken:

```smalltalk
GridTestCase >> testFireLaserAfterMirrorPush

	| grid cell |
	grid := self generateDemoGrid.
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 5 @ 1.
	self assert: cell isOff.
	grid pushCellWestFromLocation: 4 @ 5.
	grid fireLaser.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 3 @ 5.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

and pushing it while the beam is already on is the one that reproduces what the screen showed:

```smalltalk
GridTestCase >> testFireLaserDuringMirrorPush

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid pushCellWestFromLocation: 4 @ 5.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 3 @ 5.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

> Run the tests again. Sure enough it fails. This is good news. Again, we have constructed a unit test that reproduces a bug.

The debugger then steps into the push, stops where the swap is done, and the missing work is plain: the beam still lights the cells of the path it took before the mirror moved. The fix is two lines, the same two that rotation got — take the beam off the board before the change, and put it back along the new path when the laser is on.

```smalltalk
Grid >> pushCell: aGridDirection fromLocation: aPoint
	"Push the cell at aPoint one step in aGridDirection and answer the cell that ended up where
	it started. Page 122: only a mirror cell moves, the target never does, and the move happens
	only when the neighbour in that direction is a blank cell, which includes there being a
	neighbour at all. Nothing is really pushed — the mirror and the blank trade places. The beam
	is taken off the board first and put back afterwards if the laser is on, as in
	rotateCellClockwiseAt:, so the cells lit before the push go dark and the new path lights up.
	Page 127 is where the original adds those two lines, after a push under a running beam left
	the target lit by nothing."

	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [ ^ cell ].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [ ^ cell ].
	swapCell class = BlankCell ifFalse: [ ^ cell ].
	self clearCellsInPath.
	self swapCell: cell with: swapCell.
	self laserIsActive ifTrue: [ self activateCellsInPath ].
	^ swapCell
```
```smalltalk
Grid >> clearCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe clearCell]
```
```smalltalk
Grid >> activateCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe activateCell]
```

## What this section had left to do

Both tests and both lines came with the captured source, as Section 3.13 noted when it read the push protocol. A fix that arrives already made is a fix nobody has seen work, so it was taken out again: `clearCellsInPath` and `activateCellsInPath` were removed from `pushCell:fromLocation:`, and the suite answered

```
testFireLaserDuringMirrorPush
Assertion failed

testEveryCellElementAgreesWithItsCellAfterAPush
Denial failed
```

with the two lines put back, and 150 tests green again. Page 127's bug is real in this port, and those two lines are what keeps it away.

The second failure is the part of page 127 the original could only check by eye — *we can relaunch the LaserGame morph and see if the problem is resolved for the visual world too* — and it is the push counterpart of the test Section 3.12 wrote for the turn. It plays the whole scene: fire, click a push arrow, and then ask every cell element whether it draws the cell that now stands in it.

```smalltalk
LaserGameCellElementTestCase >> testEveryCellElementAgreesWithItsCellAfterAPush
	"Page 127 on the screen: fire the laser, then push the mirror at 4@5 west to 3@5. The target
	at 5@1 is drawn lit while nothing feeds it any more. This is the same walk as after a turn,
	made through a real click on a push arrow: the beam is off the board and back on it before
	anything is drawn, and every cell element shows the cell that stands in it."

	| grid board |
	grid := GridFactory demoGrid.
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	self assert: (grid at: 5 @ 1) isOn.
	(board cellElementAt: 4 @ 5) dispatchEvent: (BlClickEvent new
			 position: CellClickRegionInside regionRectangle rightCenter - (1 @ 0);
			 yourself).
	self assert: (grid at: 3 @ 5) class equals: MirrorCell.
	self deny: (grid at: 5 @ 1) isOn.
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			| location element cell |
			location := column @ row.
			cell := grid at: location.
			element := board cellElementAt: location.
			self assert: element renderer class modelClass equals: cell class.
			cell class = TargetCell ifTrue: [
				self
					assert: element children fourth background paint color
					equals: (cell isOn
							 ifTrue: [ LaserGameColors targetCenterColorActive ]
							 ifFalse: [ LaserGameColors targetCenterColorIdle ]) ] ] ]
```

The board needs nothing of its own for this. `redrawCells` draws every cell after an action, and a cell element reads its cell from the grid when it is drawn, so a target that has gone dark in the model is drawn dark without anything working out which cells the beam left.

## Checking it

```
150 run, 150 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

The space opened in Section 3.14 shows it directly: with the laser on, push the mirror at 4@5 west and the target goes dark as the beam leaves it.

> This is another good breaking point and a place to save your image.

Which is what the next section is about — except that the tool is not Monticello any more.

# Source Management With Monticello

*Pages 128 to 129A of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/128.html
     http://squeak.preeminent.org/tut2007/html/129.html
     http://squeak.preeminent.org/tut2007/html/129A.html -->

Pages 128 and 129 leave the game alone and put the code away: they open the Monticello browser, declare a package named `Laser-Game` over the three system categories `Laser-Game-Model`, `Laser-Game-Graphics` and `Laser-Game-Tests`, add a repository — a plain directory on disk — and save version `Laser-Game-sbw.1` into it. Page 128 also stops on the `*Extensions` entry of the snapshot browser, to show that the method added to `Object` travelled with the package because of the protocol it was filed under.

This port does not repeat that chapter. Pharo has replaced both tools: code lives in a Tonel repository under Git, and Iceberg is the browser that commits it. Explaining Iceberg here would duplicate a book that already exists and is kept up to date:

<https://books.pharo.org/booklet-ManageCode/pdf/2024-05-16-ManageCode.pdf>

What the two pages say about *why* still holds, and the port follows it: the code is one package, `Laser-Game`, with the same three concerns kept apart — the model classes, the Bloc graphics and the tests are each in their own tag — and every numbered section of this book is a commit of its own, so any state of the game can be reproduced and gone back to.

Page 129A closes Section 3 with an inventory of every class and method the reader should have. It is an inventory of the 2007 code, not of this port: most of the graphics classes on it are gone, `LaserGameForms` and the `Form` drawing with it, and the classes that replaced them — `LaserGameShapes`, `LaserGameBoardElement`, `LaserGameCellElement` and the rest — are not on it. The list in `PROJECT_MAP.md` is this port's equivalent.

> The basic LaserGame is complete and can be used within the Squeak environment. The following sections of this tutorial all add enhancements and features to this base we have just created.
