"
I render a BlankCell: a background and a border, and nothing inside.

I am selected for a cell by `CellRenderer class >> rendererFor:`, which matches my modelClass against the class of the cell.
"
Class {
	#name : 'BlankCellRenderer',
	#superclass : 'CellRenderer',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
BlankCellRenderer class >> modelClass [
	^ BlankCell
]

{ #category : 'as yet unclassified' }
BlankCellRenderer >> renderBeamOn: anElement [
	"A beam goes straight through a blank cell, so it is one line: down the cell when the south
	segment is lit, across it otherwise. Page 157 asks the same one question. The original had to
	build the drawing out of two masks, scale them to the cell, trim them, rotate them for the
	vertical case and paint each one onto the board form with its own colour; the shapes of Section
	4.7 hold all of that, so what is left here is the question and one child."

	anElement addChild: ((self cell isSegmentOnFor: #south)
			 ifTrue: [
				 LaserGameShapes verticalLaserBeamElementOfExtent:
					 self class cellExtent ]
			 ifFalse: [
				 LaserGameShapes horizontalLaserBeamElementOfExtent:
					 self class cellExtent ])
]

{ #category : 'drawing' }
BlankCellRenderer >> renderContents [
	self fillBackground

]
