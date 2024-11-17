Class {
	#name : #GridDirectionEast,
	#superclass : #GridDirection,
	#category : #'Laser-Game-Model'
}

{ #category : #'as yet unclassified' }
GridDirectionEast class >> adjacentInVersionSymbol [

	^ #west
]

{ #category : #'as yet unclassified' }
GridDirectionEast class >> adjacentInversionSymbol [
	^#west
]

{ #category : #'as yet unclassified' }
GridDirectionEast class >> directionSymbol [
	^#east
]

{ #category : #'as yet unclassified' }
GridDirectionEast class >> vector [
	^1@0
]