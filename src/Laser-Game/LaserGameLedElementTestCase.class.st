Class {
	#name : 'LaserGameLedElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'helpers' }
LaserGameLedElementTestCase >> litSegmentsOf: aLed at: anIndex [
	"Answer the names of the segments the digit at anIndex of aLed lights, sorted, so that a test
	can compare them against the list of a page without caring about the order."

	| digit |
	digit := aLed digitElements at: anIndex.
	^ ((1 to: digit children size)
		   select: [ :each |
		   (digit children at: each) background paint color = aLed onColor ]
		   thenCollect: [ :each | LaserGameLedElement segmentNames at: each ])
		  asSortedCollection asArray
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testANumberIsShownRightAlignedWithoutLeadingZeros [
	"A number shorter than the display sits at its right, and the digits in front of it light
	nothing at all. An LED that shows 007 for seven would read as another number."

	| led |
	led := LaserGameLedElement digits: 3.
	led value: 5.
	self assertEmpty: (self litSegmentsOf: led at: 1).
	self assertEmpty: (self litSegmentsOf: led at: 2).
	self assert: (self litSegmentsOf: led at: 3) equals: #( #a #c #d #f #g )
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testANumberTooLongForTheDisplayKeepsItsLastDigits [
	"Three digits cannot show a thousand. The last digits are the ones kept, as an odometer does,
	rather than the display going blank or raising."

	| led |
	led := LaserGameLedElement digits: 2.
	led value: 123.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #a #b #d #e #g ).
	self assert: (self litSegmentsOf: led at: 2) equals: #( #a #b #c #d #g )
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testDisplayIsAsWideAsItsDigitsAndTheGapsBetweenThem [
	"A display takes one digit width per digit and one gap between each pair, and it holds one
	element per digit. The size is read from the layout constraints, since nothing is laid out."

	| led |
	led := LaserGameLedElement digits: 3.
	self assert: led digitElements size equals: 3.
	self
		assert: led constraints horizontal resizer size
		equals: (LaserGameLedElement digitExtent x + LaserGameLedElement digitGap * 3)
			- LaserGameLedElement digitGap.
	self
		assert: led constraints vertical resizer size
		equals: LaserGameLedElement digitExtent y
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testEachDigitLightsTheSegmentsOfItsNumber [
	"Eight lights all seven segments, one lights the pair on the right, and zero lights every
	segment but the bar in the middle. Those are the shapes the segment names describe."

	| led |
	led := LaserGameLedElement digits: 1.
	led value: 8.
	self
		assert: (self litSegmentsOf: led at: 1)
		equals: #( #a #b #c #d #e #f #g ).
	led value: 1.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #b #c ).
	led value: 0.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #a #b #c #d #e #f )
]

{ #category : 'tests' }
LaserGameLedElementTestCase >> testEveryDigitHoldsOneRectanglePerSegment [
	"A digit is built once, out of seven rectangles, and they stay: showing another number only
	recolours them. The seven sit inside the digit and do not overlap."

	| led digit first |
	led := LaserGameLedElement digits: 2.
	digit := led digitElements first.
	self assert: digit children size equals: LaserGameLedElement segmentNames size.
	first := digit children first.
	led value: 8.
	self assert: digit children size equals: 7.
	self assert: digit children first identicalTo: first.
	LaserGameLedElement segmentNames do: [ :name |
		| bounds |
		bounds := LaserGameLedElement segmentBoundsOf: name.
		self assert: bounds origin >= (0 @ 0).
		self assert: bounds corner <= LaserGameLedElement digitExtent ]
]

{ #category : 'as yet unclassified' }
LaserGameLedElementTestCase >> testHighlightingBrightensTheLitSegments [
	"Page 142 highlights the counter while the laser fires. Highlighting changes the color of the
	segments that are lit and leaves the others alone. The two colors are the ones the screenshot
	of page 148 shows: the counter of the beam is almost white while the laser fires, and the move
	counter beside it stays the lavender of the LED."

	| led digit lit unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	digit := led digitElements first.
	lit := digit children second.
	unlit := digit children first.
	self deny: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitColor.
	led highlighted: true.
	self assert: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitHighlightColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterDigitOffColor
]

{ #category : 'as yet unclassified' }
LaserGameLedElementTestCase >> testTheDigitsFitInsideTheDisplay [
	"Every digit has to be inside the display, which clips what sticks out of it. A linear layout
	adds its cell spacing around the cells as well as between them, so the gap between two digits
	is a margin on each digit but the first, and the row comes to exactly the width the display
	takes."

	| led spacing used |
	led := LaserGameLedElement digits: 3.
	spacing := led layout cellSpacing.
	used := (led digitElements size + 1 * spacing)
	        + (led digitElements inject: 0 into: [ :sum :each |
			         sum + each constraints horizontal resizer size + each margin left
			         + each margin right ]).
	self assert: used equals: (LaserGameLedElement extentForDigits: 3) x.
	self assert: led digitElements first margin left equals: 0.
	self
		assert: led digitElements second margin left
		equals: LaserGameLedElement digitGap
]

{ #category : 'as yet unclassified' }
LaserGameLedElementTestCase >> testUnlitSegmentsVanishIntoTheBody [
	"The original's display is a dark slab, and a segment that is not lit is the color of that
	slab, so only the lit ones are seen. The port paints the same two colors, which means the
	display has to carry the slab as its own background: on the ramp of page 140 an unlit segment
	would otherwise read as a lit one."

	| led unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	unlit := led digitElements first children first.
	self
		assert: led background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: LaserGameColors counterDigitOffColor
		equals: LaserGameColors counterBodyColor
]
