Class {
	#name : #CellClickRegionTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
CellClickRegionTestCase >> testClicksInIgnoreRegion [

	| pt regionClass |
	pt := 1 @ 1.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionIgnore.
	pt := 29 @ 29.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionIgnore.
	pt := 3 @ 3.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self assert: regionClass equals: CellClickRegionIgnore.
	pt := 10 @ 10.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self shouldnt: [ regionClass = CellClickRegionIgnore ]
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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
