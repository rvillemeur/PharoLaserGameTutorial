Class {
	#name : 'CellClickInsideRegionPushTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'tests' }
CellClickInsideRegionPushTestCase >> testAPointOnALineIsNotUnderIt [
	"Pages 090 and 091: the first run of the original's test failed on a point that sits exactly
	on a line, and the fault was in the test, not in the code. Both line tests ask <, so a point
	on a line is not under it, and the truth table then sends the corner points the way the
	region names say."

	| rect onBoth onHeadingDown |
	rect := CellClickRegionInside regionRectangle.
	onBoth := rect center.
	onHeadingDown := rect topRight.
	self deny:
		(CellClickRegionInside pointIsUnderHeadingUpLine: onBoth).
	self deny:
		(CellClickRegionInside pointIsUnderHeadingDownLine: onBoth).
	self
		assert: (CellClickRegionInside pushRegionForPoint: onBoth)
		equals: CellClickRegionPushNorth.
	self deny:
		(CellClickRegionInside pointIsUnderHeadingDownLine: onHeadingDown).
	self assert:
		(CellClickRegionInside pointIsUnderHeadingUpLine: onHeadingDown).
	self
		assert: (CellClickRegionInside pushRegionForPoint: onHeadingDown)
		equals: CellClickRegionPushWest
]

{ #category : 'tests' }
CellClickInsideRegionPushTestCase >> testClicksInPushRegions [

	| pt regionClass pushRegion testTable cls rect |
	rect := CellClickRegionInside regionRectangle.
	pt := rect topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionInside.
	testTable := {
		             (rect topLeft -> CellClickRegionPushEast).
		             (rect topRight -> CellClickRegionPushWest).
		             (rect center -> CellClickRegionPushNorth).
		             (rect bottomLeft -> CellClickRegionPushNorth).
		             (rect bottomRight -> CellClickRegionPushNorth).
		             (rect topLeft + (1 @ 3) -> CellClickRegionPushEast).
		             (rect center + (-1 @ 1) -> CellClickRegionPushNorth).
		             (rect bottomRight + (-1 @ -3)
		              -> CellClickRegionPushWest).
		             (rect topCenter + (0 @ 1) -> CellClickRegionPushSouth) }.
	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self assert: pushRegion equals: cls ]
]

{ #category : 'tests' }
CellClickInsideRegionPushTestCase >> testEveryPointOfTheInsideRegionIsInExactlyOnePushRegion [
	"The two diagonals cut the inside region into four triangles that cover it and do not
	overlap, so every point of it belongs to one push region and to no other. The original
	checked nine points by hand; this walks the whole region, which is what makes the test hold
	at any cell size."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	rect left to: rect right do: [ :x |
		rect top to: rect bottom do: [ :y |
			| point matching |
			point := x @ y.
			matching := CellClickRegionInside subclasses select: [ :each |
				            each containsPoint: point ].
			self assert: matching size equals: 1 ] ]
]

{ #category : 'tests' }
CellClickInsideRegionPushTestCase >> testTheLinesRunThroughTheCornersOfTheInsideRegion [
	"The two diagonals are written as equations of the cell, y = x and y = cellExtent x - x, and
	no number of the inside region appears in them. They still meet its corners, which is what
	makes the arithmetic of page 087 hold at any cell size."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionInside yForHeadingUpLineWith: rect left)
		equals: rect top.
	self
		assert: (CellClickRegionInside yForHeadingUpLineWith: rect right)
		equals: rect bottom.
	self
		assert: (CellClickRegionInside yForHeadingDownLineWith: rect left)
		equals: rect bottom.
	self
		assert: (CellClickRegionInside yForHeadingDownLineWith: rect right)
		equals: rect top
]

{ #category : 'tests' }
CellClickInsideRegionPushTestCase >> testThePushRegionIsTheOneOfTheEdgeThePointIsNearest [
	"A point near an edge of the inside region pushes away from that edge: near the left edge the
	cell is pushed east, near the top edge it is pushed south. That is the arrow page 086 draws
	in its diagram, and it is why the region names read the way they do."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> CellClickRegionPushEast).
	(rect rightCenter - (1 @ 0) -> CellClickRegionPushWest).
	(rect topCenter + (0 @ 1) -> CellClickRegionPushSouth).
	(rect bottomCenter - (0 @ 1) -> CellClickRegionPushNorth) } do: [ :each |
		self
			assert: (CellClickRegionInside pushRegionForPoint: each key)
			equals: each value ]
]
