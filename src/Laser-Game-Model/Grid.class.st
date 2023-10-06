Class {
	#name : #Grid,
	#superclass : #Object,
	#instVars : [
		'cells',
		'laserIsActive',
		'numberOfColumns',
		'numberOfRows',
		'laserBeamPath'
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
	^ model
]

{ #category : #accessing }
Grid >> activateCellsInPath [

	self calculatePath.
	self laserBeamPath do: [ :pe | pe activateCell ]
]

{ #category : #accessing }
Grid >> at: aPoint [

	self revisit:
		'sbw 05/21/2007 - We should add a more meaningful accessing technique hiere. x@y is confusing.'.
	^ self cells at: aPoint ifAbsent: [  ]
]

{ #category : #accessing }
Grid >> at: aPoint put: aCell [

	self revisit:
		'sbw 05/21/2007 - We should add a more meaningful accessing technique hiere. x@y is confusing.'.
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
	[
	self laserBeamPath addLast: element.
	next := element nextElementIn: self.
	next isNil ] whileFalse: [ element := next ]
]

{ #category : #accessing }
Grid >> cells [

	^ cells
]

{ #category : #accessing }
Grid >> cells: anObject [

	cells := anObject
]

{ #category : #initialization }
Grid >> initialize [

	super initialize.
	self laserIsActive: false.
	self initializeCells
]

{ #category : #initialization }
Grid >> initializeCells [

	self cells: Dictionary new.
	1 to: self numberOfColumns do: [ :x |
		1 to: self numberOfRows do: [ :y |
			| pt cell |
			pt := x @ y.
			cell := BlankCell new.
			self at: pt put: cell ] ]
]

{ #category : #accessing }
Grid >> laserBeamPath [

	^ laserBeamPath
]

{ #category : #accessing }
Grid >> laserBeamPath: anObject [

	laserBeamPath := anObject
]

{ #category : #accessing }
Grid >> laserIsActive [

	^ laserIsActive
]

{ #category : #accessing }
Grid >> laserIsActive: anObject [

	laserIsActive := anObject
]

{ #category : #accessing }
Grid >> numberOfColumns [

	numberOfColumns isNil ifTrue: [ self numberOfColumns: 1 ].
	^ numberOfColumns
]

{ #category : #accessing }
Grid >> numberOfColumns: anObject [

	numberOfColumns := anObject
]

{ #category : #accessing }
Grid >> numberOfRows [

	numberOfRows isNil ifTrue: [ self numberOfRows: 1 ].
	^ numberOfRows
]

{ #category : #accessing }
Grid >> numberOfRows: anObject [

	numberOfRows := anObject
]

{ #category : #initialization }
Grid >> startingCell [

	| pt |
	pt := 1 @ self numberOfRows.
	^ self at: pt
]
