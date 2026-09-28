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
LaserGameControlPanelElementTestCase >> testARowOfTwoButtonsFitsInsideThePanel [
	"A row of buttons is as wide as its buttons and the gaps around and between them. Two buttons
	fill the panel exactly, so the last button of a row stops one gap short of the board beside
	the panel; a third button in the same row would not fit."

	| widthOfTwo |
	widthOfTwo := (2 * LaserGameControlPanelElement buttonWidth)
	              + (3 * LaserGameControlPanelElement buttonGap).
	self assert: widthOfTwo equals: LaserGameElement panelWidth.
	self
		assert: widthOfTwo + LaserGameControlPanelElement buttonWidth
			+ LaserGameControlPanelElement buttonGap
			> LaserGameElement panelWidth
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testButtonColumnSitsAtTheBottomLeftOneGapIn [
	"The buttons are aligned to the bottom left corner of the panel, one gap away from both edges,
	and the rows are one gap apart. That is where page 144's layout frames put them, counting rows
	from the bottom. The cell spacing is the whole of the gap, since a linear layout spaces its
	cells from its own edges as well as from each other; a margin on top of it would take the
	bottom row past the right edge of the panel and up against the board."

	| panel column |
	panel := self newPanel.
	column := panel buttonColumn.
	self
		assert: column constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: column constraints frame vertical alignment
		equals: BlElementAlignment bottom.
	self assert: column margin equals: BlInsets empty.
	self
		assert: column layout cellSpacing
		equals: LaserGameControlPanelElement buttonGap
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testButtonsKeepTheOriginalSize [
	"All three buttons are the original's forty by twenty. Sizes are read from the layout
	constraints, since nothing is laid out yet."

	| panel |
	panel := self newPanel.
	{
		panel quitButton.
		panel fireButton.
		panel newGameButton } do: [ :button |
		self
			assert: button constraints horizontal resizer size
			equals: LaserGameControlPanelElement buttonWidth.
		self
			assert: button constraints vertical resizer size
			equals: LaserGameControlPanelElement buttonHeight ]
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testCounterColumnHoldsTheBeamCounterAboveTheMoveCounter [
	"Page 143 adds the move counter under the beam counter, one counter lower in the same column."

	| panel |
	panel := self newPanel.
	self assert: panel counterColumn children asArray equals: {
			panel laserPathCounter.
			panel movesCounter }
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testCounterColumnSitsAtTheTopLeftOneGapIn [
	"The counters are aligned to the top left corner of the panel, one counter gap away from both
	edges, which is the layout frame page 141 gives them. The buttons keep the bottom."

	| panel column |
	panel := self newPanel.
	column := panel counterColumn.
	self assert: (panel children includes: column).
	self
		assert: column constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: column constraints frame vertical alignment
		equals: BlElementAlignment top.
	self
		assert: column margin
		equals: (BlInsets all: LaserGameControlPanelElement counterGap)
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testCounterShowsTheBeamLengthOnlyWhileTheLaserFires [
	"Page 142: while the laser fires the counter is bright and holds the number of path elements
	of the grid; while it does not the counter is dim and holds zero. The counter follows the grid
	only when it is updated, which is what the fire button and a move do."

	| panel |
	panel := self newPanel.
	self assert: panel laserPathCounter value equals: 0.
	self deny: panel laserPathCounter highlighted.
	panel game grid fireLaser.
	panel updateCounters.
	self assert: panel laserPathCounter highlighted.
	self
		assert: panel laserPathCounter value
		equals: panel game grid laserBeamPath size.
	self assert: panel laserPathCounter value > 0.
	panel game grid stopLaser.
	panel updateCounters.
	self deny: panel laserPathCounter highlighted.
	self assert: panel laserPathCounter value equals: 0
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
LaserGameControlPanelElementTestCase >> testLaserPathCounterIsThreeDigitsCaptionedLaserPath [
	"Page 141 asks for three digits and the caption Laser Path."

	| panel |
	panel := self newPanel.
	self assert: panel laserPathCounter class equals: LaserGameCounterElement.
	self assert: panel laserPathCounter led digitCount equals: 3.
	self assert: panel laserPathCounter label text asString equals: 'Laser Path'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testMovesCounterIsThreeDigitsCaptionedMoves [
	"Page 143's counter: the same three digit display as the beam counter, captioned Moves."

	| panel |
	panel := self newPanel.
	self assert: panel movesCounter class equals: LaserGameCounterElement.
	self assert: panel movesCounter led digitCount equals: 3.
	self assert: panel movesCounter label text asString equals: 'Moves'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testMovesCounterShowsTheMoveCountAndIsNeverBright [
	"Page 143 sets the move counter with #highlighted: false every time: only the beam says whether
	the laser is on."

	| panel |
	panel := self newPanel.
	self assert: panel movesCounter value equals: 0.
	panel game incrementMoves.
	panel game grid fireLaser.
	panel updateCounters.
	self assert: panel movesCounter value equals: 1.
	self deny: panel movesCounter highlighted.
	self assert: panel laserPathCounter highlighted
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers [
	"Page 144 puts New in the second row from the bottom, first column: here the column of rows
	holds the New row first and the Quit and Fire row last, which is lowest."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel newGameRow.
			panel buttonRow }.
	self assert: panel newGameRow children asArray equals: { panel newGameButton }.
	self assert: panel newGameButton labelText asString equals: 'New'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testPanelHoldsARowOfTwoButtons [
	"The game's panel is a control panel element. It holds the column of button rows, and the
	bottom row holds the Quit button then the Fire button. The rest of the original's buttons
	arrive with their own pages."

	| panel row |
	panel := self newPanel.
	self assert: panel class equals: LaserGameControlPanelElement.
	row := panel buttonRow.
	self assert: (panel children includes: panel buttonColumn).
	self assert: (panel buttonColumn children includes: row).
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
