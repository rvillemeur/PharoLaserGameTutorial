Class {
	#name : #CellClickRegionPushNorth,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushNorth class >> arrowForm [
	^LaserGameForms northArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionPushNorth class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellNorthFromLocation: aCell gridLocation
]

{ #category : #'as yet unclassified' }
CellClickRegionPushNorth class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^(underHeadingDown not) and: [underHeadingUp not]

]

{ #category : #'as yet unclassified' }
CellClickRegionPushNorth class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellNorthFromLocation: aCell gridLocation
]
