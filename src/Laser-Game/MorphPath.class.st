Class {
	#name : #MorphPath,
	#superclass : #DisplayObject,
	#instVars : [
		'form',
		'collectionOfPoints',
		'quadrant'
	],
	#category : #'Laser-Game-Graphics'
}

{ #category : #'instance creation' }
MorphPath class >> new [

	^self basicNew initializeCollectionOfPoints
]

{ #category : #'instance creation' }
MorphPath class >> new: anInteger [

	^self basicNew initializeCollectionOfPoints: anInteger
]

{ #category : #adding }
MorphPath >> add: aPoint [ 
	"Include aPoint as one of the receiver's elements."

	^collectionOfPoints add: aPoint
]

{ #category : #accessing }
MorphPath >> at: index put: aPoint [ 
	"Store the argument, aPoint, as the point on the receiver's path at position
	index."

	^collectionOfPoints at: index put: aPoint
]

{ #category : #'accessing - display box' }
MorphPath >> computeBoundingBox [ 
	"Refer to the comment in DisplayObject|computeBoundingBox."

	| box |
	box := Rectangle origin: (self at: 1) extent: 0 @ 0.
	collectionOfPoints do: 
		[:aPoint | box swallow: (Rectangle origin: aPoint extent: 0 @ 0)].
	^box
]

{ #category : #'displaying - generic' }
MorphPath >> displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger fillColor: aForm [ 
	"Display this Path--offset by aPoint, clipped by clipRect and the form 
	associated with this Path will be displayedr according to one of the sixteen 
	functions of two logical variables (rule). Also the source form will be first 
	anded with aForm as a mask. Does not effect the state of the Path"

	collectionOfPoints do: 
		[:element | 
		self form
			displayOn: aDisplayMedium
			at: element + aDisplayPoint
			clippingBox: clipRectangle
			rule: ruleInteger
			fillColor: aForm]
]

{ #category : #accessing }
MorphPath >> first [
	"Answer the first point on the receiver's path; included to correspond to 
	OrderedCollection protocol."

	^collectionOfPoints first
]

{ #category : #accessing }
MorphPath >> firstPoint [
	"Answer the first point on the receiver's path."

	^collectionOfPoints first
]

{ #category : #accessing }
MorphPath >> firstPoint: aPoint [ 
	"Replace the first element of the receiver with the new value aPoint. 
	Answer the argument aPoint."

	collectionOfPoints at: 1 put: aPoint.
	^aPoint
]

{ #category : #accessing }
MorphPath >> form [
	"Answer the receiver's form, or, if form is nil, then answer a 1 x 1 black 
	form (a black dot)."

	| aForm |
	form == nil
		ifTrue: 
			[aForm := Form extent: 1 @ 1.
			aForm fillBlack.
			^aForm]
		ifFalse: 
			[^form]
]

{ #category : #accessing }
MorphPath >> form: aForm [ 
	"Make the argument, aForm, be the receiver's form."

	form := aForm
]

{ #category : #initialization }
MorphPath >> initializeCollectionOfPoints [

	collectionOfPoints := OrderedCollection new
]

{ #category : #initialization }
MorphPath >> initializeCollectionOfPoints: anInteger [

	collectionOfPoints := OrderedCollection new: anInteger
]

{ #category : #accessing }
MorphPath >> last [
	"Answer the last point on the receiver's path; included to correspond to 
	OrderedCollection protocol."

	^collectionOfPoints last
]

{ #category : #accessing }
MorphPath >> offset [
	"There are basically two kinds of display objects in the system: those
	that, when asked to transform themselves, create a new object; and those
	that side effect themselves by maintaining a record of the transformation
	request (typically an offset). Path, like Rectangle and Point, is a display
	object of the first kind."

	self shouldNotImplement
]

{ #category : #accessing }
MorphPath >> quadrant [
	"Answer the part of the circle represented by the receiver."
	^quadrant
]

{ #category : #accessing }
MorphPath >> quadrant: section [ 
	"Set the part of the circle represented by the receiver to be the argument, 
	section."

	quadrant := section
]

{ #category : #accessing }
MorphPath >> secondPoint [
	"Answer the second element of the receiver."

	^collectionOfPoints at: 2
]

{ #category : #accessing }
MorphPath >> secondPoint: aPoint [ 
	"Replace the second element of the receiver with the new value aPoint. 
	Answer the argument aPoint."

	collectionOfPoints at: 2 put: aPoint.
	^aPoint
]
