"
I am the control panel of the game: the column beside the board that holds its buttons and its counters.

I replace the panel the 2007 `LaserGame` morph built in `makeControlPanelMorph` and filled through `addButtonsToPanel:` and `addCountersToPanel:`. I hold Toplo buttons instead of `PluggableButtonMorph`s, and I hold what I am asked about in an instance variable, so nothing has to search the children by name the way `findFireButton`, `findLaserPathCounter` and `findMovesCounter` do.

Three buttons: Quit, which asks the game to close, and Fire, whose label says what a click will do — `'Fire'` while the laser is off, `'Stop'` while it fires, both from page 068 — and New, from page 144, which deals a new randomized board. Quit and Fire share the bottom row and New has the row above it, which is how page 144 numbers them. Two counters, from pages 141 and 143: the length of the beam, bright while the laser fires, and the number of moves made, never bright. The buttons sit at my bottom left corner and the counters at my top left corner, which is where the original's layout frames put them. Page 140 paints me transparent, so the window ramp behind me shows through. The divider, Undo and Reset come with their own pages.

Instance variables:
- `game`: the `LaserGameElement` I control. Setting it builds everything I show.
- `quitButton`, `fireButton`, `newGameButton`: the three buttons.
- `buttonColumn`: the column of button rows. `buttonRow` and `newGameRow` read its two rows.
- `laserPathCounter`, `movesCounter`: the two counters, in the order they are stacked.
- `counterColumn`: the column holding them.

I ask the game what to display and I tell the game what the player did. The one thing I read from the grid is the length of the beam, which is where page 143 reads it too.
"
Class {
	#name : 'LaserGameControlPanelElement',
	#superclass : 'BlElement',
	#instVars : [
		'game',
		'quitButton',
		'fireButton',
		'newGameButton',
		'buttonColumn',
		'laserPathCounter',
		'movesCounter',
		'counterColumn'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonGap [
	"Answer the gap, in pixels, between the buttons and around the row they sit in. The original
	spaces its buttons ten pixels apart, and the horizontal gap its arithmetic produces for two
	buttons in a panel of this width comes to the same ten."

	^ 10
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonHeight [
	"Answer the height, in pixels, of a control panel button. The original's number."

	^ 20
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonWidth [
	"Answer the width, in pixels, of a control panel button. The original's number."

	^ 40
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> counterGap [
	"Answer the gap, in pixels, between the counters and around the column they sit in. Page 141
	insets its counter four pixels from the top and the left of the panel."

	^ 4
]

{ #category : 'instance creation' }
LaserGameControlPanelElement class >> on: aGame [
	"Answer a control panel for aGame."

	| panel |
	panel := self new.
	panel game: aGame.
	^ panel
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> buttonColumn [
	"Answer the column of button rows at the bottom of me."

	^ buttonColumn
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> buttonRow [
	"Answer the bottom row of buttons. Page 144 counts rows from the bottom, so it is the last row
	of the column."

	^ self buttonColumn children last
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> counterColumn [
	"Answer the column of counters at the top of me."

	^ counterColumn
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> fireButton [
	"Answer the button that fires and stops the laser. I hold it, so nothing has to search for it
	by name."

	^ fireButton
]

{ #category : 'updating' }
LaserGameControlPanelElement >> fireButtonLabel [
	"Answer what the fire button says: what a click will do, not what the laser is doing."

	^ self game laserIsActive
		  ifTrue: [ 'Stop' ]
		  ifFalse: [ 'Fire' ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> game [
	"Answer the game this panel controls."

	^ game
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> game: aGame [
	"Control aGame. Setting the game builds the buttons, since a button acts on a game."

	game := aGame.
	self rebuild
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> initialize [
	"A panel is a blank column with its buttons at the bottom left corner, as the original places
	them. A frame layout puts a child where it is aligned, which is what the original's layout
	frames do."

	super initialize.
	self background: LaserGameColors controlPanelColor.
	self layout: BlFrameLayout new
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> laserPathCounter [
	"Answer the counter showing how long the laser beam is. I hold it, so nothing has to search
	for it: page 142 finds it by walking every morph of the game looking for the name
	'laserPath'."

	^ laserPathCounter
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> movesCounter [
	"Answer the counter showing how many moves the player has made. I hold it, so nothing has to
	search for it: page 143 finds it by walking every morph of the game looking for the name
	'moves'."

	^ movesCounter
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButton: aLabel action: aBlock [
	"Answer a labelled button of the original's size that evaluates aBlock when it is clicked. The
	original builds a PluggableButtonMorph with a StringMorph label and paints its colors by hand;
	Toplo gives the look and the click, so only the label, the size and the action are left."

	| button |
	button := ToButton labelText: aLabel.
	button extent: self class buttonWidth @ self class buttonHeight.
	button clickAction: aBlock.
	^ button
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButtonColumn [
	"Answer the column of button rows: the bottom left corner of the panel, one gap from both
	edges, the rows one gap apart, the last row against the bottom. Page 144 places each button
	itself with #buttonLayoutFrameForRow:column:, which counts rows from the bottom and columns
	from the left; a column of rows says the same thing, and the rows of Section 5 fall in above
	these two. The cell spacing of a linear layout is added around the cells as well as between
	them, so it is the whole of the gap: a margin here would double the gap on the left and push
	the last button of the bottom row against the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class buttonGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButtonRow [
	"Answer the bottom row of buttons: Quit first, then Fire. Page 144 calls them row one, columns
	one and two."

	^ self newRowOfButtons: {
			  quitButton.
			  fireButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newCounterColumn [
	"Answer the column of counters: the beam length, and the move count under it, at the top left
	corner of the panel, one gap away from both edges. Page 143 places the second counter with a
	layout frame forty-four pixels below the first, which is the height of one counter and this
	gap."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class counterGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignTop ].
	column margin: (BlInsets all: self class counterGap).
	column addChild: laserPathCounter.
	column addChild: movesCounter.
	^ column
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newFireButton [
	"Answer the button that fires the laser, or stops it if it is already firing. Its label says
	which of the two a click will do."

	^ self newButton: self fireButtonLabel action: [ self game toggleLaser ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> newGameButton [
	"Answer the button that starts a new game."

	^ newGameButton
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> newGameRow [
	"Answer the row above the buttons, holding the New button. It is the first row of the column,
	since the column reads from the top and page 144 counts from the bottom."

	^ self buttonColumn children first
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newLaserPathCounter [
	"Answer the counter showing how long the laser beam is: three digits, captioned as on page
	141. Three digits hold every path a board of this size can produce."

	^ LaserGameCounterElement labelled: 'Laser Path' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newMovesCounter [
	"Answer the counter showing how many moves the player has made: three digits, captioned as on
	page 143."

	^ LaserGameCounterElement labelled: 'Moves' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newNewGameButton [
	"Answer the button that throws the board away and deals a new one: page 144's
	#makeNewGameButton."

	^ self newButton: 'New' action: [ self game newGame ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newNewGameRow [
	"Answer the row above it, holding the New button on the left. Page 144 calls it row two,
	column one."

	^ self newRowOfButtons: { newGameButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newQuitButton [
	"Answer the button that closes the game. The original sends #delete to its morph."

	^ self newButton: 'Quit' action: [ self game quit ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newRowOfButtons: aCollection [
	"Answer a row holding the buttons of aCollection, one gap apart, no wider than they need."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	aCollection do: [ :each | row addChild: each ].
	^ row
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> quitButton [
	"Answer the button that closes the game."

	^ quitButton
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> rebuild [
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	counterColumn := self newCounterColumn.
	buttonColumn := self newButtonColumn.
	self addChild: counterColumn.
	self addChild: buttonColumn.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y.
	self updateCounters
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateCounters [
	"Show how long the beam is while the laser fires, and nothing while it does not, and show how
	many moves have been made. This is page 143's #updateCounters, which has to find each display
	among the morphs of the game first; I hold both. The move count is never bright: only the beam
	says whether the laser is on."

	self game laserIsActive
		ifTrue: [
			self laserPathCounter
				highlighted: true;
				value: self game grid laserBeamPath size ]
		ifFalse: [
			self laserPathCounter
				highlighted: false;
				value: 0 ].
	self movesCounter
		highlighted: false;
		value: self game moves
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateFireButtonLabel [
	"Make the fire button say what a click will do now. The original has to find the button among
	its submorphs by name; I hold it in an instance variable."

	self fireButton labelText: self fireButtonLabel
]
