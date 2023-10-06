Class {
	#name : #GridTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
GridTestCase >> generateDemoGrid [

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	grid at: 4 @ 1 put: MirrorCell leanRight.
	grid at: 5 @ 1 put: TargetCell new.
	grid at: 1 @ 1 put: MirrorCell leanRight.
	grid at: 5 @ 2 put: MirrorCell leanLeft.
	grid at: 2 @ 3 put: MirrorCell leanLeft.
	grid at: 3 @ 3 put: MirrorCell leanRight.
	grid at: 5 @ 3 put: MirrorCell leanLeft.
	grid at: 2 @ 4 put: MirrorCell leanLeft.
	grid at: 3 @ 4 put: MirrorCell leanLeft.
	grid at: 1 @ 5 put: MirrorCell leanRight.
	grid at: 4 @ 5 put: MirrorCell leanRight.
	^ grid
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