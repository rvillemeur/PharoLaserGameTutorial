Class {
	#name : #Grid,
	#superclass : #Object,
	#instVars : [
		'cells',
		'laserIsActive',
		'numberOfColumns',
		'numberOfRows'
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
Grid >> at: aPoint [
^self cells at: aPoint.
]

{ #category : #accessing }
Grid >> at: aPoint put: aCell [

	self cells at: aPoint put: aCell
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
			self cells at: pt put: cell ] ]
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
