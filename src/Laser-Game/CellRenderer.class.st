"
I am the visual representation of one cell of a grid.

The original tutorial had one SketchMorph for the whole board, and every cell drew its borders and contents into that single Form. This port drops that design: each cell gets its own element, so hit testing, redrawing and hint overlays are local to the cell instead of being computed against a board-wide bitmap.

I hold the location of my cell inside the grid, and the grid itself, so I can always ask the model for the cell I represent. My subclasses declare which cell model they render with the class-side method modelClass, and `CellRenderer class >> rendererFor:` uses that to pick the right subclass for a cell. One subclass per concrete Cell subclass, no case statement.

Instance variables:
	cellLocation	<Point>	position of my cell inside the grid, 1@1 being the top left cell
	grid		<Grid>	the model I read my cell from
"
Class {
	#name : 'CellRenderer',
	#superclass : 'Object',
	#instVars : [
		'cellLocation',
		'grid'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
CellRenderer class >> borderWidth [
	"Answer the width, in pixels, of the border drawn inside the edges of every cell."

	^ 1
]

{ #category : 'constants' }
CellRenderer class >> cellExtent [
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere: page 137 of the original
	raises it from thirty pixels to forty and then goes looking for the sizes that had been
	written down instead. The port has been at fifty since Section 3.1, because the source it
	inherits is the finished game, where the author had already enlarged the cells a second time
	on page 196."

	^50@50
]

{ #category : 'constants' }
CellRenderer class >> crossHairExtent [
	"Answer the size the cross hair under the pointer is drawn at. Page 134 draws it into a form
	of one cell, with arms of ten pixels in the thirty pixel cell of the time, and the shape
	makes its arms a third of what it is given, so a cell is the size that keeps those
	proportions."

	^ self cellExtent
]

{ #category : 'accessing' }
CellRenderer class >> hintArrowExtent [
	"Answer the size a hint arrow is drawn at: a couple of pixels smaller than a cell, which is
	the size page 094 scales its arrow form to."

	^ self cellExtent - 2
]

{ #category : 'accessing' }
CellRenderer class >> hintArrowOffset [
	"Answer where a hint arrow sits within its cell: centred, as page 094 computes it from the
	two extents."

	^ (self cellExtent - self hintArrowExtent) // 2
]

{ #category : 'constants' }
CellRenderer class >> ignoreRegionOffset [
	"Answer the width, in pixels, of the margin along the edges of a cell where a click does
	nothing. Page 075 of the original picks four pixels, and four is right at any cell size: the
	margin is there to keep a click aimed at the neighbouring cell from turning this one."

	^4
]

{ #category : 'constants' }
CellRenderer class >> insideRegionExtent [
	"Answer the size of the square in the middle of a cell where a click asks for a push. Page
	138 of the original writes it as the cell less twenty pixels, so the ring around it keeps its
	width while the cell grows."

	^self cellExtent - 20
]

{ #category : 'accessing' }
CellRenderer class >> modelClass [
	"Answer the Cell subclass I render. Each concrete renderer answers exactly one."

	^ self subclassResponsibility
]

{ #category : 'examples' }
CellRenderer class >> openExample [
	"Open one blank cell in a space of its own, to look at it and change it.
	This is the Bloc equivalent of the workspace experiment of the original tutorial.

	CellRenderer openExample"

	| grid renderer space |
	grid := Grid new.
	renderer := self rendererFor: (grid at: 1 @ 1) grid: grid.
	space := BlSpace new.
	space extent: self cellExtent * 3.
	space title: 'Laser Game cell'.
	space root addChild: renderer newElement.
	space show.
	^ space
]

{ #category : 'constants' }
CellRenderer class >> outsideRegionExtent [
	"Answer the size of the square where a click asks for a rotation: the cell less the ignore
	margin on each side. The margin is what is written down, not the region."

	^self cellExtent - (2 * self ignoreRegionOffset)
]

{ #category : 'instance creation' }
CellRenderer class >> rendererFor: aCell [
	"Answer the renderer class that renders aCell."

	^ self subclasses
		  detect: [ :each | each modelClass = aCell class ]
		  ifNone: [ self error: 'No renderer for ' , aCell class name ]
]

{ #category : 'instance creation' }
CellRenderer class >> rendererFor: aCell grid: aGrid [
	"Answer a renderer for aCell positioned within aGrid. Cell geometry needs no target form."

	| renderer |
	renderer := (self rendererFor: aCell) new.
	renderer
		cellLocation: aCell gridLocation;
		grid: aGrid.
	^ renderer
]

{ #category : 'accessing' }
CellRenderer >> cell [
	^self grid at: self cellLocation.

]

{ #category : 'accessing' }
CellRenderer >> cellLocation [
	"Answer the value of cellLocation"

	^ cellLocation
]

{ #category : 'accessing' }
CellRenderer >> cellLocation: anObject [
	"Set the value of cellLocation"

	cellLocation := anObject
]

{ #category : 'accessing' }
CellRenderer >> grid [
	"Answer the value of grid"

	^ grid
]

{ #category : 'accessing' }
CellRenderer >> grid: anObject [
	"Set the value of grid"

	grid := anObject
]

{ #category : 'interaction' }
CellRenderer >> hintColorAt: aPoint [
	"Answer the colour a hint arrow is painted in at aPoint, in the coordinates of my cell. My
	cell reacts to nothing, so the question does not arise here and the neutral grey of page 081
	is answered; the mirror renderer asks the click region whether the move is allowed."

	^ LaserGameShapes arrowColor
]

{ #category : 'interaction' }
CellRenderer >> hintRegionAt: aPoint [
	"Answer the click region whose hint applies at aPoint, in the coordinates of my cell, or nil
	when my cell offers no hint at all. Every renderer is asked, and all but the mirror answer
	nothing: a click acts on mirrors only."

	^ nil
]

{ #category : 'interaction' }
CellRenderer >> mouseUpAt: aPoint [
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when nothing happened. Nothing happens here: only a mirror answers a click, which is
	page 114 of the original — the renderer superclass does nothing, and only the mirror renderer
	deals with the request."

	^ nil
]

{ #category : 'rendering' }
CellRenderer >> newElement [
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children: the
	beam first, then the contents of the cell over it, since page 162 draws the target again after
	the beam so that the light does not hide what it hits."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderLaserOn: element.
	self renderContentsOn: element.
	^ element
]

{ #category : 'rendering' }
CellRenderer >> renderBackgroundOn: anElement [
	"Paint the cell background. Every cell shares the game board background color."

	anElement background: LaserGameColors gameBoardBackgroundColor
]

{ #category : 'rendering' }
CellRenderer >> renderBeamOn: anElement [
	"Draw the beam my lit cell shows, as one child of anElement. The sides of my cell that carry
	light say the whole of what is drawn, so every kind of cell is drawn here: a blank cell the
	beam crosses, the target it ends in, the mirror it turns at, and any of them crossed twice.
	Pages 156 to 172 of the original need three renderers and a dozen masks for that, because it
	paints whole beams onto one shared form and then blacks out what does not belong."

	anElement addChild: (LaserGameShapes
			 laserBeamElementOfExtent: self class cellExtent
			 fromSides: self cell litSides)
]

{ #category : 'rendering' }
CellRenderer >> renderBorderOn: anElement [
	"Draw the cell border. Bloc draws a border inside the bounds of the element, so the
	border costs no space and the cells of a grid stay exactly cellExtent apart."

	anElement border: (BlBorder
			 paint: LaserGameColors cellBorderColor
			 width: self class borderWidth)
]

{ #category : 'rendering' }
CellRenderer >> renderContentsOn: anElement [
	"Draw what is inside the cell, as children of anElement. A cell with nothing inside
	draws nothing, so this is empty here and overridden by the subclasses that have
	contents."
]

{ #category : 'rendering' }
CellRenderer >> renderLaserOn: anElement [
	"Draw the beam where it crosses my cell, as children of anElement. Nothing is drawn while the
	laser is off or while no light reaches my cell: the original asks the first question in
	#render, before it sends #renderLaser at all, and the second at the head of every #renderLaser.
	What a lit cell draws is #renderBeamOn:, which is the same for every kind of cell."

	self grid laserIsActive ifFalse: [ ^ self ].
	self cell isOff ifTrue: [ ^ self ].
	self renderBeamOn: anElement
]
