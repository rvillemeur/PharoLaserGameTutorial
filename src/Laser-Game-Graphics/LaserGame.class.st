Class {
	#name : #LaserGame,
	#superclass : #Morph,
	#instVars : [
		'grid',
		'boardForm'
	],
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
LaserGame class >> boardExtendFor: aGrid [

	| x y |
	x := CellRenderer cellExtent x * aGrid numberOfColumns.
	y := CellRenderer cellExtent y * aGrid numberOfRows.
	^ x @ y
]

{ #category : #accessing }
LaserGame >> boardForm [

	^ boardForm
]

{ #category : #accessing }
LaserGame >> boardForm: anObject [

	boardForm := anObject
]

{ #category : #drawing }
LaserGame >> calculateExtent [

	| pt |
	pt := self boardForm extent.
	pt := pt + (self panelWidth @ 0).
	^ pt
]

{ #category : #drawing }
LaserGame >> drawGameBoard [

	| cell renderer |
	1 to: self grid numberOfColumns do: [ :x |
		1 to: self grid numberOfRows do: [ :y |
			cell := self grid at: x @ y.
			renderer := CellRenderer
				            rendererFor: cell
				            grid: self grid
				            form: self boardForm.
			renderer render ] ]
]

{ #category : #drawing }
LaserGame >> findFireButton [

	^ self allMorphs
		  detect: [ :m | m externalName = 'fireButton' ]
		  ifNone: [  ]
]

{ #category : #'as yet unclassified' }
LaserGame >> fireButtonLabel [

	^ self laserActive
		  ifTrue: [ 'Stop' ]
		  ifFalse: [ 'Fire' ]
]

{ #category : #drawing }
LaserGame >> fireLaser [

	self laserActive
		ifTrue: [ self grid stopLaser ]
		ifFalse: [ self grid fireLaser ].
	self drawGameBoard.
	self changed.
	self updateFireButtonLabel.
]

{ #category : #accessing }
LaserGame >> grid [

	^ grid
]

{ #category : #accessing }
LaserGame >> grid: anObject [

	grid := anObject
]

{ #category : #initialization }
LaserGame >> initialize [
	super initialize.
	self grid: GridFactory demoGrid .
	self boardForm: (Form extent: (self class boardExtendFor: self grid) depth: Display depth).
	self boardForm fillColor: LaserGameColors gameBoardBackgroundColor.
	self extent.
	self setupMorphs.
	self drawGameBoard 
]

{ #category : #drawing }
LaserGame >> laserActive [

	^ self grid laserIsActive 
]

{ #category : #drawing }
LaserGame >> makeButton: label action: actionSymbol state: stateSymbol [

	| btn labelMorph |
	btn := PluggableButtonMorph
		       on: self
		       getState: stateSymbol
		       action: actionSymbol.
	labelMorph := StringMorph contents: label.
	labelMorph emphasis: 1.
	btn
		label: labelMorph;
		useRoundedCorners;
		hResizing: #spaceFill;
		onColor: Color veryLightGray offColor: Color lightGray;
		borderWidth: 2;
		borderColor: #raised.
	btn label color: Color darkGray.
	^ btn
]

{ #category : #drawing }
LaserGame >> makeControlPanelMorph [

	| panel buttonHeight vertOffsetTop vertOffsetBtm |
	panel := BorderedMorph  new
		         borderWidth: 0;
		         color: Color white;
		         layoutPolicy: RowLayout  new.
	buttonHeight := 26.
	vertOffsetTop := 10 + buttonHeight + 10 + buttonHeight.
	vertOffsetBtm := 10 + buttonHeight  + 10.
	panel addMorph:  self makeFireLaserButton.
	panel addMorph: self makeQuitGameButton . 
	
	^ panel
]

{ #category : #drawing }
LaserGame >> makeFireLaserButton [

	| btn |
	btn := self
		       makeButton: self fireButtonLabel
		       action: #fireLaser
		       state: #laserActive.
	btn name: 'fireButton'.
	^ btn
]

{ #category : #drawing }
LaserGame >> makeGameBoardMorph [

	| boardMorph |
	boardMorph := ImageMorph withForm: self boardForm.
	^ boardMorph
]

{ #category : #drawing }
LaserGame >> makeQuitGameButton [

	^ self makeButton: 'Quit' action: #quitGame state: nil
]

{ #category : #drawing }
LaserGame >> panelWidth [

	^ 100
]

{ #category : #drawing }
LaserGame >> quitGame [

	self delete
]

{ #category : #drawing }
LaserGame >> setExtent [

	self extent: self calculateExtent
]

{ #category : #drawing }
LaserGame >> setupMorphs [

	self layoutPolicy: RowLayout  new.
	self addMorph: self makeGameBoardMorph "fullFrame: (LayoutFrame new
			 leftFraction: (0 @ 0 corner: 1 @ 10)
			 offset: (0 @ 0 corner: self panelWidth negated @ 0)).".
	self addMorph: self makeControlPanelMorph" fullFrame: (LayoutFrame new
			 leftFraction: (1 @ 0 corner: 1 @ 1)
			 offset: (self panelWidth negated @ 0 corner: 0 @ 0))"
]

{ #category : #drawing }
LaserGame >> updateFireButtonLabel [

	| btn |
	btn := self findFireButton.
	btn notNil ifTrue: [ btn label contents: self fireButtonLabel ]
]
