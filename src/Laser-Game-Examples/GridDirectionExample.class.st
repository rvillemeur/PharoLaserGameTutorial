"
I offer the four directions to look at.

A direction is a class, not an instance, so my example answers `GridDirection` and the inspector opens on its Directions tab, which puts the four of them side by side with the step each one takes, the side it enters a cell by and what each kind of mirror does to it.
"
Class {
	#name : 'GridDirectionExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
GridDirectionExample class >> directions [
	"The four directions of travel, side by side, on the Directions tab.
	GridDirectionExample directions"

	<sampleInstance>
	^ GridDirection
]
