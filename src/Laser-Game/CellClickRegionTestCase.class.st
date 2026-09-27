Class {
	#name : 'CellClickRegionTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInIgnoreRegion [

	| ignoreRect outsideRect |
	ignoreRect := CellClickRegionIgnore regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	"The ignore region is the margin of the cell left over once the outside region is inset."
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

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInInsideRegion [

	| insideRect outsideRect |
	insideRect := CellClickRegionInside regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	"Points outside the inside region belong to another region."
	self
		deny: (CellClickRegion clickRegionForPoint: 0 @ 0)
		equals: CellClickRegionInside.
	self
		deny: (CellClickRegion clickRegionForPoint: outsideRect topLeft)
		equals: CellClickRegionInside.
	self
		deny: (CellClickRegion clickRegionForPoint: insideRect topLeft - (1 @ 1))
		equals: CellClickRegionInside.
	"The inside region owns its top left corner, its centre and its last pixel."
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

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInOutsideRegion [

	| insideRect outsideRect |
	insideRect := CellClickRegionInside regionRectangle.
	outsideRect := CellClickRegionOutside regionRectangle.
	"The outside region is the ring between the ignore margin and the inside region."
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
