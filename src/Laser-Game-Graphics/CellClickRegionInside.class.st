Class {
	#name : #CellClickRegionInside,
	#superclass : #CellClickRegion,
	#category : #'Laser-Game-Graphics'
}

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
	^ realY < lineY
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> pushRegionForPoint: aPoint [

	^ self subclasses detect: [ :cls | cls containsPoint: aPoint ]
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> regionRectangle [

	| outer delta |
	outer := 0 @ 0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^ outer insetBy: delta // 2
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> showPositionHintFromWithinCell: aPoint [

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion
]

{ #category : #sorting }
CellClickRegionInside class >> sortIndex [

	^ 1
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> yForHeadingDownLineWith: x [

	^ 30 - x
]

{ #category : #'as yet unclassified' }
CellClickRegionInside class >> yForHeadingUpLineWith: x [
^x
]
