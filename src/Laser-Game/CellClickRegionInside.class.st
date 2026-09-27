"
I am the innermost click region of a cell: a square of `CellRenderer class >> insideRegionExtent` centred in the cell. A click here asks for the cell to be pushed.

My own subclasses are the four push regions, one per direction. They divide me along my two diagonals, which is what `yForHeadingUpLineWith:` and `yForHeadingDownLineWith:` describe, and `pushRegionForPoint:` answers the one a point falls in.

I sort first (`sortIndex` 1), so a point I contain is mine even though the outside and ignore rectangles contain it too.

"
Class {
	#name : 'CellClickRegionInside',
	#superclass : 'CellClickRegion',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegionInside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion canPushCell: aCell withinGrid: aGrid
]

{ #category : 'interaction' }
CellClickRegionInside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^pushRegion mouseUpForCell: aCell withinGrid: aGrid
]

{ #category : 'classifying' }
CellClickRegionInside class >> pointIsUnderHeadingDownLine: aPoint [

	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingDownLineWith: realX.
	^ realY < lineY
]

{ #category : 'classifying' }
CellClickRegionInside class >> pointIsUnderHeadingUpLine: aPoint [
	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingUpLineWith: realX.
	^realY < lineY
]

{ #category : 'classifying' }
CellClickRegionInside class >> pushRegionForPoint: aPoint [
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
]

{ #category : 'accessing' }
CellClickRegionInside class >> regionRectangle [
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
]

{ #category : 'hints' }
CellClickRegionInside class >> scaledHintArrowAndOffsetFromWithinCell: aPoint [
	| pushRegion arrow tinyArrow offset |
	pushRegion := self pushRegionForPoint: aPoint.
	arrow := pushRegion arrowForm.
	tinyArrow := arrow scaledToSize: CellRenderer cellExtent - 2.
	offset := (CellRenderer cellExtent - tinyArrow extent) // 2.
	^offset->tinyArrow
]

{ #category : 'hints' }
CellClickRegionInside class >> showPositionHintFromWithinCell: aPoint [

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion
]

{ #category : 'accessing' }
CellClickRegionInside class >> sortIndex [
	^1
]

{ #category : 'classifying' }
CellClickRegionInside class >> yForHeadingDownLineWith: x [
	^CellRenderer cellExtent x - x
]

{ #category : 'classifying' }
CellClickRegionInside class >> yForHeadingUpLineWith: x [
	^x
]
