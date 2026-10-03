"
I build the grids the game is played on.

`demoGrid` is the hand-made board the tests and the examples use. `defaultGrid` is the board the game opens on: eight columns by ten rows, dealt. `randomizedGridOfExtent:` deals a board of any size.

`randomizeGrid:` deals a board with its target in the top right corner, and `randomizeGrid:targetAt:` puts the target in the corner it is given. Either way it deals mirrors onto locations it has not used yet, one for every two and a half cells of the board. It writes onto the grid it is given and clears nothing, which is why `LaserGameElement >> newGame` empties the grid first.

```
GridFactory randomizedGridOfExtent: 8@10
```

`randomNumberGenerator` holds one seeded `Random` for the whole class, seeded from the clock the first time it is asked for, and `reSeed` puts it back on the clock. A test that wants the same board twice seeds it itself.
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
	"Answer the board a new game is dealt on: eight columns by ten rows, randomized."

	^self randomizedGridOfExtent: 8@10
]

{ #category : 'instance creation' }
GridFactory class >> demoGrid [
	"Answer a five by five grid holding ten mirrors and one target, always the same ones. The
	tests use it whenever a board with something on it is needed, and so do the examples."

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
	"Answer a flag per location of aGrid, true where a cell has been taken. Every location starts
	free but the corner the target stands in."
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
	"Answer true or false, each as likely as the other."

	| int |
	int := self randomNumberGenerator nextInteger: 2.
	^int > 1
]

{ #category : 'randomizing' }
GridFactory class >> randomNumberGenerator [
	"Answer the one generator the class deals from, seeded from the clock the first time it is
	asked for."
	RandomNumberGenerator isNil ifTrue: [
		RandomNumberGenerator := Random new.
		RandomNumberGenerator seed: Time totalSeconds].
	^RandomNumberGenerator
]

{ #category : 'randomizing' }
GridFactory class >> randomizeGrid: aGrid [
	"Deal mirrors and a target onto aGrid, with the target in the top right corner of whatever
	board it is."
	self randomizeGrid: aGrid targetAt: (aGrid numberOfColumns@1)
]

{ #category : 'randomizing' }
GridFactory class >> randomizeGrid: aGrid targetAt: pt [
	"Deal a target at pt and mirrors onto aGrid: one mirror per two and a half cells, each on a
	location no other mirror took and none of them on the target. The cells of aGrid are not
	cleared, so a board that is being dealt again is emptied first."
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
	"Answer a board of ext columns by ext rows, dealt ready to play: the target in the top right
	corner of that board, and the mirrors of that size."
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
	"Seed the generator from the clock again, so the next board dealt differs from this one."
	self randomNumberGenerator seed: Time totalSeconds
]

{ #category : 'randomizing' }
GridFactory class >> unusedRandomLocationIn: list forGrid: aGrid [
	"Answer a location of aGrid that list does not hold yet, and mark it used. nextInteger: answers
	one of 1 to the number asked for, so the location is always on the board."

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
