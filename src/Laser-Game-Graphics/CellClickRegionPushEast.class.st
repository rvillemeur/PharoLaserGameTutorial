Class {
	#name : #CellClickRegionPushEast,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushEast class >> arrowForm [

	^ LaserGameForms eastArrow
]

{ #category : #testing }
CellClickRegionPushEast class >> containsPoint: aPoint [

	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.

	^ underHeadingDown and: [ underHeadingUp not ]
]
