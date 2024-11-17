Class {
	#name : #Circle,
	#superclass : #Arc,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'accessing - display box' }
Circle >> computeBoundingBox [

	^center - radius + form offset extent: form extent + (radius * 2) asPoint
]

{ #category : #'accessing - display box' }
Circle >> displayOn: aDisplayMedium at: aPoint clippingBox: clipRect rule: anInteger fillColor: aForm [

	1 to: 4 do:
		[:i |
		super quadrant: i.
		super displayOn: aDisplayMedium
			at: aPoint
			clippingBox: clipRect
			rule: anInteger
			fillColor: aForm]
]

{ #category : #'as yet unclassified' }
Circle >> displayOn: aDisplayMedium transformation: aTransformation clippingBox: clipRect rule: anInteger fillColor: aForm [

	1 to: 4 do:
		[:i |
		super quadrant: i.
		super displayOn: aDisplayMedium
			transformation: aTransformation
			clippingBox: clipRect
			rule: anInteger
			fillColor: aForm]
]
