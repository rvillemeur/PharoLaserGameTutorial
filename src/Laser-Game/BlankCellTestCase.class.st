Class {
	#name : #BlankCellTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
BlankCellTestCase >> testCellExitSides [

	| cell exit |
	cell := BlankCell new.
	exit := cell exitSideFor: #north.
	self assert: exit equals: #south.
	
	exit := cell exitSideFor: #east.
	self assert: exit equals: #west.

	exit := cell exitSideFor: #south.
	self assert: exit equals: #north.

	exit := cell exitSideFor: #west.
	self assert: exit equals: #east
]

{ #category : #tests }
BlankCellTestCase >> testCellLaserActivity [

	| cell |
	cell := BlankCell new.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self assert: (cell isSegmentOnFor: #south).
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : #tests }
BlankCellTestCase >> testCellOnState [

	| cell |
	cell := BlankCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
]

{ #category : #tests }
BlankCellTestCase >> testCellSegmentState [

	| cell |
	cell := BlankCell new.
	self shouldnt: [ cell isSegmentOnFor: #north ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : #tests }
BlankCellTestCase >> testCellSegmentsState [
	| cell |
	cell := BlankCell new.
	self shouldnt: [cell isSegmentOnFor: #north].
	self shouldnt: [cell isSegmentOnFor: #east].
	self shouldnt: [cell isSegmentOnFor: #south].
	self shouldnt: [cell isSegmentOnFor: #west].
]
