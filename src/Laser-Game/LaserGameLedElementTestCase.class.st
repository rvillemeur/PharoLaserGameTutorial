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

{ #category : 'tests' }
LaserGameLedElementTestCase >> testHighlightingBrightensTheLitSegments [
	"Page 142 highlights the counter while the laser fires. Highlighting changes the colour of the
	segments that are lit and leaves the others alone."

	| led digit lit unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	digit := led digitElements first.
	lit := digit children second.
	unlit := digit children first.
	self deny: led highlighted.
	self assert: lit background paint color equals: LaserGameColors counterDigitColor darker.
	led highlighted: true.
	self assert: led highlighted.
	self assert: lit background paint color equals: LaserGameColors counterDigitColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterDigitOffColor
]
