"
I am the whole game on the screen: a control panel on the left, a board on the right, and a margin around both.

I replace the 2007 `LaserGame` morph of pages 065 to 067, which held a `SketchMorph` over a board form and a white rectangle for the panel. I hold a `LaserGameBoardElement` and a `LaserGameControlPanelElement` instead, and I take my size from them, the panel width and the margin, the way the original's `calculatedExtent` did. Page 139 puts the panel on the left, and page 140 fills me with the colour ramp of `LaserGameColors windowColorRamp`.

```
LaserGameElement openExample
```

Instance variables:
- `grid`: the grid played on. Setting it rebuilds what I hold.
- `board`: the `LaserGameBoardElement` showing that grid.
- `controlPanel`: the panel beside it, holding the buttons and the counters.

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
LaserGameElement class >> windowBackgroundPaint [
	"Answer the paint behind the whole game: page 140's ramp, running in the direction that page
	orients its fill in. The original sets a flat window color and then fills the morph with the
	ramp on top of it; an element takes one paint, so only the ramp is left, and the flat color
	stays as LaserGameColors gameWindowColor for whatever needs a single color."

	^ BlLinearGradientPaint new
		  stops: LaserGameColors windowColorRamp;
		  start: 0 @ 0;
		  end: LaserGameColors windowColorRampDirection;
		  yourself
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
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it."

	super initialize.
	self background: self class windowBackgroundPaint.
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
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. Page 139 moves the panel to the left of the
	board, which here is the order the two are added in. The board tells the panel when a move
	changed the grid, so the counters follow a click as well as the fire button."

	self removeChildren.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: controlPanel.
	self addChild: board.
	board whenMoveMadeDo: [ self controlPanel updateCounters ].
	self extent: (self class extentForGrid: self grid)
]

{ #category : 'updating' }
LaserGameElement >> refresh [
	"Show what the model says now: redraw the cells, put the right label on the fire button and
	set the counters. This is the original's #updateGameBoardAndControls, and page 142 adds the
	counters to it."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel.
	self controlPanel updateCounters
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
