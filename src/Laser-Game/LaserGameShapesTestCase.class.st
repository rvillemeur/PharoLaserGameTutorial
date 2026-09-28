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
LaserGameShapesTestCase >> testABeamIsAPaleBandWithABrightCentreOnIt [
	"Page 152 takes two masks out of the painted beam, a wide splatter and a narrow centre, and
	page 153 paints them in two colours. Here the beam is an element holding two bars: the pale
	one first, the bright one on top of it, both running the whole length and both centred across
	it."

	| extent element splatter centre |
	extent := 50 @ 50.
	element := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	splatter := element children first.
	centre := element children second.
	self
		assert: splatter background paint color
		equals: LaserGameColors laserBeamSplatterColor.
	self
		assert: centre background paint color
		equals: LaserGameColors laserBeamCenterColor.
	self assert: (self requestedExtentOf: splatter) x equals: extent x.
	self assert: (self requestedExtentOf: centre) x equals: extent x.
	self
		assert: (self requestedExtentOf: centre) y
		< (self requestedExtentOf: splatter) y.
	element children do: [ :each |
		self
			assert: each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testABeamThatArrivesFromTwoSidesTurnsInTheMiddle [
	"A mirror sends the beam on by another side, so two half beams meet in the middle of the cell:
	one from the side the light arrives by, one to the side it leaves by. Pages 166 to 172 of the
	original draw two whole beams instead and then black out the two quadrants of the cell the
	light never reaches."

	| extent beam half |
	extent := 40 @ 40.
	half := extent x // 2.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #west #north ).
	self assert: beam children size equals: 4.
	self assert: (self requestedExtentOf: beam children first) x equals: half.
	self assert: beam children first constraints position x equals: 0.
	self assert: (self requestedExtentOf: beam children second) y equals: half.
	self assert: beam children second constraints position y equals: 0.
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testABeamThatCrossesItsOwnPathDrawsBothCoresOverBothBands [
	"A cell all four sides of which are lit is crossed twice, which page 170 finds on the board and
	page 173 fixes for the blank cell. Both bands run the whole way across, and both bright cores
	are drawn after them, so neither core is buried under the other band. Page 167 arrives at the
	same order by painting one of the cores a second time."

	| extent beam |
	extent := 40 @ 40.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #north #east #south #west ).
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
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
LaserGameShapesTestCase >> testAHalfBeamCrossesHalfTheCellFromTheSideItComesFrom [
	"A cell that swallows the light shows the beam only as far as its middle. Pages 160 and 162 of
	the original draw the whole beam and then black out the half the light never reaches, keeping
	the west half when the west segment is lit and the east half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent x // 2.
	{ #west -> 0. #east -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { each key }.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) x equals: half.
			self assert: bar constraints position x equals: each value.
			self
				assert: bar constraints position y + ((self requestedExtentOf: bar) y / 2)
				equals: extent y / 2 ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAHalfBeamGoingUpOrDownKeepsTheHalfTheLightComesFrom [
	"The same half beam turned a quarter: page 161 keeps the bottom half when the south segment is
	lit and the top half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent y // 2.
	{ #north -> 0. #south -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { each key }.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) y equals: half.
			self assert: bar constraints position y equals: each value.
			self
				assert: bar constraints position x + ((self requestedExtentOf: bar) x / 2)
				equals: extent x / 2 ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAHalfBeamIsAsThickAsAWholeOne [
	"Half a beam is half as long and no thinner: the original cuts its mask in half and leaves the
	pixels it keeps alone."

	| extent whole |
	extent := 40 @ 40.
	whole := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	#( #west #east ) do: [ :side |
		| half |
		half := LaserGameShapes
			        laserBeamElementOfExtent: extent
			        fromSides: { side }.
		half children asArray with: whole children asArray do: [ :bar :wholeBar |
			self
				assert: (self requestedExtentOf: bar) y
				equals: (self requestedExtentOf: wholeBar) y.
			self
				assert: bar background paint color
				equals: wholeBar background paint color ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testAVerticalBeamIsTheHorizontalOneTurned [
	"A beam runs across a cell or down it. The original has one painted form and turns the drawing
	by asking the mask for a vertical strip instead of a horizontal one; here the two bars are the
	same two bars with their sides exchanged, so the two beams meet at the same thickness where a
	path turns."

	| extent horizontal vertical |
	extent := 50 @ 50.
	horizontal := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #west #east ).
	vertical := LaserGameShapes laserBeamElementOfExtent: extent fromSides: #( #north #south ).
	self assert: (self requestedExtentOf: vertical) equals: extent.
	self assert: vertical children size equals: 2.
	vertical children asArray
		with: horizontal children asArray
		do: [ :down :across |
			self
				assert: (self requestedExtentOf: down)
				equals: (self requestedExtentOf: across) transposed.
			self
				assert: down background paint color
				equals: across background paint color.
			self
				assert: down constraints position + ((self requestedExtentOf: down) / 2)
				equals: extent / 2 ]
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

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheBeamGetsThickerWithTheCell [
	"The original paints one beam form of one cell size and scales the bitmap when the cell grows,
	so the beam keeps its proportions. Here the two thicknesses are computed from the extent, which
	comes to the same thing: twice the cell, twice the beam."

	| small large |
	small := LaserGameShapes laserBeamElementOfExtent: 30 @ 30 fromSides: #( #west #east ).
	large := LaserGameShapes laserBeamElementOfExtent: 60 @ 60 fromSides: #( #west #east ).
	self
		assert: (self requestedExtentOf: large children first) y
		equals: (self requestedExtentOf: small children first) y * 2.
	self
		assert: (self requestedExtentOf: large children second) y
		equals: (self requestedExtentOf: small children second) y * 2.
	self
		assert: (self requestedExtentOf: small children first) y
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: 30 @ 30).
	self
		assert: (self requestedExtentOf: small children second) y
		equals: (LaserGameShapes laserBeamCenterThicknessFor: 30 @ 30).
	self
		assert: (LaserGameShapes laserBeamCenterThicknessFor: 2 @ 2)
		equals: 1
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheClockwiseArrowIsTheCounterClockwiseOneMirrored [
	"Page 099 makes the clockwise arrow by flipping the other one horizontally, which is one
	step there and one line here."

	| left right |
	left := LaserGameShapes counterClockwiseArrowPoints.
	right := LaserGameShapes clockwiseArrowPoints.
	self assert: right size equals: left size.
	left with: right do: [ :each :mirrored |
		self assert: mirrored x equals: each x negated.
		self assert: mirrored y equals: each y ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheRingOfTheRotateArrowIsAsWideAsTheStemOfItsHead [
	"The two radii of page 099 are 160 and 200, and the stem of its arrow head is 40 wide and
	sits at the left end of the ring. That is why the flood fill of the original made one shape
	out of the two drawings, and it is what keeps the outline of the port closed."

	| head ring |
	head := LaserGameShapes rotateArrowHeadPoints.
	ring := LaserGameShapes rotateArrowOuterRadius
	        - LaserGameShapes rotateArrowInnerRadius.
	self assert: ring equals: (head sixth x - head third x).
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowOuterRadius
		equals: head third x.
	self
		assert: LaserGameShapes rotateArrowCenter x
		        - LaserGameShapes rotateArrowInnerRadius
		equals: head sixth x
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheRotateArrowElementsArePolygonsOfTheSizeAsked [
	"Like the four straight arrows, a rotate arrow is a polygon scaled into the extent asked
	for, so the 450 pixel form of page 099 and the cache it went into have no counterpart."

	{ (#counterClockwiseArrowElementOfExtent:
	 -> LaserGameShapes counterClockwiseArrowPoints).
	(#clockwiseArrowElementOfExtent: -> LaserGameShapes clockwiseArrowPoints) }
		do: [ :each |
			#( 30 48 120 ) do: [ :size |
				| element extent |
				extent := size @ size.
				element := LaserGameShapes perform: each key with: extent.
				self assert: (self requestedExtentOf: element) equals: extent.
				self
					assert: element geometry vertices
					equals:
					(LaserGameShapes pointsOf: each value scaledToExtent: extent) ] ]
]

{ #category : 'tests' }
LaserGameShapesTestCase >> testTheRotateArrowIsARingBetweenTwoCirclesWithAHeadOnIt [
	"Page 099 draws the curved arrow as two arcs about one centre, cut off by a line, with the
	straight arrow head of the earlier pages stuck on the end. Every point of the outline is
	therefore either a point of that head or a point of one of the two circles."

	| center head |
	center := LaserGameShapes rotateArrowCenter.
	head := LaserGameShapes rotateArrowHeadPoints.
	LaserGameShapes counterClockwiseArrowPoints do: [ :each |
		| radius |
		radius := (each - center) r.
		self assert: ((head includes: each) or: [
				 (radius closeTo: LaserGameShapes rotateArrowInnerRadius) or: [
					 radius closeTo: LaserGameShapes rotateArrowOuterRadius ] ]) ]
]
