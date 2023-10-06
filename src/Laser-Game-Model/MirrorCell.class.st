Class {
	#name : #MirrorCell,
	#superclass : #Cell,
	#instVars : [
		'leansLeft'
	],
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
MirrorCell class >> leanLeft [

	^ super new leanLeft
]

{ #category : #accessing }
MirrorCell class >> leanRight [

	^ super new leanRight 
]

{ #category : #initialization }
MirrorCell >> initialize [

	super initialize.
	self initializeExitSides.
	self leanLeft.
]

{ #category : #initialization }
MirrorCell >> initializeExitSides [

	self exitSides: Dictionary new
]

{ #category : #testing }
MirrorCell >> isLeft [

	^ self leansLeft
]

{ #category : #testing }
MirrorCell >> isRight [

	^ self isLeft not.
]

{ #category : #accessing }
MirrorCell >> leanLeft [

	self leansLeft: true.
	self exitSides at: #north put: #east.
	self exitSides at: #east put: #north.
	self exitSides at: #south put: #west.
	self exitSides at: #west put: #south
]

{ #category : #accessing }
MirrorCell >> leanRight [

	self leansLeft: false.
	self exitSides at: #north put:#west.
	self exitSides at: #east put: #south.
	self exitSides at: #south put: #east.
	self exitSides at: #west put: #north
]

{ #category : #accessing }
MirrorCell >> leansLeft [

	^ leansLeft
]

{ #category : #accessing }
MirrorCell >> leansLeft: anObject [

	leansLeft := anObject
]
