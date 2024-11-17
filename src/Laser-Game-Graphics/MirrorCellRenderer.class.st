Class {
	#name : #MirrorCellRenderer,
	#superclass : #CellRenderer,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
MirrorCellRenderer class >> modelClass [
	^MirrorCell
]

{ #category : #drawing }
MirrorCellRenderer >> cornerInset [
	^8@8
]

{ #category : #drawing }
MirrorCellRenderer >> hintArrowColorFor: regionClass offset: offsetWithinCell [
	| permissionToActOnCell arrowColor |
	permissionToActOnCell := regionClass
								canActOnCellAtPoint: offsetWithinCell 
								cell: self cell 
								withinGrid: self grid.
	arrowColor := permissionToActOnCell
		ifTrue: [LaserGameColors allowActionArrowColor]
		ifFalse: [LaserGameColors denyActionArrowColor].
	^arrowColor
]

{ #category : #drawing }
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

{ #category : #drawing }
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

{ #category : #drawing }
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

{ #category : #drawing }
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

{ #category : #drawing }
MirrorCellRenderer >> maskOffHorizontalOn: aMask [
	^aMask
]

{ #category : #drawing }
MirrorCellRenderer >> maskOffVerticalOn: aMask [
	^aMask
]

{ #category : #drawing }
MirrorCellRenderer >> mouseUpWithinBoardOffset: aPoint [
	| cellPosn offsetWithinCell regionClass |
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell. 
	^regionClass mouseUpWithinCellAtPoint: offsetWithinCell cell: self cell withinGrid: self grid.

]

{ #category : #drawing }
MirrorCellRenderer >> redrawCell [

	| offset backgroundRect |
	offset := self offsetWithinGridForm.
	backgroundRect := offset extent: CellRenderer cellExtent - 2.
	self targetForm
		fill: backgroundRect
		fillColor: LaserGameColors gameBoardBackgroundColor.
	self render
]

{ #category : #drawing }
MirrorCellRenderer >> removeLaserFromInactiveLeftSide [
	(self cell activeSegments at: #west) ifFalse: [self maskForSouthWest].
	(self cell activeSegments at: #east) ifFalse: [self maskForNorthEast].
	
]

{ #category : #drawing }
MirrorCellRenderer >> removeLaserFromInactiveRightSide [
	(self cell activeSegments at: #west) ifFalse: [self maskForNorthWest].
	(self cell activeSegments at: #east) ifFalse: [self maskForSouthEast].
	
]

{ #category : #drawing }
MirrorCellRenderer >> removeLaserFromInactiveSide [
	self cell isLeft
		ifTrue: [self removeLaserFromInactiveLeftSide]
		ifFalse: [self removeLaserFromInactiveRightSide]
]

{ #category : #drawing }
MirrorCellRenderer >> renderContents [
	self fillBackground.
	self renderMirror
]

{ #category : #drawing }
MirrorCellRenderer >> renderContentsLeanLeft [
	| offset delta x1 x2 y1 y2 line fillForm |
	offset := self offsetWithinGridForm.
	delta := CellRenderer cellExtent - 1.
	x1 := offset x + (self cornerInset x).
	x2 := offset x + delta x - (self cornerInset x).
	y1 := offset y + (self cornerInset y).
	y2 := offset y + delta y - (self cornerInset y).
	fillForm := Form extent: 2@2 depth: 8.
	fillForm fillColor: LaserGameColors mirrorColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #drawing }
MirrorCellRenderer >> renderContentsLeanRight [
	| offset delta x1 x2 y1 y2 line fillForm |
	offset := self offsetWithinGridForm.
	delta := CellRenderer cellExtent - 1.
	x1 := offset x + delta x - self cornerInset x.
	x2 := offset x + self cornerInset x.
	y1 := offset y + (self cornerInset y).
	y2 := offset y + delta y - (self cornerInset y).
	fillForm := Form extent: 2@2 depth: 8.
	fillForm fillColor: LaserGameColors mirrorColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #drawing }
MirrorCellRenderer >> renderLaser [
	self cell isOff ifTrue: [^self].
	self renderLaserVertical.
	self renderLaserHorizontal.
	self renderLaserVerticalCenter.
	self removeLaserFromInactiveSide.
	self renderMirror.

]

{ #category : #drawing }
MirrorCellRenderer >> renderMirror [
	self cell isLeft
		ifTrue: [self renderContentsLeanLeft]
		ifFalse: [self renderContentsLeanRight]
]

{ #category : #drawing }
MirrorCellRenderer >> showPositionHintFromWithinBoardOffset: aPoint [
	| cellPosn offsetWithinCell regionClass arrowAndOffset |
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell. 
	arrowAndOffset := regionClass scaledHintArrowAndOffsetFromWithinCell: offsetWithinCell.
	arrowAndOffset isNil
		ifTrue: [self currentHand showTemporaryCursor: nil]
		ifFalse: [
			| arrowColor arrow offset |
			arrowColor := self hintArrowColorFor: regionClass offset: offsetWithinCell.
			arrow := arrowAndOffset value.
			offset := arrowAndOffset key.
			offset := self offsetWithinGridForm + offset.
			arrow
				displayOn: self targetForm
				at: offset
				clippingBox: self backgroundRectangle
				rule: Form oldPaint
				fillColor: arrowColor.
			self currentHand
				showTemporaryCursor: LaserGameForms crossHair
				hotSpotOffset: (LaserGameForms crossHair extent // 2)]
]
