Class {
	#name : #CellClickRegionIgnore,
	#superclass : #CellClickRegion,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
CellClickRegionIgnore class >> regionRectangle [

	^ 0 @ 0 extent: CellRenderer cellExtent
]

{ #category : #sorting }
CellClickRegionIgnore class >> sortIndex [

	^ 3
]
