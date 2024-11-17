Class {
	#name : #LaserGame,
	#superclass : #Morph,
	#instVars : [
		'grid',
		'boardForm',
		'activeCellLocation',
		'dirty',
		'moves'
	],
	#classVars : [
		'FullWorld'
	],
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
LaserGame class >> addApplication [
	"LaserGame addApplication"
	Smalltalk addToStartUpList: LaserGame.

]

{ #category : #'as yet unclassified' }
LaserGame class >> boardExtendFor: aGrid [

	| x y |
	x := CellRenderer cellExtent x * aGrid numberOfColumns.
	y := CellRenderer cellExtent y * aGrid numberOfRows.
	^ x @ y
]

{ #category : #'as yet unclassified' }
LaserGame class >> boardExtentFor: aGrid [
	| x y |
	x := CellRenderer cellExtent x * aGrid numberOfColumns.
	y := CellRenderer cellExtent y * aGrid numberOfRows.
	^x@y
]

{ #category : #'as yet unclassified' }
LaserGame class >> clearApplication [
	"LaserGame clearApplication"
	Smalltalk removeFromStartUpList: LaserGame.

]

{ #category : #'as yet unclassified' }
LaserGame class >> closeAllOpenWindowsMessage [
	^'Do you really want to close all windows?' translated
]

{ #category : #'as yet unclassified' }
LaserGame class >> closeAllWindows [
	"LaserGame closeAllWindows"
	(SystemWindow windowsIn: World satisfying: [:w | w model canDiscardEdits])
		do: [:w | w delete]
]

{ #category : #'as yet unclassified' }
LaserGame class >> disableFeatures [
	Preferences disable: #warnIfNoSourcesFile.
	Preferences disable: #warnIfNoChangesFile.
	Preferences disable: #cmdDotEnabled.
	Preferences enable: #eToyFriendly.
	Preferences enable: #noviceMode.
	Preferences compileHardCodedPref: #cmdGesturesEnabled enable: false.
	Preferences compileHardCodedPref: #cmdKeysInText enable: false.
	HaloMorph compileSilently: 'addCircleHandles' classified: 'disable'.
	


]

{ #category : #'as yet unclassified' }
LaserGame class >> fullWorld [
	FullWorld isNil ifTrue: [self fullWorld: false].
	^FullWorld
]

{ #category : #'as yet unclassified' }
LaserGame class >> fullWorld: aBoolean [
	"LaserGame fullWorld: false"
	FullWorld := aBoolean

]

{ #category : #'as yet unclassified' }
LaserGame class >> launchFullWorld [
	"LaserGame launchFullWorld"
	| morph |
	self fullWorld: true.
	morph := self new.
	morph openInWorld.
	^morph
]

{ #category : #'as yet unclassified' }
LaserGame class >> launchStandard [
	"LaserGame launchStandard"
	| morph |
	self fullWorld: false.
	morph := self new.
	morph openInHand
]

{ #category : #'as yet unclassified' }
LaserGame class >> prepareApplication [
	"LaserGame prepareApplication"
	(self confirm: self prepareApplicationWarningMessage) ifTrue: [
		(SelectionMenu confirm: self closeAllOpenWindowsMessage) ifFalse: [^ self].
		self closeAllWindows.
		self launchFullWorld.
		self disableFeatures.
		self addApplication.
		SmalltalkImage current saveAs.
		]

]

{ #category : #'as yet unclassified' }
LaserGame class >> prepareApplicationWarningMessage [
	^'Really make a stand-alone image?
	Any existing Laser Game morpsh should be closed.
A new one will be re-created by this process.
Important developer tools will be disabled.
The image should be saved a new name as the final step of this process.' translated

]

{ #category : #'as yet unclassified' }
LaserGame class >> purgeAndAnswerSoleInstance [
	"LaserGame purgeAndAnswerSoleInstance"
	| coll result |
	coll := self allInstances.
	coll size > 1 ifTrue: [2 to: coll size do: [:index |
			| morph |
			morph := coll at: index.
			morph delete]].
	result := coll isEmpty
		ifTrue: [nil]
		ifFalse: [coll first].
	^result
]

{ #category : #'as yet unclassified' }
LaserGame class >> randomizedGridOfExtent: aPoint [
	| model grid |
	model := self basicNew.
	grid := GridFactory randomizedGridOfExtent: aPoint.
	model initializeForGrid: grid.
	^model
]

{ #category : #'as yet unclassified' }
LaserGame class >> startUp [
	| soleInstance |
	soleInstance := self purgeAndAnswerSoleInstance.
	soleInstance isNil ifTrue: [soleInstance := self launchFullWorld].
	GridFactory reSeed.
	soleInstance newGame.
	
]

{ #category : #accessing }
LaserGame >> activeCellLocation [
	^activeCellLocation
]

{ #category : #accessing }
LaserGame >> activeCellLocation: aPoint [
	activeCellLocation := aPoint
]

{ #category : #accessing }
LaserGame >> addButtonsToPanel: panel [
	| layout |
	layout := self buttonLayoutFrameForRow: 1 column: 1.
	panel addMorph: self makeQuitGameButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 1 column: 2.
	panel addMorph: self makeFireLaserButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 2 column: 1.
	panel addMorph: self makeNewGameButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 2 column: 2.
	panel addMorph: self makeUndoButton fullFrame: layout.

	layout := self buttonLayoutFrameForRow: 3 column: 1.
	panel addMorph: self makeResetButton fullFrame: layout.

	^panel
]

{ #category : #initialization }
LaserGame >> addCountersToPanel: panel [
	panel
		addMorph: self makeLaserPathCounterMorph
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (4 @ 4 corner: -8 @ 44));
				
		addMorph: self makeMovesCounterMorph
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (4 @ 48 corner: -8 @ 92));
				
		addMorph: self makeMirrorsCounterMorph
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (4 @ 96 corner: -8 @ 140));

		addMorph: self makeActiveMirrorsCounterMorph
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 0)
				offsets: (4 @ 144 corner: -8 @ 188))
]

{ #category : #accessing }
LaserGame >> addDividerBarToPanel: panel [
	| layout offset |
	offset := -105.
	layout := LayoutFrame
		fractions: (0 @ 1 corner: 0 @ 1)
		offsets: (10@offset corner: (self panelWidth - 10)@(offset + 5)).
	panel addMorph: self makePanelDividerMorph fullFrame: layout.
	^panel
]

{ #category : #accessing }
LaserGame >> boardForm [
	"Answer the value of boardForm"

	^ boardForm
]

{ #category : #accessing }
LaserGame >> boardForm: anObject [
	"Set the value of boardForm"

	boardForm := anObject
]

{ #category : #'events-processing' }
LaserGame >> boardRelativePositionFor: evt [
	| evtPosn |
	evtPosn := evt hand position.
	^evtPosn - self position - ((self gameMargin + self panelWidth) @ self gameMargin)
]

{ #category : #initialization }
LaserGame >> buttonLayoutFrameForRow: fromBottom column: fromLeft [
	| buttonHeight buttonWidth xOffset xOrigin yOrigin xCorner yCorner yOffset |
	buttonHeight := 20.
	buttonWidth := 40.
	xOffset := (self panelWidth - (2 * buttonWidth)) // 3.
	yOffset := 10.

	xOrigin := xOffset * fromLeft.
	xOrigin := xOrigin + ((fromLeft - 1) * buttonWidth).

	yOrigin := yOffset * fromBottom.
	yOrigin := yOrigin + (fromBottom * buttonHeight).
	yOrigin := yOrigin negated.

	xCorner := xOrigin + buttonWidth.
	yCorner := yOrigin + buttonHeight.

	^LayoutFrame
		fractions: (0 @ 1 corner: 0 @ 1)
		offsets: (xOrigin@yOrigin corner: xCorner@yCorner)
]

{ #category : #drawing }
LaserGame >> calculateExtent [

	| pt |
	pt := self boardForm extent.
	pt := pt + (self panelWidth @ 0).
	^ pt
]

{ #category : #initialization }
LaserGame >> calculatedExtent [
	| pt |
	pt := self boardForm extent.
	pt := pt + (self panelWidth@0).
	pt := pt + (2 * self gameMargin).
	^pt
]

{ #category : #'events-processing' }
LaserGame >> cellForEvent: evt [
	| posn |
	posn := self cellPositionForEvent: evt.
	^self grid at: posn
]

{ #category : #'events-processing' }
LaserGame >> cellPositionForEvent: evt [
	| posn ext counts |
	posn := self boardRelativePositionFor: evt.
	ext := CellRenderer cellExtent.
	counts := posn // ext.
	counts := counts + (1@1).
	^counts
]

{ #category : #accessing }
LaserGame >> dirty [
	dirty isNil ifTrue: [self initializeDirty].
	^dirty
]

{ #category : #accessing }
LaserGame >> dirty: aDictionary [
	dirty := aDictionary
]

{ #category : #drawing }
LaserGame >> drawGameBoard [
	| cell renderer |
	1 to: self grid numberOfColumns do: [:x |
		1 to: self grid numberOfRows do: [:y |
			cell := self grid at: x@y.
			renderer := CellRenderer rendererFor: cell grid: self grid form: self boardForm.
		renderer render]].
]

{ #category : #'events-processing' }
LaserGame >> eventDiagnosticFor: evt tag: aString [
	| cell posn |
	cell := self cellForEvent: evt.
	posn := self boardRelativePositionFor: evt.
	Transcript
		show: aString, ' at ', posn asString; cr;
		show: cell asString; cr;
		cr
]

{ #category : #initialization }
LaserGame >> findActiveMirrorsCounter [
	^self allMorphs detect: [:m | m knownName = 'activeMirrors'] ifNone: []
]

{ #category : #'as yet unclassified' }
LaserGame >> findFireButton [
	^self allMorphs detect: [:m | m knownName = 'fireButton'] ifNone: []
]

{ #category : #initialization }
LaserGame >> findLaserPathCounter [
	^self allMorphs detect: [:m | m knownName = 'laserPath'] ifNone: []
]

{ #category : #initialization }
LaserGame >> findMirrorsCounter [
	^self allMorphs detect: [:m | m knownName = 'mirrors'] ifNone: []
]

{ #category : #initialization }
LaserGame >> findMovesCounter [
	^self allMorphs detect: [:m | m knownName = 'moves'] ifNone: []
]

{ #category : #'as yet unclassified' }
LaserGame >> fireButtonLabel [
	^self laserActive
		ifTrue: ['Stop']
		ifFalse: ['Fire']
]

{ #category : #'as yet unclassified' }
LaserGame >> fireLaser [
	self laserActive
		ifTrue: [self grid stopLaser]
		ifFalse: [self grid fireLaser].
	self updateGameBoardAndControls
]

{ #category : #initialization }
LaserGame >> gameMargin [
	^10
]

{ #category : #accessing }
LaserGame >> grid [
	"Answer the value of grid"

	^ grid
]

{ #category : #accessing }
LaserGame >> grid: anObject [
	"Set the value of grid"

	grid := anObject
]

{ #category : #'events-processing' }
LaserGame >> handleListenEvent: evt [
	| pos unders boardMorph |
	((evt isMouse and: [evt isMove]) and: [evt isMouseDown not]) ifFalse: [^self].
	pos := evt hand position.
	unders := self morphsAt: pos.
	unders isEmpty ifTrue: [^self].
	boardMorph := unders detect: [:m | m knownName = 'board'] ifNone: [].
	boardMorph isNil ifTrue: [^self].
	self mouseMoveWhileButtonUp: evt forMorph: boardMorph
]

{ #category : #'as yet unclassified' }
LaserGame >> incrementMoves [
	self moves: self moves + 1
]

{ #category : #initialization }
LaserGame >> initialize [
	self initializeForGrid: GridFactory emptyStandardGrid
]

{ #category : #accessing }
LaserGame >> initializeDirty [
	self dirty: Dictionary new
]

{ #category : #initialization }
LaserGame >> initializeForGrid: aGrid [
	super initialize.
	self moves: 0.
	self grid: aGrid.
	self boardForm: (Form extent: (self class boardExtentFor: self grid) depth: Display depth).
	self boardForm fillColor: LaserGameColors gameBoardBackgroundColor.
	self class fullWorld ifTrue: [
		self setToAdhereToEdge: #adjustedCenter.
		self beSticky].
	self setExtent.
	self setupMorphs.
	self drawGameBoard.
	self updateCounters.
]

{ #category : #'as yet unclassified' }
LaserGame >> isDirty: aCell [
	^self dirty at: aCell gridLocation ifAbsent: [false]
]

{ #category : #'as yet unclassified' }
LaserGame >> laserActive [
	^self grid laserIsActive
]

{ #category : #initialization }
LaserGame >> makeActiveMirrorsCounterMorph [
	| count |
	count := LedMorph new
				digits: 3;
				extent: 3 * 10 @ 15;
				setBalloonText: ''.
	count color: (Color r: 0.674 g: 0.674 b: 0.96).
	count name: 'activeMirrors'.
	^ self wrapPanel: count label: 'Active Mirrors'
]

{ #category : #'as yet unclassified' }
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

{ #category : #initialization }
LaserGame >> makeControlPanelMorph [
	| panel |
	panel := RectangleMorph new borderWidth: 0;
				 color: Color transparent;
				 layoutPolicy: ProportionalLayout new.
	self addButtonsToPanel: panel.
	self addCountersToPanel: panel.
	self addDividerBarToPanel: panel.
	^panel
]

{ #category : #'as yet unclassified' }
LaserGame >> makeFireLaserButton [
	| btn |
	btn := self makeButton: self fireButtonLabel action: #fireLaser state: #laserActive.
	btn name: 'fireButton'.
	^btn
]

{ #category : #initialization }
LaserGame >> makeGameBoardMorph [
	| boardMorph |
	boardMorph := SketchMorph withForm: self boardForm.
	boardMorph name: 'board'.
	boardMorph
		on: #mouseUp send: #mouseUp:forMorph: to: self;
		on: #mouseDown send: #mouseDown:forMorph: to: self;
		on: #mouseEnter send: #mouseEnter:forMorph: to: self;
		on: #mouseLeave send: #mouseLeave:forMorph: to: self;
		on: #mouseMove send: #mouseMoveWhileButtonDown:forMorph: to: self.
	boardMorph
		hasDropShadow: true;
		shadowOffset: 3@3;
		shadowColor: (Color r: 0.25 g: 0.25 b: 0.254).
	^boardMorph
]

{ #category : #initialization }
LaserGame >> makeLaserHomeMorph [
	| form |
	form := Form
		extent: CellRenderer cellExtent x @ self gameMargin 
		depth: self boardForm depth.
	form fillColor: LaserGameColors laserBeamSplatterColor.
	^SketchMorph withForm: form
]

{ #category : #initialization }
LaserGame >> makeLaserPathCounterMorph [
	| count |
	count := LedMorph new
				digits: 3;
				extent: 3 * 10 @ 15;
				setBalloonText: ''.
	count color: (Color r: 0.674 g: 0.674 b: 0.96).
	count name: 'laserPath'.
	^ self wrapPanel: count label: 'Laser Path'
]

{ #category : #initialization }
LaserGame >> makeMirrorsCounterMorph [
	| count |
	count := LedMorph new
				digits: 3;
				extent: 3 * 10 @ 15;
				setBalloonText: ''.
	count color: (Color r: 0.674 g: 0.674 b: 0.96).
	count name: 'mirrors'.
	^ self wrapPanel: count label: 'Mirrors'
]

{ #category : #initialization }
LaserGame >> makeMovesCounterMorph [
	| count |
	count := LedMorph new
				digits: 3;
				extent: 3 * 10 @ 15;
				setBalloonText: ''.
	count color: (Color r: 0.674 g: 0.674 b: 0.96).
	count name: 'moves'.
	^ self wrapPanel: count label: 'Moves'
]

{ #category : #'as yet unclassified' }
LaserGame >> makeNewGameButton [
	^self makeButton: 'New' action: #newGame state: nil
]

{ #category : #initialization }
LaserGame >> makePanelDividerMorph [
	| divider |
	divider := RectangleMorph new.
	divider
		layoutPolicy: ProportionalLayout new;
		borderWidth: 2;
		borderStyle: (BorderStyle complexRaised width: 3);
		color: Color gray;
		fillStyle: ((GradientFillStyle ramp: 
					{0.0->(Color r: 0.847 g: 0.847 b: 0.85).
					1.0->(Color r: 0.972 g: 0.972 b: 0.976)})
						origin: 30@400;
						direction: 0@40;
						normal: 50@0;
						radial: false
					).
	^divider
]

{ #category : #'as yet unclassified' }
LaserGame >> makeQuitGameButton [
	^self makeButton: 'Quit' action: #quitGame state: nil
]

{ #category : #'as yet unclassified' }
LaserGame >> makeResetButton [
	^self makeButton: 'Reset' action: #reset state: nil
]

{ #category : #'as yet unclassified' }
LaserGame >> makeUndoButton [
	^self makeButton: 'Undo' action: #undo state: nil
]

{ #category : #'events-processing' }
LaserGame >> mouseDown: evt forMorph: aSketchMorph [
	| cell |
	cell := self cellForEvent: evt.
	cell isNil
		ifTrue: [self activeCellLocation: nil]
		ifFalse: [self activeCellLocation: cell gridLocation].
]

{ #category : #'events-processing' }
LaserGame >> mouseEnter: evt forMorph: aSketchMorph [
	evt hand addMouseListener: self.

]

{ #category : #'events-processing' }
LaserGame >> mouseLeave: evt forMorph: aSketchMorph [
	evt hand removeMouseListener: self.
	self sweepDirtyCells.
	self changed.
	self currentHand showTemporaryCursor: nil
]

{ #category : #'events-processing' }
LaserGame >> mouseMoveWhileButtonDown: evt forMorph: aSketchMorph [

]

{ #category : #'events-processing' }
LaserGame >> mouseMoveWhileButtonUp: evt forMorph: aSketchMorph [
	| cell renderer pixelPositionWithinBoard |
	cell := self cellForEvent: evt.
	renderer := CellRenderer rendererFor: cell grid: self grid form: self boardForm.
	pixelPositionWithinBoard := self boardRelativePositionFor: evt.
	self sweepDirtyCells.
	renderer showPositionHintFromWithinBoardOffset: pixelPositionWithinBoard.
	self setDirty: cell.
	self changed
]

{ #category : #'events-processing' }
LaserGame >> mouseUp: evt forMorph: aSketchMorph [
	| cell |
	cell := self cellForEvent: evt.
	cell isNil ifFalse: [
		self activeCellLocation = cell gridLocation ifTrue: [
			self mouseUp: evt forMorph: aSketchMorph cell: cell
			]
		].
	self activeCellLocation: nil
]

{ #category : #'events-processing' }
LaserGame >> mouseUp: evt forMorph: aSketchMorph cell: aCell [
	| renderer pixelPositionWithinBoard cellForRedraw |
	renderer := CellRenderer rendererFor: aCell grid: self grid form: self boardForm.
	pixelPositionWithinBoard := self boardRelativePositionFor: evt.
	cellForRedraw := renderer mouseUpWithinBoardOffset: pixelPositionWithinBoard.
	self redrawCell: cellForRedraw.
	self incrementMoves.
	self updateGameBoardAndControls

]

{ #category : #accessing }
LaserGame >> moves [
	^moves
]

{ #category : #accessing }
LaserGame >> moves: anInteger [
	moves := anInteger
]

{ #category : #'as yet unclassified' }
LaserGame >> newGame [
	self grid initializeCells.
	self grid stopLaser.
	self moves: 0.
	self activeCellLocation: nil.
	self initializeDirty.
	GridFactory randomizeGrid: self grid.
	self updateGameBoardAndControls
]

{ #category : #initialization }
LaserGame >> panelWidth [
	^110
]

{ #category : #'as yet unclassified' }
LaserGame >> quitGame [
	(self confirm: 'Are you sure you want to quit?') ifTrue: [self quitGameAction]
]

{ #category : #'as yet unclassified' }
LaserGame >> quitGameAction [
	self delete.
	self class fullWorld ifTrue: [self class fullWorld: false].
	self quitGameExitSqueakCheck
]

{ #category : #'as yet unclassified' }
LaserGame >> quitGameExitSqueakCheck [
	"Use the Preferences cmdDotEnabled as an indicator that we are run-time or not."
	Preferences cmdDotEnabled ifFalse: [Smalltalk quitPrimitive]
]

{ #category : #drawing }
LaserGame >> redrawCell: aCell [
	| renderer |
	renderer := CellRenderer rendererFor: aCell grid: self grid form: self boardForm.
	renderer redrawCell
]

{ #category : #'as yet unclassified' }
LaserGame >> reset [
	self grid reset.
	self grid stopLaser.
	self moves: 0.
	self activeCellLocation: nil.
	self initializeDirty.	
	self updateGameBoardAndControls
]

{ #category : #'as yet unclassified' }
LaserGame >> setClean: aCell [
	self dirty removeKey: aCell gridLocation ifAbsent: []
]

{ #category : #'as yet unclassified' }
LaserGame >> setDirty: aCell [
	self dirty at: aCell gridLocation put: true
]

{ #category : #initialization }
LaserGame >> setExtent [
	self extent: self calculatedExtent
]

{ #category : #initialization }
LaserGame >> setWindowColors [
	| targetForFill |
	self class fullWorld
		ifTrue: [
			self color: Color transparent.
			targetForFill := World
			]
		ifFalse: [
			self color: (Color r: 0.369 g: 0.369 b: 0.505).
			targetForFill := self
			].
	targetForFill fillWithRamp: self windowColorRamp oriented: 0.3@0.8
]

{ #category : #initialization }
LaserGame >> setupMorphs [
	self layoutPolicy: ProportionalLayout new.
	self setWindowColors.
	self
		addMorph: self makeControlPanelMorph
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 0 @ 1)
				offsets: (self gameMargin @ self gameMargin
					corner: (self gameMargin + self panelWidth) @ self gameMargin negated)).
	self
		addMorph: self makeGameBoardMorph
		fullFrame: (LayoutFrame
				fractions: (0 @ 0 corner: 1 @ 1)
				offsets: ((self gameMargin + self panelWidth) @ self gameMargin 
					corner: self gameMargin negated @ self gameMargin negated)).
	self
		addMorph: self makeLaserHomeMorph
		fullFrame: (LayoutFrame
				fractions: (0 @ 1 corner: 0 @ 1)
				offsets: ((self gameMargin + self panelWidth + 1)@(self gameMargin negated) 
					corner: (self gameMargin + self panelWidth + CellRenderer cellExtent x - 2)@(self gameMargin negated + 4))).
]

{ #category : #drawing }
LaserGame >> sweepDirtyCells [
	| cell renderer |
	1 to: self grid numberOfColumns do: [:x |
		1 to: self grid numberOfRows do: [:y |
			cell := self grid at: x@y.
			(self isDirty: cell) ifTrue: [
				renderer := CellRenderer rendererFor: cell grid: self grid form: self boardForm.
				renderer redrawCell.
				self setClean: cell
				]]].
]

{ #category : #'as yet unclassified' }
LaserGame >> undo [
	| completed |
	completed := self grid undo.
	completed ifTrue: [
		self incrementMoves.
		self updateGameBoardAndControls]
]

{ #category : #initialization }
LaserGame >> updateCounters [
	| led |
	led := self findLaserPathCounter.
	led notNil ifTrue: [
		self laserActive
			ifTrue: [led 
				highlighted: true;
				value: self grid laserBeamPath size]
			ifFalse: [led
				highlighted: false;
				value: 0]
			].
	led := self findMovesCounter.
	led notNil ifTrue: [
		led
			highlighted: false;
			value: self moves asString].
	led := self findMirrorsCounter.
	led notNil ifTrue: [
		led
			highlighted: false;
			value: self grid numberOfMirrors asString].
	led := self findActiveMirrorsCounter.
	led notNil ifTrue: [
		led
			highlighted: false;
			value: self grid numberOfActiveMirrors asString].

]

{ #category : #'as yet unclassified' }
LaserGame >> updateFireButtonLabel [
	| btn |
	btn := self findFireButton.
	btn notNil ifTrue: [btn label contents: self fireButtonLabel]
]

{ #category : #'as yet unclassified' }
LaserGame >> updateGameBoardAndControls [
	self drawGameBoard.
	self updateFireButtonLabel.
	self updateCounters.
	self changed
]

{ #category : #initialization }
LaserGame >> windowColorRamp [
	^ {0.0 -> (Color r: 0.3 g: 0.8 b: 0.9).
                        1.0 -> (Color r: 0.2 g: 0.1 b: 0.7)}
]

{ #category : #initialization }
LaserGame >> wrapPanel: aPanel label: aLabel [ 
	"wrap a panel in an alignmentMorph and put a label above it"
	| column strM |
	column := AlignmentMorph newColumn 
				wrapCentering: #topLeft;
				cellPositioning: #topLeft;
				hResizing: #spaceFill;
				vResizing: #shrinkWrap;
				borderWidth: 2;
				layoutInset: 5;
				color: Color transparent;
				useRoundedCorners;
				borderStyle: (BorderStyle complexAltInset width: 2).
	column addMorph: aPanel.
	strM := StringMorph contents: aLabel.
	strM color: Color veryVeryLightGray.
	column addMorph: strM.
	^ column
]
