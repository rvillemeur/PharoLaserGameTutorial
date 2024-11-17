Class {
	#name : #CellClickRegionOutside,
	#superclass : #CellClickRegion,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionOutside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	^true
]

{ #category : #'as yet unclassified' }
CellClickRegionOutside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	| rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	^rotateRegion mouseUpForCell: aCell withinGrid: aGrid
]

{ #category : #'as yet unclassified' }
CellClickRegionOutside class >> regionRectangle [
	"CellClickRegionOutside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer outsideRegionExtent.
	^outer insetBy: (delta // 2)
]

{ #category : #'as yet unclassified' }
CellClickRegionOutside class >> rotateRegionForPoint: aPoint [
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
]

{ #category : #'as yet unclassified' }
CellClickRegionOutside class >> scaledHintArrowAndOffsetFromWithinCell: aPoint [
	| arrow tinyArrow offset rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	arrow := rotateRegion arrowForm.
	tinyArrow := arrow scaledToSize: CellRenderer cellExtent.
	offset := 0.
	^offset->tinyArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionOutside class >> sortIndex [
	^2
]
