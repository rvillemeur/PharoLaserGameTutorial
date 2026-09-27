"
I am the control panel of the game: the column beside the board that holds its buttons.

I replace the panel the 2007 `LaserGame` morph built in `makeControlPanelMorph` and filled through `addButtonsToPanel:`. I hold Toplo buttons instead of `PluggableButtonMorph`s, and I hold each one in an instance variable, so nothing has to search the children by name the way `findFireButton` does.

Two buttons so far, both from page 068: Quit, which closes the game, and Fire, whose label says what a click will do — `'Fire'` while the laser is off, `'Stop'` while it fires. The counters, the divider and the New Game, Undo and Reset buttons come with their own pages.

Instance variables:
- `game`: the `LaserGameElement` my buttons act on. Setting it builds the buttons.
- `quitButton`, `fireButton`: the two buttons, in the order they sit in the row.

I ask the game what to display and I tell the game what the player did. I never touch the grid myself.
"
Class {
	#name : 'LaserGameControlPanelElement',
	#superclass : 'BlElement',
	#instVars : [
		'game',
		'quitButton',
		'fireButton'
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

{ #category : 'instance creation' }
LaserGameControlPanelElement class >> on: aGame [
	"Answer a control panel for aGame."

	| panel |
	panel := self new.
	panel game: aGame.
	^ panel
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
LaserGameControlPanelElement >> newFireButton [
	"Answer the button that fires the laser, or stops it if it is already firing. Its label says
	which of the two a click will do."

	^ self newButton: self fireButtonLabel action: [ self game toggleLaser ]
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
	"Replace what I hold with a fresh row of buttons for my game, and take the width of a panel and
	the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	self addChild: self newButtonRow.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateFireButtonLabel [
	"Make the fire button say what a click will do now. The original has to find the button among
	its submorphs by name; I hold it in an instance variable."

	self fireButton labelText: self fireButtonLabel
]
