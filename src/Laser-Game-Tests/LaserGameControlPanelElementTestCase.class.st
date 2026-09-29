Class {
	#name : 'LaserGameControlPanelElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
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
LaserGameControlPanelElementTestCase >> testActiveMirrorsCounterIsThreeDigitsCaptionedActiveMirrors [
	"Page 181's second new counter, captioned Active Mirrors. That caption is the longest of the
	four, and it is why the original widens its panel on the same page."

	| panel |
	panel := self newPanel.
	self assert: panel activeMirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel activeMirrorsCounter led digitCount equals: 3.
	self
		assert: panel activeMirrorsCounter label text asString
		equals: 'Active Mirrors'
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
LaserGameControlPanelElementTestCase >> testContentHeightIsWhatTheCountersAndButtonsMeasure [
	"The height the panel falls back on is stated from the constants, so that it can be asked of
	the class before a panel exists. Here it is checked against what the two columns actually
	measure, which is the only thing that keeps the statement true."

	| panel counters buttons |
	panel := self newPanel.
	counters := panel counterColumn.
	buttons := panel buttonColumn.
	counters measure: BlExtentMeasurementSpec unspecified.
	buttons measure: BlExtentMeasurementSpec unspecified.
	self
		assert: LaserGameControlPanelElement contentHeight
		equals:
			counters measuredExtent y
			+ (2 * LaserGameControlPanelElement counterGap)
			+ buttons measuredExtent y.
	self
		assert: counters children size
		equals: LaserGameControlPanelElement counterCount
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testCounterColumnHoldsTheFourCountersInOrder [
	"Page 181 adds the mirror counters under the two the panel already had, in the order the
	layout frames of that page put them: the beam, the moves, the mirrors, then the active
	mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel counterColumn children asArray equals: {
			panel laserPathCounter.
			panel movesCounter.
			panel mirrorsCounter.
			panel activeMirrorsCounter }
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
LaserGameControlPanelElementTestCase >> testEveryCounterFitsInsideThePanel [
	"Page 181 widens the panel because the caption of the active mirrors counter is longer than
	the ones before it. Here the panel width is the width of a row of two buttons, so the check
	runs the other way: the widest counter has to fit in the width the buttons ask for, with the
	gap on both sides. A counter takes the size of its caption, so the column is asked to measure
	itself first; nothing is laid out, and no element is opened."

	| panel |
	panel := self newPanel.
	panel counterColumn measure: BlExtentMeasurementSpec unspecified.
	panel counterColumn children do: [ :counter |
		self
			assert:
				counter measuredExtent x
				+ (2 * LaserGameControlPanelElement counterGap)
			<= LaserGameElement panelWidth ]
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
LaserGameControlPanelElementTestCase >> testMirrorCountersShowTheGridCountsAndAreNeverBright [
	"Page 182 sets both mirror counters from the grid with #highlighted: false, like the move
	counter: only the beam counter says whether the laser is on. The demo grid holds ten mirrors,
	of which three are lit once the laser fires; the numbers are read from the grid, since
	GridTestCase is where they are written down."

	| panel |
	panel := self newPanel.
	self
		assert: panel mirrorsCounter value
		equals: panel game grid numberOfMirrors.
	self assert: panel activeMirrorsCounter value equals: 0.
	panel game grid fireLaser.
	panel updateCounters.
	self
		assert: panel mirrorsCounter value
		equals: panel game grid numberOfMirrors.
	self
		assert: panel activeMirrorsCounter value
		equals: panel game grid numberOfActiveMirrors.
	self assert: panel activeMirrorsCounter value > 0.
	self deny: panel mirrorsCounter highlighted.
	self deny: panel activeMirrorsCounter highlighted
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testMirrorsCounterIsThreeDigitsCaptionedMirrors [
	"Page 181's first new counter: the same three digit display as the others, captioned Mirrors."

	| panel |
	panel := self newPanel.
	self assert: panel mirrorsCounter class equals: LaserGameCounterElement.
	self assert: panel mirrorsCounter led digitCount equals: 3.
	self assert: panel mirrorsCounter label text asString equals: 'Mirrors'
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
	"Page 144 puts New in the second row from the bottom, first column: the Quit and Fire row is
	the lowest of the column and the New row sits directly above it. What else stands in the row,
	and what rows a later page adds above it, is asserted by
	#testUndoButtonSharesTheRowWithNewGame and #testResetButtonHasTheTopRowToItself."

	| panel rows |
	panel := self newPanel.
	rows := panel buttonColumn children asArray.
	self assert: rows last equals: panel buttonRow.
	self
		assert: (rows indexOf: panel newGameRow) + 1
		equals: (rows indexOf: panel buttonRow).
	self assert: panel newGameRow children first equals: panel newGameButton.
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
LaserGameControlPanelElementTestCase >> testPanelIsAPanelWideColumnAsTallAsTheBoardOrItsContents [
	"The panel sizes itself: the original's panel width, and the height of the board beside it —
	unless the board is shorter than what the panel holds, which the demo grid of five rows is
	once page 181 has added the mirror counters. Then the panel keeps the height of its contents,
	so the counters never reach the buttons."

	| grid panel |
	grid := GridFactory demoGrid.
	panel := (LaserGameElement on: grid) controlPanel.
	self
		assert: panel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: panel constraints vertical resizer size
		equals: LaserGameControlPanelElement contentHeight.
	self
		assert: LaserGameControlPanelElement contentHeight
		> (LaserGameBoardElement extentForGrid: grid) y.
	self
		assert: (LaserGameControlPanelElement heightForGrid:
				 (GridFactory randomizedGridOfExtent: 8 @ 10))
		equals:
			(LaserGameBoardElement extentForGrid:
				 (GridFactory randomizedGridOfExtent: 8 @ 10)) y
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testResetButtonHasTheTopRowToItself [
	"Page 188 puts Reset in row three, column one, which is the row above New and Undo and the
	topmost of the three. Its button is the one thing the panel does not hold in an instance
	variable, so it is read from its row."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel resetRow.
			panel newGameRow.
			panel buttonRow }.
	self assert: panel resetRow children asArray equals: { panel resetButton }.
	self assert: panel resetButton class equals: ToButton.
	self assert: panel resetButton labelText asString equals: 'Reset'
]

{ #category : 'tests' }
LaserGameControlPanelElementTestCase >> testUndoButtonSharesTheRowWithNewGame [
	"Page 186 puts Undo in row two, column two: beside New, above Quit and Fire."

	| panel |
	panel := self newPanel.
	self assert: panel newGameRow children asArray equals: {
			panel newGameButton.
			panel undoButton }.
	self assert: panel undoButton class equals: ToButton.
	self assert: panel undoButton labelText asString equals: 'Undo'
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
