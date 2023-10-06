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
	self should: [ exit = #south ].
	exit := cell exitSideFor: #east.
	self should: [ exit = #west ].

	exit := cell exitSideFor: #south.
	self should: [ exit = #north ].

	exit := cell exitSideFor: #west.
	self should: [ exit = #east ]
]

{ #category : #tests }
BlankCellTestCase >> testCellLaserActivity [

	| cell |
	cell := BlankCell new.
	cell laserEntersFrom: #north.
	self should: [ cell isOn ].
	self should: [ cell isSegmentOnFor: #north ].
	self should: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : #tests }
BlankCellTestCase >> testCellOnState [
|cell|

cell := BlankCell new.
self should: [ cell isOff ].
self shouldnt: [ cell isOn ].

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
