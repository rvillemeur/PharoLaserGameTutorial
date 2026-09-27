"
I am the element that shows one cell of the grid, and I am the thing a player clicks on.

I keep the CellRenderer that built me, so I can answer the cell I show, where that cell sits in the grid, and — through `clickRegionAt:` — which click region a point of mine falls in. The point is in my own coordinates, which is what Bloc hands to an event handler, so nothing has to subtract my position from a board-wide coordinate first. The original tutorial had no such element: every cell drew into one shared Form, and a click had to be converted into a grid location by dividing by the cell size (`CellRenderer >> offsetWithinGridForm` and the `cellForEvent:` family on the LaserGame morph).

Instance variables:
	renderer	<CellRenderer>	the renderer that built me; it carries the grid and my location in it

"
Class {
	#name : 'LaserGameCellElement',
	#superclass : 'BlElement',
	#instVars : [
		'renderer'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
LaserGameCellElement >> cell [
	"Answer the cell I show."

	^ self renderer cell
]

{ #category : 'interaction' }
LaserGameCellElement >> clickRegionAt: aPoint [
	"Answer the click region class aPoint falls in. aPoint is in my own coordinates, which is what
	Bloc hands to an event handler, so no board offset is subtracted first."

	^ CellClickRegion clickRegionForPoint: aPoint
]

{ #category : 'accessing' }
LaserGameCellElement >> gridLocation [
	"Answer where my cell sits in the grid, x being the column and y the row."

	^ self renderer cellLocation
]

{ #category : 'accessing' }
LaserGameCellElement >> renderer [
	"Answer the renderer that built me and redraws me."

	^ renderer
]

{ #category : 'accessing' }
LaserGameCellElement >> renderer: aCellRenderer [
	"Set the renderer that built me. It carries the grid and my location within it."

	renderer := aCellRenderer
]
