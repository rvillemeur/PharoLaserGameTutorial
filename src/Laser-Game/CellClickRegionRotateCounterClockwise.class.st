Class {
	#name : #CellClickRegionRotateCounterClockwise,
	#superclass : #CellClickRegionOutside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionRotateCounterClockwise class >> arrowForm [
	^LaserGameForms counterClockwiseArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionRotateCounterClockwise class >> containsPoint: aPoint [
	^aPoint y > (CellRenderer cellExtent y // 2)
]

{ #category : #'as yet unclassified' }
CellClickRegionRotateCounterClockwise class >> mouseUpForCell: aCell withinGrid: aGrid [
	aGrid rotateCellCounterClockwiseAt: aCell gridLocation.
	^aCell
]
