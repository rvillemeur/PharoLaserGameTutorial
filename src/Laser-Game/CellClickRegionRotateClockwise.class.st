Class {
	#name : #CellClickRegionRotateClockwise,
	#superclass : #CellClickRegionOutside,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionRotateClockwise class >> arrowForm [
	^LaserGameForms clockwiseArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionRotateClockwise class >> containsPoint: aPoint [
	^aPoint y <= (CellRenderer cellExtent y // 2)
]

{ #category : #'as yet unclassified' }
CellClickRegionRotateClockwise class >> mouseUpForCell: aCell withinGrid: aGrid [
	aGrid rotateCellClockwiseAt: aCell gridLocation.
	^aCell
]
