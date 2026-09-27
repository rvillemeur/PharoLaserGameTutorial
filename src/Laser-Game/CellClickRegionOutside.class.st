"
I am the ring between the ignore margin and the inside region: a square of `CellRenderer class >> outsideRegionExtent` centred in the cell, minus the inside region, which sorts before me. A click here asks for the cell to be rotated.

My own subclasses are the two rotate regions, clockwise and counter-clockwise, and `rotateRegionForPoint:` answers the one a point falls in.

I sort second (`sortIndex` 2).

"
Class {
	#name : 'CellClickRegionOutside',
	#superclass : 'CellClickRegion',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionOutside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	^true
]

{ #category : 'interaction' }
CellClickRegionOutside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	| rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	^rotateRegion mouseUpForCell: aCell withinGrid: aGrid
]

{ #category : 'accessing' }
CellClickRegionOutside class >> regionRectangle [
	"CellClickRegionOutside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer outsideRegionExtent.
	^outer insetBy: (delta // 2)
]

{ #category : 'classifying' }
CellClickRegionOutside class >> rotateRegionForPoint: aPoint [
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
]

{ #category : 'hints' }
CellClickRegionOutside class >> scaledHintArrowAndOffsetFromWithinCell: aPoint [
	| arrow tinyArrow offset rotateRegion |
	rotateRegion := self rotateRegionForPoint: aPoint.
	arrow := rotateRegion arrowForm.
	tinyArrow := arrow scaledToSize: CellRenderer cellExtent.
	offset := 0.
	^offset->tinyArrow
]

{ #category : 'accessing' }
CellClickRegionOutside class >> sortIndex [
	^2
]
