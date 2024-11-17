Class {
	#name : #MirrorCellTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
MirrorCellTestCase >> testCellExitSidesMirrorLeft [

	| cell exit |
	cell := MirrorCell new.
	cell leanLeft.

	exit := cell exitSideFor: #north.
	self should: [ exit = #east ].

	exit := cell exitSideFor: #east.
	self should: [ exit = #north ].

	exit := cell exitSideFor: #south.
	self should: [ exit = #west ].

	exit := cell exitSideFor: #west.
	self should: [ exit = #south ]
]

{ #category : #tests }
MirrorCellTestCase >> testCellExitSidesMirrorRight [

	| cell exit |
	cell := MirrorCell new.
	cell leanRight .

	exit := cell exitSideFor: #north.
	self should: [ exit = #west ].

	exit := cell exitSideFor: #east.
	self should: [ exit = #south ].

	exit := cell exitSideFor: #south.
	self should: [ exit = #east ].

	exit := cell exitSideFor: #west.
	self should: [ exit = #north ]
]

{ #category : #tests }
MirrorCellTestCase >> testCellLaserActivityMirrorLeft [
|cell|
cell := MirrorCell leanLeft .
cell laserEntersFrom: #north.
self should: [ cell isOn ].
self should: [ cell isSegmentOnFor: #north ].
self should: [ cell isSegmentOnFor: #east  ].
self shouldnt: [ cell isSegmentOnFor: #south ].
self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : #tests }
MirrorCellTestCase >> testCellLaserActivityMirrorRight [
|cell|
cell := MirrorCell leanRight .
cell laserEntersFrom: #north.
self should: [ cell isOn ].
self should: [ cell isSegmentOnFor: #north ].
self should: [ cell isSegmentOnFor: #west  ].
self shouldnt: [ cell isSegmentOnFor: #south ].
self shouldnt: [ cell isSegmentOnFor: #east ]
]

{ #category : #tests }
MirrorCellTestCase >> testCellOnState [
|cell|

cell := MirrorCell  new.
self should: [ cell isOff ].
self shouldnt: [ cell isOn ].

]

{ #category : #tests }
MirrorCellTestCase >> testCellRotate [
	| cell |
	cell := MirrorCell new.
	cell leanLeft.
	self should: [cell isLeft].
	self should: [(cell exitSideFor: #south) = #west].
	cell rotateClockwise.
	self should: [cell isRight].
	self should: [(cell exitSideFor: #south) = #east].
	cell rotateCounterClockwise.
	self should: [cell isLeft].
	self should: [(cell exitSideFor: #south) = #west].

]

{ #category : #tests }
MirrorCellTestCase >> testCellSegmentState [

	| cell |
	cell := MirrorCell  new.
	self shouldnt: [ cell isSegmentOnFor: #north ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : #tests }
MirrorCellTestCase >> testCellSegmentsState [
	| cell |
	cell := MirrorCell new.
	self shouldnt: [cell isSegmentOnFor: #north].
	self shouldnt: [cell isSegmentOnFor: #east].
	self shouldnt: [cell isSegmentOnFor: #south].
	self shouldnt: [cell isSegmentOnFor: #west].
]
