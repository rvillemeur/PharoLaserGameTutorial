Class {
	#name : #CellClickRegionPushWest,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushWest class >> arrowForm [

	^ LaserGameForms westArrow
]

{ #category : #testing }
CellClickRegionPushWest class >> containsPoint: aPoint [

	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.

	^ underHeadingDown not and: [ underHeadingUp ]
]
