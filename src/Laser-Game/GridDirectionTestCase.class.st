Class {
	#name : #GridDirectionTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
GridDirectionTestCase >> testDirectionSelection [

	| direction |
	direction := GridDirection directionFor: #north.
	self assert: direction equals: GridDirectionNorth.
	self assert: direction vector equals: 0 @ -1.
	self assert: direction adjacentInVersionSymbol equals: #south.

	direction := GridDirection directionFor: #east.
	self assert: direction equals: GridDirectionEast.
	self assert: direction vector equals: 1 @ 0.
	self assert: direction adjacentInVersionSymbol equals: #west.

	direction := GridDirection directionFor: #south.
	self assert: direction equals: GridDirectionSouth.
	self assert: direction vector equals: 0 @ 1.
	self assert: direction adjacentInVersionSymbol equals: #north.

	direction := GridDirection directionFor: #west.
	self assert: direction equals: GridDirectionWest.
	self assert: direction vector equals: -1 @ 0.
	self assert: direction adjacentInVersionSymbol equals: #east
]
