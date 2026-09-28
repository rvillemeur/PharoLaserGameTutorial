"
I check the random game generator of page 145: what a randomized grid holds, and that it is the same grid twice from the same seed.

Every test deals from a fixed seed and puts the generator back on the clock afterwards, so the tests are repeatable and the game still deals a different board every time it is played.
"
Class {
	#name : 'GridFactoryTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game',
	#tag : 'Tests'
}

{ #category : 'helpers' }
GridFactoryTestCase >> cellsOf: aGrid [
	"Answer every cell of aGrid, in no particular order."

	| cells |
	cells := OrderedCollection new.
	1 to: aGrid numberOfColumns do: [ :x |
		1 to: aGrid numberOfRows do: [ :y | cells add: (aGrid at: x @ y) ] ].
	^ cells
]

{ #category : 'running' }
GridFactoryTestCase >> setUp [
	"Deal from a known seed, so a randomized board is the same board every run."

	super setUp.
	GridFactory randomNumberGenerator seed: 42
]

{ #category : 'running' }
GridFactoryTestCase >> tearDown [
	"Put the generator back on the clock, so a game deals a different board every time."

	GridFactory reSeed.
	super tearDown
]

{ #category : 'tests' }
GridFactoryTestCase >> testAGridOfAnyExtentIsDealtReadyToPlay [
	"Page 147 builds a board of any size and deals it in one message: the grid is made, the target
	goes in the top right corner of that grid, and the mirrors follow the size of the board.
	Eight by ten is the board of page 148."

	| grid |
	grid := GridFactory randomizedGridOfExtent: 8 @ 10.
	self assert: grid numberOfColumns equals: 8.
	self assert: grid numberOfRows equals: 10.
	self assert: (grid at: 8 @ 1) class equals: TargetCell.
	self assert: grid numberOfMirrors equals: 32.
	self
		assert: ((self cellsOf: grid) count: [ :cell | cell isKindOf: TargetCell ])
		equals: 1
]

{ #category : 'tests' }
GridFactoryTestCase >> testARandomizedGridHoldsNothingButBlanksMirrorsAndTheTarget [
	"Page 145 deals mirrors onto an empty board and puts one target on it."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	(self cellsOf: grid) do: [ :cell |
		self assert:
			({ BlankCell. MirrorCell. TargetCell } includes: cell class) ]
]

{ #category : 'tests' }
GridFactoryTestCase >> testARandomizedGridPutsTheTargetInTheTopRightCorner [
	"Page 147 reads the corner from the grid, where page 145 writes 5@1 for the board it has. Both
	are the same cell on a five by five board."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: (grid at: 5 @ 1) class equals: TargetCell.
	self
		assert: ((self cellsOf: grid) count: [ :cell | cell isKindOf: TargetCell ])
		equals: 1
]

{ #category : 'tests' }
GridFactoryTestCase >> testBothMirrorsAreDealt [
	"A dealt mirror leans either way, and over enough deals both come up."

	| leans |
	leans := ((1 to: 200) collect: [ :each |
		          GridFactory randomizedMirrorCell isLeft ]) asSet.
	self assert: (leans includes: true).
	self assert: (leans includes: false)
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheDefaultGridIsTheStandardBoard [
	"The board page 148 plays on is eight columns by ten rows, dealt. That is the board the
	inherited source calls the default one, and it is what the game opens on from this section."

	| grid |
	grid := GridFactory defaultGrid.
	self assert: grid numberOfColumns equals: 8.
	self assert: grid numberOfRows equals: 10.
	self assert: (grid at: 8 @ 1) class equals: TargetCell.
	self assert: grid numberOfMirrors equals: 32
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheMirrorsStandOneToACellAndAwayFromTheTarget [
	"Page 145 deals its mirrors onto locations it has not used yet, and it starts with the target
	marked used, so every mirror it deals is still on the board afterwards and none of them is on
	the target. A five by five board takes ten mirrors, which is the number page 145 writes down
	before page 147 derives it from the size of the board."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 10
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheNumberOfMirrorsFollowsTheSizeOfTheBoard [
	"Page 147 asks for one mirror per two and a half cells, which is ten on the board of page 145
	and thirty-two on the standard board."

	| grid |
	grid := Grid newOfSize: 8 @ 10.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 32
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheSameSeedDealsTheSameBoard [
	"The generator is seeded, so the same seed deals the same board. That is what #reSeed is for:
	page 145 adds it to make the next game differ from this one."

	| first second |
	GridFactory randomNumberGenerator seed: 1234.
	first := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: first.
	GridFactory randomNumberGenerator seed: 1234.
	second := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: second.
	1 to: 5 do: [ :x |
		1 to: 5 do: [ :y |
			| here there |
			here := first at: x @ y.
			there := second at: x @ y.
			self assert: here class equals: there class.
			here class = MirrorCell ifTrue: [
				self assert: here isLeft equals: there isLeft ] ] ]
]

{ #category : 'tests' }
GridFactoryTestCase >> testTheTargetCornerIsMarkedUsedOnABoardOfAnySize [
	"Page 147 marks the top right corner of the board used before a single mirror is dealt, so the
	target keeps its cell whatever the size of the board. The dictionary holds one flag per
	location, false for the locations still free."

	| grid flags |
	grid := Grid newOfSize: 8 @ 10.
	flags := GridFactory emptyRandomLocationsFor: grid.
	self assert: flags size equals: 80.
	self assert: (flags at: 8 @ 1).
	self
		assert: (flags keys count: [ :each | flags at: each ])
		equals: 1
]
