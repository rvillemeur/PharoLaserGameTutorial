Class {
	#name : #MirrorCellRenderer,
	#superclass : #CellRenderer,
	#category : #'Laser-Game-Graphics'
}

{ #category : #accessing }
MirrorCellRenderer class >> modelClass [

	^ MirrorCell 
]

{ #category : #rendering }
MirrorCellRenderer >> cornerInset [

	^ 8 @ 8
]

{ #category : #'as yet unclassified' }
MirrorCellRenderer >> redrawCell [

	| offset backgroundRect |
	offset := self offsetWithinGridForm.
	backgroundRect := offset extent: CellRenderer cellExtent - 2.
	self targetForm
		fill: backgroundRect
		fillColor: LaserGameColors gameBoardBackgroundColor.
	self render
]

{ #category : #rendering }
MirrorCellRenderer >> renderContents [

	| cell |
	cell := self grid at: self cellLocation.
	cell isLeft
		ifTrue: [ self renderContentsLeanLeft ]
		ifFalse: [ self renderContentsLeanRight ]
]

{ #category : #rendering }
MirrorCellRenderer >> renderContentsLeanLeft [

	| offset delta x1 x2 y1 y2 line fillForm|
	offset := self offsetWithinGridForm.
	delta := CellRenderer cellExtent - 1.
	x1 := offset x + self cornerInset x.
	x2 := offset x + delta x - self cornerInset x.
	y1 := offset y + self cornerInset y.
	y2 := offset y + delta y - self cornerInset y.
	fillForm := Form extent: 2@2 depth: 8.
	fillForm fillColor: LaserGameColors mirrorColor .
	line := Line
		        from: x1 @ y1
		        to: x2 @ y2
		        withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #rendering }
MirrorCellRenderer >> renderContentsLeanRight [

	| offset delta x1 x2 y1 y2 line fillForm|
	offset := self offsetWithinGridForm.
	delta := CellRenderer cellExtent - 1.
	x1 := offset x + delta x -  self cornerInset x.
	x2 := offset x + self cornerInset x.
	y1 := offset y + self cornerInset y.
	y2 := offset y + delta y - self cornerInset y.
	fillForm := Form extent: 2@2 depth: 8.
	fillForm fillColor: LaserGameColors mirrorColor .
	line := Line
		        from: x1 @ y1
		        to: x2 @ y2
		        withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #'as yet unclassified' }
MirrorCellRenderer >> showPositionHintFromWithinBoardOffset: aPoint [

	| cellPosn offsetWithinCell regionClass pushRegionClass arrow tinyArrow offset |
	self redrawCell.
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell.
	pushRegionClass := regionClass showPositionHintFromWithinCell:
		                   offsetWithinCell.
	pushRegionClass isNil ifTrue: [ ^ self ].
	arrow := pushRegionClass arrowForm.
	tinyArrow := arrow scaledToSize: CellRenderer cellExtent - 2.
	offset := self offsetWithinGridForm + 5.
	tinyArrow
		displayOn: self targetForm
		at: offset
		clippingBox: self targetForm computeBoundingBox 
		rule: Form oldPaint
		fillColor: Color gray
]
