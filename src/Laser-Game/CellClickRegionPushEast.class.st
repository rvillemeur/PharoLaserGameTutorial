Class {
	#name : #CellClickRegionPushEast,
	#superclass : #CellClickRegionInside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionPushEast class >> arrowForm [
	^LaserGameForms eastArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionPushEast class >> canPushCell: aCell withinGrid: aGrid [
	^aGrid canPushCellEastFromLocation: aCell gridLocation
]

{ #category : #'as yet unclassified' }
CellClickRegionPushEast class >> containsPoint: aPoint [
	| underHeadingDown underHeadingUp |
	underHeadingDown := self pointIsUnderHeadingDownLine: aPoint.
	underHeadingUp := self pointIsUnderHeadingUpLine: aPoint.
	^underHeadingDown and: [underHeadingUp not]
]

{ #category : #'as yet unclassified' }
CellClickRegionPushEast class >> mouseUpForCell: aCell withinGrid: aGrid [
	^aGrid pushCellEastFromLocation: aCell gridLocation
]
