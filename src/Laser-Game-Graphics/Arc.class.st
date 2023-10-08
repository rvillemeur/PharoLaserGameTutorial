Class {
	#name : #Arc,
	#superclass : #MorphPath,
	#instVars : [
		'center',
		'radius',
		'numberOfVertices'
	],
	#category : #'Laser-Game-Graphics'
}

{ #category : #accessing }
Arc >> center [
	"Answer the point at the center of the receiver."

	^center
]

{ #category : #accessing }
Arc >> center: aPoint [ 
	"Set aPoint to be the receiver's center."

	center := aPoint
]

{ #category : #'displaying - generic' }
Arc >> computeVertices: size [

	| dAngle dSin dCos point |
	dAngle := (90 / (size - 1)) degreesToRadians.
	dSin := dAngle sin.
	dCos := dAngle cos.
	point := (1 to: quadrant)
		inject: 0 @ radius
		into: [:p :i | p leftRotated].
	^ (OrderedCollection new: size)
		add: (center + point) rounded;
		addAll: ((2 to: size) collect: [:i |
			point := point * dCos + (point * dSin) leftRotated.
			(center + point) rounded]);
		yourself
]

{ #category : #'displaying - generic' }
Arc >> displayOn: aDisplayMedium at: aPoint clippingBox: clipRect rule: anInteger fillColor: aForm [

	| line |
	line := Line new.
	line form: self form.
	(self computeVertices: self numberOfVertices) overlappingPairsDo: [:start :dest |
		line
			beginPoint: start;
			endPoint: dest;
			displayOn: aDisplayMedium
				at: aPoint
				clippingBox: clipRect
				rule: anInteger
				fillColor: aForm]
]

{ #category : #'displaying - generic' }
Arc >> displayOn: aDisplayMedium transformation: aTransformation clippingBox: clipRect rule: anInteger fillColor: aForm [

	| newArc tempCenter |
	newArc := Arc new.
	tempCenter := aTransformation applyTo: self center.
	newArc center: tempCenter x asInteger @ tempCenter y asInteger.
	newArc quadrant: self quadrant.
	newArc radius: (self radius * aTransformation scale x) asInteger.
	newArc form: self form.
	newArc
		displayOn: aDisplayMedium
		at: 0 @ 0
		clippingBox: clipRect
		rule: anInteger
		fillColor: aForm
]

{ #category : #accessing }
Arc >> numberOfVertices [

	^ numberOfVertices ifNil: [12]
]

{ #category : #accessing }
Arc >> numberOfVertices: anInteger [

	numberOfVertices := anInteger.
]

{ #category : #accessing }
Arc >> radius [
	"Answer the receiver's radius."

	^radius
]

{ #category : #accessing }
Arc >> radius: anInteger [ 
	"Set the receiver's radius to be the argument, anInteger."

	radius := anInteger
]
