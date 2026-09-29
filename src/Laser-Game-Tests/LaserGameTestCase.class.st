"
I am the test case the tests of this port that have to run at more than one cell size inherit from.

The 2007 tutorial writes its click points as numbers of a thirty pixel cell, and pages 190 to 196 rewrite them relative to the rectangles the regions answer, so that a change of `CellRenderer cellExtent` cannot make a correct test fail. This port inherited the rewritten tables with the captured source, and proves them here instead of trusting them: `withCellExtent:do:` sets the cell size of the whole package for the duration of a block and puts the old size back afterwards, so one test can run the same table at thirty, forty and eighty pixels.

I hold nothing else and I am abstract. A test that never looks at a cell size has no reason to be here.
"
Class {
	#name : 'LaserGameTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'testing' }
LaserGameTestCase class >> isAbstract [
	"Answer whether I am abstract. I hold what my subclasses share and no test of my own."

	^ self = LaserGameTestCase
]

{ #category : 'support' }
LaserGameTestCase >> withCellExtent: anExtent do: aBlock [
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Page 137 of the original raises the cell size and then looks by eye for the
	sizes that were written down instead of derived from it; this runs that experiment from the
	test suite. Pages 190 to 196 ask the same question of the click tables, so the method lives
	here, where every test that has to ask it can reach it."

	| previous |
	previous := CellRenderer class >> #cellExtent.
	[
	CellRenderer class
		compile: 'cellExtent' , String cr , String tab , '^ ' , anExtent printString
		classified: 'constants'.
	aBlock value ] ensure: [
		CellRenderer class compile: previous sourceCode classified: 'constants' ]
]
