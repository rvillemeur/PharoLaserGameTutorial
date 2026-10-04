Class {
	#name : 'GridTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
GridTestCase >> generateDemoGrid [

	^ GridFactory demoGrid
]

{ #category : 'tests' }
GridTestCase >> testAPushThatMovesNothingRecordsNoMove [
	"A push that the rules refuse is not a move, so nothing goes on the moves stack. This is what
	pushCellAction:fromLocation: asks when it compares the two locations."

	| grid |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 1 @ 1.
	grid pushCellWestFromLocation: 1 @ 2.
	grid pushCellEastFromLocation: 2 @ 3.
	grid pushCellSouthFromLocation: 5 @ 1.
	self assert: grid movesStack isEmpty.
	grid pushCellNorthFromLocation: 3 @ 3.
	self assert: grid movesStack size equals: 1
]

{ #category : 'tests' }
GridTestCase >> testAPushedMirrorIsTheSameCellInItsNewPlace [
	"A push test that only asks which class sits where leaves room for a push that builds a fresh
	mirror: the classes would still be right and the lean of the mirror, or anything else the
	cell carries, would be lost. Both cells are the ones that were there before, and both know
	their new location."

	| grid mirror blank |
	grid := self generateDemoGrid.
	mirror := grid at: 3 @ 3.
	blank := grid at: 3 @ 2.
	grid pushCellNorthFromLocation: 3 @ 3.
	self assert: (grid at: 3 @ 2) identicalTo: mirror.
	self assert: (grid at: 3 @ 3) identicalTo: blank.
	self assert: mirror gridLocation equals: 3 @ 2.
	self assert: blank gridLocation equals: 3 @ 3.
	self deny: mirror leansLeft
]

{ #category : 'tests' }
GridTestCase >> testCellInteractions [

	| grid cell expectedActiveLocationList foundOn |
	grid := self generateDemoGrid.
	cell := grid at: 5 @ 1.
	self assert: cell isOff.
	grid activateCellsInPath.
	self assert: cell isOn.
	expectedActiveLocationList := {
		                              (1 @ 5).
		                              (2 @ 5).
		                              (3 @ 5).
		                              (4 @ 5).
		                              (4 @ 4).
		                              (4 @ 3).
		                              (4 @ 2).
		                              (4 @ 1).
		                              (5 @ 1) }.
	foundOn := grid cells select: [ :each | each isOn ].
	self assert: foundOn size equals: expectedActiveLocationList size.
	foundOn do: [ :fCell |
		self assert:
			(expectedActiveLocationList includes: fCell gridLocation) ]
]

{ #category : 'tests' }
GridTestCase >> testFireLaser [

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn
]

{ #category : 'tests' }
GridTestCase >> testFireLaserAfterMirrorPush [
	"The same push with the laser off moves the mirror and lights nothing. Firing afterwards
	follows the new path, which no longer reaches the target."

	| grid cell |
	grid := self generateDemoGrid.
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 5 @ 1.
	self assert: cell isOff.
	grid pushCellWestFromLocation: 4 @ 5.
	grid fireLaser.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 3 @ 5.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
]

{ #category : 'tests' }
GridTestCase >> testFireLaserAfterMirrorRotation [

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid stopLaser.
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 4 @ 1.
	self assert: cell isOff.
	grid rotateCellClockwiseAt: cell gridLocation.
	grid fireLaser.
	cell := grid at: 4 @ 1.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
]

{ #category : 'tests' }
GridTestCase >> testFireLaserDuringMirrorPush [
	"A push made while the laser is on takes the beam off the board and lays it down again along
	the new path. The beam crosses the mirror at 4@5, so pushing that mirror west sends the beam
	a different way and the target goes dark."

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	grid pushCellWestFromLocation: 4 @ 5.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 3 @ 5.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
]

{ #category : 'tests' }
GridTestCase >> testFireLaserDuringMirrorRotation [

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn.
	cell := grid at: 4 @ 1.
	grid rotateCellCounterClockwiseAt: cell gridLocation.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
]

{ #category : 'tests' }
GridTestCase >> testInitialConditions [

	| grid cell |
	grid := Grid new.
	self shouldnt: [ grid laserIsActive ].
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell
]

{ #category : 'tests' }
GridTestCase >> testInitialEmptyGrid [

	| grid |
	grid := GridFactory emptyStandardGrid.
	self assert: grid numberOfColumns equals: 8.
	self assert: grid numberOfRows equals: 10.
	1 to: grid numberOfColumns do: [ :columnNumber |
		1 to: grid numberOfRows do: [ :rowNumber |
			| cell |
			cell := grid at: columnNumber @ rowNumber.
			self assert: cell class equals: BlankCell ] ]
]

{ #category : 'tests' }
GridTestCase >> testNonDefaultGridSizeInitialConditions [

	| grid cell |
	grid := Grid newOfSize: 4 @ 4.
	self shouldnt: [ grid laserIsActive ].
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: BlankCell.
	self assert: cell isOff
]

{ #category : 'tests' }
GridTestCase >> testNumberOfActiveMirrorsCounter [
	"No mirror is lit before the laser fires. The demo beam crosses three of the ten."

	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfActiveMirrors.
	self assert: count equals: 0.
	grid fireLaser.
	count := grid numberOfActiveMirrors.
	self assert: count equals: 3
]

{ #category : 'tests' }
GridTestCase >> testNumberOfMirrorsCounter [
	"The demo grid holds ten mirrors. They are counted over the whole board, lit or not."

	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfMirrors.
	self assert: count equals: 10
]

{ #category : 'tests' }
GridTestCase >> testPushBlankCell [

	| grid cell |
	grid := self generateDemoGrid.
	cell := grid at: 1 @ 1.
	grid pushCellSouthFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellNorthFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellWestFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	grid pushCellEastFromLocation: 1 @ 1.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell
]

{ #category : 'tests' }
GridTestCase >> testPushIsolatedMirrorCellEastCase1 [

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellEastFromLocation: 1 @ 2.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	cell := grid at: 1 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 2.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 1 @ 3.
	self assert: cell class equals: BlankCell
]

{ #category : 'tests' }
GridTestCase >> testPushIsolatedMirrorCellEastCase2 [

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellEastFromLocation: 3 @ 3.
	cell := grid at: 3 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 4.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: MirrorCell
]

{ #category : 'tests' }
GridTestCase >> testPushIsolatedMirrorCellNorthCase1 [

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 1 @ 2.
	cell := grid at: 1 @ 1.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 1 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 1 @ 3.
	self assert: cell class equals: BlankCell
]

{ #category : 'tests' }
GridTestCase >> testPushIsolatedMirrorCellNorthCase2 [

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 3 @ 3.
	cell := grid at: 3 @ 2.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 4.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell
]

{ #category : 'tests' }
GridTestCase >> testPushIsolatedMirrorCellSouth [

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellSouthFromLocation: 3 @ 3.
	cell := grid at: 3 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 4.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell
]

{ #category : 'tests' }
GridTestCase >> testPushIsolatedMirrorCellWest [

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellWestFromLocation: 3 @ 3.
	cell := grid at: 3 @ 2.
	self assert: cell class equals: BlankCell.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 3 @ 4.
	self assert: cell class equals: MirrorCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell
]

{ #category : 'tests' }
GridTestCase >> testPushTargetCell [

	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellSouthFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellNorthFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellWestFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell.
	grid pushCellEastFromLocation: 5 @ 1.
	cell := grid at: 5 @ 1.
	self assert: cell class equals: TargetCell
]

{ #category : 'tests' }
GridTestCase >> testPushingAMirrorAgainstANonBlankNeighbourDoesNothing [
	"A mirror with a blank cell beside it moves; two mirrors beside each other do not move
	together. The target is no different from a mirror here — it is simply not blank, so a
	mirror cannot be pushed into it either."

	| grid |
	grid := self generateDemoGrid.
	grid pushCellEastFromLocation: 2 @ 3.
	self assert: (grid at: 2 @ 3) class equals: MirrorCell.
	self assert: (grid at: 3 @ 3) class equals: MirrorCell.
	grid pushCellEastFromLocation: 4 @ 1.
	self assert: (grid at: 4 @ 1) class equals: MirrorCell.
	self assert: (grid at: 5 @ 1) class equals: TargetCell
]

{ #category : 'tests' }
GridTestCase >> testPushingAMirrorOffTheEdgeOfTheGridDoesNothing [
	"There is no cell beyond the border, so the push finds nothing to trade places with. The rule
	is a rule about the adjacent cell; the demo grid has a mirror on the left edge at 1@2 and one
	on the bottom edge at 1@5."

	| grid |
	grid := self generateDemoGrid.
	grid pushCellWestFromLocation: 1 @ 2.
	self assert: (grid at: 1 @ 2) class equals: MirrorCell.
	grid pushCellSouthFromLocation: 1 @ 5.
	self assert: (grid at: 1 @ 5) class equals: MirrorCell
]

{ #category : 'tests' }
GridTestCase >> testResetGrid [
	"Two pushes, then a reset, and the cells that moved are back where they were with an empty
	stack behind them. Reset is the undo stack unwound to the end, so this is the same rule
	#testUndoingEveryMoveGivesTheGridBackAsItWas states one move at a time."

	| grid cell |
	grid := self generateDemoGrid.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: BlankCell.
	grid pushCellEastFromLocation: 3 @ 3.
	grid pushCellSouthFromLocation: 4 @ 3.
	cell := grid at: 3 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 4 @ 3.
	self assert: cell class equals: BlankCell.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: MirrorCell.
	self assert: grid movesStack size equals: 2.
	grid reset.
	cell := grid at: 4 @ 4.
	self assert: cell class equals: BlankCell.
	self assert: grid movesStack isEmpty
]

{ #category : 'tests' }
GridTestCase >> testStopLaser [

	| grid cell |
	grid := self generateDemoGrid.
	grid stopLaser.
	self shouldnt: [ grid laserIsActive ].
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
]

{ #category : 'tests' }
GridTestCase >> testTheCellsTabListsEveryCellWithItsState [
	"The Cells tab answers in one view whether any cell disagrees with the beam: one row per cell,
	with what the cell is and whether it is lit."

	| grid builder table |
	grid := self generateDemoGrid.
	grid fireLaser.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := grid inspectionCells: builder.
	self
		assert: table items size
		equals: grid numberOfColumns * grid numberOfRows.
	self assert: (table items includes: (grid at: 5 @ 1)).
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Cell' 'Lit' )
]

{ #category : 'tests' }
GridTestCase >> testTheInspectorTabsOfAGridShowTheBoardAndTheBeam [
	"A grid can show the board itself, since it has an element that draws it, as well as the path
	the laser takes. One row per step of the beam, and the board as a picture."

	| grid builder |
	grid := self generateDemoGrid.
	grid fireLaser.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	self
		assert: (grid inspectionBeam: builder) items size
		equals: grid laserBeamPath size.
	self assert: (grid inspectionBoard: builder) class equals: SpMorphPresenter
]

{ #category : 'tests' }
GridTestCase >> testTheMovesTabListsWhatUndoWillDo [
	"The Moves tab is the undo stack read out loud: one row per move, youngest first, with the
	selector undo will send for it. It is the view that saves reading the seven Reverse classes
	the grid looks up by symbol."

	| grid builder table undoSends |
	grid := self generateDemoGrid.
	grid rotateCellClockwiseAt: 1 @ 5.
	grid pushCellEastFromLocation: 1 @ 2.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := grid inspectionMoves: builder.
	self assert: table items size equals: 2.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Move' 'Cell now at' 'Undo sends' ).
	self assert: table items first key equals: #east.
	self assert: table items last key equals: #clockwise.
	undoSends := table columns third.
	self
		assert: (undoSends evaluation value: table items last)
		equals: 'rotateCellCounterClockwiseAt:'
]

{ #category : 'tests' }
GridTestCase >> testThePushesTabSaysWhichPushesTheRulesAllow [
	"The Pushes tab asks the four push rules of every mirror on the board and answers in one
	table. A mirror with no yes is a mirror the player cannot move, which is what the arrows on
	the board are drawn from."

	| grid builder table north east |
	grid := self generateDemoGrid.
	builder := SpPresenterBuilder new
		           application: SpApplication new;
		           yourself.
	table := grid inspectionPushes: builder.
	self assert: table items size equals: grid numberOfMirrors.
	self
		assert: (table columns collect: [ :each | each title ]) asArray
		equals: #( 'Mirror' 'North' 'East' 'South' 'West' ).
	self assert: (table items includes: 1 @ 2).
	self deny: (table items includes: 5 @ 1).
	north := table columns second.
	east := table columns third.
	self
		assert: (north evaluation value: 1 @ 2)
		equals: ((grid canPushCellNorthFromLocation: 1 @ 2)
				 ifTrue: [ 'yes' ]
				 ifFalse: [ '' ]).
	self assert: (east evaluation value: 1 @ 2) equals: 'yes'
]

{ #category : 'tests' }
GridTestCase >> testToggleLaser [

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	grid stopLaser.
	self shouldnt: [ grid laserIsActive ].
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
]

{ #category : 'tests' }
GridTestCase >> testUndoActions [
	"Every action symbol the stack can hold answers the selector that takes it back. The six pairs
	are the four pushes, each answering the push the other way, and the two rotations, each
	answering the other turn."

	| undoAction |
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #north.
	self assert: undoAction equals: #pushCellSouthFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #east.
	self assert: undoAction equals: #pushCellWestFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #south.
	self assert: undoAction equals: #pushCellNorthFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #west.
	self assert: undoAction equals: #pushCellEastFromLocation:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor:
		              #clockwise.
	self assert: undoAction equals: #rotateCellCounterClockwiseAt:.
	undoAction := ReverseLaserGameAction reverseActionSymbolFor:
		              #counterClockwise.
	self assert: undoAction equals: #rotateCellClockwiseAt:
]

{ #category : 'tests' }
GridTestCase >> testUndoStackAfterPush [
	"A push puts one entry on the stack, the undo takes it off and answers true, and a
	second undo finds the stack empty and answers false."

	| grid |
	grid := self generateDemoGrid.
	self assert: grid movesStack isEmpty.
	grid pushCellEastFromLocation: 1 @ 2.
	self assert: grid movesStack size equals: 1.
	self assert: grid undo.
	self deny: grid undo
]

{ #category : 'tests' }
GridTestCase >> testUndoingEveryMoveGivesTheGridBackAsItWas [
	"Undo takes one move off the stack and plays its reverse. A run of pushes and turns mixed
	together, undone one at a time, has to leave every cell of the grid where it was and facing
	the way it did, and leave the stack empty. Only a move that changed something is stacked, so
	each move is checked to have been recorded before the run is undone."

	| grid before after reading |
	reading := [ :aGrid |
	            aGrid cells collect: [ :each |
		            | lean |
		            lean := (each isKindOf: MirrorCell)
			                    ifTrue: [ each leansLeft printString ]
			                    ifFalse: [ '' ].
		            each class name , ' ' , each gridLocation printString , ' '
		            , lean ] ].
	grid := self generateDemoGrid.
	before := reading value: grid.
	{
		(#pushCellEastFromLocation: -> (1 @ 2)).
		(#rotateCellClockwiseAt: -> (2 @ 2)).
		(#pushCellSouthFromLocation: -> (4 @ 1)).
		(#rotateCellCounterClockwiseAt: -> (3 @ 3)).
		(#pushCellWestFromLocation: -> (5 @ 3)) } doWithIndex: [ :each :index |
		grid perform: each key with: each value.
		self assert: grid movesStack size equals: index ].
	[ grid undo ] whileTrue.
	self assert: grid movesStack isEmpty.
	after := reading value: grid.
	self assert: after equals: before
]
