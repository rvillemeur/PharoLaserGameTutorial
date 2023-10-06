Class {
	#name : #GridDirectionSouth,
	#superclass : #GridDirection,
	#category : #'Laser-Game-Model'
}

{ #category : #'as yet unclassified' }
GridDirectionSouth class >> adjacentInVersionSymbol [

	^ #north
]

{ #category : #'as yet unclassified' }
GridDirectionSouth class >> directionSymbol [

	^ #south
]

{ #category : #'as yet unclassified' }
GridDirectionSouth class >> vector [

	^ 0 @ 1
]
