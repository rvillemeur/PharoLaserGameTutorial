"
I offer the shape library to look at.

The shapes of the game are drawn by class-side methods of `LaserGameShapes`, so my example answers that class and the inspector opens on its Shapes tab, which draws every shape at three sizes.
"
Class {
	#name : 'LaserGameShapesExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
LaserGameShapesExample class >> shapes [
	"Every shape the game draws, at 30, 50 and 80 pixels, on the Shapes tab.
	LaserGameShapesExample shapes"

	<sampleInstance>
	^ LaserGameShapes
]

{ #category : 'accessing' }
LaserGameShapesExample >> shapes [
	"Every shape the game draws, at 30, 50 and 80 pixels, on the Shapes tab.
	LaserGameShapesExample shapes"

	<sampleInstance>
	^ LaserGameShapes
]
