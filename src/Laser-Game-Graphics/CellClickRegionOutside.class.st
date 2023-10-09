Class {
	#name : #CellClickRegionOutside,
	#superclass : #CellClickRegion,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionOutside class >> regionRectangle [

	| outer delta |
	outer := 0 @ 0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer outsideRegionExtent.
	^ outer insetBy: delta // 2
]

{ #category : #sorting }
CellClickRegionOutside class >> sortIndex [

	^ 2
]
