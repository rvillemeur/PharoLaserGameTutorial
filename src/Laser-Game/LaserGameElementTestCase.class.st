Class {
	#name : 'LaserGameElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'tests' }
LaserGameElementTestCase >> testBoardShowsTheGridOfTheGame [
	"The board the game holds renders the game's own grid, one element per cell."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self assert: game grid equals: grid.
	self assert: game board grid equals: grid.
	self assert: game board children size equals: 25
]

{ #category : 'tests' }
LaserGameElementTestCase >> testControlPanelIsAFixedColumnAsTallAsTheBoard [
	"The panel keeps the original's width whatever the grid is, and it is as tall as the board
	beside it. Sizes are read from the layout constraints, since nothing is laid out yet."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: (LaserGameBoardElement extentForGrid: grid) y.
	self
		assert: game controlPanel background paint color
		equals: LaserGameColors controlPanelColor
]

{ #category : 'tests' }
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins [
	"The game is as wide as the board, the panel beside it and a margin on each side, and as
	tall as the board with a margin above and below. This is the original's calculatedExtent."

	| grid expected |
	grid := GridFactory demoGrid.
	expected := (LaserGameBoardElement extentForGrid: grid)
	            + (LaserGameElement panelWidth @ 0)
	            + (2 * LaserGameElement gameMargin).
	self assert: (LaserGameElement extentForGrid: grid) equals: expected.
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals: 5 * CellRenderer cellExtent + (110 @ 0) + 20
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel [
	"A game is a row of two children: the board first, the control panel beside it."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game children size equals: 2.
	self assert: game children first equals: game board.
	self assert: game children second equals: game controlPanel.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameTakesTheExtentItCalculates [
	"The game asks for exactly the size its own arithmetic gives, and the margin around its two
	children is padding, so the window color shows through it."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: grid) x.
	self
		assert: game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: grid) y.
	self assert: game padding equals: (BlInsets all: LaserGameElement gameMargin).
	self
		assert: game background paint color
		equals: LaserGameColors gameWindowColor
]
