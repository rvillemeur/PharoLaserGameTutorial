Class {
	#name : #CellClickRegionPushWest,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushWest class >> arrowForm [
	^LaserGameForms westArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionPushWest class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellWestFromLocation: aCell gridLocation
]

{ #category : #'as yet unclassified' }
CellClickRegionPushWest class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown not and: [underHeadingUp]
]

{ #category : #'as yet unclassified' }
CellClickRegionPushWest class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellWestFromLocation: aCell gridLocation
]
