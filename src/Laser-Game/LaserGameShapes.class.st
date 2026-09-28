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

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> arcPointsFromAngle: startDegrees toAngle: stopDegrees radius: aRadius [
	"Answer the points of an arc of aRadius about my rotate arrow centre, running from
	startDegrees to stopDegrees. Angles are measured anticlockwise from east, and the sine is
	subtracted because y grows downwards."

	| center step |
	center := self rotateArrowCenter.
	step := stopDegrees - startDegrees / self rotateArrowArcSteps.
	^ (0 to: self rotateArrowArcSteps) collect: [ :each |
		  | angle |
		  angle := (startDegrees + (each * step)) degreesToRadians.
		  (center x + (aRadius * angle cos))
		  @ (center y - (aRadius * angle sin)) ]
]

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

{ #category : 'shapes' }
LaserGameShapes class >> clockwiseArrowElementOfExtent: anExtent [
	"Answer an element drawing the clockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self clockwiseArrowPoints
		  ofExtent: anExtent
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> clockwiseArrowPoints [
	"Answer the outline of the arrow that turns a mirror clockwise, which page 099 makes by
	flipping the other one horizontally."

	^ self counterClockwiseArrowPoints collect: [ :each |
		  each x negated @ each y ]
]

{ #category : 'shapes' }
LaserGameShapes class >> counterClockwiseArrowElementOfExtent: anExtent [
	"Answer an element drawing the anticlockwise rotate arrow at anExtent."

	^ self
		  arrowElementFromPoints: self counterClockwiseArrowPoints
		  ofExtent: anExtent
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> counterClockwiseArrowPoints [
	"Answer the outline of the arrow that turns a mirror anticlockwise: the head of page 099,
	then the outer arc from the head round to the cut, the cut itself, and the inner arc back.
	The original drew the same shape as two arcs, a line and a flood fill."

	| head |
	head := self rotateArrowHeadPoints.
	^ { head first. head second. head third }
	  , (self
			   arcPointsFromAngle: 180
			   toAngle: self rotateArrowCutAngle
			   radius: self rotateArrowOuterRadius)
	  , (self
			   arcPointsFromAngle: self rotateArrowCutAngle
			   toAngle: 180
			   radius: self rotateArrowInnerRadius)
	  , { head sixth. head seventh }
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

{ #category : 'shapes' }
LaserGameShapes class >> crossHairElementOfExtent: anExtent [
	"Answer a cross hair of anExtent: two bars crossing at the centre. Page 083 drew the same
	figure as two lines in a form of one cell, and Section 4.2 puts it under the pointer while
	the pointer is over a hint of a mirror."

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

{ #category : 'shapes' }
LaserGameShapes class >> horizontalLaserBeamElementOfExtent: anExtent [
	"Answer an element of anExtent drawing the beam where it crosses a cell from side to side: a
	pale band the whole way across, and a brighter, thinner bar along its middle. Pages 149 to 152
	paint the same picture by hand in a paint tool, store the form in a class method and reload it
	from a workspace; page 153 pulls the bright part out of it again as a mask so that the two can
	be painted in different colours. Two rectangles and two colours say all of that, and they join
	without a seam where one cell meets the next, which the painted form does not."

	| splatter centre |
	splatter := self
		            laserBeamBarOfExtent:
		            anExtent x @ (self laserBeamSplatterThicknessFor: anExtent)
		            within: anExtent
		            color: LaserGameColors laserBeamSplatterColor.
	centre := self
		          laserBeamBarOfExtent:
		          anExtent x @ (self laserBeamCenterThicknessFor: anExtent)
		          within: anExtent
		          color: LaserGameColors laserBeamCenterColor.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: splatter;
		  addChild: centre;
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> horizontalLaserBeamElementOfExtent: anExtent enteringFrom: aSymbol [
	"Answer an element of anExtent drawing the beam where it enters a cell from the side aSymbol
	names, west or east, and stops in the middle of it, which is what a cell that swallows the
	light shows. Pages 160 and 162 of the original draw the whole beam and then black out the half
	the light never reaches, with a mask built for the purpose; half a bar needs no mask. The bars
	are as thick as the ones of a whole beam, since the cell they cross is the same size."

	| length left splatter centre |
	length := anExtent x // 2.
	left := aSymbol = #west
		        ifTrue: [ 0 ]
		        ifFalse: [ anExtent x - length ].
	splatter := self laserBeamSplatterThicknessFor: anExtent.
	centre := self laserBeamCenterThicknessFor: anExtent.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self
				   laserBeamBarOfExtent: length @ splatter
				   at: left @ ((anExtent y - splatter) / 2)
				   color: LaserGameColors laserBeamSplatterColor);
		  addChild: (self
				   laserBeamBarOfExtent: length @ centre
				   at: left @ ((anExtent y - centre) / 2)
				   color: LaserGameColors laserBeamCenterColor);
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent at: aPoint color: aColor [
	"Answer one bar of a beam, of aBarExtent and painted in aColor, at aPoint of the cell."

	^ BlElement new
		  extent: aBarExtent;
		  position: aPoint;
		  background: aColor;
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent within: anExtent color: aColor [
	"Answer one bar of a beam, of aBarExtent and painted in aColor, centred in a cell of anExtent."

	^ self
		  laserBeamBarOfExtent: aBarExtent
		  at: (anExtent - aBarExtent) / 2
		  color: aColor
]

{ #category : 'beam geometry' }
LaserGameShapes class >> laserBeamCenterThicknessFor: anExtent [
	"Answer how thick the bright core of the beam is in a cell of anExtent: half the pale band it
	sits on. Page 153 pulls the same core out of the painted beam as a mask of its own."

	^ ((anExtent x min: anExtent y) // 6) max: 1
]

{ #category : 'beam geometry' }
LaserGameShapes class >> laserBeamSplatterThicknessFor: anExtent [
	"Answer how thick the pale part of the beam is in a cell of anExtent. The original paints one
	beam of one cell size and scales the bitmap; the port keeps the proportion instead of the
	pixels, and a beam is never thinner than one pixel."

	^ ((anExtent x min: anExtent y) // 3) max: 1
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

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowArcSteps [
	"Answer how many segments an arc of the curved arrow is drawn with. The original had a pixel
	arc and no choice to make; a polygon has as many corners as it is given, and two dozen are
	enough for the largest cell the game uses."

	^ 24
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowCenter [
	"Answer the centre both arcs of the curved arrow turn about, as page 099 typed it into its
	workspace."

	^ 282 @ 240
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowCutAngle [
	"Answer where the ring stops, in degrees measured anticlockwise from east. Page 099 draws a
	line from the centre of the arcs to the top right corner of its 450 pixel form, fills the
	shape the line closes, and then paints the line out again with a very wide white pen. The
	angle of that line is all the port keeps of it."

	| corner |
	corner := 450 @ 0 - self rotateArrowCenter.
	^ (corner y negated arcTan: corner x) radiansToDegrees
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowHeadPoints [
	"Answer the arrow head of the curved arrow: the array page 099 types into its workspace,
	moved by the offset the page adds to it. It is the south arrow of page 082 with almost no
	stem, since the ring is the stem. The two points in the middle, at the top of the stem, are
	where the ring begins, so the outline replaces them with the ends of the two arcs."

	^ { 100 @ 260. 40 @ 150. 80 @ 150. 80 @ 141. 120 @ 141. 120 @ 150. 160 @ 150 }
		  collect: [ :each | each + (2 @ 100) ]
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowInnerRadius [
	"Answer the radius of the inner arc of the curved arrow, the 160 of page 099."

	^ 160
]

{ #category : 'rotate arrow geometry' }
LaserGameShapes class >> rotateArrowOuterRadius [
	"Answer the radius of the outer arc of the curved arrow, the 200 of page 099."

	^ 200
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

{ #category : 'shapes' }
LaserGameShapes class >> verticalLaserBeamElementOfExtent: anExtent [
	"Answer an element of anExtent drawing the beam where it crosses a cell from top to bottom: the
	horizontal beam with its sides exchanged. The original has one painted beam and asks its mask
	for a vertical strip of it."

	| splatter centre |
	splatter := self
		            laserBeamBarOfExtent:
		            (self laserBeamSplatterThicknessFor: anExtent) @ anExtent y
		            within: anExtent
		            color: LaserGameColors laserBeamSplatterColor.
	centre := self
		          laserBeamBarOfExtent:
		          (self laserBeamCenterThicknessFor: anExtent) @ anExtent y
		          within: anExtent
		          color: LaserGameColors laserBeamCenterColor.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: splatter;
		  addChild: centre;
		  yourself
]

{ #category : 'building' }
LaserGameShapes class >> verticalLaserBeamElementOfExtent: anExtent enteringFrom: aSymbol [
	"Answer an element of anExtent drawing the beam where it enters a cell from the side aSymbol
	names, north or south, and stops in the middle of it. Page 161 is the same picture turned a
	quarter, and asks one question, the south segment, to choose which half it keeps."

	| length top splatter centre |
	length := anExtent y // 2.
	top := aSymbol = #north
		       ifTrue: [ 0 ]
		       ifFalse: [ anExtent y - length ].
	splatter := self laserBeamSplatterThicknessFor: anExtent.
	centre := self laserBeamCenterThicknessFor: anExtent.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self
				   laserBeamBarOfExtent: splatter @ length
				   at: (anExtent x - splatter) / 2 @ top
				   color: LaserGameColors laserBeamSplatterColor);
		  addChild: (self
				   laserBeamBarOfExtent: centre @ length
				   at: (anExtent x - centre) / 2 @ top
				   color: LaserGameColors laserBeamCenterColor);
		  yourself
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
