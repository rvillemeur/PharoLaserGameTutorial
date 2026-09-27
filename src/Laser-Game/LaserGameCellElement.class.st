"
I am the element that shows one cell of the grid, and I am the thing a player clicks on.

I keep the CellRenderer that built me, so I can answer the cell I show, where that cell sits in the grid, and — through `clickRegionAt:` — which click region a point of mine falls in. The point is in my own coordinates, which is what Bloc hands to an event handler, so nothing has to subtract my position from a board-wide coordinate first. The original tutorial had no such element: every cell drew into one shared Form, and a click had to be converted into a grid location by dividing by the cell size (`CellRenderer >> offsetWithinGridForm` and the `cellForEvent:` family on the LaserGame morph).

I listen to the mouse myself: entering, leaving, moving and clicking all reach me because Bloc delivers an event to the element it happened in. I tell my board what happened (`hoverCellElement:`, `unhoverCellElement:`, `clickCellElement:`), and my board holds the state the game reads. The original registered five events on one board morph, added itself as a listener of the hand morph to see moves with the button up, and searched the submorphs under the pointer for the morph named 'board'; none of that has a counterpart here.

While the pointer is in me I also keep a hint: `showPositionHintAt:` asks my renderer what applies at that point and `clearPositionHint` forgets it when the pointer leaves. Only a mirror answers a region, since a click acts on mirrors only.

Instance variables:
	renderer	<CellRenderer>	the renderer that built me; it carries the grid and my location in it
	hintRegion	<CellClickRegion class>	the region the pointer is in, nil when it is elsewhere or my cell offers no hint

"
Class {
	#name : 'LaserGameCellElement',
	#superclass : 'BlElement',
	#instVars : [
		'renderer',
		'hintRegion'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
LaserGameCellElement >> board [
	"Answer the board element I am a cell of, or nil while I have no parent."

	^ self hasParent ifTrue: [ self parent ] ifFalse: [ nil ]
]

{ #category : 'accessing' }
LaserGameCellElement >> cell [
	"Answer the cell I show."

	^ self renderer cell
]

{ #category : 'interaction' }
LaserGameCellElement >> clearPositionHint [
	"Forget my hint: the pointer is no longer in me."

	hintRegion := nil
]

{ #category : 'event handling' }
LaserGameCellElement >> click: anEvent [
	"A click landed on me: a press and a release in the same cell, which the original checked by
	keeping the location of the press in activeCellLocation and comparing it on mouse up."

	self board ifNotNil: [ :board | board clickCellElement: self ]
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
LaserGameCellElement >> hintRegion [
	"Answer the click region the pointer is in, or nil when the pointer is not in me or my cell
	offers no hint. Section 3.6 draws an arrow from this; for now it is what the original wrote
	to the Transcript on page 080."

	^ hintRegion
]

{ #category : 'initialization' }
LaserGameCellElement >> initialize [
	"Listen to the mouse myself. In the original the LaserGame morph registered interest in the
	events of one board morph and then worked out which cell each event belonged to; here every
	cell is an element of its own, so Bloc delivers the event to the cell it happened in."

	super initialize.
	self addEventHandlerOn: BlMouseEnterEvent do: [ :anEvent | self mouseEnter: anEvent ].
	self addEventHandlerOn: BlMouseLeaveEvent do: [ :anEvent | self mouseLeave: anEvent ].
	self addEventHandlerOn: BlMouseMoveEvent do: [ :anEvent | self mouseMove: anEvent ].
	self addEventHandlerOn: BlClickEvent do: [ :anEvent | self click: anEvent ]
]

{ #category : 'event handling' }
LaserGameCellElement >> mouseEnter: anEvent [
	"The pointer came over me: my board now hovers me."

	self board ifNotNil: [ :board | board hoverCellElement: self ]
]

{ #category : 'event handling' }
LaserGameCellElement >> mouseLeave: anEvent [
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
]

{ #category : 'event handling' }
LaserGameCellElement >> mouseMove: anEvent [
	"The pointer moved inside me, so I am the cell it is over, and the point it carries decides
	which hint I show. The original reached the same two facts from a hand position, a board
	offset and a division by the cell size."

	self board ifNotNil: [ :board | board hoverCellElement: self ].
	self showPositionHintAt: anEvent localPosition
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

{ #category : 'interaction' }
LaserGameCellElement >> showPositionHintAt: aPoint [
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates. My renderer
	decides: a mirror answers the region the point falls in, every other cell answers nothing."

	hintRegion := self renderer hintRegionAt: aPoint
]
