Class {
	#name : #CellClickRegionPushNorth,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushNorth class >> arrowForm [

	^ LaserGameForms northArrow 
]

{ #category : #testing }
CellClickRegionPushNorth class >> containsPoint: aPoint [

	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.

	^ underHeadingDown not and: [ underHeadingUp not ]

]
