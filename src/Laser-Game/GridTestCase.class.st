Class {
	#name : #GridTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
GridTestCase >> generateDemoGrid [

	^ GridFactory demoGrid
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
GridTestCase >> testFireLaserAfterMirrorPush [

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

{ #category : #tests }
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

{ #category : #tests }
GridTestCase >> testFireLaserDuringMirrorPush [

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

{ #category : #tests }
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

{ #category : #tests }
GridTestCase >> testInitialConditions [

	| grid cell |
	grid := Grid new.
	self shouldnt: [ grid laserIsActive ].
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
GridTestCase >> testNumberOfActiveMirrorsCounter [

	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfActiveMirrors.
	self assert: count equals: 0.
	grid fireLaser.
	count := grid numberOfActiveMirrors.
	self assert: count equals: 3
]

{ #category : #tests }
GridTestCase >> testNumberOfMirrorsCounter [

	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfMirrors.
	self assert: count equals: 10
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
GridTestCase >> testResetGrid [

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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
GridTestCase >> testUndoActions [

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

{ #category : #tests }
GridTestCase >> testUndoStackAfterPush [

	| grid |
	grid := self generateDemoGrid.
	self assert: grid movesStack isEmpty.
	grid pushCellEastFromLocation: 1 @ 2.
	self assert: grid movesStack size equals: 1.
	self assert: grid undo.
	self shouldnt: [ grid undo ]
]
