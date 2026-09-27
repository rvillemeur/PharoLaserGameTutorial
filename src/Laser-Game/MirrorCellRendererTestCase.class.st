Class {
	#name : 'MirrorCellRendererTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'running' }
MirrorCellRendererTestCase >> mirrorElementLeaning: aSymbol [
	"Answer the mirror child of the element rendered for a mirror cell leaning aSymbol."

	^ (self rendererLeaning: aSymbol) newElement children first
]

{ #category : 'running' }
MirrorCellRendererTestCase >> rendererLeaning: aSymbol [
	"Answer a mirror renderer for a mirror cell leaning aSymbol, #left or #right, sitting at 1@1
	of a fresh grid."

	| grid cell |
	grid := Grid new.
	cell := MirrorCell new.
	aSymbol = #left
		ifTrue: [ cell leanLeft ]
		ifFalse: [ cell leanRight ].
	grid at: 1 @ 1 put: cell.
	^ CellRenderer rendererFor: cell grid: grid
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testLeanLeftMirrorRunsFromTopLeftToBottomRight [
	"A left leaning mirror goes down and to the right, inset from both corners it points at."

	| renderer mirror inset delta |
	renderer := self rendererLeaning: #left.
	mirror := renderer newElement children first.
	inset := renderer cornerInset.
	delta := MirrorCellRenderer cellExtent - 1.
	self assert: mirror geometry class equals: BlLineGeometry.
	self assert: mirror geometry from equals: inset.
	self assert: mirror geometry to equals: delta - inset
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testLeanRightMirrorRunsFromTopRightToBottomLeft [
	"A right leaning mirror goes down and to the left, inset from both corners it points at."

	| renderer mirror inset delta |
	renderer := self rendererLeaning: #right.
	mirror := renderer newElement children first.
	inset := renderer cornerInset.
	delta := MirrorCellRenderer cellExtent - 1.
	self assert: mirror geometry class equals: BlLineGeometry.
	self assert: mirror geometry from equals: delta x - inset x @ inset y.
	self assert: mirror geometry to equals: inset x @ (delta y - inset y)
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testMirrorCellHoldsOneMirror [
	"A mirror cell draws one diagonal, whichever way it leans."

	self assert: (self rendererLeaning: #left) newElement children size equals: 1.
	self assert: (self rendererLeaning: #right) newElement children size equals: 1
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testMirrorCoversTheWholeCell [
	"The child carrying the line is the size of the cell, so both ends of the diagonal are cell
	local coordinates."

	| mirror |
	mirror := self mirrorElementLeaning: #right.
	self
		assert: mirror constraints horizontal resizer size
		equals: MirrorCellRenderer cellExtent x.
	self
		assert: mirror constraints vertical resizer size
		equals: MirrorCellRenderer cellExtent y
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testMirrorIsAStrokeInTheMirrorColor [
	"The diagonal is painted by the border of the child, since a line has no inside to fill. The
	stroke is centered on the line, so the mirror is as thick on one side of it as on the other."

	| mirror |
	mirror := self mirrorElementLeaning: #left.
	self
		assert: mirror border paint color
		equals: LaserGameColors mirrorColor.
	self
		assert: mirror border width
		equals: MirrorCellRenderer mirrorWidth.
	self assert: mirror outskirts equals: BlOutskirts centered
]

{ #category : 'tests' }
MirrorCellRendererTestCase >> testRotatingTheCellTurnsTheMirrorOver [
	"Rendering follows the cell. Rotating a mirror cell and rendering it again draws the other
	diagonal, so the two ends swap corners along the x axis."

	| renderer before after |
	renderer := self rendererLeaning: #left.
	before := renderer newElement children first geometry.
	renderer cell rotate.
	after := renderer newElement children first geometry.
	self assert: after from y equals: before from y.
	self assert: after to y equals: before to y.
	self assert: after from x equals: before to x.
	self assert: after to x equals: before from x
]
