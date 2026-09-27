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
LaserGameCellElementTestCase >> testEachCellElementCarriesTheRendererOfItsCell [
	"The element is built by a renderer, and it keeps it: that is what redraws the cell later."

	| board |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	board children do: [ :each |
		self assert: each renderer class modelClass equals: each cell class ]
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
