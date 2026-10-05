"
I offer the boards the factory deals to look at.

`GridFactory` deals boards from class-side methods, so my example answers that class and the inspector opens on its Boards tab, which draws each board it deals, and on its Counts tab, which says how many cells, mirrors, targets and blanks each one holds.
"
Class {
	#name : 'GridFactoryExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
GridFactoryExample class >> boardsTheFactoryDeals [
	"The three boards the factory deals, drawn on the Boards tab and counted on the Counts tab.
	GridFactoryExample boardsTheFactoryDeals"

	<sampleInstance>
	^ GridFactory
]
