"
I am the one place the game's colors are written down. Every element the game shows asks me for its paint, so no `Color` literal appears anywhere else on the Bloc side.

My answers are plain `Color` instances. Bloc wraps them in paints and backgrounds where it needs to, so a caller can hand one of my answers straight to `BlBorder paint:width:` or to `BlElement >> background:`.

```
LaserGameColors gameBoardBackgroundColor
```

Changing a color here changes it everywhere, which is what the original tutorial wanted this class for, and what a color preference of the player would later need.
"
Class {
	#name : 'LaserGameColors',
	#superclass : 'Object',
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'colors' }
LaserGameColors class >> allowActionArrowColor [
	^Color green
]

{ #category : 'colors' }
LaserGameColors class >> cellBorderColor [
	^Color white
]

{ #category : 'colors' }
LaserGameColors class >> controlPanelColor [
	"Answer the color of the control panel beside the board. Page 140 paints it transparent, so
	the ramp behind the whole window shows through it; the white of page 068 was only a
	placeholder."

	^ Color transparent
]

{ #category : 'colors' }
LaserGameColors class >> counterBorderColor [
	"Answer the color of the frame around a counter. Page 141 asks for a two pixel
	#complexAltInset border, a bevel drawn in two shades of the color behind it; Bloc draws a
	border in one paint, so the frame is flat and takes the color of the label beside it."

	^ Color veryVeryLightGray
]

{ #category : 'colors' }
LaserGameColors class >> counterDigitColor [
	"Answer the color a counter lights its segments in. Page 141's color for the LED."

	^ Color r: 0.674 g: 0.674 b: 0.96
]

{ #category : 'colors' }
LaserGameColors class >> counterDigitOffColor [
	"Answer the color of a segment that is not lit. The original's LedMorph draws those in a
	darkened version of its own color, which is what this is."

	^ self counterDigitColor muchDarker
]

{ #category : 'colors' }
LaserGameColors class >> counterLabelColor [
	"Answer the color of the text under a counter. Page 141's color for the label."

	^ Color veryVeryLightGray
]

{ #category : 'colors' }
LaserGameColors class >> denyActionArrowColor [
	^Color red
]

{ #category : 'colors' }
LaserGameColors class >> gameBoardBackgroundColor [
	^Color r: 0.860 g: 0.860 b: 0.860
]

{ #category : 'colors' }
LaserGameColors class >> gameWindowColor [
	"Answer the color behind the whole game: the margin around the board and the control panel.
	This is the window color the original gives its morph."

	^ Color r: 0.369 g: 0.369 b: 0.505
]

{ #category : 'colors' }
LaserGameColors class >> laserBeamCenterColor [
	^Color r: 0.909 g: 1.0 b: 0.27
]

{ #category : 'colors' }
LaserGameColors class >> laserBeamSplatterColor [
	^Color r: 1.0 g: 1.0 b: 0.71
]

{ #category : 'colors' }
LaserGameColors class >> mirrorColor [
	^Color blue
]

{ #category : 'colors' }
LaserGameColors class >> targetCenterColor [
	^Color r: 0.0 g: 0.0 b: 0.92
]

{ #category : 'colors' }
LaserGameColors class >> targetCenterColorActive [
	^Color r: 1.0 g: 1.0 b: 0.634
]

{ #category : 'colors' }
LaserGameColors class >> targetCenterColorIdle [
	^Color r: 0.313 g: 0.753 b: 0.976
]

{ #category : 'colors' }
LaserGameColors class >> windowColorRamp [
	"Answer the ramp the window is filled with: page 140's two stops, each a fraction of the way
	along the fill paired with the color there. The original hands the same array of associations
	to #fillWithRamp:oriented:, and Bloc calls them the stops of a gradient paint."

	^ {
		  (0.0 -> (Color r: 0.3 g: 0.8 b: 0.9)).
		  (1.0 -> (Color r: 0.2 g: 0.1 b: 0.7)) }
]

{ #category : 'colors' }
LaserGameColors class >> windowColorRampDirection [
	"Answer the direction the window ramp runs in, as a fraction of the window in each direction:
	page 140's #oriented: argument. The first stop sits at the top left corner and the last one
	that fraction of the way across and down."

	^ 0.3 @ 0.8
]
