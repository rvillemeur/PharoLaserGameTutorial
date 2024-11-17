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
	self should: [ cell isOff ].
	grid activateCellsInPath.
	self should: [ cell isOn ].
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
	self should: [ foundOn size = expectedActiveLocationList size ].
	foundOn do: [ :fCell |
		self should: [
			expectedActiveLocationList includes: fCell gridLocation ] ]
]

{ #category : #tests }
GridTestCase >> testFireLaser [

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self should: [ grid laserIsActive ].
	cell := grid startingCell.
	self should: [ cell isOn ].
	cell := grid at: 5@1.
	self should: [ cell isOn ]
]

{ #category : #tests }
GridTestCase >> testFireLaserAfterMirrorPush [
	| grid cell |
	grid := self generateDemoGrid.
	cell := grid startingCell.
	self should: [cell isOff].
	cell := grid at: 5@1.
	self should: [cell isOff].
	grid pushCellWestFromLocation: 4@5.
	grid fireLaser.
	cell := grid startingCell.
	self should: [cell isOn].
	cell := grid at: 3@5.
	self should: [cell isOn].
	cell := grid at: 5@1.
	self should: [cell isOff].

]

{ #category : #tests }
GridTestCase >> testFireLaserAfterMirrorRotation [
	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self should: [grid laserIsActive].
	cell := grid startingCell.
	self should: [cell isOn].
	cell := grid at: 5@1.
	self should: [cell isOn].
	grid stopLaser.
	cell := grid startingCell.
	self should: [cell isOff].
	cell := grid at: 4@1.
	self should: [cell isOff].
	grid rotateCellClockwiseAt: cell gridLocation.
	grid fireLaser.
	cell := grid at: 4@1.
	self should: [cell isOn].
	cell := grid at: 5@1.
	self should: [cell isOff].
	
]

{ #category : #tests }
GridTestCase >> testFireLaserDuringMirrorPush [
	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	cell := grid startingCell.
	self should: [cell isOn].
	cell := grid at: 5@1.
	self should: [cell isOn].
	grid pushCellWestFromLocation: 4@5.
	cell := grid startingCell.
	self should: [cell isOn].
	cell := grid at: 3@5.
	self should: [cell isOn].
	cell := grid at: 5@1.
	self should: [cell isOff].

]

{ #category : #tests }
GridTestCase >> testFireLaserDuringMirrorRotation [
	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self should: [grid laserIsActive].
	cell := grid startingCell.
	self should: [cell isOn].
	cell := grid at: 5@1.
	self should: [cell isOn].
	cell := grid at: 4@1.
	grid rotateCellCounterClockwiseAt: cell gridLocation.
	self should: [cell isOn].
	cell := grid at: 5@1.
	self should: [cell isOff].
	
]

{ #category : #tests }
GridTestCase >> testInitialConditions [

	| grid cell |
	grid := Grid new.
	self shouldnt: [ grid laserIsActive ].
	cell := grid at: 1 @ 1.
	self should: [ cell class = BlankCell ]
]

{ #category : #tests }
GridTestCase >> testInitialEmptyGrid [
	| grid |
	grid := GridFactory emptyStandardGrid.
	self should: [grid numberOfColumns = 8].
	self should: [grid numberOfRows = 10].
	1 to: grid numberOfColumns do: [:columnNumber |
		1 to: grid numberOfRows do: [:rowNumber |
			| cell |
			cell := grid at: columnNumber@rowNumber.
			self should: [cell class = BlankCell]]].

	
]

{ #category : #tests }
GridTestCase >> testNonDefaultGridSizeInitialConditions [

	| grid cell |
	grid := Grid newOfSize: 4@4.
	self shouldnt: [ grid laserIsActive ].
	cell := grid at: 1 @ 1.
	self should: [ cell class = BlankCell ].
	cell := grid at: 2 @ 3.
	self should: [ cell class = BlankCell ].
	self should: [ cell isOff ]
]

{ #category : #tests }
GridTestCase >> testNumberOfActiveMirrorsCounter [
	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfActiveMirrors.
	self should: [count = 0].
	grid fireLaser.
	count := grid numberOfActiveMirrors.
	self should: [count = 3].
]

{ #category : #tests }
GridTestCase >> testNumberOfMirrorsCounter [
	| grid count |
	grid := self generateDemoGrid.
	count := grid numberOfMirrors.
	self should: [count = 10].
]

{ #category : #tests }
GridTestCase >> testPushBlankCell [
	| grid cell |
	grid := self generateDemoGrid.
	cell := grid at: 1@1.
	grid pushCellSouthFromLocation: 1@1.
	cell := grid at: 1@1.
	self should: [cell class = BlankCell].
	grid pushCellNorthFromLocation: 1@1.
	cell := grid at: 1@1.
	self should: [cell class = BlankCell].
	grid pushCellWestFromLocation: 1@1.
	cell := grid at: 1@1.
	self should: [cell class = BlankCell].
	grid pushCellEastFromLocation: 1@1.
	cell := grid at: 1@1.
	self should: [cell class = BlankCell].

]

{ #category : #tests }
GridTestCase >> testPushIsolatedMirrorCellEastCase1 [
	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellEastFromLocation: 1@2.
	cell := grid at: 1@1.
	self should: [cell class = BlankCell].
	cell := grid at: 1@2.
	self should: [cell class = BlankCell].
	cell := grid at: 2@2.
	self should: [cell class = MirrorCell].
	cell := grid at: 1@3.
	self should: [cell class = BlankCell].

]

{ #category : #tests }
GridTestCase >> testPushIsolatedMirrorCellEastCase2 [
	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellEastFromLocation: 3@3.
	cell := grid at: 3@2.
	self should: [cell class = BlankCell].
	cell := grid at: 3@3.
	self should: [cell class = BlankCell].
	cell := grid at: 2@3.
	self should: [cell class = MirrorCell].
	cell := grid at: 3@4.
	self should: [cell class = MirrorCell].
	cell := grid at: 4@3.
	self should: [cell class = MirrorCell].

]

{ #category : #tests }
GridTestCase >> testPushIsolatedMirrorCellNorthCase1 [
	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 1@2.
	cell := grid at: 1@1.
	self should: [cell class = MirrorCell].
	cell := grid at: 1@2.
	self should: [cell class = BlankCell].
	cell := grid at: 2@2.
	self should: [cell class = BlankCell].
	cell := grid at: 1@3.
	self should: [cell class = BlankCell].
]

{ #category : #tests }
GridTestCase >> testPushIsolatedMirrorCellNorthCase2 [
	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellNorthFromLocation: 3@3.
	cell := grid at: 3@2.
	self should: [cell class = MirrorCell].
	cell := grid at: 3@3.
	self should: [cell class = BlankCell].
	cell := grid at: 2@3.
	self should: [cell class = MirrorCell].
	cell := grid at: 3@4.
	self should: [cell class = MirrorCell].
	cell := grid at: 4@3.
	self should: [cell class = BlankCell].
]

{ #category : #tests }
GridTestCase >> testPushIsolatedMirrorCellSouth [
	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellSouthFromLocation: 3@3.
	cell := grid at: 3@2.
	self should: [cell class = BlankCell].
	cell := grid at: 3@3.
	self should: [cell class = MirrorCell].
	cell := grid at: 2@3.
	self should: [cell class = MirrorCell].
	cell := grid at: 3@4.
	self should: [cell class = MirrorCell].
	cell := grid at: 4@3.
	self should: [cell class = BlankCell].
]

{ #category : #tests }
GridTestCase >> testPushIsolatedMirrorCellWest [
	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellWestFromLocation: 3@3.
	cell := grid at: 3@2.
	self should: [cell class = BlankCell].
	cell := grid at: 3@3.
	self should: [cell class = MirrorCell].
	cell := grid at: 2@3.
	self should: [cell class = MirrorCell].
	cell := grid at: 3@4.
	self should: [cell class = MirrorCell].
	cell := grid at: 4@3.
	self should: [cell class = BlankCell].

]

{ #category : #tests }
GridTestCase >> testPushTargetCell [
	| grid cell |
	grid := self generateDemoGrid.
	grid pushCellSouthFromLocation: 5@1.
	cell := grid at: 5@1.
	self should: [cell class = TargetCell].
	grid pushCellNorthFromLocation: 5@1.
	cell := grid at: 5@1.
	self should: [cell class = TargetCell].
	grid pushCellWestFromLocation: 5@1.
	cell := grid at: 5@1.
	self should: [cell class = TargetCell].
	grid pushCellEastFromLocation: 5@1.
	cell := grid at: 5@1.
	self should: [cell class = TargetCell].

]

{ #category : #tests }
GridTestCase >> testResetGrid [
	| grid cell |
	grid := self generateDemoGrid.
	cell := grid at: 4@4.
	self should: [cell class = BlankCell].
	grid pushCellEastFromLocation: 3@3.
	grid pushCellSouthFromLocation: 4@3.
	cell := grid at: 3@3.
	self should: [cell class = BlankCell].
	cell := grid at: 4@3.
	self should: [cell class = BlankCell].
	cell := grid at: 4@4.
	self should: [cell class = MirrorCell].
	self should: [grid movesStack size = 2].
	grid reset.
	cell := grid at: 4@4.
	self should: [cell class = BlankCell].
	self should: [grid movesStack isEmpty].
	
]

{ #category : #tests }
GridTestCase >> testStopLaser [

	| grid cell |
	grid := self generateDemoGrid.
	grid stopLaser.
	self shouldnt: [ grid laserIsActive ].
	cell := grid startingCell.
	self should: [ cell isOff ].
	cell := grid at: 5@1.
	self should: [ cell isOff ]	
]

{ #category : #tests }
GridTestCase >> testToggleLaser [

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	grid stopLaser.
	self shouldnt: [ grid laserIsActive ].
	cell := grid startingCell.
	self should: [ cell isOff ].
	cell := grid at: 5 @ 1.
	self should: [ cell isOff ]
]

{ #category : #tests }
GridTestCase >> testUndoActions [
	| undoAction |
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #north.
	self should: [undoAction = #pushCellSouthFromLocation:].
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #east.
	self should: [undoAction = #pushCellWestFromLocation:].
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #south.
	self should: [undoAction = #pushCellNorthFromLocation:].
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #west.
	self should: [undoAction = #pushCellEastFromLocation:].
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #clockwise.
	self should: [undoAction = #rotateCellCounterClockwiseAt:].
	undoAction := ReverseLaserGameAction reverseActionSymbolFor: #counterClockwise.
	self should: [undoAction = #rotateCellClockwiseAt:].

]

{ #category : #tests }
GridTestCase >> testUndoStackAfterPush [
	| grid |
	grid := self generateDemoGrid.
	self should: [grid movesStack isEmpty].
	grid pushCellEastFromLocation: 1@2.
	self should: [grid movesStack size = 1].
	self should: [grid undo].
	self shouldnt: [grid undo].
	
]
