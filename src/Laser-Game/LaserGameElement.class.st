"
I am the whole game on the screen: a control panel on the left, a board on the right, and a margin around both.

I replace the 2007 `LaserGame` morph of pages 065 to 067, which held a `SketchMorph` over a board form and a white rectangle for the panel. I hold a `LaserGameBoardElement` and a `LaserGameControlPanelElement` instead, and I take my size from them, the panel width and the margin, the way the original's `calculatedExtent` did. Page 139 puts the panel on the left, and page 140 fills me with the colour ramp of `LaserGameColors windowColorRamp`.

```
LaserGameElement openExample
LaserGameElement openStandardExample
LaserGameElement openRandomOfExtent: 12@12
```

From page 143 I also count the moves the player makes, and from page 146 I can start a new game on a randomized grid. Page 144 asks before quitting, which the original does with `#confirm:`; I lay a `LaserGameConfirmElement` over myself instead, since a Bloc element cannot wait for an answer.

I play on the grid I am given, of any size: page 147 splits the original's `#initialize` into `#initializeForGrid:` for that, and `#on:` is the same split. The board is one element per location, the panel keeps its width and takes the height of the board, and my own size follows both, so nothing but the grid decides how big the game is.

Instance variables:
- `grid`: the grid played on. Setting it rebuilds what I hold.
- `board`: the `LaserGameBoardElement` showing that grid.
- `controlPanel`: the panel beside it, holding the buttons and the counters.
- `moves`: how many moves have been made on the board.
- `confirmation`: the question laid over me, nil while none is asked.

I know nothing about the rules. The grid answers those, and the model-side `LaserGame` of the later sections will own the moves, the counters and the undo stack.
"
Class {
	#name : 'LaserGameElement',
	#superclass : 'BlElement',
	#instVars : [
		'grid',
		'board',
		'controlPanel',
		'moves',
		'confirmation'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
LaserGameElement class >> extentForGrid: aGrid [
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side. This is the original's calculatedExtent, with the board element
	standing in for the board form. The height is the taller of the board and the panel, since a
	board of few rows is shorter than everything the panel holds; the original has no such case
	and takes the board height alone."

	^ (LaserGameBoardElement extentForGrid: aGrid) x + self panelWidth
	  @ (LaserGameControlPanelElement heightForGrid: aGrid)
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

{ #category : 'instance creation' }
LaserGameElement class >> onRandomOfExtent: aPoint [
	"Answer a game on a freshly dealt board of aPoint columns by aPoint rows. This is page 147's
	LaserGame class >> randomizedGridOfExtent:, which builds the model with #basicNew and hands it
	the grid through #initializeForGrid:. A game here takes its grid from outside already, so #on:
	is that method, and this one only deals the board."

	^ self on: (GridFactory randomizedGridOfExtent: aPoint)
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
	"Open a space showing a game on aGrid and answer it. The space starts at the size the game is
	drawn at, and the game follows it from there: a window the player resizes scales the game to
	match, which the original, a Morph of a fixed size, does not do.

	LaserGameElement openOn: GridFactory demoGrid"

	| space element |
	space := BlSpace new.
	element := self on: aGrid.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: element.
	space root
		addEventHandlerOn: BlElementExtentChangedEvent
		do: [ :anEvent | element fitIn: space root extent ].
	element fitIn: space extent.
	space show.
	^ space
]

{ #category : 'instance creation' }
LaserGameElement class >> openRandomOfExtent: aPoint [
	"Open a game on a freshly dealt board of aPoint columns by aPoint rows and answer the space.
	Page 148 changes its workspace to this, so that the game opens on a board of the size asked
	for instead of the demo board.

	LaserGameElement openRandomOfExtent: 8@10"

	^ self openOn: (GridFactory randomizedGridOfExtent: aPoint)
]

{ #category : 'examples' }
LaserGameElement class >> openStandardExample [
	"Open the standard board of page 148: eight columns by ten rows, dealt. The demo board of
	#openExample is the five by five one the earlier sections play on.

	LaserGameElement openStandardExample"

	<sampleInstance>
	^ self openOn: GridFactory defaultGrid
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

{ #category : 'actions' }
LaserGameElement >> ask: aString onConfirm: aBlock [
	"Lay the question aString over me, and evaluate aBlock if the player answers yes. Either answer
	takes the question off first. One question is asked at a time, so a second click on Quit while
	the question stands does nothing."

	| question |
	self confirmation ifNotNil: [ ^ self ].
	question := LaserGameConfirmElement asking: aString.
	question extent: (self class extentForGrid: self grid).
	question whenAnsweredDo: [ :answer |
		self dismissQuestion.
		answer ifTrue: [ aBlock value ] ].
	confirmation := question.
	self addChild: question
]

{ #category : 'accessing' }
LaserGameElement >> board [
	"Answer the element showing the board."

	^ board
]

{ #category : 'actions' }
LaserGameElement >> close [
	"Close the game. The original sends #delete to its morph."

	self space ifNotNil: [ :aSpace | aSpace close ]
]

{ #category : 'accessing' }
LaserGameElement >> confirmation [
	"Answer the question laid over me, or nil while none is asked."

	^ confirmation
]

{ #category : 'accessing' }
LaserGameElement >> controlPanel [
	"Answer the panel beside the board. It is empty until the controls are added."

	^ controlPanel
]

{ #category : 'actions' }
LaserGameElement >> dismissQuestion [
	"Take the question off me. Answering does this, whichever answer it was."

	confirmation ifNil: [ ^ self ].
	self removeChild: confirmation.
	confirmation := nil
]

{ #category : 'geometry' }
LaserGameElement >> fitIn: anExtent [
	"Scale the game to a window of anExtent and centre it there. The original is a Morph of a
	fixed size and has nothing like this: it is the port's answer to a window the player can
	resize, and it costs nothing, because every cell is drawn from geometries rather than from a
	bitmap. A window of no size is left alone, since a space announces one while it opens."

	(anExtent x > 0 and: [ anExtent y > 0 ]) ifFalse: [ ^ self ].
	self transformDo: [ :aBuilder |
		aBuilder
			topLeftOrigin;
			scaleBy: (self scaleToFitIn: anExtent) ].
	self position: (self positionToCenterIn: anExtent)
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

{ #category : 'updating' }
LaserGameElement >> incrementMoves [
	"Count one more move. Page 143's #incrementMoves."

	self moves: self moves + 1
]

{ #category : 'initialization' }
LaserGameElement >> initialize [
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it. No move has been made yet."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin).
	moves := 0
]

{ #category : 'accessing' }
LaserGameElement >> laserIsActive [
	"Answer whether the laser is firing. The grid knows; I only ask."

	^ self grid laserIsActive
]

{ #category : 'updating' }
LaserGameElement >> moveMade [
	"A move was made on my board. Page 144 counts it and then updates the whole game; the board has
	already drawn its cells by the time it tells me, so only the counters are left to set."

	self incrementMoves.
	self controlPanel updateCounters
]

{ #category : 'accessing' }
LaserGameElement >> moves [
	"Answer how many moves the player has made. Page 143 counts every click on the board, and the
	player is meant to solve the puzzle in as few as possible."

	^ moves
]

{ #category : 'accessing' }
LaserGameElement >> moves: anInteger [
	"Say that anInteger moves have been made."

	moves := anInteger
]

{ #category : 'geometry' }
LaserGameElement >> naturalExtent [
	"Answer the extent the game is drawn at: the board, the panel and the margins, in the pixel
	sizes every page of the tutorial writes down. The window can be any size; this one is the
	size the drawing is scaled from."

	^ self class extentForGrid: self grid
]

{ #category : 'initialization' }
LaserGameElement >> newControlPanel [
	"Answer the control panel: the fixed-width column of buttons that sits beside the board."

	^ LaserGameControlPanelElement on: self
]

{ #category : 'actions' }
LaserGameElement >> newGame [
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
]

{ #category : 'geometry' }
LaserGameElement >> positionToCenterIn: anExtent [
	"Answer where the scaled game sits in a window of anExtent: in the middle of it, with the
	leftover of the looser direction split between the two sides."

	^ (anExtent - (self naturalExtent * (self scaleToFitIn: anExtent))) / 2
]

{ #category : 'actions' }
LaserGameElement >> quit [
	"Ask before closing. Page 144 makes the buttons smaller and puts Quit next to Fire, which is
	easy to hit by accident, so #quitGame asks first. The original asks with #confirm:, which opens
	a Morphic dialog and waits for the answer; a Bloc element does not wait, so the question is laid
	over the game and answers back."

	self ask: 'Are you sure you want to quit?' onConfirm: [ self close ]
]

{ #category : 'initialization' }
LaserGameElement >> rebuild [
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. Page 139 moves the panel to the left of the
	board, which here is the order the two are added in. The board tells me when a move changed the
	grid, so the counters follow a click as well as the fire button."

	self removeChildren.
	confirmation := nil.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: controlPanel.
	self addChild: board.
	board whenMoveMadeDo: [ self moveMade ].
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
LaserGameElement >> reset [
	"Put the board back where the game started: page 188 unwinds the whole undo stack, stops the
	laser and sets the move count to zero. The original's two other lines have no counterpart —
	#activeCellLocation: nil is the mouse press it remembers by hand, which Bloc delivers instead,
	and #initializeDirty is the repaint bookkeeping of a shared board form, where every cell here
	draws itself."

	self grid reset.
	self grid stopLaser.
	self moves: 0.
	self refresh
]

{ #category : 'geometry' }
LaserGameElement >> scaleToFitIn: anExtent [
	"Answer how much the game has to be scaled by to fill a window of anExtent without changing
	its shape: the tighter of the two directions, so the whole board stays in view and the cells
	stay square."

	| natural |
	natural := self naturalExtent.
	^ ((anExtent x / natural x) min: (anExtent y / natural y)) asFloat
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

{ #category : 'actions' }
LaserGameElement >> undo [
	"Take the last move back, and count the undo as a move of its own: page 183 says an undo must
	not remove any count from the player's total, so the counter goes up, not down. The grid
	answers whether it undid anything, and on an empty stack there is nothing to draw again. This
	is page 186's #undo, with #refresh for #updateGameBoardAndControls."

	self grid undo ifFalse: [ ^ self ].
	self incrementMoves.
	self refresh
]
