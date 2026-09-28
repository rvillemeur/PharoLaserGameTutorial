Class {
	#name : 'LaserGameForms',
	#superclass : 'Object',
	#classVars : [
		'CachedForms'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'as yet unclassified' }
LaserGameForms class >> arrowFormFromPointArray: pts [

	| form fillForm index startPoint nextIndex endPoint line offset |
	offset := 2 @ 2.
	form := Form extent: 330 @ 330 depth: 1.
	form fillColor: Color white.
	fillForm := Form extent: 1 @ 1 depth: 1.
	fillForm fillColor: Color black.
	index := 1.
	[ index <= pts size ] whileTrue: [
		startPoint := pts at: index.
		nextIndex := index = pts size
			             ifTrue: [ 1 ]
			             ifFalse: [ index + 1 ].
		endPoint := pts at: nextIndex.
		startPoint := startPoint + offset.
		endPoint := endPoint + offset.
		line := Line from: startPoint to: endPoint withForm: fillForm.
		line displayOn: form.
		index := index + 1 ].
	"form floodFillTolerance: (Color black at: 1@1."
	form reverse.
	^ form
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> arrowFormFromPointsArray: pts [
	"LaserGameForms initializeCachedForms"
	| form fillForm index startPoint nextIndex endPoint line offset |
	offset := 2@2.
	form := Form extent: 330@330 depth: 1.
	form fillColor: Color white.
	fillForm := Form extent: 1@1 depth: 1.
	fillForm fillColor: Color black.
	index := 1.
	[index <= pts size] whileTrue: [
		startPoint := pts at: index.
		nextIndex := index = pts size
			ifTrue: [1]
			ifFalse: [index + 1].
		endPoint := pts at: nextIndex.
		startPoint := startPoint + offset.
		endPoint := endPoint + offset.
		line := Line from: startPoint to: endPoint withForm: fillForm.
		line displayOn: form.
		index := index + 1].
	form floodFill: Color black at: 1@1.
	form reverse.
	^form copy: (form tightRectangleAroundColor: Color black)
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> clockwiseArrow [
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #clockwise
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> counterClockwiseArrow [
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #counterClockwise
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> drawClockWiseArrow [

	^ self drawConterClockWiseArrow flipBy: #horizonal centerAt: 0 @ 0
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> drawClockwiseArrow [
	^self drawCounterClockwiseArrow flipBy: #horizontal centerAt: 0@0
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> drawConterClockWiseArrow [

	| form penForm |
	form := Form extent: 450 @ 450 depth: 1.
	form fillColor: Color white.
	penForm := Form extent: 1 @ 1 depth: 1.
	penForm fillColor: Color black.
	self drawCounterClockWiseArrowHeadOn: form withPen: penForm.  
	^ form
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> drawCounterClockWiseArrowHeadOn: form withPen: penForm [

	| arrowPts index offset startPoint nextIndex endPoint line |
	arrowPts := {
		            (100 @ 260).
		            (40 @ 150).
		            (80 @ 150).
		            (80 @ 141).
		            (120 @ 141).
		            (120 @ 150).
		            (160 @ 150) }.
	index := 1.
	offset := 2 @ 100.
	[ index <= arrowPts size ] whileTrue: [
		startPoint := arrowPts at: index.
		nextIndex := index = arrowPts size
			             ifTrue: [ 1 ]
			             ifFalse: [ index + 1 ].
		endPoint := arrowPts at: nextIndex.
		startPoint := startPoint + offset.
		endPoint := endPoint + offset.
		line := Line from: startPoint to: endPoint withForm: penForm.
		line displayOn: form.
		index := index + 1 ].
	form fill: Color black
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> drawCounterClockwiseArcsOn: form withPen: penForm [
	| center outsideCircle insideCircle line bigPen |
	center := 282@240.
	outsideCircle := Arc new.
	outsideCircle quadrant: 2.
	outsideCircle form: penForm.
	outsideCircle radius: 200.
	outsideCircle center: center.
	outsideCircle displayOn: form.
	outsideCircle quadrant: 1.
	outsideCircle displayOn: form.
	insideCircle := Arc new.
	insideCircle quadrant: 2.
	insideCircle form: penForm.
	insideCircle radius: 160.
	insideCircle center: center.
	insideCircle displayOn: form.
	insideCircle quadrant: 1.
	insideCircle displayOn: form.
	line := Line from: center to: (form extent x@0) withForm: penForm.
	line displayOn: form.
	form floodFill: Color black at: 100@235.
	bigPen := Form extent: 100@100 depth: 1.
	bigPen fillColor: Color white.
	line form: bigPen.
	line displayOn: form.

]

{ #category : 'as yet unclassified' }
LaserGameForms class >> drawCounterClockwiseArrow [
	| form penForm |
	form := Form extent: 450@450 depth: 1.
	form fillColor: Color white.
	penForm := Form extent: 1@1 depth: 1.
	penForm fillColor: Color black.
	self drawCounterClockwiseArrowHeadOn: form withPen: penForm.
	self drawCounterClockwiseArcsOn: form withPen: penForm.
	^form

]

{ #category : 'as yet unclassified' }
LaserGameForms class >> drawCounterClockwiseArrowHeadOn: form withPen: penForm [
	| arrowPts index offset startPoint nextIndex endPoint line |
	arrowPts := {100@260. 40@150. 80@150. 80@141. 120@141. 120@150. 160@150}.
	index := 1.
	offset := 2@100.
	[index <= arrowPts size] whileTrue: [
		startPoint := arrowPts at: index.
		nextIndex := index = arrowPts size
			ifTrue: [1]
			ifFalse: [index + 1].
		endPoint := arrowPts at: nextIndex.
		startPoint := startPoint + offset.
		endPoint := endPoint + offset.
		line := Line from: startPoint to: endPoint withForm: penForm.
		line displayOn: form.
		index := index + 1].
	form floodFill: Color black at: 100@255.

]

{ #category : 'as yet unclassified' }
LaserGameForms class >> eastArrow [
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #east
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> eastArrowPoints [
	^{0@80. 150@80. 150@0. 260@100. 150@200. 150@120. 0@120}
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> initialize [
	super initialize.
	LaserGameForms initializeCachedForms
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> initializeCachedForms [
	"LaserGameForms initializeCachedForms"
	| form |
	CachedForms := Dictionary new.
	form := self arrowFormFromPointsArray: self northArrowPoints.
	CachedForms at: #north put: form.
	form := self arrowFormFromPointsArray: self eastArrowPoints.
	CachedForms at: #east put: form.
	form := self arrowFormFromPointsArray: self southArrowPoints.
	CachedForms at: #south put: form.
	form := self arrowFormFromPointsArray: self westArrowPoints.
	CachedForms at: #west put: form.
	form := self drawCounterClockwiseArrow.
	CachedForms at: #counterClockwise put: form.
	form := self drawClockwiseArrow.
	CachedForms at: #clockwise put: form.

]

{ #category : 'as yet unclassified' }
LaserGameForms class >> northArrow [
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #north
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> northArrowPoints [
	^{100@0. 200@110. 120@110. 120@260. 80@260. 80@110. 0@110}
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> southArrow [
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #south
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> southArrowPoints [
	^{100@260. 0@150. 80@150. 80@0. 120@0. 120@150. 200@150}
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> westArrow [
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #west
]

{ #category : 'as yet unclassified' }
LaserGameForms class >> westArrowPoints [
	^{260@80. 110@80. 110@0. 0@100. 110@200. 110@120. 260@120}
]
