Class {
	#name : 'CellRendererTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

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
