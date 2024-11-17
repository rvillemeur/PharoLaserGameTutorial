Class {
	#name : #GridFactory,
	#superclass : #Object,
	#classVars : [
		'RandomNumberGenerator'
	],
	#category : #'Laser-Game-Model'
}

{ #category : #'as yet unclassified' }
GridFactory class >> defaultGrid [
	^self randomizedGridOfExtent: 8@10
]

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
GridFactory class >> emptyStandardGrid [
	^Grid newOfSize: 8@10
]

{ #category : #'as yet unclassified' }
GridFactory class >> randomBoolean [
	| int |
	int := self randomNumberGenerator nextInt: 2.
	^int > 1
]

{ #category : #'as yet unclassified' }
GridFactory class >> randomNumberGenerator [
	RandomNumberGenerator isNil ifTrue: [
		RandomNumberGenerator := Random new.
		RandomNumberGenerator seed: Time totalSeconds].
	^RandomNumberGenerator
]

{ #category : #'as yet unclassified' }
GridFactory class >> randomizeGrid: aGrid [
	self randomizeGrid: aGrid targetAt: (aGrid numberOfColumns@1)
]

{ #category : #'as yet unclassified' }
GridFactory class >> randomizeGrid: aGrid targetAt: pt [
	| emptyList loc howMany |
	emptyList := self emptyRandomLocationsFor: aGrid.
	aGrid at: pt put: TargetCell new.
	howMany := ((aGrid numberOfColumns * aGrid numberOfRows) / 2.5) rounded.
	howMany timesRepeat: [
		loc := self unusedRandomLocationIn: emptyList forGrid: aGrid.
		aGrid at: loc put: self randomizedMirrorCell]
]

{ #category : #'as yet unclassified' }
GridFactory class >> randomizedGridOfExtent: ext [
	| grid |
	grid := Grid newOfSize: ext.
	self randomizeGrid: grid targetAt: ((ext x)@1).
	^grid
]

{ #category : #'as yet unclassified' }
GridFactory class >> randomizedMirrorCell [
	^self randomBoolean
		ifTrue: [MirrorCell leanLeft]
		ifFalse: [MirrorCell leanRight]
]

{ #category : #'as yet unclassified' }
GridFactory class >> reSeed [
	self randomNumberGenerator seed: Time totalSeconds
]

{ #category : #'as yet unclassified' }
GridFactory class >> unusedRandomLocationIn: list forGrid: aGrid [
	| x y pt |
	[
	x := self randomNumberGenerator nextInt: aGrid numberOfColumns.
	y := self randomNumberGenerator nextInt: aGrid numberOfRows.
	pt := x@y.
	list at: pt
	] whileTrue: [].
	list at: pt put: true.
	^pt
]
