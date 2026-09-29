Class {
	#name : 'LaserGameElementTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
LaserGameElementTestCase >> testAClickThatChangesNothingIsNoMove [
	"A click on a blank cell does nothing, so the board is never told and nothing is counted. The
	original counts every mouse up on the board, whether or not the board changed; the count is
	what the player is asked to keep down, so only a move that happened counts here."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: (game grid at: 2 @ 2) class equals: BlankCell.
	(game board cellElementAt: 2 @ 2) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameIgnoresAWindowOfNoSize [
	"A space announces its extent while it is being opened, and that extent can be nothing at all.
	Scaling by zero would take the game off the screen, so a window of no size is left alone."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural * 2.
	game fitIn: 0 @ 0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameKeepsItsShapeInAWindowOfAnotherShape [
	"A board is as wide and as tall as it is. A window of another shape scales the game by the
	tighter of the two directions and centres what is left over, so the cells stay square and the
	game is never stretched. The window is twice the natural extent in one direction only, so the
	scale is one and the leftover is half the other direction, at any cell size."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural x * 2 @ natural y.
	self assert: (game scaleToFitIn: natural x * 2 @ natural y) equals: 1.0.
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: natural x / 2 @ 0.
	game fitIn: natural x @ (natural y * 2).
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: 0 @ (natural y / 2)
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameMadeWithNoGridPlaysTheStandardBoard [
	"Page 203 opens a LaserGame from the world menu and finds it too small to play: the menu
	sends #new, and #initialize builds the five by five demo board. Page 204 answers with
	GridFactory defaultGrid, eight columns by ten rows, dealt. Here a game takes its grid from
	outside, so the default is what it falls back on when nobody gave it one, and it is dealt
	when it is first asked for rather than in #initialize, so a game that is given a grid deals
	no board it would throw away."

	| game |
	game := LaserGameElement new.
	self assert: game grid numberOfColumns equals: 8.
	self assert: game grid numberOfRows equals: 10.
	self assert: game board grid equals: game grid.
	self
		assert: game constraints horizontal resizer size
			@ game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: game grid).
	self
		assert: (LaserGameElement on: GridFactory demoGrid) grid numberOfColumns
		equals: 5
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameScalesToFillTheWindowItIsGiven [
	"The game is drawn at the size the board asks for and scaled to whatever the window is, so a
	window of twice that extent shows the same game twice as big, filling it. The extent is read
	from the game and not written down, because the cell size decides it: pages 174 to 179 of the
	original are the tale of four tests that had been written down for a cell of thirty pixels."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural * 2.
	self assert: (game scaleToFitIn: natural * 2) equals: 2.0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game transformation matrix sy equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameShowsItsCountsBeforeAnythingHappens [
	"Page 188 opens with a bug of the original's: a game just opened shows zero mirrors, because
	the counters are only written to when something happens, and the page fixes it by updating
	them at the end of #initializeForGrid:. The port cannot have that bug, since the panel sets
	its counters at the end of #rebuild, which is what building it does; this test says so, here
	and after a new board is dealt."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self
		assert: game controlPanel mirrorsCounter value
		equals: game grid numberOfMirrors.
	self assert: game controlPanel mirrorsCounter value > 0.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0.
	game newGame.
	self
		assert: game controlPanel mirrorsCounter value
		equals: game grid numberOfMirrors.
	self assert: game controlPanel mirrorsCounter value > 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameShrinksWithASmallerWindow [
	"A window smaller than the board scales the game down rather than cutting it off, so the whole
	board is always in view. Half the natural extent is half the game, whatever a cell measures."

	| game natural |
	game := LaserGameElement on: GridFactory demoGrid.
	natural := game naturalExtent.
	game fitIn: natural / 2.
	self assert: game transformation matrix sx equals: 0.5.
	self assert: game constraints position equals: 0 @ 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAGameTakesTheSizeOfWhateverBoardItIsGiven [
	"Page 147 hands the game a grid instead of building one, so the size of the board is the size
	of the grid. The game is one cell per location, the panel keeps its width and takes the height
	of the board beside it, and the window is the two of them and the margins. The sizes are read
	from the layout constraints, since nothing is laid out until a space shows it."

	| game wanted |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	wanted := LaserGameElement extentForGrid: game grid.
	self assert: game board children size equals: 80.
	self
		assert: wanted
		equals: (8 * CellRenderer cellExtent x + LaserGameElement panelWidth
		         + (2 * LaserGameElement gameMargin))
			        @ (10 * CellRenderer cellExtent y
				         + (2 * LaserGameElement gameMargin)).
	self assert: game constraints horizontal resizer size equals: wanted x.
	self assert: game constraints vertical resizer size equals: wanted y.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: 10 * CellRenderer cellExtent y
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAMoveOnTheBoardSetsTheCounter [
	"A move changes the path, so it changes the counter too: page 142 adds #updateCounters to the
	mouse up handler as well. The board says that a move was made and the game asks its panel to
	catch up; a board opened on its own says the same thing to nobody. Turning the mirror at the
	foot of the first column sends the beam somewhere else, and the path gets shorter."

	| game cellElement before |
	game := LaserGameElement on: GridFactory demoGrid.
	game toggleLaser.
	before := game controlPanel laserPathCounter value.
	self assert: before equals: game grid laserBeamPath size.
	cellElement := game board cellElementAt: 1 @ 5.
	cellElement clickAt: CellClickRegionRotateClockwise regionRectangle center.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self deny: game controlPanel laserPathCounter value equals: before
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameDealsAFreshBoardAndForgetsTheMoves [
	"Page 146: a new game clears the cells, stops the laser, sets the count to zero and randomizes
	the grid. The demo grid holds ten mirrors and so does a randomized five by five board, so the
	proof that the old cells went first is the count: the randomizer writes onto the board it is
	given and clears nothing, and ten mirrors is what it deals."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game grid fireLaser.
	game incrementMoves.
	game newGame.
	self assert: game moves equals: 0.
	self deny: game grid laserIsActive.
	self assert: game grid numberOfMirrors equals: 10.
	self assert: (game grid at: 5 @ 1) class equals: TargetCell.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameIsShownOnTheBoard [
	"Every cell element is built again from the cell that stands at its location now, so a cell
	that was a mirror and is now blank draws itself blank. Page 146 needs three new rendering
	methods for that, because its cells paint onto one shared form and a cell used to be able to
	assume it was blank underneath."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game newGame.
	1 to: game grid numberOfRows do: [ :row |
		1 to: game grid numberOfColumns do: [ :column |
			self
				assert: (game board cellElementAt: column @ row) renderer cell
				equals: (game grid at: column @ row) ] ]
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameKeepsTheSizeOfTheBoard [
	"New deals the grid the game already plays on, so a bigger board stays bigger: the cells are
	emptied and dealt again, one target in the corner and the mirrors of that size."

	| game |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	game newGame.
	self assert: game grid numberOfColumns equals: 8.
	self assert: game grid numberOfRows equals: 10.
	self assert: game grid numberOfMirrors equals: 32.
	self assert: (game grid at: 8 @ 1) class equals: TargetCell.
	self assert: game board children size equals: 80
]

{ #category : 'tests' }
LaserGameElementTestCase >> testANewGameStartsWithNoMoves [
	"Page 143 sets the count to zero when the game is built."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAnsweringNoLeavesTheGameAsItWas [
	"No takes the question away and does nothing else."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game quit.
	game confirmation answer: false.
	self assert: game confirmation isNil.
	self assert: game children asArray equals: {
			game controlPanel.
			game board parent }
]

{ #category : 'tests' }
LaserGameElementTestCase >> testAnsweringYesToAGameThatIsNotOpenIsHarmless [
	"Yes takes the question away and closes the game. A game that was never opened has no space,
	and closing it is harmless."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game space isNil.
	game quit.
	game confirmation answer: true.
	self assert: game confirmation isNil.
	self assert: game children size equals: 2
]

{ #category : 'tests' }
LaserGameElementTestCase >> testBoardShowsTheGridOfTheGame [
	"The board the game holds renders the game's own grid, one element per cell."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self assert: game grid equals: grid.
	self assert: game board grid equals: grid.
	self assert: game board children size equals: 25
]

{ #category : 'tests' }
LaserGameElementTestCase >> testControlPanelIsAFixedColumnAsTallAsTheBoardOrItsContents [
	"The panel keeps the original's width whatever the grid is, and it is as tall as the board
	beside it — or as tall as what it holds, when that is more, which is what a board of five rows
	comes to once page 181 has added the mirror counters. Sizes are read from the layout
	constraints, since nothing is laid out yet."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: (LaserGameControlPanelElement heightForGrid: grid).
	self
		assert: game controlPanel background paint color
		equals: LaserGameColors controlPanelColor
]

{ #category : 'tests' }
LaserGameElementTestCase >> testEveryMoveOnTheBoardCountsOne [
	"Page 144 counts the click in the mouse up handler of the board. Here the board announces the
	move and the game counts it, so the count is shown without anything searching for the display."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	(game board cellElementAt: 1 @ 5) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 1.
	self assert: game controlPanel movesCounter value equals: 1
]

{ #category : 'tests' }
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins [
	"The game is as wide as the board, the panel beside it and a margin on each side, and as tall
	as the taller of the board and the panel, with a margin above and below. This is the
	original's calculatedExtent, which knows only the board height; the demo grid is short enough
	for the panel to decide instead."

	| grid expected |
	grid := GridFactory demoGrid.
	expected := (LaserGameBoardElement extentForGrid: grid) x
	            + LaserGameElement panelWidth
	            @ (LaserGameControlPanelElement heightForGrid: grid)
	            + (2 * LaserGameElement gameMargin).
	self assert: (LaserGameElement extentForGrid: grid) equals: expected.
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals:
			5 * CellRenderer cellExtent x + 110
			@ LaserGameControlPanelElement contentHeight + 20
]

{ #category : 'tests' }
LaserGameElementTestCase >> testFiringTheLaserSetsTheCounter [
	"The fire button reaches the counter: page 142 adds #updateCounters to the method behind it."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game controlPanel laserPathCounter value equals: 0.
	game toggleLaser.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self assert: game controlPanel laserPathCounter highlighted.
	game toggleLaser.
	self assert: game controlPanel laserPathCounter value equals: 0.
	self deny: game controlPanel laserPathCounter highlighted
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel [
	"A game is a row of two children: the control panel first, the board beside it. Page 139 moves
	the panel to the left of the board. Since page 189 the board is wrapped in a column, which
	holds the mark of the laser's home under it; the board is reached through the same accessor
	as before."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game children size equals: 2.
	self assert: game children first equals: game controlPanel.
	self assert: game children second equals: game board parent.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameShowsWhereTheLaserComesFrom [
	"Page 189 marks where the laser enters the board: a bar one cell wide and one margin tall, in
	the colour of the beam's splatter. It belongs under the bottom left corner of the board, which
	is where the beam starts — Grid >> startingCell is column one of the last row, and the beam
	enters it from the south. The original adds a SketchMorph over a filled Form; here it is a
	plain element with a background, standing under the board in a column of its own."

	| game column |
	game := LaserGameElement on: GridFactory demoGrid.
	column := game board parent.
	self assert: column children asArray equals: {
			game board.
			game laserHome }.
	self
		assert: game laserHome constraints horizontal resizer size
		equals: CellRenderer cellExtent x.
	self
		assert: game laserHome constraints vertical resizer size
		equals: LaserGameElement gameMargin.
	self
		assert: game laserHome background paint color
		equals: LaserGameColors laserBeamSplatterColor
]

{ #category : 'tests' }
LaserGameElementTestCase >> testGameTakesTheExtentItCalculates [
	"The game asks for exactly the size its own arithmetic gives, and the margin around its two
	children is padding, so the window ramp shows through it. The bottom margin is the one
	exception, kept free for the mark of page 189 and asserted by
	#testTheLaserHomeSitsInTheMarginAndCostsNoSize."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: grid) x.
	self
		assert: game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: grid) y.
	self assert: game padding top equals: LaserGameElement gameMargin.
	self assert: game padding left equals: LaserGameElement gameMargin.
	self assert: game padding right equals: LaserGameElement gameMargin
]

{ #category : 'tests' }
LaserGameElementTestCase >> testQuittingAsksBeforeItCloses [
	"Page 144 makes the buttons smaller and puts Quit beside Fire, so #quitGame asks first. The
	question covers the game and is not one of the two children the game lays out in a row. A
	second click on Quit while the question stands asks nothing more."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game quit.
	self assert: game confirmation class equals: LaserGameConfirmElement.
	self assert: game children size equals: 3.
	self assert: game children last equals: game confirmation.
	game quit.
	self assert: game children size equals: 3
]

{ #category : 'tests' }
LaserGameElementTestCase >> testResetPutsEveryCellBackAndZeroesTheMoves [
	"Page 188: Reset unwinds the whole undo stack, stops the laser and sets the move count back to
	zero, so the player can start the same board again."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game grid fireLaser.
	game grid pushCellEastFromLocation: 1 @ 2.
	game incrementMoves.
	game grid rotateCellClockwiseAt: 2 @ 2.
	game incrementMoves.
	self assert: game grid movesStack size equals: 2.
	game reset.
	self assert: game grid movesStack isEmpty.
	self assert: (game grid at: 1 @ 2) class equals: MirrorCell.
	self deny: game laserIsActive.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testSettingAnotherGridRebuildsTheGame [
	"Handing the game another grid throws away the board and the panel it held and builds them
	again for the new grid, so its size follows."

	| game oldBoard smallGrid |
	game := LaserGameElement on: GridFactory demoGrid.
	oldBoard := game board.
	smallGrid := Grid new.
	game grid: smallGrid.
	self assert: game children size equals: 2.
	self deny: game board identicalTo: oldBoard.
	self assert: game board grid equals: smallGrid.
	self assert: game board children size equals: 1.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: smallGrid) x
]

{ #category : 'tests' }
LaserGameElementTestCase >> testTheCountersStillHoldWhatABiggerBoardProduces [
	"A bigger board makes a longer beam, and the counter of page 141 has three digits. Eighty
	cells cannot make a path of a thousand, so the beam counter still shows the whole number the
	grid answers, whatever board the game was dealt."

	| game |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	game toggleLaser.
	self assert: game grid laserBeamPath size < 1000.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self
		assert: game controlPanel laserPathCounter led digitCount
		equals: 3
]

{ #category : 'tests' }
LaserGameElementTestCase >> testTheLaserHomeSitsInTheMarginAndCostsNoSize [
	"The bar stands in the margin under the board, not in a row of its own, so the game is the
	size it was before page 189. That is arranged by taking the bottom margin out of the padding
	and giving it to the panel instead: the column under the board then ends where the game ends,
	and the bar fills the band between the last row of cells and the bottom edge. The original
	places the morph in the margin with a layout frame and has nothing to arrange."

	| game column |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	column := game board parent.
	column measure: BlExtentMeasurementSpec unspecified.
	self
		assert: column measuredExtent
		equals: (LaserGameBoardElement extentForGrid: game grid)
			+ (0 @ LaserGameElement gameMargin).
	self
		assert: game padding
		equals: (BlInsets
				 top: LaserGameElement gameMargin
				 left: LaserGameElement gameMargin
				 bottom: 0
				 right: LaserGameElement gameMargin).
	self
		assert: game controlPanel margin
		equals: (BlInsets bottom: LaserGameElement gameMargin).
	self
		assert:
		LaserGameElement gameMargin + (column measuredExtent y
			 max: LaserGameControlPanelElement contentHeight
				 + LaserGameElement gameMargin)
		equals: (LaserGameElement extentForGrid: game grid) y
]

{ #category : 'tests' }
LaserGameElementTestCase >> testTogglingTheLaserFiresItAndStopsItAgain [
	"The fire button toggles: the first click fires the laser and lights the target, the second
	stops it and puts the target out. The board and the button label both follow. The disc is the
	last child of the target, since a lit target draws the beam under its picture."

	| game target |
	game := LaserGameElement on: GridFactory demoGrid.
	target := game grid at: 5 @ 1.
	game toggleLaser.
	self assert: game laserIsActive.
	self assert: target isOn.
	self
		assert: (game board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorActive.
	self assert: game controlPanel fireButton labelText asString equals: 'Stop'.
	game toggleLaser.
	self deny: game laserIsActive.
	self assert: target isOff.
	self
		assert: (game board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorIdle.
	self assert: game controlPanel fireButton labelText asString equals: 'Fire'
]

{ #category : 'tests' }
LaserGameElementTestCase >> testUndoOnABoardNobodyHasTouchedDoesNothing [
	"An empty stack answers false on page 185, and the game does nothing with it: no move is
	counted and the board is left as it stands."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self deny: game grid undo.
	game undo.
	self assert: game moves equals: 0.
	self assert: game controlPanel movesCounter value equals: 0
]

{ #category : 'tests' }
LaserGameElementTestCase >> testUndoTakesTheLastMoveBackAndCountsAsAMove [
	"Page 186: the Undo button asks the grid to undo, and when the grid says it did, the game
	counts a move and draws itself again. The count is not taken back — page 183 says an undo
	must not remove any count from the player's total — so a move and its undo are two moves."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game grid pushCellEastFromLocation: 1 @ 2.
	game incrementMoves.
	self assert: (game grid at: 2 @ 2) class equals: MirrorCell.
	game undo.
	self assert: (game grid at: 1 @ 2) class equals: MirrorCell.
	self assert: game grid movesStack isEmpty.
	self assert: game moves equals: 2.
	self
		assert: game controlPanel movesCounter value
		equals: game moves
]

{ #category : 'tests' }
LaserGameElementTestCase >> testWindowIsFilledWithTheColorRamp [
	"Page 140 fills the window with a ramp of two colors rather than one flat color, running the
	fraction of the way across and down that the page orients it by."

	| game paint |
	game := LaserGameElement on: GridFactory demoGrid.
	paint := game background paint.
	self assert: paint class equals: BlLinearGradientPaint.
	self assert: paint stops equals: LaserGameColors windowColorRamp.
	self assert: paint start equals: 0 @ 0.
	self assert: paint end equals: LaserGameColors windowColorRampDirection
]
