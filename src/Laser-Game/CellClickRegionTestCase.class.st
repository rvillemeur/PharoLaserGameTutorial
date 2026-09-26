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

	| pt regionClass |
	pt := 1 @ 1.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionInside ].

	pt := CellClickRegionOutside regionRectangle topLeft + (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionInside ].

	pt := CellClickRegionInside regionRectangle topLeft - (1 @ 1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionInside ].

	pt := CellClickRegionInside regionRectangle topLeft.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionInside
]

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInOutsideRegion [

	| pt regionClass |
	pt := 1 @ 1.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionOutside ].
	pt := 5 @ 5.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionOutside.
	pt := 9 @ 9.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionOutside.
	pt := 16 @ 16.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionOutside ]
]

{ #category : 'tests' }
CellClickRegionTestCase >> testClicksInsideRegion [

	| pt regionClass |
	pt := 1 @ 1.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionInside ].
	pt := 5 @ 5.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionInside ].
	pt := 9 @ 9.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionInside ].
	pt := 10 @ 10.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionInside
]
