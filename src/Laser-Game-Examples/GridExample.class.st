"
I offer boards to look at.

Each of my examples answers a `Grid`, so the inspector opens on the rules of the game: the Board tab draws it, Beam lists the cells the light crosses, Cells counts what is on it, and Moves and Pushes say what has been played and what could be.
"
Class {
	#name : 'GridExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
GridExample class >> demoGrid [
	"The five by five board of the earlier chapters: ten mirrors and one target.
	GridExample demoGrid"

	<sampleInstance>
	^ GridFactory demoGrid
]

{ #category : 'examples' }
GridExample class >> emptyStandardGrid [
	"The same eight by ten board before anything is dealt on it: eighty blank cells.
	Compare its Cells tab with the one of #standardGrid.
	GridExample emptyStandardGrid"

	<sampleInstance>
	^ GridFactory emptyStandardGrid
]

{ #category : 'examples' }
GridExample class >> gridAfterAMoveAndARotation [
	"The demo board with the mirror at 1@2 turned clockwise and the one at 3@3 pushed east.
	The Moves tab hides itself until something has been played, so this is the board to click when you want to read it.
	GridExample gridAfterAMoveAndARotation"

	<sampleInstance>
	| grid |
	grid := GridFactory demoGrid.
	grid rotateCellClockwiseAt: 1 @ 2.
	grid pushCellEastFromLocation: 3 @ 3.
	^ grid
]

{ #category : 'examples' }
GridExample class >> gridWithTheLaserFiring [
	"The demo board with the laser lit, which is the one board whose Beam tab has anything in it.
	GridExample gridWithTheLaserFiring"

	<sampleInstance>
	| grid |
	grid := GridFactory demoGrid.
	grid fireLaser.
	^ grid
]

{ #category : 'examples' }
GridExample class >> randomGrid [
	"A board dealt afresh, so no two clicks show the same one.
	GridExample randomGrid"

	<sampleInstance>
	^ GridFactory randomizedGridOfExtent: 8 @ 10
]

{ #category : 'examples' }
GridExample class >> standardGrid [
	"The board a new game is dealt on: eight columns by ten rows, thirty-two mirrors, the target in the corner.
	GridExample standardGrid"

	<sampleInstance>
	^ GridFactory defaultGrid
]
