Class {
	#name : #TargetCellRenderer,
	#superclass : #CellRenderer,
	#category : #'Laser-Game-Graphics'
}

{ #category : #accessing }
TargetCellRenderer class >> modelClass [

	^ TargetCell 
]

{ #category : #'as yet unclassified' }
TargetCellRenderer >> drawCircleOutline [

	| delta offset fillForm circle |
	delta := CellRenderer cellExtent - 1.
	offset := self offsetWithinGridForm.
	circle := Circle new.
	fillForm := Form extent: 2 @ 2 depth: 8.
	fillForm fillColor: LaserGameColors targetCenterColor.
	circle form: fillForm.
	circle radius: 7.
	circle center: offset + (delta // 2).
	circle displayOn: self targetForm
]

{ #category : #'as yet unclassified' }
TargetCellRenderer >> drawCrossHairsOutlines [

	| inset delta offset x1 x2 y1 y2 fillForm line |
	inset := 6 @ 6.
	delta := CellRenderer cellExtent - 1.
	offset := self offsetWithinGridForm.
	x1 := offset x + inset x.
	x2 := offset x + delta x - inset x.
	y1 := offset y + (delta y // 2).
	y2 := y1.
	fillForm := Form extent: 2 @ 2 depth: 8.
	fillForm fillColor: LaserGameColors targetCenterColor.
	line := Line from: x1 @ y1 to: x2 @ y2 withForm: fillForm.
	line displayOn: self targetForm.
	x1 := offset x + (delta x // 2).
	x2 := x1.
	y1 := offset y + inset x.
	y2 := offset y + delta y - inset y.
	fillForm := Form extent: 2 @ 2 depth: 8.
	fillForm fillColor: LaserGameColors targetCenterColor.
	line := Line from: x1 @ y1 to: x2 @ y2 withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #'as yet unclassified' }
TargetCellRenderer >> drawTargetOutlines [

	self drawCrossHairsOutlines.
	self drawCircleOutline
]

{ #category : #'as yet unclassified' }
TargetCellRenderer >> renderContents [

	| cell |
	cell := self grid at: self cellLocation.
	self drawTargetOutlines.
	cell isOn
		ifTrue: [ self renderContentsOn ]
		ifFalse: [ self renderContentsOff ]
]

{ #category : #'as yet unclassified' }
TargetCellRenderer >> renderContentsOff [

	self renderInnerCircleColor: LaserGameColors targetCenterColorIdle
]

{ #category : #'as yet unclassified' }
TargetCellRenderer >> renderContentsOn [

	self renderInnerCircleColor: LaserGameColors targetCenterColorActive
]

{ #category : #'as yet unclassified' }
TargetCellRenderer >> renderInnerCircleColor: aColor [

	| circle fillForm offset delta |
	delta := CellRenderer cellExtent - 1.
	offset := self offsetWithinGridForm.
	circle := Circle new.
	fillForm := Form extent: 4 @ 4 depth: 8.
	fillForm fillColor: aColor.
	circle form: fillForm.
	circle radius: 3.
	circle center: offset + (delta // 2) - 1.
	circle displayOn: self targetForm
]
