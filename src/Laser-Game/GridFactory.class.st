"
I build the grids the game is played on.

`demoGrid` is the hand-made board of Section 1, the one the tests and the examples of the earlier sections use. `defaultGrid` is the board of page 148: eight columns by ten rows, dealt. `randomizedGridOfExtent:` deals a board of any size, which is page 147's way of making the game bigger.

`randomizeGrid:` is the random game generator of page 145, and `randomizeGrid:targetAt:` the generalized one of page 147: it puts a target in the corner it is given and deals mirrors onto locations it has not used yet, one for every two and a half cells of the board. It writes onto the grid it is given and clears nothing, which is why `LaserGameElement >> newGame` empties the grid first.

```
GridFactory randomizedGridOfExtent: 8@10
```

`randomNumberGenerator` holds one seeded `Random` for the whole class, seeded from the clock the first time it is asked for, and `reSeed` puts it back on the clock. A test that wants the same board twice seeds it itself. The original calls `#nextInt:`, which is the Squeak name of Pharo's `#nextInteger:`; that is the only change these methods needed.
"
Class {
	#name : 'GridFactory',
	#superclass : 'Object',
	#classVars : [
		'RandomNumberGenerator'
	],
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'instance creation' }
GridFactory class >> defaultGrid [
	^self randomizedGridOfExtent: 8@10
]

{ #category : 'instance creation' }
GridFactory class >> demoGrid [
	| grid |
	grid := Grid newOfSize: 5@5.
	grid at: 4@1 put: MirrorCell leanRight.
	grid at: 5@1 put: TargetCell new.
	grid at: 1@2 put: MirrorCell leanRight.
	grid at: 5@2 put: MirrorCell leanLeft.
	grid at: 2@3 put: MirrorCell leanLeft.
	grid at: 3@3 put: MirrorCell leanRight.
	grid at: 5@3 put: MirrorCell leanLeft.
	grid at: 2@4 put: MirrorCell leanLeft.
	grid at: 3@4 put: MirrorCell leanLeft.
	grid at: 1@5 put: MirrorCell leanRight.
	grid at: 4@5 put: MirrorCell leanRight.
	^grid
]

{ #category : 'randomizing' }
GridFactory class >> emptyRandomLocationsFor: aGrid [
	| dict |
	dict := Dictionary new.
	1 to: aGrid numberOfColumns do: [:x |
		1 to: aGrid numberOfRows do: [:y |
			| pt |
			pt := x@y.
			dict at: pt put: false]].
	dict at: (aGrid numberOfColumns)@1 put: true.  "Target Cell"
	^dict
]

{ #category : 'instance creation' }
GridFactory class >> emptyStandardGrid [
	^Grid newOfSize: 8@10
]

{ #category : 'randomizing' }
GridFactory class >> randomBoolean [
	"Answer true or false, each as likely as the other. Squeak's Random answers #nextInt:, which
	Pharo calls #nextInteger:; both answer one of 1 to the number asked for."

	| int |
	int := self randomNumberGenerator nextInteger: 2.
	^int > 1
]

{ #category : 'randomizing' }
GridFactory class >> randomNumberGenerator [
	RandomNumberGenerator isNil ifTrue: [
		RandomNumberGenerator := Random new.
		RandomNumberGenerator seed: Time totalSeconds].
	^RandomNumberGenerator
]

{ #category : 'randomizing' }
GridFactory class >> randomizeGrid: aGrid [
	self randomizeGrid: aGrid targetAt: (aGrid numberOfColumns@1)
]

{ #category : 'randomizing' }
GridFactory class >> randomizeGrid: aGrid targetAt: pt [
	| emptyList loc howMany |
	emptyList := self emptyRandomLocationsFor: aGrid.
	aGrid at: pt put: TargetCell new.
	howMany := ((aGrid numberOfColumns * aGrid numberOfRows) / 2.5) rounded.
	howMany timesRepeat: [
		loc := self unusedRandomLocationIn: emptyList forGrid: aGrid.
		aGrid at: loc put: self randomizedMirrorCell]
]

{ #category : 'instance creation' }
GridFactory class >> randomizedGridOfExtent: ext [
	| grid |
	grid := Grid newOfSize: ext.
	self randomizeGrid: grid targetAt: ((ext x)@1).
	^grid
]

{ #category : 'randomizing' }
GridFactory class >> randomizedMirrorCell [
	^self randomBoolean
		ifTrue: [MirrorCell leanLeft]
		ifFalse: [MirrorCell leanRight]
]

{ #category : 'randomizing' }
GridFactory class >> reSeed [
	self randomNumberGenerator seed: Time totalSeconds
]

{ #category : 'randomizing' }
GridFactory class >> unusedRandomLocationIn: list forGrid: aGrid [
	"Answer a location of aGrid that list does not hold yet, and mark it used. Squeak's #nextInt:
	is Pharo's #nextInteger:; both answer one of 1 to the number asked for, which is a column or a
	row of the grid."

	| x y pt |
	[
	x := self randomNumberGenerator nextInteger: aGrid numberOfColumns.
	y := self randomNumberGenerator nextInteger: aGrid numberOfRows.
	pt := x@y.
	list at: pt
	] whileTrue: [].
	list at: pt put: true.
	^pt
]
