Class {
	#name : #LaserPathElement,
	#superclass : #Object,
	#instVars : [
		'cell',
		'entrySide'
	],
	#category : #'Laser-Game-Model'
}

{ #category : #'as yet unclassified' }
LaserPathElement class >> cell: aCell entrySide: aSymbol [
	| model |
	model := self basicNew.
	model
		cell: aCell;
		entrySide: aSymbol.
	model initialize.
	^model
]

{ #category : #'as yet unclassified' }
LaserPathElement >> activateCell [
	self cell laserEntersFrom: self entrySide
]

{ #category : #accessing }
LaserPathElement >> cell [
	"Answer the value of cell"

	^ cell
]

{ #category : #accessing }
LaserPathElement >> cell: anObject [
	"Set the value of cell"

	cell := anObject
]

{ #category : #'as yet unclassified' }
LaserPathElement >> clearCell [
	self cell clearCell
]

{ #category : #accessing }
LaserPathElement >> entrySide [
	"Answer the value of entrySide"

	^ entrySide
]

{ #category : #accessing }
LaserPathElement >> entrySide: anObject [
	"Set the value of entrySide"

	entrySide := anObject
]

{ #category : #'as yet unclassified' }
LaserPathElement >> nextElementIn: aGrid [
	| loc dirSym direction vector newLoc nextCell |
	loc := self cell gridLocation.
	dirSym := self cell exitSideFor: self entrySide.
	dirSym isNil ifTrue: [^nil].
	direction := GridDirection directionFor: dirSym.
	vector := direction vector.
	newLoc := loc + vector.
	nextCell := aGrid at: newLoc.
	^nextCell isNil
		ifTrue: [nil]
		ifFalse: [self class cell: nextCell entrySide: direction adjacentInversionSymbol]
]

{ #category : #printing }
LaserPathElement >> printOn: aStream [
	super printOn: aStream.
	aStream
		cr;
		nextPut: $(..
	self cell printOn: aStream.
	aStream
		cr;
		nextPutAll: 'entrySide = ', self entrySide asString;
		nextPut: $)
]
