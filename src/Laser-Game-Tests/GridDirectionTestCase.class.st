Class {
	#name : #GridDirectionTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
GridDirectionTestCase >> testDirectionSelection [

	| direction |
	direction := GridDirection directionFor: #north.
	self should: [ direction = GridDirectionNorth ].
	self should: [ direction vector = (0 @ -1) ].
	self should: [ direction adjacentInVersionSymbol = #south ].

	direction := GridDirection directionFor: #east.
	self should: [ direction = GridDirectionEast ].
	self should: [ direction vector = (1 @ 0) ].
	self should: [ direction adjacentInVersionSymbol = #west ].

	direction := GridDirection directionFor: #south.
	self should: [ direction = GridDirectionSouth ].
	self should: [ direction vector = (0 @ 1) ].
	self should: [ direction adjacentInVersionSymbol = #north ].

	direction := GridDirection directionFor: #west.
	self should: [ direction = GridDirectionWest ].
	self should: [ direction vector = (-1 @ 0) ].
	self should: [ direction adjacentInVersionSymbol = #east ].
]
