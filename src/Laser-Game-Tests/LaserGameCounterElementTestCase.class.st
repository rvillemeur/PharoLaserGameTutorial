Class {
	#name : 'LaserGameCounterElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
LaserGameCounterElementTestCase >> testCounterIsATransparentRoundedFrame [
	"Page 141 wraps the display in a transparent column with rounded corners, a two pixel border
	and a five pixel inset, and takes the size of what it holds."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter background class equals: BlTransparentBackground.
	self assert: counter geometry class equals: BlRoundedRectangleGeometry.
	self assert: counter border width equals: LaserGameCounterElement borderWidth.
	self
		assert: counter border paint color
		equals: LaserGameColors counterBorderColor.
	self
		assert: counter padding
		equals: (BlInsets all: LaserGameCounterElement inset).
	self
		assert: counter constraints horizontal resizer class
		equals: BlLayoutFitContentResizer.
	self
		assert: counter constraints vertical resizer class
		equals: BlLayoutFitContentResizer
]

{ #category : 'tests' }
LaserGameCounterElementTestCase >> testCounterShowsADisplayWithItsCaptionUnderIt [
	"A counter is the display and then the caption, in that order, which is the order page 141
	adds them in. Its comment says the label goes above the panel, and the code puts it after."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter children size equals: 2.
	self assert: counter children first identicalTo: counter led.
	self assert: counter children second identicalTo: counter label.
	self assert: counter led class equals: LaserGameLedElement.
	self assert: counter led digitCount equals: 3.
	self assert: counter label text asString equals: 'Laser Path'.
	self assert: counter layout class equals: BlLinearLayout
]

{ #category : 'tests' }
LaserGameCounterElementTestCase >> testTheCounterPassesWhatItIsToldToItsDisplay [
	"A counter holds its display, so the game sets a value on the counter and never looks for the
	display. Page 142 has to find the LED itself, by name, among every morph of the game."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter value equals: 0.
	self deny: counter highlighted.
	counter value: 17.
	counter highlighted: true.
	self assert: counter led value equals: 17.
	self assert: counter value equals: 17.
	self assert: counter led highlighted.
	self assert: counter highlighted
]
