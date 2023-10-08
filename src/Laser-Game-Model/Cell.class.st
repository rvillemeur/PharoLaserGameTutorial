Class {
	#name : #Cell,
	#superclass : #Object,
	#instVars : [
		'activeSegments',
		'exitSides',
		'gridLocation'
	],
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
Cell >> activeSegments [

	^ activeSegments
]

{ #category : #accessing }
Cell >> activeSegments: anObject [

	activeSegments := anObject
]

{ #category : #'as yet unclassified' }
Cell >> clearCell [

	self initializeActiveSegments
]

{ #category : #testing }
Cell >> exitSideFor: aSymbol [

	^ self exitSides at: aSymbol
]

{ #category : #accessing }
Cell >> exitSides [

	^ exitSides
]

{ #category : #accessing }
Cell >> exitSides: anObject [

	exitSides := anObject
]

{ #category : #accessing }
Cell >> gridLocation [

	^ gridLocation
]

{ #category : #accessing }
Cell >> gridLocation: anObject [

	gridLocation := anObject
]

{ #category : #initialization }
Cell >> initialize [

	super initialize.
	self initializeActiveSegments.
]

{ #category : #initialization }
Cell >> initializeActiveSegments [

	self activeSegments: Dictionary new.
	self activeSegments at: #north put: false.
	self activeSegments at: #east put: false.
	self activeSegments at: #south put: false.
	self activeSegments at: #west put: false
]

{ #category : #testing }
Cell >> isOff [

	^ self isOn not
]

{ #category : #testing }
Cell >> isOn [

	^ self activeSegments values anySatisfy: [ :each | each = true ]
]

{ #category : #testing }
Cell >> isSegmentOnFor: aSymbol [

	^ self activeSegments at: aSymbol
]

{ #category : #testing }
Cell >> laserEntersFrom: aSymbol [

	| exit |
	self activeSegments at: aSymbol put: true.
	exit := self exitSideFor: aSymbol.
	self activeSegments at: exit put: true
]
