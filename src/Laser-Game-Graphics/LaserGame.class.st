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

{ #category : #'events - processing' }
LaserGame >> boardRelativePositionFor: evt [

	| evtPosn |
	evtPosn := evt hand position.
	^ evtPosn - self position
]

{ #category : #drawing }
LaserGame >> calculateExtent [

	| pt |
	pt := self boardForm extent.
	pt := pt + (self panelWidth @ 0).
	^ pt
]

{ #category : #'events - processing' }
LaserGame >> cellForEvent: evt [

	| posn |
	posn := self cellPositionForEvent: evt.
	^ self grid at: posn
]

{ #category : #'events - processing' }
LaserGame >> cellPositionForEvent: evt [

	| posn ext counts |
	posn := self boardRelativePositionFor: evt.
	ext := CellRenderer cellExtent.
	counts := posn // ext.
	counts := counts + (1 @ 1).
	^ counts
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

{ #category : #'events - processing' }
LaserGame >> handleListenEvent: evt [

	| pos unders boardMorph |
	((evt isMouse and: [ evt isMove ]) and: [ evt isMouseDown not ])
		ifFalse: [ ^ self ].
	pos := evt hand position.
	unders := self morphsAt: pos.
	unders isEmpty ifTrue: [ ^ self ].
	boardMorph := unders detect: [ :m | m externalName = 'board' ] ifNone: [  ].
	boardMorph isNil ifTrue: [ ^ self ].
	self mouseMoveWhileButtonDown: evt forMorph: boardMorph
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
	boardMorph name: 'board'.
	boardMorph 
		on: #mouseUp send: #mouseUp:forMorph: to: self;
		on: #mouseDown send: #mouseDown:forMorph: to: self;
		on: #mouseEnter send: #mouseEnter:forMorph: to: self;
		on: #mouseLeave send: #mouseLeave:forMorph: to: self;
		on: #mouseMove send: #mouseMoveWhileButtonDown:forMorph: to: self.
		
	^ boardMorph
]

{ #category : #drawing }
LaserGame >> makeQuitGameButton [

	^ self makeButton: 'Quit' action: #quitGame state: nil
]

{ #category : #'events - processing' }
LaserGame >> mouseDown: evt forMorph: anImageMorph [
]

{ #category : #'events - processing' }
LaserGame >> mouseEnter: evt forMorph: anImageMorph [

	evt hand addMouseListener: self
]

{ #category : #'events - processing' }
LaserGame >> mouseLeave: evt forMorph: anImageMorph [

	evt hand removeMouseListener: self
]

{ #category : #'events - processing' }
LaserGame >> mouseMoveWhileButtonDown: evt forMorph: anImageMorph [

	| cell renderer pixelPositionWithinBoard|
	cell := self cellForEvent: evt.
	renderer := CellRenderer rendererFor:  cell grid: self grid  form: boardForm.
	pixelPositionWithinBoard := self boardRelativePositionFor: evt.
	renderer showPositionHintFromWithinBoardOffset: pixelPositionWithinBoard.
	self changed.
	
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
