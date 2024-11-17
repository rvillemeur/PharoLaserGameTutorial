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
	"Answer the value of activeSegments"

	^ activeSegments
]

{ #category : #accessing }
Cell >> activeSegments: aDictionary [
	"Set the value of activeSegments"

	activeSegments := aDictionary
]

{ #category : #accessing }
Cell >> clearCell [
	self initializeActiveSegments
]

{ #category : #accessing }
Cell >> exitSideFor: aSymbol [
	^self exitSides at: aSymbol
]

{ #category : #accessing }
Cell >> exitSides [
	"Answer the value of exitSides"

	^ exitSides
]

{ #category : #accessing }
Cell >> exitSides: aDictionary [
	"Set the value of exitSides"

	exitSides := aDictionary
]

{ #category : #accessing }
Cell >> gridLocation [
	"Answer the value of gridLocation"

	^ gridLocation
]

{ #category : #accessing }
Cell >> gridLocation: anObject [
	"Set the value of gridLocation"

	gridLocation := anObject
]

{ #category : #'initialize-release' }
Cell >> initialize [
	super initialize.
	self initializeActiveSegments.

]

{ #category : #'initialize-release' }
Cell >> initializeActiveSegments [
	self activeSegments: Dictionary new.
	self activeSegments at: #north put: false.
	self activeSegments at: #east put: false.
	self activeSegments at: #south put: false.
	self activeSegments at: #west put: false.
	
]

{ #category : #testing }
Cell >> isOff [
	^self isOn not
]

{ #category : #testing }
Cell >> isOn [
	^self activeSegments values anySatisfy: [:each | each = true]
]

{ #category : #testing }
Cell >> isSegmentOnFor: aSymbol [
	^self activeSegments at: aSymbol
]

{ #category : #accessing }
Cell >> laserEntersFrom: aSymbol [
	| exit |
	self activeSegments at: aSymbol put: true.
	exit := self exitSideFor: aSymbol.
	self activeSegments at: exit put: true.
]

{ #category : #printing }
Cell >> printOn: aStream [
	super printOn: aStream.
	aStream
		cr;
		nextPutAll: '  location = ', self gridLocation asString;
		cr;
		nextPutAll: '  ';
		nextPutAll: (self isOn ifTrue: ['ON'] ifFalse: ['OFF'])
]

{ #category : #actions }
Cell >> rotateClockwise [
]

{ #category : #actions }
Cell >> rotateCounterClockwise [
]
