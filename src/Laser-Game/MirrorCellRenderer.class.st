"
I render a MirrorCell: a background, a border and the mirror itself, drawn as a thick diagonal leaning one way or the other according to the orientation of my cell model.

I am selected for a cell by `CellRenderer class >> rendererFor:`, which matches my modelClass against the class of the cell.
"
Class {
	#name : 'MirrorCellRenderer',
	#superclass : 'CellRenderer',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
MirrorCellRenderer class >> mirrorWidth [
	"Answer the thickness, in pixels, of the mirror. The original drew its diagonal with a two
	pixel pen, and this is that pen."

	^ 2
]

{ #category : 'accessing' }
MirrorCellRenderer class >> modelClass [
	^ MirrorCell
]

{ #category : 'drawing' }
MirrorCellRenderer >> addMirrorFrom: aPoint to: anotherPoint on: anElement [
	"Add the mirror to anElement as a child carrying a line geometry. The child covers the whole
	cell, so both points are cell local, and the stroke is centered on the line so that the
	mirror is as thick on one side of it as on the other."

	| mirror |
	mirror := BlElement new.
	mirror extent: self class cellExtent.
	mirror geometry: (BlLineGeometry from: aPoint to: anotherPoint).
	mirror outskirts: BlOutskirts centered.
	mirror border: (BlBorder
			 paint: LaserGameColors mirrorColor
			 width: self class mirrorWidth).
	anElement addChild: mirror
]

{ #category : 'drawing' }
MirrorCellRenderer >> cornerInset [
	^8@8
]

{ #category : 'interaction' }
MirrorCellRenderer >> hintColorAt: aPoint [
	"Answer the colour of the hint arrow at aPoint, in the coordinates of my cell: page 130 wants
	the arrow to say whether the move it offers could actually be made. The region the point
	falls in knows — the outside region always allows a turn, and the inside region asks the
	push region whether the cell beside mine would let my cell through."

	^ ((CellClickRegion clickRegionForPoint: aPoint)
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [ LaserGameColors allowActionArrowColor ]
		  ifFalse: [ LaserGameColors denyActionArrowColor ]
]

{ #category : 'interaction' }
MirrorCellRenderer >> hintRegionAt: aPoint [
	"Answer the region whose hint applies at aPoint: a mirror reacts to a click, and which of its
	actions is meant depends on where in the cell the pointer is. The region that contains the
	point has the last word, so a point near the middle answers one of the four push regions.
	The original had to subtract the offset of my cell within the board form before it could ask
	this."

	^ (CellClickRegion clickRegionForPoint: aPoint) hintRegionForPoint: aPoint
]

{ #category : 'drawing' }
MirrorCellRenderer >> maskForNorthEast [
	| mask pen line cellPosn |
	mask := Form extent: CellRenderer cellExtent depth: 1.
	mask fillColor: Color white.
	pen := Form extent: 1@1 depth: 1.
	pen fillColor: Color black.
	line := Line
			from: 0@0
			to: mask extent
			withForm: pen.
	line displayOn: mask.
	mask floodFill: Color black at: 5@1.
	cellPosn := self offsetWithinGridForm.
	mask
		displayOn: self targetForm
		at: cellPosn
		clippingBox: self targetForm boundingBox
		rule: Form oldPaint
		fillColor: LaserGameColors gameBoardBackgroundColor.
	self renderBorderTop.
	self renderBorderRight
]

{ #category : 'drawing' }
MirrorCellRenderer >> maskForNorthWest [
	| mask pen line cellPosn |
	mask := Form extent: CellRenderer cellExtent depth: 1.
	mask fillColor: Color white.
	pen := Form extent: 1@1 depth: 1.
	pen fillColor: Color black.
	line := Line
			from: (mask width)@0
			to: 0@(mask height)
			withForm: pen.
	line displayOn: mask.
	mask floodFill: Color black at: 5@5.
	cellPosn := self offsetWithinGridForm.
	mask
		displayOn: self targetForm
		at: cellPosn
		clippingBox: self targetForm boundingBox
		rule: Form oldPaint
		fillColor: LaserGameColors gameBoardBackgroundColor.
	self renderBorderTop.
	self renderBorderLeft
]

{ #category : 'drawing' }
MirrorCellRenderer >> maskForSouthEast [
	| mask pen line cellPosn |
	mask := Form extent: CellRenderer cellExtent depth: 1.
	mask fillColor: Color white.
	pen := Form extent: 1@1 depth: 1.
	pen fillColor: Color black.
	line := Line
			from: (mask width)@0
			to: 0@(mask height)
			withForm: pen.
	line displayOn: mask.
	mask floodFill: Color black at: (mask width - 5)@(mask height - 5).
	cellPosn := self offsetWithinGridForm.
	mask
		displayOn: self targetForm
		at: cellPosn
		clippingBox: self targetForm boundingBox
		rule: Form oldPaint
		fillColor: LaserGameColors gameBoardBackgroundColor.
	self renderBorderBottom.
	self renderBorderRight
]

{ #category : 'drawing' }
MirrorCellRenderer >> maskForSouthWest [
	| mask pen line cellPosn |
	mask := Form extent: CellRenderer cellExtent depth: 1.
	mask fillColor: Color white.
	pen := Form extent: 1@1 depth: 1.
	pen fillColor: Color black.
	line := Line
			from: 0@0
			to: mask extent
			withForm: pen.
	line displayOn: mask.
	mask floodFill: Color black at: 1@5.
	cellPosn := self offsetWithinGridForm.
	mask
		displayOn: self targetForm
		at: cellPosn
		clippingBox: self targetForm boundingBox
		rule: Form oldPaint
		fillColor: LaserGameColors gameBoardBackgroundColor.
	self renderBorderBottom.
	self renderBorderLeft
]

{ #category : 'drawing' }
MirrorCellRenderer >> maskOffHorizontalOn: aMask [
	^aMask
]

{ #category : 'drawing' }
MirrorCellRenderer >> maskOffVerticalOn: aMask [
	^aMask
]

{ #category : 'interaction' }
MirrorCellRenderer >> mouseUpAt: aPoint [
	"Act on a click at aPoint, in the coordinates of my cell, and answer the cell it acted on, or
	nil when the region aPoint falls in can do nothing. The region decides both questions: the
	outside region turns my mirror one way or the other, the inside region pushes it when there
	is room, and the ignore margin does nothing. Page 114 of the original passes the cell and the
	grid down to the region for exactly this reason: a region knows what a click means, and
	nothing else does."

	| region |
	region := CellClickRegion clickRegionForPoint: aPoint.
	^ (region
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [
		  region
			  mouseUpWithinCellAtPoint: aPoint
			  cell: self cell
			  withinGrid: self grid ]
		  ifFalse: [ nil ]
]

{ #category : 'drawing' }
MirrorCellRenderer >> removeLaserFromInactiveLeftSide [
	(self cell activeSegments at: #west) ifFalse: [self maskForSouthWest].
	(self cell activeSegments at: #east) ifFalse: [self maskForNorthEast].
	
]

{ #category : 'drawing' }
MirrorCellRenderer >> removeLaserFromInactiveRightSide [
	(self cell activeSegments at: #west) ifFalse: [self maskForNorthWest].
	(self cell activeSegments at: #east) ifFalse: [self maskForSouthEast].
	
]

{ #category : 'drawing' }
MirrorCellRenderer >> removeLaserFromInactiveSide [
	self cell isLeft
		ifTrue: [self removeLaserFromInactiveLeftSide]
		ifFalse: [self removeLaserFromInactiveRightSide]
]

{ #category : 'drawing' }
MirrorCellRenderer >> renderContentsLeanLeftOn: anElement [
	"Draw the mirror from the top left corner of the cell to the bottom right one, inset from
	both."

	| inset delta |
	inset := self cornerInset.
	delta := self class cellExtent - 1.
	self
		addMirrorFrom: inset
		to: delta - inset
		on: anElement
]

{ #category : 'drawing' }
MirrorCellRenderer >> renderContentsLeanRightOn: anElement [
	"Draw the mirror from the top right corner of the cell to the bottom left one, inset from
	both."

	| inset delta |
	inset := self cornerInset.
	delta := self class cellExtent - 1.
	self
		addMirrorFrom: delta x - inset x @ inset y
		to: inset x @ (delta y - inset y)
		on: anElement
]

{ #category : 'rendering' }
MirrorCellRenderer >> renderContentsOn: anElement [
	"A mirror is one diagonal, leaning the way my cell leans."

	self cell isLeft
		ifTrue: [ self renderContentsLeanLeftOn: anElement ]
		ifFalse: [ self renderContentsLeanRightOn: anElement ]
]

{ #category : 'drawing' }
MirrorCellRenderer >> renderLaser [
	self cell isOff ifTrue: [^self].
	self renderLaserVertical.
	self renderLaserHorizontal.
	self renderLaserVerticalCenter.
	self removeLaserFromInactiveSide.
	self renderMirror.

]
