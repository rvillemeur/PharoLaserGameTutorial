Class {
	#name : 'LaserGameBoardElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testBoardHasOneElementPerCell [
	"Every cell of the grid gets exactly one element, and no element is left over."

	| grid board |
	grid := GridFactory demoGrid.
	board := LaserGameBoardElement on: grid.
	self
		assert: board children size
		equals: grid numberOfRows * grid numberOfColumns
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testBoardLaysCellsOutInAGridAndFitsThem [
	"The layout does the placing, and the board takes the size of the cells it holds. Both are
	read without a layout pass. BlGridLayout keeps its column count privately, so the number of
	columns is not asserted here; the placement it produces is checked by opening the example."

	| grid board |
	grid := GridFactory demoGrid.
	board := LaserGameBoardElement on: grid.
	self assert: board layout class equals: BlGridLayout.
	self
		assert: board constraints horizontal resizer class
		equals: BlLayoutFitContentResizer.
	self
		assert: board constraints vertical resizer class
		equals: BlLayoutFitContentResizer
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testCellElementsAreInRowMajorOrder [
	"Cells are added row by row, so the element of a location is found by arithmetic and
	every location answers a different element."

	| grid board elements |
	grid := GridFactory demoGrid.
	board := LaserGameBoardElement on: grid.
	self
		assert: (board cellElementAt: 1 @ 1)
		equals: board children first.
	self
		assert:
			(board cellElementAt:
				 grid numberOfColumns @ grid numberOfRows)
		equals: board children last.
	elements := IdentitySet new.
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			elements add: (board cellElementAt: column @ row) ] ].
	self assert: elements size equals: board children size
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testExtentForGridComesFromTheCellSize [
	"The board extent is the cell extent times the grid dimensions. Borders are painted inside
	the cells, so they add nothing, and the number is never written down as a literal."

	| grid |
	grid := GridFactory demoGrid.
	self
		assert: (LaserGameBoardElement extentForGrid: grid)
		equals:
			CellRenderer cellExtent x * grid numberOfColumns
			@ (CellRenderer cellExtent y * grid numberOfRows)
]

{ #category : 'tests' }
LaserGameBoardElementTestCase >> testSettingAnotherGridRebuildsTheCells [
	"The same board can show another game. Nothing of the previous grid is left behind."

	| board first second |
	first := GridFactory demoGrid.
	second := Grid new.
	board := LaserGameBoardElement on: first.
	board grid: second.
	self assert: board grid equals: second.
	self
		assert: board children size
		equals: second numberOfRows * second numberOfColumns.
	self
		assert: (board cellElementAt: 1 @ 1)
		equals: board children first
]
