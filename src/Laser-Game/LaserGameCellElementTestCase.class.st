"
I test LaserGameCellElement: that a cell element knows the cell it shows and the renderer that built it, and that it classifies a point of its own into a click region without any board-wide arithmetic.

"
Class {
	#name : 'LaserGameCellElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'tests' }
LaserGameCellElementTestCase >> testACellElementClassifiesAPointOfItsOwn [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testACellElementKnowsTheCellItShows [
	"A cell element carries its own cell, so nothing has to work back from a position on the
	board to a grid location."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 2 @ 3.
	self assert: element cell identicalTo: (board grid at: 2 @ 3).
	self assert: element gridLocation equals: 2 @ 3
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testAMirrorCellShowsOneArrowAtATime [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testClickingACellElementRecordsItsCell [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEachCellElementCarriesTheRendererOfItsCell [
	"The element is built by a renderer, and it keeps it: that is what redraws the cell later."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	board children do: [ :each |
		self assert: each renderer class modelClass equals: each cell class ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEnteringACellElementMakesItTheHoveredCell [
	"The pointer entering a cell element is enough for the board to know which cell it is over.
	The original had to ask the hand for its position and divide it by the cell size."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	self assert: board hoveredCellElement identicalTo: element.
	self assert: board hoveredCell identicalTo: (board grid at: 2 @ 3)
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testEveryChildOfTheBoardIsACellElement [
	"The board holds one cell element per cell of its grid."

	| board grid |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	grid := board grid.
	self
		assert: board children size
		equals: grid numberOfColumns * grid numberOfRows.
	board children do: [ :each |
		self assert: each class equals: LaserGameCellElement ]
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testLeavingACellClearsItsHintRegion [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testLeavingACellElementThatIsNotHoveredKeepsTheHover [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testLeavingTheHoveredCellElementClearsTheHover [
	"The pointer leaving the cell it hovers leaves the board hovering nothing."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 2 @ 3.
	element dispatchEvent: BlMouseEnterEvent new.
	element dispatchEvent: BlMouseLeaveEvent new.
	self assert: board hoveredCellElement isNil.
	self assert: board hoveredCell isNil
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingInTheOutsideRegionOfAMirrorCellShowsARotateArrow [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellRecordsItsHintRegion [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingInsideAMirrorCellShowsTheArrowOfItsPushRegion [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingOverACellElementMakesItTheHoveredCell [
	"A mouse move over a cell is the event the original watched: it answers which cell the
	pointer is over. Bloc sends it to the cell itself, so the board learns it from the cell."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 2.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: 10 @ 10;
			 yourself).
	self assert: board hoveredCellElement identicalTo: element
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testMovingOverACellThatIsNotAMirrorRecordsNoHint [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheArrowGoesWhenThePointerLeavesOrReachesARegionWithoutOne [
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
]

{ #category : 'tests' }
LaserGameCellElementTestCase >> testTheSameLocalPointMeansTheSameRegionInEveryCell [
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
]
