Class {
	#name : #CellRendererTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
CellRendererTestCase >> testCellOffsetCalculations [

	| grid form cellLoc cell rendererClass renderer offset |
	grid := GridFactory demoGrid.
	form := Form
		        extent: (LaserGame boardExtendFor: grid)
		        depth: Display depth.
	form fillColor: (Color r: 0.820 g: 0.820 b: 0.820).
	
	cellLoc := 1 @ 1.
	cell := grid at: cellLoc.
	renderer := CellRenderer rendererFor: cell grid: grid form: form.
	offset := renderer offsetWithinGridForm.
	self should: [ offset = (0 @ 0) ].
	
	cellLoc := 2 @ 1.
	cell := grid at: cellLoc.
	renderer := CellRenderer rendererFor: cell grid: grid form: form.
	offset := renderer offsetWithinGridForm.
	self should: [ offset = (50 @ 0) ].
	
	cellLoc := 1 @ 2.
	cell := grid at: cellLoc.
	renderer := CellRenderer rendererFor: cell grid: grid form: form.
	offset := renderer offsetWithinGridForm.
	self should: [ offset = (0 @ 50) ].
	
	cellLoc :=2 @ 2.
	cell := grid at: cellLoc.
	renderer := CellRenderer rendererFor: cell grid: grid form: form.
	offset := renderer offsetWithinGridForm.
	self should: [ offset = (50 @ 50) ]
]

{ #category : #tests }
CellRendererTestCase >> testRendererSelection [

	| renderer cell |
	cell := BlankCell new.
	renderer := CellRenderer rendererFor: cell.
	self should: [ renderer = BlankCellRenderer ].


	cell := MirrorCell new.
	renderer := CellRenderer rendererFor: cell.
	self should: [ renderer = MirrorCellRenderer ].

	cell := TargetCell new.
	renderer := CellRenderer rendererFor: cell.
	self should: [ renderer = TargetCellRenderer ]
]
