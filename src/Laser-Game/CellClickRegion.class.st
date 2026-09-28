"
I am the root of the click regions of a cell: the three concentric areas a click can fall in, told apart by where the click is within the cell.

My subclasses are CellClickRegionInside, CellClickRegionOutside and CellClickRegionIgnore. Each answers a `regionRectangle` in cell coordinates and a `sortIndex`. `clickRegionForPoint:` asks the subclasses in `sortIndex` order — inside first, ignore last — and answers the first one whose rectangle holds the point. Without that order the three would all claim a point near the centre, since each rectangle contains the ones inside it.

Every rectangle is derived from `CellRenderer class >> cellExtent`, `insideRegionExtent` and `ignoreRegionOffset`, so a cell of another size needs no new numbers here.

I am a class-side hierarchy: no instance is ever created. The region a point falls in decides what a click does — the inside region pushes a cell, the outside region rotates it, the ignore region does nothing.

"
Class {
	#name : 'CellClickRegion',
	#superclass : 'Object',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'interaction' }
CellClickRegion class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	"Answer whether a click at aPoint can do anything to aCell. Nothing can be done in me: the
	ignore margin is a region where a click is a click on nothing, and the inside and outside
	regions each answer for the region the point really falls in. Page 114 of the original says
	the same of the mouse up handler it writes here: this guy will do nothing."

	^ false
]

{ #category : 'classifying' }
CellClickRegion class >> clickRegionForPoint: aPoint [
	"Answer the region of a cell aPoint falls in. My subclasses are tried innermost first, and the
	ignore region covers the whole cell, so any point within a cell finds one. A point outside the
	cell finds none, and is ignored: a click there can do nothing, which is what the ignore region
	already means. A mouse event carries such a point whenever the element under the pointer is
	larger than the cell the regions are computed from, and answering it here keeps the case out of
	every mouse handler."

	^self sortedSubclasses
		detect: [ :cls | cls regionRectangle containsPoint: aPoint ]
		ifNone: [ CellClickRegionIgnore ]
]

{ #category : 'hints' }
CellClickRegion class >> hintElementOfExtent: anExtent [
	"Answer an element drawing my hint at anExtent, or nil when I have no picture to show. The four
	push regions answer a straight arrow and the two rotate regions a curved one; the inside and
	outside regions never answer this themselves, since each refines itself first, and the ignore
	region shows nothing."

	^ nil
]

{ #category : 'hints' }
CellClickRegion class >> hintRegionForPoint: aPoint [
	"Answer the region whose hint applies at aPoint, which I already contain. I have nothing
	finer to say than my own name, so I answer myself; the inside region answers one of its four
	push regions."

	^ self
]

{ #category : 'interaction' }
CellClickRegion class >> mouseUpWithinCellAtPoint: aPoint cell: aCell withinGrid: aGrid [
	^aCell
]

{ #category : 'accessing' }
CellClickRegion class >> regionRectangle [
	"Answer the rectangle, in cell coordinates, that I claim. Every concrete region answers one."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
CellClickRegion class >> sortIndex [
	"Answer where I come in the order regions are asked in. The innermost region answers the
	smallest number, so that it claims a point the wider regions also contain."

	^ self subclassResponsibility
]

{ #category : 'classifying' }
CellClickRegion class >> sortedSubclasses [
	^self subclasses asSortedCollection: [:a :b | a sortIndex < b sortIndex]
]
