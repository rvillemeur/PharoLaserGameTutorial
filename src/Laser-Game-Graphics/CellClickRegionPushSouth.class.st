Class {
	#name : #CellClickRegionPushSouth,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushSouth class >> arrowForm [
	^LaserGameForms southArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionPushSouth class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellSouthFromLocation: aCell gridLocation
]

{ #category : #'as yet unclassified' }
CellClickRegionPushSouth class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp]
]

{ #category : #'as yet unclassified' }
CellClickRegionPushSouth class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellSouthFromLocation: aCell gridLocation
]
