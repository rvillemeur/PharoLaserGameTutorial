"
I am a `Cell` with a mirror on one of its diagonals. `leansLeft` says which one. When I lean left the mirror runs from my top left corner to my bottom right one, and a beam entering from the north leaves by the east. When I lean right it runs from my top right corner to my bottom left one, and the same beam leaves by the west.

`leanLeft` and `leanRight` set the lean and all four exit sides together, which is why `rotate` uses them instead of flipping `leansLeft` on its own: pages 107 to 110 of the original spend three pages on exactly that bug.

`rotateClockwise` and `rotateCounterClockwise` are both `rotate`. A diagonal has only two positions, so either direction lands on the other one.
"
Class {
	#name : 'MirrorCell',
	#superclass : 'Cell',
	#instVars : [
		'leansLeft'
	],
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'instance creation' }
MirrorCell class >> leanLeft [
	"Answer a mirror on the diagonal from my top left corner to my bottom right one."

	^ self new leanLeft
]

{ #category : 'instance creation' }
MirrorCell class >> leanRight [
	"Answer a mirror on the diagonal from my top right corner to my bottom left one."

	^ self new leanRight
]

{ #category : 'initialization' }
MirrorCell >> initialize [
	super initialize.
	self initializeExitSides.
	self leanLeft
]

{ #category : 'initialization' }
MirrorCell >> initializeExitSides [
	self exitSides: Dictionary new.
	
]

{ #category : 'testing' }
MirrorCell >> isLeft [
	^self leansLeft
]

{ #category : 'testing' }
MirrorCell >> isRight [
	^self isLeft not
]

{ #category : 'initialization' }
MirrorCell >> leanLeft [
	self leansLeft: true.
	self exitSides at: #north put: #east.
	self exitSides at: #east put: #north.
	self exitSides at: #south put: #west.
	self exitSides at: #west put: #south.
	
]

{ #category : 'initialization' }
MirrorCell >> leanRight [
	self leansLeft: false.
	self exitSides at: #north put: #west.
	self exitSides at: #east put: #south.
	self exitSides at: #south put: #east.
	self exitSides at: #west put: #north.
	
]

{ #category : 'accessing' }
MirrorCell >> leansLeft [
	"Answer the value of leansLeft"

	^ leansLeft
]

{ #category : 'accessing' }
MirrorCell >> leansLeft: anObject [
	"Set the value of leansLeft"

	leansLeft := anObject
]

{ #category : 'printing' }
MirrorCell >> printDetailsOn: aStream [
	"Add the way I lean, which is the fact pages 109 and 110 are about."

	super printDetailsOn: aStream.
	aStream nextPutAll:
		(self isLeft ifTrue: [ ' leans left' ] ifFalse: [ ' leans right' ])
]

{ #category : 'actions' }
MirrorCell >> rotate [
	"Turn me a quarter of a turn, which puts my mirror on the other diagonal. Page 107 of the
	original writes this as `leansLeft: self isLeft not`, and pages 108 to 110 spend three pages
	finding out why the laser then leaves me on the side it left before: the lean changed and my
	exit sides did not. `leanLeft` and `leanRight` set both, so the fix of page 110 is to use them."

	self isLeft
		ifTrue: [ self leanRight ]
		ifFalse: [ self leanLeft ]
]

{ #category : 'actions' }
MirrorCell >> rotateClockwise [
	"Turn me clockwise. A quarter of a turn either way leaves my mirror on the same diagonal, so
	both directions do the same thing to me; page 107 keeps them apart anyway, in case the turn is
	ever animated, and lets one method do the work."

	self rotate
]

{ #category : 'actions' }
MirrorCell >> rotateCounterClockwise [
	"Turn me counter clockwise, which does the same to me as turning me clockwise. See
	`rotateClockwise`."

	self rotate
]
