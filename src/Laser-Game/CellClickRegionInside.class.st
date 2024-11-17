Class {
	#name : #CellClickRegionInside,
	#superclass : #CellClickRegion,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion canPushCell: aCell withinGrid: aGrid
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^pushRegion mouseUpForCell: aCell withinGrid: aGrid
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> pointIsUnderHeadingDownLine: aPoint [

	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingDownLineWith: realX.
	^ realY < lineY
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> pointIsUnderHeadingUpLine: aPoint [
	| realX realY lineY |
	realX := aPoint x.
	realY := aPoint y.
	lineY := self yForHeadingUpLineWith: realX.
	^realY < lineY
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> pushRegionForPoint: aPoint [
	^self subclasses detect: [:cls | cls containsPoint: aPoint]
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> regionRectangle [
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> scaledHintArrowAndOffsetFromWithinCell: aPoint [
	| pushRegion arrow tinyArrow offset |
	pushRegion := self pushRegionForPoint: aPoint.
	arrow := pushRegion arrowForm.
	tinyArrow := arrow scaledToSize: CellRenderer cellExtent - 2.
	offset := (CellRenderer cellExtent - tinyArrow extent) // 2.
	^offset->tinyArrow
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> showPositionHintFromWithinCell: aPoint [

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> sortIndex [
	^1
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> yForHeadingDownLineWith: x [
	^CellRenderer cellExtent x - x
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> yForHeadingUpLineWith: x [
	^x
]
