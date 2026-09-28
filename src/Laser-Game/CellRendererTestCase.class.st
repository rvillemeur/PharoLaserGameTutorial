Class {
	#name : 'CellRendererTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

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

{ #category : 'running' }
CellRendererTestCase >> withCellExtent: anExtent do: aBlock [
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Page 137 of the original raises the cell size and then looks by eye for the
	sizes that were written down instead of derived from it; this runs that experiment from the
	test suite."

	| previous |
	previous := CellRenderer class >> #cellExtent.
	[
	CellRenderer class
		compile: 'cellExtent' , String cr , String tab , '^ ' , anExtent printString
		classified: 'constants'.
	aBlock value ] ensure: [
		CellRenderer class compile: previous sourceCode classified: 'constants' ]
]
