"
I am the whole game on the screen: a board on the left, a control panel on the right, and a margin around both.

I replace the 2007 `LaserGame` morph of pages 065 to 067, which held a `SketchMorph` over a board form and a white rectangle for the panel. I hold a `LaserGameBoardElement` and a plain element instead, and I take my size from them, the panel width and the margin, the way the original's `calculatedExtent` did.

```
LaserGameElement openExample
```

Instance variables:
- `grid`: the grid played on. Setting it rebuilds what I hold.
- `board`: the `LaserGameBoardElement` showing that grid.
- `controlPanel`: the panel beside it, empty until the controls arrive.

I know nothing about the rules. The grid answers those, and the model-side `LaserGame` of the later sections will own the moves, the counters and the undo stack.
"
Class {
	#name : 'LaserGameElement',
	#superclass : 'BlElement',
	#instVars : [
		'grid',
		'board',
		'controlPanel'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
LaserGameElement class >> extentForGrid: aGrid [
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side. This is the original's calculatedExtent, with the board element
	standing in for the board form."

	^ (LaserGameBoardElement extentForGrid: aGrid) + (self panelWidth @ 0)
	  + (2 * self gameMargin)
]

{ #category : 'accessing' }
LaserGameElement class >> gameMargin [
	"Answer the margin, in pixels, between the edge of the game and what it holds. The original's
	number."

	^ 10
]

{ #category : 'instance creation' }
LaserGameElement class >> on: aGrid [
	"Answer a game element playing on aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
]

{ #category : 'examples' }
LaserGameElement class >> openExample [
	"Open the demo grid of the tests, as the original opens its morph on the grid of the factory.

	LaserGameElement openExample"

	<sampleInstance>
	^ self openOn: GridFactory demoGrid
]

{ #category : 'instance creation' }
LaserGameElement class >> openOn: aGrid [
	"Open a space showing a game on aGrid and answer it.

	LaserGameElement openOn: GridFactory demoGrid"

	| space |
	space := BlSpace new.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: (self on: aGrid).
	space show.
	^ space
]

{ #category : 'accessing' }
LaserGameElement class >> panelWidth [
	"Answer the width, in pixels, of the control panel beside the board. The original's number."

	^ 110
]

{ #category : 'accessing' }
LaserGameElement >> board [
	"Answer the element showing the board."

	^ board
]

{ #category : 'accessing' }
LaserGameElement >> controlPanel [
	"Answer the panel beside the board. It is empty until the controls are added."

	^ controlPanel
]

{ #category : 'accessing' }
LaserGameElement >> grid [
	"Answer the grid the game plays on."

	^ grid
]

{ #category : 'accessing' }
LaserGameElement >> grid: aGrid [
	"Play on aGrid. Setting the grid rebuilds what I hold, so the same game element can show
	another grid."

	grid := aGrid.
	self rebuild
]

{ #category : 'initialization' }
LaserGameElement >> initialize [
	"A game is a row of two: the board, and the control panel beside it. The margin around both is
	padding, and the color behind them shows through it."

	super initialize.
	self background: LaserGameColors gameWindowColor.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin)
]

{ #category : 'accessing' }
LaserGameElement >> laserIsActive [
	"Answer whether the laser is firing. The grid knows; I only ask."

	^ self grid laserIsActive
]

{ #category : 'initialization' }
LaserGameElement >> newControlPanel [
	"Answer the control panel: the fixed-width column of buttons that sits beside the board."

	^ LaserGameControlPanelElement on: self
]

{ #category : 'actions' }
LaserGameElement >> quit [
	"Close the game. The original sends #delete to its morph."

	self space ifNotNil: [ :aSpace | aSpace close ]
]

{ #category : 'initialization' }
LaserGameElement >> rebuild [
	"Replace what I hold with a board showing my grid and a control panel beside it, and take the
	size the two of them and my margins need."

	self removeChildren.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: board.
	self addChild: controlPanel.
	self extent: (self class extentForGrid: self grid)
]

{ #category : 'updating' }
LaserGameElement >> refresh [
	"Show what the model says now: redraw the cells and put the right label on the fire button.
	This is the original's #updateGameBoardAndControls, without the counters it does not have yet."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel
]

{ #category : 'actions' }
LaserGameElement >> toggleLaser [
	"Fire the laser, or stop it if it is already firing, and show the result. This is what the fire
	button does, and it is the original's #fireLaser on the morph."

	self laserIsActive
		ifTrue: [ self grid stopLaser ]
		ifFalse: [ self grid fireLaser ].
	self refresh
]
