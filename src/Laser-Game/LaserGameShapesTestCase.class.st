Class {
	#name : 'LaserGameShapesTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'support' }
LaserGameShapesTestCase >> requestedExtentOf: anElement [
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testACrossHairIsTwoBarsCrossingAtTheCentre [
	"The cross hair of page 083 is two crossing lines. Here it is an element holding two bars,
	one wide and one tall, both centred in it."

	| extent element horizontal vertical |
	extent := 60 @ 60.
	element := LaserGameShapes crossHairElementOfExtent: extent.
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	horizontal := element children detect: [ :each |
		              (self requestedExtentOf: each) x
		              > (self requestedExtentOf: each) y ].
	vertical := element children detect: [ :each |
		            (self requestedExtentOf: each) y
		            > (self requestedExtentOf: each) x ].
	element children do: [ :each |
		self
			assert:
				each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ].
	self
		assert: (self requestedExtentOf: horizontal) x
		equals: (self requestedExtentOf: vertical) y
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAnArrowElementIsAPolygonOfTheSizeAsked [
	"An arrow is an element with a polygon geometry, not a bitmap: its vertices are the scaled
	points, and it asks for the extent the caller named. The size is read from the resizer, since
	an element measures itself only in a layout pass."

	| extent element |
	extent := 40 @ 40.
	element := LaserGameShapes eastArrowElementOfExtent: extent.
	self assert: element geometry class equals: BlPolygonGeometry.
	self assert: (self requestedExtentOf: element) equals: extent.
	self
		assert: element geometry vertices asArray
		equals:
			(LaserGameShapes
				 pointsOf: LaserGameShapes eastArrowPoints
				 scaledToExtent: extent) asArray
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testEachArrowHasOneTipAndItIsCentredOnTheOtherAxis [
	"An arrow points where its name says: exactly one vertex reaches the far edge, and it sits in
	the middle of the other axis."

	| bounds |
	{ LaserGameShapes northArrowPoints -> [ :point :box | point y = box top and: [ point x = box center x ] ].
	LaserGameShapes southArrowPoints -> [ :point :box | point y = box bottom and: [ point x = box center x ] ].
	LaserGameShapes eastArrowPoints -> [ :point :box | point x = box right and: [ point y = box center y ] ].
	LaserGameShapes westArrowPoints -> [ :point :box | point x = box left and: [ point y = box center y ] ] }
		do: [ :each |
			bounds := Rectangle encompassing: each key.
			self
				assert: (each key select: [ :point | each value value: point value: bounds ]) size
				equals: 1 ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testEachArrowIsSevenVerticesWideEnoughToBeAnArrow [
	"The four vertex arrays are the ones the original typed into a workspace on pages 081 and
	082: seven points each, an outline drawn as a closed polygon."

	{ LaserGameShapes northArrowPoints.
	LaserGameShapes eastArrowPoints.
	LaserGameShapes southArrowPoints.
	LaserGameShapes westArrowPoints } do: [ :points |
		self assert: points size equals: 7.
		points do: [ :each | self assert: each isPoint ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testEveryArrowElementUsesTheVerticesOfItsDirection [
	"Each of the four accessors builds from its own vertex array."

	| extent |
	extent := 30 @ 30.
	{ (LaserGameShapes northArrowElementOfExtent: extent) -> LaserGameShapes northArrowPoints.
	(LaserGameShapes eastArrowElementOfExtent: extent) -> LaserGameShapes eastArrowPoints.
	(LaserGameShapes southArrowElementOfExtent: extent) -> LaserGameShapes southArrowPoints.
	(LaserGameShapes westArrowElementOfExtent: extent) -> LaserGameShapes westArrowPoints }
		do: [ :each |
			self
				assert: each key geometry vertices asArray
				equals: (LaserGameShapes pointsOf: each value scaledToExtent: extent) asArray ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testPointsScaleToFillTheRequestedExtent [
	"Scaling maps the vertex array onto the rectangle the caller asks for, so the same array
	serves a 12 pixel hint and a 200 pixel drawing. The original had one fixed 330 pixel form and
	shrank the bitmap afterwards with scaledToSize:."

	{ 12 @ 12. 48 @ 48. 200 @ 120 } do: [ :extent |
		| scaled |
		scaled := LaserGameShapes
			          pointsOf: LaserGameShapes northArrowPoints
			          scaledToExtent: extent.
		self assert: scaled size equals: 7.
		self
			assert: (Rectangle encompassing: scaled)
			equals: (0 @ 0 corner: extent) ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testShapesAreBuiltAtWhateverSizeIsAsked [
	"Vertices scale, so no shape has a size of its own. The original drew every arrow into a 330
	pixel form once, cached the bitmap and scaled it down on use, which is why its small arrows
	were ragged."

	{ 12 @ 12. 50 @ 50. 200 @ 200 } do: [ :extent |
		{ LaserGameShapes northArrowElementOfExtent: extent.
		LaserGameShapes crossHairElementOfExtent: extent } do: [ :element |
			self assert: (self requestedExtentOf: element) equals: extent ] ]
]
