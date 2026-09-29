Class {
	#name : 'CellRendererTestCase',
	#superclass : 'LaserGameTestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'support' }
CellRendererTestCase >> requestedExtentOf: anElement [
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
]

{ #category : 'tests' }
CellRendererTestCase >> testABlankCellCrossedTwiceShowsBothBeams [
	"Page 173 finds the same on a blank cell: the beam can cross its own path there too, and the
	original then draws the vertical beam when north is lit, the horizontal one when west is lit,
	and the vertical core once more so that the crossing looks right. The port asks nothing extra:
	the cell is lit on four sides, so both bands are drawn and both cores go over them."

	| grid cell element beam extent |
	grid := Grid new.
	cell := BlankCell new.
	grid at: 1 @ 1 put: cell.
	cell laserEntersFrom: #west.
	cell laserEntersFrom: #north.
	grid laserIsActive: true.
	extent := CellRenderer cellExtent.
	element := (CellRenderer rendererFor: cell grid: grid) newElement.
	beam := element children first.
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	self
		assert: beam children last background paint color
		equals: LaserGameColors laserBeamCenterColor
]

{ #category : 'tests' }
CellRendererTestCase >> testABlankCellDrawsNoBeamUnlessTheLaserReachesIt [
	"A cell draws a beam only while the laser is firing and only where the beam runs. The original
	asks the first question in #render and the second at the head of #renderLaser."

	| grid |
	grid := GridFactory demoGrid.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children.
	grid fireLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid) newElement
				children.
	grid stopLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children
]

{ #category : 'tests' }
CellRendererTestCase >> testBlankCellElement [
	"A blank cell is a square of the board background with a border and nothing inside.
	The element is checked before any layout pass, so the size is read from the layout
	constraints rather than from the extent, which stays zero until the element is laid out."

	| grid element |
	grid := Grid new.
	element := (CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
		           newElement.
	self
		assert: element constraints horizontal resizer size
		equals: CellRenderer cellExtent x.
	self
		assert: element constraints vertical resizer size
		equals: CellRenderer cellExtent y.
	self assert: element geometry class equals: BlRectangleGeometry.
	self
		assert: element background paint color
		equals: LaserGameColors gameBoardBackgroundColor.
	self assert: element border width equals: CellRenderer borderWidth.
	self
		assert: element border paint color
		equals: LaserGameColors cellBorderColor.
	"A blank cell draws nothing inside its border."
	self assertEmpty: element children
]

{ #category : 'tests' }
CellRendererTestCase >> testEveryCellClassHasExactlyOneRenderer [

	Cell allSubclasses do: [ :cellClass |
		| renderers |
		renderers := CellRenderer allSubclasses select: [ :each |
			             each modelClass = cellClass ].
		self
			assert: renderers size = 1
			description: cellClass name , ' must have exactly one renderer, found '
				, renderers size printString ]
]

{ #category : 'tests' }
CellRendererTestCase >> testEverySizeInACellFollowsTheCellSize [
	"Page 137 of the original raises the cell size, and page 138 then finds the sizes that do not
	follow: the inside region, the line between the two rotate regions and one of the two
	diagonals. The port derives all of them from the cell size already, so this section proves
	that rather than changing it. At any cell size the two nested regions stay centred in the
	cell, every point of the cell still falls in a region, the four push regions still divide the
	inside square between them without overlapping, the ring of a target still fits in the cell,
	and a board is still the grid times the cell."

	| grid |
	grid := GridFactory demoGrid.
	#( 30 40 80 ) do: [ :side |
		self withCellExtent: side @ side do: [
			| cell inside outside middle renderer |
			cell := 0 @ 0 extent: side @ side.
			inside := CellClickRegionInside regionRectangle.
			outside := CellClickRegionOutside regionRectangle.
			self assert: inside extent equals: CellRenderer insideRegionExtent.
			self assert: outside extent equals: CellRenderer outsideRegionExtent.
			self assert: inside center equals: cell center.
			self assert: outside center equals: cell center.

			middle := side // 2.
			self assert: (CellClickRegionRotateClockwise containsPoint: 0 @ middle).
			self deny: (CellClickRegionRotateClockwise containsPoint: 0 @ (middle + 1)).
			self assert:
				(CellClickRegionRotateCounterClockwise containsPoint: 0 @ (middle + 1)).

			0 to: side - 1 do: [ :x |
				0 to: side - 1 do: [ :y |
					self assert: (CellClickRegion clickRegionForPoint: x @ y) notNil ] ].
			inside left to: inside right do: [ :x |
				inside top to: inside bottom do: [ :y |
					self
						assert: (CellClickRegionInside subclasses count: [ :each |
								 each containsPoint: x @ y ])
						equals: 1 ] ].

			renderer := CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid.
			self assert: renderer radius > 0.
			self assert: renderer innerRadius > 0.
			self assert: renderer radius * 2 <= side.

			self
				assert: (LaserGameBoardElement extentForGrid: grid)
				equals: side * grid numberOfColumns @ (side * grid numberOfRows) ] ]
]

{ #category : 'tests' }
CellRendererTestCase >> testOnlyAMirrorAnswersAHintRegion [
	"Every renderer is asked for a hint region, and all but the mirror answer nothing. That is
	the polymorphism the original page points at: the message goes to every cell renderer, and
	each one decides what to do with it. The mirror answers the push region of the point, since
	the middle of a cell is where a push is asked for."

	| grid point |
	grid := GridFactory demoGrid.
	point := CellClickRegionInside regionRectangle center.
	self
		assert: ((CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
				 hintRegionAt: point) isNil.
	self
		assert: ((CellRenderer rendererFor: (grid at: 4 @ 1) grid: grid)
				 hintRegionAt: point)
		equals: CellClickRegionPushNorth
]

{ #category : 'tests' }
CellRendererTestCase >> testRendererForUnsupportedModelIsAnError [

	self should: [ CellRenderer rendererFor: 42 ] raise: Error
]

{ #category : 'tests' }
CellRendererTestCase >> testRendererSelection [

	| renderer cell |
	cell := BlankCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: BlankCellRenderer.


	cell := MirrorCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: MirrorCellRenderer.

	cell := TargetCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: TargetCellRenderer
]

{ #category : 'tests' }
CellRendererTestCase >> testTheBeamCrossesABlankCellFromSideToSide [
	"Page 156 draws the beam on the blank cells, which is the easiest case: the beam goes straight
	through, so it is one line. The demo grid sends the beam along the bottom row from west to
	east, and the blank cell at 2@5 is one the beam crosses that way."

	| grid element beam |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: CellRenderer cellExtent x
			@ (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent).
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
]

{ #category : 'tests' }
CellRendererTestCase >> testTheBeamCrossesABlankCellFromTopToBottom [
	"Page 157 asks one question to choose between the two drawings: is the south segment lit. The
	demo grid turns the beam north at 4@5, so the blank cell at 4@4 is crossed from top to bottom."

	| grid element beam |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 4) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent)
			@ CellRenderer cellExtent y.
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
]
