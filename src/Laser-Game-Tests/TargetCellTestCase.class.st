Class {
	#name : #TargetCellTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
TargetCellTestCase >> testCellExitSides [

	| cell inputSides |
	cell := TargetCell new.
	inputSides := #( #north #east #south #west ).
	inputSides do: [ :inputSide |
		| exit |
		exit := cell exitSideFor: inputSide.
		self should: [ exit isNil ] ]
]

{ #category : #tests }
TargetCellTestCase >> testCellLaserActivity [ 
|cell|
cell := TargetCell new.
cell laserEntersFrom: #north.
self should: [ cell isOn ].
self should: [ cell isSegmentOnFor: #north ].
self shouldnt: [ cell isSegmentOnFor: #south ].
self shouldnt: [ cell isSegmentOnFor: #east ].
self shouldnt: [ cell isSegmentOnFor: #west ]
]

{ #category : #tests }
TargetCellTestCase >> testCellOnState [ 
|cell|
cell := TargetCell new.
self should: [ cell isOff ].
self shouldnt: [ cell isOn ].
]

{ #category : #tests }
TargetCellTestCase >> testCellSegmentState [ 
|cell|
cell := TargetCell new.
self shouldnt: [ cell isSegmentOnFor: #north ].
self shouldnt: [ cell isSegmentOnFor: #east ].
self shouldnt: [ cell isSegmentOnFor: #south ].
self shouldnt: [ cell isSegmentOnFor: #west ].
]
