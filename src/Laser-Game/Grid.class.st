Class {
	#name : #Grid,
	#superclass : #Object,
	#instVars : [
		'cells',
		'laserIsActive',
		'numberOfColumns',
		'numberOfRows',
		'laserBeamPath',
		'movesStack'
	],
	#category : #'Laser-Game-Model'
}

{ #category : #'instance creation' }
Grid class >> newOfSize: aPoint [
	| model |
	model := self basicNew.
	model
		numberOfRows: aPoint y;
		numberOfColumns: aPoint x.
	model initialize.
	^model
]

{ #category : #action }
Grid >> activateCellsInPath [
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe activateCell]
]

{ #category : #accessing }
Grid >> at: aPoint [
	self revisit: 'sbw 05/21/2007 - We should add a more meaningful accessing technique here.  x@y is confusing.'.
	^self cells at: aPoint ifAbsent: []
]

{ #category : #accessing }
Grid >> at: aPoint put: aCell [
	self revisit: 'sbw 05/21/2007 - We should add a more meaningful accessing technique here.  x@y is confusing.'.
	aCell gridLocation: aPoint.
	self cells at: aPoint put: aCell
]

{ #category : #accessing }
Grid >> calculatePath [
	| cell dirSym element next |
	self laserBeamPath: OrderedCollection new.
	cell := self startingCell.
	dirSym := #south.
	element := LaserPathElement cell: cell entrySide: dirSym.
	[self laserBeamPath addLast: element.
	next := element nextElementIn: self.
	next isNil] whileFalse: [
		element := next]
]

{ #category : #action }
Grid >> canPushCell: aGridDirection fromLocation: aPoint [
	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [^false].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [^false].
	swapCell class = BlankCell ifFalse: [^false].
	^true

]

{ #category : #action }
Grid >> canPushCellEastFromLocation: aPoint [
	| direction |
	direction := GridDirection directionFor: #east.
	^self canPushCell: direction fromLocation: aPoint.
]

{ #category : #action }
Grid >> canPushCellNorthFromLocation: aPoint [
	| direction |
	direction := GridDirection directionFor: #north.
	^self canPushCell: direction fromLocation: aPoint.
]

{ #category : #action }
Grid >> canPushCellSouthFromLocation: aPoint [
	| direction |
	direction := GridDirection directionFor: #south.
	^self canPushCell: direction fromLocation: aPoint.

]

{ #category : #action }
Grid >> canPushCellWestFromLocation: aPoint [
	| direction |
	direction := GridDirection directionFor: #west.
	^self canPushCell: direction fromLocation: aPoint.
]

{ #category : #accessing }
Grid >> cells [
	"Answer the value of cells"

	^ cells
]

{ #category : #accessing }
Grid >> cells: anObject [
	"Set the value of cells"

	cells := anObject
]

{ #category : #action }
Grid >> clearCellsInPath [
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe clearCell]
]

{ #category : #action }
Grid >> fireLaser [
	self laserIsActive: true.
	self activateCellsInPath.
	
]

{ #category : #'initialize-release' }
Grid >> initialize [
	super initialize.
	self laserIsActive: false.
	self initializeCells.
	
]

{ #category : #'initialize-release' }
Grid >> initializeCells [
	self cells: Dictionary new.
	1 to: self numberOfColumns do: [:x |
		1 to: self numberOfRows do: [:y |
			| pt cell |
			pt := x@y.
			cell := BlankCell new.
			self at: pt put: cell]]
]

{ #category : #accessing }
Grid >> laserBeamPath [
	"Answer the value of laserBeamPath"

	^ laserBeamPath
]

{ #category : #accessing }
Grid >> laserBeamPath: anObject [
	"Set the value of laserBeamPath"

	laserBeamPath := anObject
]

{ #category : #accessing }
Grid >> laserIsActive [
	"Answer the value of laserIsActive"

	^ laserIsActive
]

{ #category : #accessing }
Grid >> laserIsActive: anObject [
	"Set the value of laserIsActive"

	laserIsActive := anObject
]

{ #category : #accessing }
Grid >> movesStack [
	movesStack isNil ifTrue: [self movesStack: OrderedCollection new].
	^movesStack
]

{ #category : #accessing }
Grid >> movesStack: aCollection [
	movesStack := aCollection
]

{ #category : #accessing }
Grid >> numberOfActiveMirrors [
	^(self cells select: [:each | (each class = MirrorCell) and: [each isOn]]) size
]

{ #category : #accessing }
Grid >> numberOfColumns [
	numberOfColumns isNil ifTrue: [self numberOfColumns: 1].
	^ numberOfColumns
]

{ #category : #accessing }
Grid >> numberOfColumns: anObject [
	"Set the value of numberOfColumns"

	numberOfColumns := anObject
]

{ #category : #accessing }
Grid >> numberOfMirrors [
	^(self cells select: [:each | each class = MirrorCell]) size
]

{ #category : #accessing }
Grid >> numberOfRows [
	numberOfRows isNil ifTrue: [self numberOfRows: 1].
	^ numberOfRows
]

{ #category : #accessing }
Grid >> numberOfRows: anObject [
	"Set the value of numberOfRows"

	numberOfRows := anObject
]

{ #category : #action }
Grid >> pushCell: aGridDirection fromLocation: aPoint [
	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [^cell].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [^cell].
	swapCell class = BlankCell ifFalse: [^cell].
	self clearCellsInPath.
	self swapCell: cell with: swapCell.
	self laserIsActive ifTrue: [self activateCellsInPath].
	^swapCell

]

{ #category : #action }
Grid >> pushCellAction: aDirectionSymbol fromLocation: aPoint [
	| direction cell swappedCell |
	cell := self at: aPoint.
	direction := GridDirection directionFor: aDirectionSymbol.
	swappedCell := self pushCell: direction fromLocation: aPoint.
	swappedCell gridLocation = cell gridLocation ifFalse: [
		self stackAction: aDirectionSymbol forCell: cell].
	^swappedCell 
]

{ #category : #action }
Grid >> pushCellEastFromLocation: aPoint [
	^self pushCellAction: #east fromLocation: aPoint

]

{ #category : #action }
Grid >> pushCellNorthFromLocation: aPoint [
	^self pushCellAction: #north fromLocation: aPoint

]

{ #category : #action }
Grid >> pushCellSouthFromLocation: aPoint [
	^self pushCellAction: #south fromLocation: aPoint

]

{ #category : #action }
Grid >> pushCellWestFromLocation: aPoint [
	^self pushCellAction: #west fromLocation: aPoint

]

{ #category : #action }
Grid >> reset [
	[self undo] whileTrue: []
]

{ #category : #action }
Grid >> rotateCellClockwiseAt: aPoint [
	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateClockwise.
	self laserIsActive ifTrue: [self activateCellsInPath].
	self stackAction: #clockwise forCell: cell

]

{ #category : #action }
Grid >> rotateCellCounterClockwiseAt: aPoint [
	| cell |
	cell := self at: aPoint.
	self clearCellsInPath.
	(self at: aPoint) rotateCounterClockwise.
	self laserIsActive ifTrue: [self activateCellsInPath].
	self stackAction: #counterClockwise forCell: cell

]

{ #category : #action }
Grid >> stackAction: aSymbol forCell: aCell [
	self movesStack add: aSymbol->(aCell gridLocation)
]

{ #category : #accessing }
Grid >> startingCell [
	| pt |
	pt := 1@(self numberOfRows).
	^self at: pt
]

{ #category : #action }
Grid >> stopLaser [
	self laserIsActive: false.
	self clearCellsInPath.
	
]

{ #category : #action }
Grid >> swapCell: aCell with: anotherCell [
	| oldLocation newLocation |
	oldLocation := aCell gridLocation copy.
	newLocation := anotherCell gridLocation copy.
	self at: newLocation put: aCell.
	self at: oldLocation put: anotherCell
]

{ #category : #action }
Grid >> undo [
	| actionAssociation symbol location reverseAction arguments |
	self movesStack isEmpty ifTrue: [^false].
	actionAssociation := self movesStack removeLast.
	symbol := actionAssociation key.
	location := actionAssociation value.
	reverseAction := ReverseLaserGameAction reverseActionSymbolFor: symbol.
	arguments := Array with: location.
	self perform: reverseAction withArguments: arguments.
	self movesStack removeLast.
	^true
]
