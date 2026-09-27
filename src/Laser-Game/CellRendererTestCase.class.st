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
CellRendererTestCase >> testCellOffsetCalculations [

	| grid extent expected |
	grid := GridFactory demoGrid.
	extent := CellRenderer cellExtent.
	expected := {
		            (1 @ 1 -> (0 @ 0)).
		            (2 @ 1 -> (extent x @ 0)).
		            (1 @ 2 -> (0 @ extent y)).
		            (2 @ 2 -> (extent x @ extent y)) }.
	expected do: [ :each |
		| renderer |
		renderer := CellRenderer
			            rendererFor: (grid at: each key)
			            grid: grid.
		self assert: renderer offsetWithinGridForm equals: each value ]
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
