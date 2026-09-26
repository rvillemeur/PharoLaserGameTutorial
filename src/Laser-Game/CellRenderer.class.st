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
		'grid',
		'targetForm'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
CellRenderer class >> cellExtent [
	^50@50
]

{ #category : 'constants' }
CellRenderer class >> ignoreRegionOffset [
	^4
]

{ #category : 'constants' }
CellRenderer class >> insideRegionExtent [
	^self cellExtent - 20
]

{ #category : 'accessing' }
CellRenderer class >> modelClass [
	"Answer the Cell subclass I render. Each concrete renderer answers exactly one."

	^ self subclassResponsibility
]

{ #category : 'constants' }
CellRenderer class >> outsideRegionExtent [
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

{ #category : 'instance creation' }
CellRenderer class >> rendererFor: aCell grid: aGrid form: aForm [
	| renderer |
	renderer := self rendererFor: aCell grid: aGrid.
	renderer targetForm: aForm.
	^ renderer
]

{ #category : 'drawing' }
CellRenderer >> backgroundRectangle [
	| offset |
	offset := self offsetWithinGridForm + 1.
	^offset extent: CellRenderer cellExtent - 2
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

{ #category : 'drawing' }
CellRenderer >> fillBackground [
	| backgroundRect |
	backgroundRect := self backgroundRectangle.
	self targetForm fill: backgroundRect fillColor: LaserGameColors gameBoardBackgroundColor.

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

{ #category : 'drawing' }
CellRenderer >> mouseUpWithinBoardOffset: aPoint [ 
	^self cell
]

{ #category : 'accessing' }
CellRenderer >> offsetWithinGridForm [
	| delta xCount yCount offset |
	delta := CellRenderer cellExtent.
	xCount := (self cellLocation x) - 1.
	yCount := (self cellLocation y) - 1.
	offset := delta * (xCount@yCount).
	^offset
]

{ #category : 'drawing' }
CellRenderer >> redrawCell [
	self fillBackground.
	self render

]

{ #category : 'drawing' }
CellRenderer >> render [
	self
		renderBorder;
		renderContents.
	self grid laserIsActive ifTrue: [self renderLaser]
]

{ #category : 'drawing' }
CellRenderer >> renderBorder [
	self
		renderBorderTop;
		renderBorderRight;
		renderBorderBottom;
		renderBorderLeft
]

{ #category : 'drawing' }
CellRenderer >> renderBorderBottom [
	| line delta offset x1 x2 y1 y2 fillForm |
	delta := CellRenderer cellExtent - 1.
	offset := self offsetWithinGridForm.
	x1 := offset x.
	x2 := x1 + delta x.
	y1 := offset y + delta y.
	y2 := y1.
	fillForm := Form extent: 1@1 depth: 8.
	fillForm fillColor: LaserGameColors cellBorderColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : 'drawing' }
CellRenderer >> renderBorderLeft [
	| line delta offset x1 x2 y1 y2 fillForm |
	delta := CellRenderer cellExtent.
	offset := self offsetWithinGridForm.
	x1 := offset x.
	x2 := x1.
	y1 := offset y.
	y2 := y1 + delta y.
	fillForm := Form extent: 1@1 depth: 8.
	fillForm fillColor: LaserGameColors cellBorderColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : 'drawing' }
CellRenderer >> renderBorderRight [
	| line delta offset x1 x2 y1 y2 fillForm |
	delta := CellRenderer cellExtent - 1.
	offset := self offsetWithinGridForm.
	x1 := offset x + delta x.
	x2 := x1.
	y1 := offset y.
	y2 := y1 + delta y.
	fillForm := Form extent: 1@1 depth: 8.
	fillForm fillColor: LaserGameColors cellBorderColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : 'drawing' }
CellRenderer >> renderBorderTop [
	| line delta offset x1 x2 y1 y2 fillForm |
	delta := CellRenderer cellExtent.
	offset := self offsetWithinGridForm.
	x1 := offset x.
	x2 := x1 + delta x.
	y1 := offset y.
	y2 := y1.
	fillForm := Form extent: 1@1 depth: 8.
	fillForm fillColor: LaserGameColors cellBorderColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : 'drawing' }
CellRenderer >> renderContents [
]

{ #category : 'drawing' }
CellRenderer >> renderLaser [
]

{ #category : 'drawing' }
CellRenderer >> renderLaserHorizontal [
	self renderLaserHorizontalSplatter.
	self renderLaserHorizontalCenter.
	
]

{ #category : 'drawing' }
CellRenderer >> renderLaserHorizontalCenter [
	self
		renderLaserHorizontalMask: LaserGameForms centerBeamMask 
		color: LaserGameColors laserBeamCenterColor
]

{ #category : 'drawing' }
CellRenderer >> renderLaserHorizontalMask: aMaskForm color: aColor [
	| cellPosn scaledBeam scale trimmedBeam offset masked |
	cellPosn := self offsetWithinGridForm.
	scale := CellRenderer cellExtent * 6.
	scaledBeam := aMaskForm scaledToSize: scale.
	trimmedBeam := Form extent: (CellRenderer cellExtent x)@(scaledBeam height) depth: scaledBeam depth.
	scaledBeam
		displayOn: trimmedBeam
		at: 0@0
		clippingBox: trimmedBeam boundingBox
		rule: Form paint
		fillColor: nil.
	offset := 0@(5 + (CellRenderer cellExtent y - trimmedBeam height) // 2).
	masked := self maskOffHorizontalOn: trimmedBeam.
	masked
		displayOn: self targetForm
		at: (cellPosn + offset)
		clippingBox: self targetForm boundingBox
		rule: Form oldPaint
		fillColor: aColor
]

{ #category : 'drawing' }
CellRenderer >> renderLaserHorizontalSplatter [
	self
		renderLaserHorizontalMask: LaserGameForms splatterBeamMask 
		color: LaserGameColors laserBeamSplatterColor
]

{ #category : 'drawing' }
CellRenderer >> renderLaserVertical [
	self renderLaserVerticalSplatter.
	self renderLaserVerticalCenter.
	
]

{ #category : 'drawing' }
CellRenderer >> renderLaserVerticalCenter [
	self
		renderLaserVerticalMask: LaserGameForms centerBeamMask 
		color: LaserGameColors laserBeamCenterColor
]

{ #category : 'drawing' }
CellRenderer >> renderLaserVerticalMask: aMaskForm color: aColor [
	| cellPosn scaledBeam scale trimmedBeam offset rotatedBeam masked |
	cellPosn := self offsetWithinGridForm.
	scale := CellRenderer cellExtent * 6.
	scaledBeam := aMaskForm scaledToSize: scale.
	trimmedBeam := Form extent: (CellRenderer cellExtent x)@(scaledBeam height) depth: scaledBeam depth.
	scaledBeam
		displayOn: trimmedBeam
		at: 0@0
		clippingBox: trimmedBeam boundingBox
		rule: Form paint
		fillColor: nil.
	rotatedBeam := trimmedBeam rotateBy: 90.
	offset := (-3 + (CellRenderer cellExtent x - rotatedBeam width) // 2)@(3 + (CellRenderer cellExtent y // 2) negated).
	masked := self maskOffVerticalOn: rotatedBeam.
	masked
		displayOn: self targetForm
		at: (cellPosn + offset)
		clippingBox: self targetForm boundingBox
		rule: Form oldPaint
		fillColor: aColor
]

{ #category : 'drawing' }
CellRenderer >> renderLaserVerticalSplatter [
	self
		renderLaserVerticalMask: LaserGameForms splatterBeamMask 
		color: LaserGameColors laserBeamSplatterColor
]

{ #category : 'drawing' }
CellRenderer >> showPositionHintFromWithinBoardOffset: aPoint [ 
]

{ #category : 'accessing' }
CellRenderer >> targetForm [
	"Answer the value of targetForm"

	^ targetForm
]

{ #category : 'accessing' }
CellRenderer >> targetForm: anObject [
	"Set the value of targetForm"

	targetForm := anObject
]
