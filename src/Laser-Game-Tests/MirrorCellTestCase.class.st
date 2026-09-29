Class {
	#name : 'MirrorCellTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'tests' }
MirrorCellTestCase >> testCellExitSidesMirrorLeft [

	| cell exit |
	cell := MirrorCell new.
	cell leanLeft.

	exit := cell exitSideFor: #north.
	self assert: exit equals: #east.

	exit := cell exitSideFor: #east.
	self assert: exit equals: #north.

	exit := cell exitSideFor: #south.
	self assert: exit equals: #west.

	exit := cell exitSideFor: #west.
	self assert: exit equals: #south
]

{ #category : 'tests' }
MirrorCellTestCase >> testCellExitSidesMirrorRight [

	| cell exit |
	cell := MirrorCell new.
	cell leanRight.

	exit := cell exitSideFor: #north.
	self assert: exit equals: #west.

	exit := cell exitSideFor: #east.
	self assert: exit equals: #south.

	exit := cell exitSideFor: #south.
	self assert: exit equals: #east.

	exit := cell exitSideFor: #west.
	self assert: exit equals: #north
]

{ #category : 'tests' }
MirrorCellTestCase >> testCellLaserActivityMirrorLeft [

	| cell |
	cell := MirrorCell leanLeft.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self assert: (cell isSegmentOnFor: #east).
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : 'tests' }
MirrorCellTestCase >> testCellLaserActivityMirrorRight [

	| cell |
	cell := MirrorCell leanRight.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self assert: (cell isSegmentOnFor: #west).
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #east ]
]

{ #category : 'tests' }
MirrorCellTestCase >> testCellOnState [

	| cell |
	cell := MirrorCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
]

{ #category : 'tests' }
MirrorCellTestCase >> testCellRotate [

	| cell |
	cell := MirrorCell new.
	cell leanLeft.
	self assert: cell isLeft.
	self assert: (cell exitSideFor: #south) equals: #west.
	cell rotateClockwise.
	self assert: cell isRight.
	self assert: (cell exitSideFor: #south) equals: #east.
	cell rotateCounterClockwise.
	self assert: cell isLeft.
	self assert: (cell exitSideFor: #south) equals: #west
]

{ #category : 'tests' }
MirrorCellTestCase >> testCellSegmentState [

	| cell |
	cell := MirrorCell  new.
	self shouldnt: [ cell isSegmentOnFor: #north ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : 'tests' }
MirrorCellTestCase >> testCellSegmentsState [
	| cell |
	cell := MirrorCell new.
	self shouldnt: [cell isSegmentOnFor: #north].
	self shouldnt: [cell isSegmentOnFor: #east].
	self shouldnt: [cell isSegmentOnFor: #south].
	self shouldnt: [cell isSegmentOnFor: #west].
]

{ #category : 'tests' }
MirrorCellTestCase >> testPrintStringSaysWhereTheCellIsHowItLeansAndWhetherItIsOn [
	"Page 108 of the original improves what a cell shows in a debugger. Pharo prints objects on
	one line, in lists, in inspector headers and in the code pane, so the port says the same
	things in one line and lets the inspector show the rest."

	| cell |
	cell := MirrorCell leanLeft.
	cell gridLocation: 4 @ 1.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans left, off)'.
	cell rotate.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans right, off)'.
	cell laserEntersFrom: #north.
	self assert: cell printString equals: 'a MirrorCell(4@1 leans right, on)'
]

{ #category : 'tests' }
MirrorCellTestCase >> testTheSidesTabListsTheFourSidesOfTheCell [
	"Page 108 of the original wants a cell to say more about itself while it is being debugged. In
	Pharo that belongs in an inspector tab, and the tab has one row per side, which is where the
	bug of page 110 becomes visible: the exit sides of a rotated mirror."

	| cell table |
	cell := MirrorCell leanRight.
	cell gridLocation: 4 @ 1.
	table := cell inspectionSides:
		         (SpPresenterBuilder new
			          application: SpApplication new;
			          yourself).
	self assert: table items asArray equals: #( #north #east #south #west ).
	self assert: table columns size equals: 3
]
