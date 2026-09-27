"
I am the repository of the shapes the game draws on top of its cells: the four push arrows and the cross hair.

I hold each shape as a vertex array in the coordinates the original drew it in, around 260 pixels wide, and I answer elements: `pointsOf:scaledToExtent:` stretches an array onto the rectangle a caller asks for, and `arrowElementFromPoints:ofExtent:` wraps the result in a `BlElement` with a `BlPolygonGeometry`. A shape therefore has no size of its own, and the same array serves a hint of twelve pixels and a drawing of two hundred.

I replace `LaserGameForms` of pages 081 to 083, which cached one `Form` per shape. It drew an outline line by line into a form of 330 pixels, flood filled the inside, reversed black and white so that only the filled pixels would be painted, and scaled the bitmap down at the point of use. A polygon geometry is filled by the renderer and drawn at any size, so the workspace experiments of pages 081 and 082, the flood fill, the reversal and the cache all have no counterpart here. What survives from them is the numbers: my four vertex arrays are the ones those pages typed in.

I am a class-side repository: no instance of me is ever created. The colours I paint with, `arrowColor` and `crossHairColor`, are the defaults of the original drawings; a caller that knows whether a move is allowed sets its own on the element it gets.

"
Class {
	#name : 'LaserGameShapes',
	#superclass : 'Object',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'accessing' }
LaserGameShapes class >> arrowColor [
	"Answer the colour an arrow is painted in when nobody says otherwise: the grey of page 081.
	A caller that knows more sets its own, as the hints do from Section 4 on."

	^ Color gray
]

{ #category : 'building' }
LaserGameShapes class >> arrowElementFromPoints: anArrayOfPoints ofExtent: anExtent [
	"Answer an element of anExtent whose geometry is the outline anArrayOfPoints describes. The
	outline is a polygon, so it is drawn at whatever size it is given and needs no flood fill:
	the original drew the outline line by line, filled the inside with black and reversed the
	form, which is what pages 081 and 082 spend their workspace code on."

	^ BlElement new
		  geometry: (BlPolygonGeometry vertices:
					   (self pointsOf: anArrayOfPoints scaledToExtent: anExtent));
		  extent: anExtent;
		  background: self arrowColor;
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> crossHairBarOfExtent: aBarExtent within: anExtent [
	"Answer one bar of a cross hair, centred in a shape of anExtent."

	^ BlElement new
		  extent: aBarExtent;
		  position: (anExtent - aBarExtent) / 2;
		  background: self crossHairColor;
		  yourself
]

{ #category : 'accessing' }
LaserGameShapes class >> crossHairColor [
	"Answer the colour of a cross hair: the black page 083 drew it in."

	^ Color black
]

{ #category : 'building' }
LaserGameShapes class >> crossHairElementOfExtent: anExtent [
	"Answer a cross hair of anExtent: two bars crossing at the centre. Page 083 drew the same
	figure as two lines in a form of one cell, and Section 3.6 puts it under the pointer while
	the pointer is over a mirror."

	| span thickness |
	span := (anExtent x min: anExtent y) // 3.
	thickness := (span // 5) max: 1.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self crossHairBarOfExtent: span @ thickness within: anExtent);
		  addChild: (self crossHairBarOfExtent: thickness @ span within: anExtent);
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> eastArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points east."

	^ self arrowElementFromPoints: self eastArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> eastArrowPoints [
	"Answer the outline of an arrow that points east, as the original typed it into a workspace
	on page 081."

	^ { 0 @ 80. 150 @ 80. 150 @ 0. 260 @ 100. 150 @ 200. 150 @ 120. 0 @ 120 }
]

{ #category : 'building' }
LaserGameShapes class >> northArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points north."

	^ self arrowElementFromPoints: self northArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> northArrowPoints [
	"Answer the outline of an arrow that points north, as the original typed it into a workspace
	on page 082. The numbers are the ones LaserGameForms holds."

	^ { 100 @ 0. 200 @ 110. 120 @ 110. 120 @ 260. 80 @ 260. 80 @ 110. 0 @ 110 }
]

{ #category : 'scaling' }
LaserGameShapes class >> pointsOf: anArrayOfPoints scaledToExtent: anExtent [
	"Answer anArrayOfPoints moved to the origin and stretched to fill anExtent exactly. The
	vertex arrays are written at the size the original drew them at, around 260 pixels, and every
	user asks for the size it needs. The original could not do this: it drew one 330 pixel bitmap
	per arrow, cached it, and scaled the pixels afterwards."

	| bounds scale |
	bounds := Rectangle encompassing: anArrayOfPoints.
	scale := anExtent x / bounds width @ (anExtent y / bounds height).
	^ anArrayOfPoints collect: [ :each |
		  ((each - bounds origin) * scale) asFloatPoint ]
]

{ #category : 'building' }
LaserGameShapes class >> southArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points south."

	^ self arrowElementFromPoints: self southArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> southArrowPoints [
	"Answer the outline of an arrow that points south, as the original typed it into a workspace
	on page 082."

	^ { 100 @ 260. 0 @ 150. 80 @ 150. 80 @ 0. 120 @ 0. 120 @ 150. 200 @ 150 }
]

{ #category : 'building' }
LaserGameShapes class >> westArrowElementOfExtent: anExtent [
	"Answer an arrow of anExtent that points west."

	^ self arrowElementFromPoints: self westArrowPoints ofExtent: anExtent
]

{ #category : 'vertices' }
LaserGameShapes class >> westArrowPoints [
	"Answer the outline of an arrow that points west, as the original typed it into a workspace
	on page 082."

	^ { 260 @ 80. 110 @ 80. 110 @ 0. 0 @ 100. 110 @ 200. 110 @ 120. 260 @ 120 }
]
