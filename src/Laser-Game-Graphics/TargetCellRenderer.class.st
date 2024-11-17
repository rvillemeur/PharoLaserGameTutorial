Class {
	#name : #TargetCellRenderer,
	#superclass : #CellRenderer,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
TargetCellRenderer class >> modelClass [
	^TargetCell
]

{ #category : #drawing }
TargetCellRenderer >> drawCircleOutline [
	self drawCircleOutlineOn: self targetForm color: LaserGameColors targetCenterColor
]

{ #category : #drawing }
TargetCellRenderer >> drawCircleOutlineOn: aForm color: aColor [
	| offset |
	offset := self offsetWithinGridForm.
	self drawCircleOutlineOn: aForm color: aColor offset: offset
]

{ #category : #drawing }
TargetCellRenderer >> drawCircleOutlineOn: aForm color: aColor offset: offset [
	| delta fillForm circle |
	delta := self class cellExtent - 1.
	circle := Circle new.
	fillForm := Form extent: 2@2 depth: 8.
	fillForm fillColor: aColor.
	circle form: fillForm.
	circle radius: self radius.
	circle center: (offset + (delta // 2)).
	circle displayOn: aForm
]

{ #category : #drawing }
TargetCellRenderer >> drawCrossHairsOutlines [
	| inset delta offset x1 x2 y1 y2 fillForm line |
	inset := 6@6.
	delta := CellRenderer cellExtent - 1.
	offset := self offsetWithinGridForm.
	x1 := offset x + inset x.
	x2 := offset x + delta x - inset x.
	y1 := offset y + (delta y // 2).
	y2 := y1.
	fillForm := Form extent: 2@2 depth: 8.
	fillForm fillColor: LaserGameColors targetCenterColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm.
	x1 := offset x + (delta x // 2).
	x2 := x1.
	y1 := offset y + inset y.
	y2 := offset y + delta y - inset y.
	fillForm := Form extent: 2@2 depth: 8.
	fillForm fillColor: LaserGameColors targetCenterColor.
	line := Line
			from: x1@y1 
			to: x2@y2
			withForm: fillForm.
	line displayOn: self targetForm.

]

{ #category : #drawing }
TargetCellRenderer >> drawTargetOutlines [
	self drawCrossHairsOutlines.
	self drawCircleOutline
]

{ #category : #drawing }
TargetCellRenderer >> maskOffHorizontalOn: aMask [
	| newMask halfExtent halfRect offset |
	halfExtent := (aMask width // 2)@(aMask height).
	newMask := Form extent: aMask extent depth: aMask depth.
	newMask fillColor: Color white.
	(self cell activeSegments at: #west)
		ifTrue: [offset := 0]
		ifFalse: [offset := halfExtent x].
	halfRect := (aMask boundingBox origin + (offset@0)) extent: halfExtent.
	aMask
		displayOn: newMask
		at: offset@0
		clippingBox: halfRect
		rule: Form paint
		fillColor: Color black.
	^newMask
]

{ #category : #drawing }
TargetCellRenderer >> maskOffVerticalOn: aMask [
	| newMask halfExtent halfRect offset |
	newMask := Form extent: aMask extent depth: aMask depth.
	newMask fillColor: Color white.
	halfExtent := (aMask width)@(aMask height // 2).
	(self cell activeSegments at: #south)
		ifTrue: [offset := halfExtent y]
		ifFalse: [offset := 0].
	halfRect := (0@offset) extent: halfExtent.
	aMask
		displayOn: newMask
		at: 0@0
		clippingBox: halfRect
		rule: Form paint
		fillColor: Color black.
	^newMask
]

{ #category : #drawing }
TargetCellRenderer >> radius [
	^(self class cellExtent x // 2 - 8) min: 10
]

{ #category : #drawing }
TargetCellRenderer >> renderContents [
	self fillBackground.
	self drawTargetOutlines.
	self cell isOn
		ifTrue: [self renderContentsOn]
		ifFalse: [self renderContentsOff]
]

{ #category : #drawing }
TargetCellRenderer >> renderContentsOff [
	self renderInnerCircleColor: LaserGameColors targetCenterColorIdle.

]

{ #category : #drawing }
TargetCellRenderer >> renderContentsOn [
	self renderInnerCircleColor: LaserGameColors targetCenterColorActive.

]

{ #category : #drawing }
TargetCellRenderer >> renderInnerCircleColor: aColor [
	| circle fillForm offset delta |
	delta := CellRenderer cellExtent - 1.
	offset := self offsetWithinGridForm.
	circle := Circle new.
	fillForm := Form extent: 4@4 depth: 8.
	fillForm fillColor: aColor.
	circle form: fillForm.
	circle radius: self radius - 4.
	circle center: (offset + (delta // 2) - 1).
	circle displayOn: self targetForm.
]

{ #category : #drawing }
TargetCellRenderer >> renderLaser [
	| horizontal |
	self cell isOff ifTrue: [^self].
	horizontal := (self cell activeSegments at: #east) or: [self cell activeSegments at: #west].
	horizontal
		ifTrue: [self renderLaserHorizontal]
		ifFalse: [self renderLaserVertical].
	self drawTargetOutlines.
	self renderContentsOn.
	
]
