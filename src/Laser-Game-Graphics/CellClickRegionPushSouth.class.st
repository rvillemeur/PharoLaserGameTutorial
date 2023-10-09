Class {
	#name : #CellClickRegionPushSouth,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushSouth class >> arrowForm [

	^ LaserGameForms southArrow
]

{ #category : #testing }
CellClickRegionPushSouth class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.

	^ underHeadingDown and: [ underHeadingUp ]
]
