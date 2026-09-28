"
I am the control panel of the game: the column beside the board that holds its buttons and its counters.

I replace the panel the 2007 `LaserGame` morph built in `makeControlPanelMorph` and filled through `addButtonsToPanel:` and `addCountersToPanel:`. I hold Toplo buttons instead of `PluggableButtonMorph`s, and I hold everything I show in an instance variable, so nothing has to search the children by name the way `findFireButton` and `findLaserPathCounter` do.

Two buttons so far, both from page 068: Quit, which closes the game, and Fire, whose label says what a click will do — `'Fire'` while the laser is off, `'Stop'` while it fires. One counter, from page 141: the length of the beam, bright while the laser fires and zero while it does not. The buttons sit at my bottom left corner and the counters at my top left corner, which is where the original's layout frames put them. Page 140 paints me transparent, so the window ramp behind me shows through. The divider and the New Game, Undo and Reset buttons come with their own pages.

Instance variables:
- `game`: the `LaserGameElement` I control. Setting it builds everything I show.
- `quitButton`, `fireButton`: the two buttons, in the order they sit in the row.
- `buttonRow`: the row holding them.
- `laserPathCounter`: the counter showing the length of the beam.
- `counterColumn`: the column holding the counters.

I ask the game what to display and I tell the game what the player did. The one thing I read from the grid is the length of the beam, which is where page 142 reads it too.

"
Class {
	#name : 'LaserGameControlPanelElement',
	#superclass : 'BlElement',
	#instVars : [
		'game',
		'quitButton',
		'fireButton',
		'buttonRow',
		'laserPathCounter',
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
LaserGameControlPanelElement >> buttonRow [
	"Answer the row of buttons at the bottom of me."

	^ buttonRow
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
LaserGameControlPanelElement >> newButtonRow [
	"Answer the row of buttons: Quit first, then Fire, one gap apart. The original puts these two
	in the bottom row of its panel, and the rest of its buttons come later."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	row margin: (BlInsets all: self class buttonGap).
	row addChild: quitButton.
	row addChild: fireButton.
	^ row
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newCounterColumn [
	"Answer the column of counters: one so far, at the top left corner of the panel, one gap away
	from both edges. The original places it with a layout frame of the same offsets, and the
	counters of page 143 fall in under this one."

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
	^ column
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newFireButton [
	"Answer the button that fires the laser, or stops it if it is already firing. Its label says
	which of the two a click will do."

	^ self newButton: self fireButtonLabel action: [ self game toggleLaser ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newLaserPathCounter [
	"Answer the counter showing how long the laser beam is: three digits, captioned as on page
	141. Three digits hold every path a board of this size can produce."

	^ LaserGameCounterElement labelled: 'Laser Path' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newQuitButton [
	"Answer the button that closes the game. The original sends #delete to its morph."

	^ self newButton: 'Quit' action: [ self game quit ]
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
	laserPathCounter := self newLaserPathCounter.
	counterColumn := self newCounterColumn.
	buttonRow := self newButtonRow.
	self addChild: counterColumn.
	self addChild: buttonRow.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y.
	self updateCounters
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateCounters [
	"Show how long the beam is while the laser fires, and nothing while it does not. This is page
	142's #updateCounters, which has to find the LED among the morphs of the game first; I hold
	it."

	self game laserIsActive
		ifTrue: [
			self laserPathCounter
				highlighted: true;
				value: self game grid laserBeamPath size ]
		ifFalse: [
			self laserPathCounter
				highlighted: false;
				value: 0 ]
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateFireButtonLabel [
	"Make the fire button say what a click will do now. The original has to find the button among
	its submorphs by name; I hold it in an instance variable."

	self fireButton labelText: self fireButtonLabel
]
