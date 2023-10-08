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

{ #category : #'as yet unclassified' }
CellRenderer class >> cellExtent [

	^ 30 @ 30
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

	^ self subclasses detect: [ :cls | cls modelClass = aCell class ]
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
	^ model
]

{ #category : #accessing }
CellRenderer >> cellLocation [

	^ cellLocation
]

{ #category : #accessing }
CellRenderer >> cellLocation: anObject [

	cellLocation := anObject
]

{ #category : #accessing }
CellRenderer >> grid [

	^ grid
]

{ #category : #accessing }
CellRenderer >> grid: anObject [

	grid := anObject
]

{ #category : #'as yet unclassified' }
CellRenderer >> offsetWithinGridForm [

	| delta xCount yCount offset |
	delta := CellRenderer cellExtent.
	xCount := self cellLocation x - 1.
	yCount := self cellLocation y - 1.
	offset := delta * (xCount @ yCount).
	^ offset
]

{ #category : #rendering }
CellRenderer >> render [

	self
		renderBorder
		renderContents
]

{ #category : #rendering }
CellRenderer >> renderBorder [

	self
		renderBorderTop;
		renderBorderRight;
		renderBorderBottom;
		renderBorderLeft
]

{ #category : #rendering }
CellRenderer >> renderBorderBottom [

	| line delta offset x1 x2 y1 y2 fillForm |
	delta := CellRenderer cellExtent -1.
	offset := self offsetWithinGridForm.
	x1 := offset x.
	x2 := x1 + delta x.
	y1 := offset y + delta y.
	y2 := y1.
	fillForm := Form extent: 1@1 depth: 8.
	fillForm fillColor: LaserGameColors cellBorderColor.
	line := Line
		        from: x1 @ y1
		        to: x2 @ y2
		        withForm: fillForm .
	line displayOn: self targetForm
]

{ #category : #rendering }
CellRenderer >> renderBorderLeft [

	| line delta offset x1 x2 y1 y2 fillForm|
	delta := CellRenderer cellExtent.
	offset := self offsetWithinGridForm.
	x1 := offset x.
	x2 := x1.
	y1 := offset y.
	y2 := y1 + delta y.
	fillForm := Form extent: 1@1 depth: 8.
	fillForm fillColor: LaserGameColors cellBorderColor.
	line := Line
		        from: x1 @ y1
		        to: x2 @ y2
		        withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #rendering }
CellRenderer >> renderBorderRight [

	| line delta offset x1 x2 y1 y2 fillForm|
	delta := CellRenderer cellExtent -1.
	offset := self offsetWithinGridForm.
	x1 := offset x + delta x.
	x2 := x1.
	y1 := offset y.
	y2 := y1 + delta y.
	fillForm := Form extent: 1@1 depth: 8.
	fillForm fillColor: LaserGameColors cellBorderColor.
	line := Line
		        from: x1 @ y1
		        to: x2 @ y2
		        withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #rendering }
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
		        from: x1 @ y1
		        to: x2 @ y2
		        withForm: fillForm.
	line displayOn: self targetForm
]

{ #category : #accessing }
CellRenderer >> targetForm [

	^ targetForm
]

{ #category : #accessing }
CellRenderer >> targetForm: anObject [

	targetForm := anObject
]
