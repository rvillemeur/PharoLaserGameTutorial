Class {
	#name : #CellRenderer,
	#superclass : #Object,
	#instVars : [
		'cellLocation',
		'grid',
		'targetForm'
	],
	#category : #'Laser-Game-Graphics'
}

{ #category : #constants }
CellRenderer class >> cellExtent [
	^50@50
]

{ #category : #constants }
CellRenderer class >> ignoreRegionOffset [
	^4
]

{ #category : #constants }
CellRenderer class >> insideRegionExtent [
	^self cellExtent - 20
]

{ #category : #constants }
CellRenderer class >> outsideRegionExtent [
	^self cellExtent - (2 * self ignoreRegionOffset)
]

{ #category : #rendering }
CellRenderer class >> renderBorderTop [ 
|line delta offset x1 x2 y1 y2|
delta := CellRenderer cellExtent.
offset := self offsetWithinGridForm.
x1 := offset x.
x2 := x1 + delta x.
y1 := offset y.
y2 := y1.
line := Line from: x1@y1 to: x2@y2 withForm: (Form extent: 1@1 depth: 8) fillBlack.
line displayOn: self targetForm.
]

{ #category : #'as yet unclassified' }
CellRenderer class >> rendererFor: aCell [
	^self subclasses detect: [:cls | cls modelClass = aCell class]
]

{ #category : #'as yet unclassified' }
CellRenderer class >> rendererFor: aCell grid: aGrid form: aForm [
	| cls model |
	cls := self rendererFor: aCell.
	model := cls new.
	model
		cellLocation: aCell gridLocation;
		grid: aGrid;
		targetForm: aForm.
	^model
]

{ #category : #drawing }
CellRenderer >> backgroundRectangle [
	| offset |
	offset := self offsetWithinGridForm + 1.
	^offset extent: CellRenderer cellExtent - 2
]

{ #category : #accessing }
CellRenderer >> cell [
	^self grid at: self cellLocation.

]

{ #category : #accessing }
CellRenderer >> cellLocation [
	"Answer the value of cellLocation"

	^ cellLocation
]

{ #category : #accessing }
CellRenderer >> cellLocation: anObject [
	"Set the value of cellLocation"

	cellLocation := anObject
]

{ #category : #drawing }
CellRenderer >> fillBackground [
	| backgroundRect |
	backgroundRect := self backgroundRectangle.
	self targetForm fill: backgroundRect fillColor: LaserGameColors gameBoardBackgroundColor.

]

{ #category : #accessing }
CellRenderer >> grid [
	"Answer the value of grid"

	^ grid
]

{ #category : #accessing }
CellRenderer >> grid: anObject [
	"Set the value of grid"

	grid := anObject
]

{ #category : #drawing }
CellRenderer >> mouseUpWithinBoardOffset: aPoint [ 
	^self cell
]

{ #category : #accessing }
CellRenderer >> offsetWithinGridForm [
	| delta xCount yCount offset |
	delta := CellRenderer cellExtent.
	xCount := (self cellLocation x) - 1.
	yCount := (self cellLocation y) - 1.
	offset := delta * (xCount@yCount).
	^offset
]

{ #category : #drawing }
CellRenderer >> redrawCell [
	self fillBackground.
	self render

]

{ #category : #drawing }
CellRenderer >> render [
	self
		renderBorder;
		renderContents.
	self grid laserIsActive ifTrue: [self renderLaser]
]

{ #category : #drawing }
CellRenderer >> renderBorder [
	self
		renderBorderTop;
		renderBorderRight;
		renderBorderBottom;
		renderBorderLeft
]

{ #category : #drawing }
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

{ #category : #drawing }
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

{ #category : #drawing }
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

{ #category : #drawing }
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

{ #category : #drawing }
CellRenderer >> renderContents [
]

{ #category : #drawing }
CellRenderer >> renderLaser [
]

{ #category : #drawing }
CellRenderer >> renderLaserHorizontal [
	self renderLaserHorizontalSplatter.
	self renderLaserHorizontalCenter.
	
]

{ #category : #drawing }
CellRenderer >> renderLaserHorizontalCenter [
	self
		renderLaserHorizontalMask: LaserGameForms centerBeamMask 
		color: LaserGameColors laserBeamCenterColor
]

{ #category : #drawing }
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

{ #category : #drawing }
CellRenderer >> renderLaserHorizontalSplatter [
	self
		renderLaserHorizontalMask: LaserGameForms splatterBeamMask 
		color: LaserGameColors laserBeamSplatterColor
]

{ #category : #drawing }
CellRenderer >> renderLaserVertical [
	self renderLaserVerticalSplatter.
	self renderLaserVerticalCenter.
	
]

{ #category : #drawing }
CellRenderer >> renderLaserVerticalCenter [
	self
		renderLaserVerticalMask: LaserGameForms centerBeamMask 
		color: LaserGameColors laserBeamCenterColor
]

{ #category : #drawing }
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

{ #category : #drawing }
CellRenderer >> renderLaserVerticalSplatter [
	self
		renderLaserVerticalMask: LaserGameForms splatterBeamMask 
		color: LaserGameColors laserBeamSplatterColor
]

{ #category : #drawing }
CellRenderer >> showPositionHintFromWithinBoardOffset: aPoint [ 
]

{ #category : #accessing }
CellRenderer >> targetForm [
	"Answer the value of targetForm"

	^ targetForm
]

{ #category : #accessing }
CellRenderer >> targetForm: anObject [
	"Set the value of targetForm"

	targetForm := anObject
]
