Class {
	#name : #GridDirectionWest,
	#superclass : #GridDirection,
	#category : #'Laser-Game-Model'
}

{ #category : #'as yet unclassified' }
GridDirectionWest class >> adjacentInVersionSymbol [

	^ #east
]

{ #category : #'as yet unclassified' }
GridDirectionWest class >> directionSymbol [

	^ #west
]

{ #category : #'as yet unclassified' }
GridDirectionWest class >> vector [

	^ -1 @ 0
]
