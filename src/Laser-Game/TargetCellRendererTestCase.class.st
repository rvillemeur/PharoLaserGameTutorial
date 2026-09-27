Class {
	#name : 'TargetCellRendererTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'running' }
TargetCellRendererTestCase >> rendererForTarget: aTargetCell [
	"Answer a renderer for aTargetCell, sitting at 1@1 of a fresh grid."

	| grid |
	grid := Grid new.
	grid at: 1 @ 1 put: aTargetCell.
	^ CellRenderer rendererFor: aTargetCell grid: grid
]

{ #category : 'tests' }
TargetCellRendererTestCase >> testALitTargetIsFilledWithTheActiveColor [
	"A target the laser reaches shows the active fill, and rendering the cell again picks the new
	color up."

	| cell renderer |
	cell := TargetCell new.
	renderer := self rendererForTarget: cell.
	cell activeSegments at: #west put: true.
	self assert: cell isOn.
	self
		assert: renderer centerColor
		equals: LaserGameColors targetCenterColorActive.
	self
		assert: (renderer newElement children at: 4) background paint color
		equals: LaserGameColors targetCenterColorActive
]

{ #category : 'tests' }
TargetCellRendererTestCase >> testAnUnlitTargetIsFilledWithTheIdleColor [
	"A target no laser reaches shows the idle fill."

	| cell renderer |
	cell := TargetCell new.
	renderer := self rendererForTarget: cell.
	self assert: cell isOff.
	self
		assert: renderer centerColor
		equals: LaserGameColors targetCenterColorIdle.
	self
		assert: (renderer newElement children at: 4) background paint color
		equals: LaserGameColors targetCenterColorIdle
]

{ #category : 'tests' }
TargetCellRendererTestCase >> testCenterSitsInsideTheRing [
	"The disc is centered where the ring is and is one centerInset smaller in radius."

	| renderer center middle |
	renderer := self rendererForTarget: TargetCell new.
	center := renderer newElement children at: 4.
	middle := TargetCellRenderer cellExtent - 1 // 2.
	self
		assert: renderer innerRadius
		equals: renderer radius - TargetCellRenderer centerInset.
	self
		assert: center constraints horizontal resizer size
		equals: renderer innerRadius * 2.
	self
		assert: center constraints vertical resizer size
		equals: renderer innerRadius * 2.
	self
		assert: center constraints position
		equals: middle - renderer innerRadius
]

{ #category : 'tests' }
TargetCellRendererTestCase >> testCrossHairsCrossInTheMiddleInsetFromTheEdges [
	"The horizontal line runs along the middle row of the cell and the vertical one along the
	middle column, each stopping short of the two edges it points at."

	| renderer children inset delta middle |
	renderer := self rendererForTarget: TargetCell new.
	children := renderer newElement children.
	inset := renderer crossHairInset.
	delta := TargetCellRenderer cellExtent - 1.
	middle := delta // 2.
	self assert: children first geometry from equals: inset x @ middle y.
	self
		assert: children first geometry to
		equals: delta x - inset x @ middle y.
	self
		assert: (children at: 2) geometry from
		equals: middle x @ inset y.
	self
		assert: (children at: 2) geometry to
		equals: middle x @ (delta y - inset y)
]

{ #category : 'tests' }
TargetCellRendererTestCase >> testOutlinesAreDrawnInTheTargetColor [
	"Both crosshairs and the ring share one color, and all three are strokes of the same width."

	| children |
	children := (self rendererForTarget: TargetCell new) newElement children.
	1 to: 3 do: [ :index |
		self
			assert: (children at: index) border paint color
			equals: LaserGameColors targetCenterColor.
		self
			assert: (children at: index) border width
			equals: TargetCellRenderer outlineWidth.
		self
			assert: (children at: index) outskirts
			equals: BlOutskirts centered ]
]

{ #category : 'tests' }
TargetCellRendererTestCase >> testRingIsAnEmptyOutlineAroundTheMiddleOfTheCell [
	"The ring is a circle of the renderer's radius, centered on the cell, with nothing painted
	inside it, so the crosshairs stay visible through it."

	| renderer ring middle |
	renderer := self rendererForTarget: TargetCell new.
	ring := renderer newElement children at: 3.
	middle := TargetCellRenderer cellExtent - 1 // 2.
	self
		assert: ring constraints horizontal resizer size
		equals: renderer radius * 2.
	self
		assert: ring constraints vertical resizer size
		equals: renderer radius * 2.
	self
		assert: ring constraints position
		equals: middle - renderer radius.
	self
		assert: ring border width
		equals: TargetCellRenderer outlineWidth.
	self assert: ring background class equals: BlTransparentBackground
]

{ #category : 'tests' }
TargetCellRendererTestCase >> testTargetHasCrossHairsARingAndACenter [
	"A target draws four things: two crossing lines, the ring, and the disc inside it."

	| children |
	children := (self rendererForTarget: TargetCell new) newElement children.
	self assert: children size equals: 4.
	self assert: (children at: 1) geometry class equals: BlLineGeometry.
	self assert: (children at: 2) geometry class equals: BlLineGeometry.
	self assert: (children at: 3) geometry class equals: BlCircleGeometry.
	self assert: (children at: 4) geometry class equals: BlCircleGeometry
]
