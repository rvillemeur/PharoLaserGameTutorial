Class {
	#name : #GridDirectionNorth,
	#superclass : #GridDirection,
	#category : #'Laser-Game-Model'
}

{ #category : #'as yet unclassified' }
GridDirectionNorth class >> adjacentInVersionSymbol [

	^ #south
]

{ #category : #'as yet unclassified' }
GridDirectionNorth class >> directionSymbol [

	^ #north
]

{ #category : #'as yet unclassified' }
GridDirectionNorth class >> vector [

	^ 0 @ -1
]
