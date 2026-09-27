Class {
	#name : 'LaserGameControlPanelElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'helpers' }
LaserGameControlPanelElementTestCase >> newPanel [
	"Answer the control panel of a game playing on the demo grid, with the laser not firing."

	^ (LaserGameElement on: GridFactory demoGrid) controlPanel
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testButtonRowSitsAtTheBottomLeftOneGapIn [
	"The row is aligned to the bottom left corner of the panel, one gap away from both edges, and
	the buttons inside it are one gap apart. That is where the original's layout frames put them."

	| panel row |
	panel := self newPanel.
	row := panel children first.
	self
		assert: row constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: row constraints frame vertical alignment
		equals: BlElementAlignment bottom.
	self
		assert: row margin
		equals: (BlInsets all: LaserGameControlPanelElement buttonGap).
	self
		assert: row layout cellSpacing
		equals: LaserGameControlPanelElement buttonGap
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testButtonsKeepTheOriginalSize [
	"Both buttons are the original's forty by twenty. Sizes are read from the layout constraints,
	since nothing is laid out yet."

	| panel |
	panel := self newPanel.
	{ panel quitButton. panel fireButton } do: [ :button |
		self
			assert: button constraints horizontal resizer size
			equals: LaserGameControlPanelElement buttonWidth.
		self
			assert: button constraints vertical resizer size
			equals: LaserGameControlPanelElement buttonHeight ]
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testFireButtonSaysWhatAClickWillDo [
	"The label names the action, not the state: Fire while the laser is off, Stop while it fires."

	| panel |
	panel := self newPanel.
	self deny: panel game laserIsActive.
	self assert: panel fireButtonLabel equals: 'Fire'.
	panel game grid fireLaser.
	self assert: panel fireButtonLabel equals: 'Stop'.
	panel game grid stopLaser.
	self assert: panel fireButtonLabel equals: 'Fire'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testPanelHoldsARowOfTwoButtons [
	"The game's panel is a control panel element. It holds one child, the row, and the row holds the
	Quit button then the Fire button. The rest of the original's buttons arrive with their own pages."

	| panel row |
	panel := self newPanel.
	self assert: panel class equals: LaserGameControlPanelElement.
	self assert: panel children size equals: 1.
	row := panel children first.
	self assert: row children asArray
		equals: { panel quitButton. panel fireButton }.
	self assert: panel quitButton class equals: ToButton.
	self assert: panel fireButton class equals: ToButton.
	self assert: panel quitButton labelText asString equals: 'Quit'.
	self assert: panel fireButton labelText asString equals: 'Fire'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testPanelIsAPanelWideColumnAsTallAsTheBoard [
	"The panel sizes itself now: the original's panel width, and the height of the board beside it."

	| grid panel |
	grid := GridFactory demoGrid.
	panel := (LaserGameElement on: grid) controlPanel.
	self
		assert: panel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: panel constraints vertical resizer size
		equals: (LaserGameBoardElement extentForGrid: grid) y
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testUpdatingTheLabelPutsItOnTheButton [
	"The label on the button follows the grid only when it is updated, which is what a click does."

	| panel |
	panel := self newPanel.
	panel game grid fireLaser.
	self assert: panel fireButton labelText asString equals: 'Fire'.
	panel updateFireButtonLabel.
	self assert: panel fireButton labelText asString equals: 'Stop'
]
