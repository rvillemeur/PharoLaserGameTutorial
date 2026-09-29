Class {
	#name : 'CellClickRegionTestCase',
	#superclass : 'LaserGameTestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'support' }
CellClickRegionTestCase >> assertIgnoreRegionBoundaries [
	"Check where the ignore region begins and ends. It is the margin of the cell left over once
	the outside region is inset, so the corner of the cell belongs to it and the centre of the
	inside region does not. Page 192 writes both points relative to a rectangle a region answers,
	so neither goes stale when the cell size changes."

	| ignoreRect outsideRect |
	ignoreRect := CellClickRegionIgnore regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	self
		assert: (CellClickRegion clickRegionForPoint: ignoreRect topLeft)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: ignoreRect bottomRight - (1 @ 1))
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect topLeft - (1 @ 1))
		equals: CellClickRegionIgnore.
	self
		deny: (CellClickRegion clickRegionForPoint: CellClickRegionInside regionRectangle center)
		equals: CellClickRegionIgnore
]

{ #category : 'support' }
CellClickRegionTestCase >> assertInsideRegionBoundaries [
	"Check where the inside region begins and ends: it owns its top left corner, its centre and
	its last pixel, and nothing a pixel outside it. The cell corner and the top left of the
	outside region belong to another region."

	| insideRect outsideRect |
	insideRect := CellClickRegionInside regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	self
		deny: (CellClickRegion clickRegionForPoint: 0 @ 0)
		equals: CellClickRegionInside.
	self
		deny: (CellClickRegion clickRegionForPoint: outsideRect topLeft)
		equals: CellClickRegionInside.
	self
		deny: (CellClickRegion clickRegionForPoint: insideRect topLeft - (1 @ 1))
		equals: CellClickRegionInside.
	self
		assert: (CellClickRegion clickRegionForPoint: insideRect topLeft)
		equals: CellClickRegionInside.
	self
		assert: (CellClickRegion clickRegionForPoint: insideRect center)
		equals: CellClickRegionInside.
	self
		assert: (CellClickRegion clickRegionForPoint: insideRect bottomRight - (1 @ 1))
		equals: CellClickRegionInside
]

{ #category : 'support' }
CellClickRegionTestCase >> assertOutsideRegionBoundaries [
	"Check where the outside region begins and ends. It is the ring between the ignore margin and
	the inside region: it owns its own top left corner and the pixel before the inside region, and
	neither the pixel before itself nor the centre of the cell."

	| insideRect outsideRect |
	insideRect := CellClickRegionInside regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	self
		deny: (CellClickRegion clickRegionForPoint: outsideRect topLeft - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect topLeft)
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: insideRect topLeft - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		assert: (CellClickRegion clickRegionForPoint: outsideRect bottomRight - (1 @ 1))
		equals: CellClickRegionOutside.
	self
		deny: (CellClickRegion clickRegionForPoint: insideRect center)
		equals: CellClickRegionOutside
]

{ #category : 'tests' }
CellClickRegionTestCase >> testAPointOutsideTheCellIsIgnored [
	"A point that falls in no region is ignored rather than an error. An element larger than the
	cell the regions are computed from sends such a point on every mouse move, and what happens
	there must be nothing at all, not a walkback out of the event handler."

	| beyond |
	beyond := CellRenderer cellExtent.
	self
		assert: (CellClickRegion clickRegionForPoint: beyond)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: -1 @ -1)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: beyond x @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: 0 @ beyond y)
		equals: CellClickRegionIgnore
]

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInIgnoreRegion [
	"Check the boundaries of the ignore region at the cell size of the package."

	self assertIgnoreRegionBoundaries
]

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInInsideRegion [
	"Check the boundaries of the inside region at the cell size of the package."

	self assertInsideRegionBoundaries
]

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInOutsideRegion [
	"Check the boundaries of the outside region at the cell size of the package."

	self assertOutsideRegionBoundaries
]

{ #category : 'tests' }
CellClickRegionTestCase >> testEachRegionWithAPictureAnswersTheArrowOfItsDirection [
	"Page 094 asks a push region for its arrow and page 105 asks a rotate region for its own. Here
	each answers an element built at the size asked for, and the regions that have no picture
	answer nothing: the inside and outside regions always refine themselves first, and the ignore
	region never shows anything."

	| extent |
	extent := 48 @ 48.
	self assert: (CellClickRegionOutside hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionIgnore hintElementOfExtent: extent) isNil.
	self assert: (CellClickRegionInside hintElementOfExtent: extent) isNil.
	{ (CellClickRegionPushNorth -> LaserGameShapes northArrowPoints).
	(CellClickRegionPushEast -> LaserGameShapes eastArrowPoints).
	(CellClickRegionPushSouth -> LaserGameShapes southArrowPoints).
	(CellClickRegionPushWest -> LaserGameShapes westArrowPoints).
	(CellClickRegionRotateClockwise
	 -> LaserGameShapes clockwiseArrowPoints).
	(CellClickRegionRotateCounterClockwise
	 -> LaserGameShapes counterClockwiseArrowPoints) } do: [ :each |
		| element |
		element := each key hintElementOfExtent: extent.
		self
			assert: element geometry vertices
			equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) ]
]

{ #category : 'tests' }
CellClickRegionTestCase >> testTheInsideAndOutsideRegionsRefineTheHintTheyAnswer [
	"Page 092 gives every region the hint message. The inside region answers the push region of
	the point, and since page 105 the outside region answers the rotate region of the point. The
	ignore region answers itself, having nothing finer to say and no picture to show."

	| rect |
	rect := CellClickRegionInside regionRectangle.
	self
		assert: (CellClickRegionOutside hintRegionForPoint: 
				 CellClickRegionOutside regionRectangle topLeft)
		equals: CellClickRegionRotateClockwise.
	self
		assert: (CellClickRegionIgnore hintRegionForPoint: 0 @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegionInside hintRegionForPoint: rect leftCenter + (1 @ 0))
		equals: CellClickRegionPushEast
]

{ #category : 'tests' }
CellClickRegionTestCase >> testTheRegionBoundariesHoldAtEveryCellSize [
	"Run the three boundary tables at three cell sizes. The three regions are concentric squares
	derived from the cell size, one of them by a margin that stays four pixels wide and one by a
	ring that stays ten pixels wide, so the smallest size of the sweep is the one that could break
	them. None of the three loses a pixel to another."

	#( 30 40 80 ) do: [ :size |
		self withCellExtent: size @ size do: [
			self assertIgnoreRegionBoundaries.
			self assertInsideRegionBoundaries.
			self assertOutsideRegionBoundaries ] ]
]
