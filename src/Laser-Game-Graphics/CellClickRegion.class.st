Class {
	#name : #CellClickRegion,
	#superclass : #Object,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegion class >> clickRegionForPoint: aPoint [
	^self sortedSubclasses detect: [:cls | cls regionRectangle containsPoint: aPoint]
]

{ #category : #'as yet unclassified' }
CellClickRegion class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	^aCell
]

{ #category : #'as yet unclassified' }
CellClickRegion class >> scaledHintArrowAndOffsetFromWithinCell: aPoint [
	^nil
]

{ #category : #'as yet unclassified' }
CellClickRegion class >> sortedSubclasses [
	^self subclasses asSortedCollection: [:a :b | a sortIndex < b sortIndex]
]
