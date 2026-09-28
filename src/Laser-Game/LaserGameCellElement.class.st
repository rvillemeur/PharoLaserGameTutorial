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
		'hintRegion',
		'hintElement',
		'hintPosition'
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

{ #category : 'hints' }
LaserGameCellElement >> clearPositionHint [
	"Forget my hint: the pointer is no longer in me, so the arrow goes too, and so does the point
	it was read at."

	hintPosition := nil.
	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
]

{ #category : 'interaction' }
LaserGameCellElement >> click: anEvent [
	"A click landed on me: a press and a release in the same cell, which the original checked by
	keeping the location of the press in activeCellLocation and comparing it on mouse up. The
	point the event carries is in my own coordinates, and it decides what the click does."

	self clickAt: anEvent localPosition
]

{ #category : 'interaction' }
LaserGameCellElement >> clickAt: aPoint [
	"Act on a click at aPoint, in my own coordinates. My board records that I was clicked, my
	renderer decides whether my cell acts and which region handles it, and the board draws itself
	again when something changed. The original walked the same chain from the morph to the
	renderer to the click region; it started from a board offset, where this starts from a point
	Bloc already expressed in the cell."

	self board ifNotNil: [ :board | board clickCellElement: self ].
	(self renderer mouseUpAt: aPoint) ifNil: [ ^ self ].
	self board ifNotNil: [ :board | board redrawCells ]
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
LaserGameCellElement >> hintElement [
	"Answer the element drawing my hint, or nil when I show none."

	^ hintElement
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

{ #category : 'drawing' }
LaserGameCellElement >> redraw [
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because page 126 of the original is the
	tale of a view that went on believing in the cell that had moved away. A blank cell offers no
	push, so the arrow of the mirror that left goes with it. The original repainted a rectangle
	of the board form and called it redrawCell."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
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

{ #category : 'hints' }
LaserGameCellElement >> showPositionHintAt: aPoint [
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing, so the arrow is built once. The point
	itself is kept, because a redraw has to ask the question again for the cell that stands in me
	then."

	| region |
	hintPosition := aPoint.
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self ].
	hintRegion := region.
	self updateHintElement
]

{ #category : 'hints' }
LaserGameCellElement >> updateHintElement [
	"Show the picture of the hint I hold, and no other, in the colour of what a click there would
	do. The original drew its arrow straight onto the board form, which is why page 093 warns
	that old arrows have to be cleaned off; here the arrow is a child of mine, so the previous
	one goes when it is removed. The colour comes from page 130: my renderer answers green when
	the move is allowed and red when it is refused. A region without a picture, such as the
	ignore margin, answers nothing and leaves me with no hint at all."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each
			background: (self renderer hintColorAt: hintPosition);
			position: CellRenderer hintArrowOffset.
		self addChild: each ]
]
