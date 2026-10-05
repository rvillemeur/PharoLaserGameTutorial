"
I offer the colour palette to look at.

Every colour of the game is a class-side method of `LaserGameColors`, so my example answers that class and the inspector opens on its Palette tab, which shows a swatch of each colour beside the name it answers to.
"
Class {
	#name : 'LaserGameColorsExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
LaserGameColorsExample class >> palette [
	"Every colour of the game, swatch beside name, on the Palette tab.
	LaserGameColorsExample palette"

	<sampleInstance>
	^ LaserGameColors
]
