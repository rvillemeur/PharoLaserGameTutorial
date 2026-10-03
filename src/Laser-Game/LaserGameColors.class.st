"
I am the one place the game's colors are written down. Every element the game shows asks me for its paint, so no `Color` literal appears anywhere else.

My answers are plain `Color` instances. Bloc wraps them in paints and backgrounds where it needs to, so a caller can hand one of my answers straight to `BlBorder paint:width:` or to `BlElement >> background:`.

```
LaserGameColors gameBoardBackgroundColor
```

Changing a color here changes it everywhere, which is the point of the class: the game is retuned in one place, and a color chosen by the player would be answered from here too.
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
	"Answer the colour of a hint arrow for a move that can be made. The arrow says which way a
	click would move a cell; this colour says the click would work."

	^Color green
]

{ #category : 'colors' }
LaserGameColors class >> boardShadowColor [
	"Answer the colour of the shadow the board casts: a dark grey."

	^ Color r: 0.25 g: 0.25 b: 0.254
]

{ #category : 'colors' }
LaserGameColors class >> cellBorderColor [
	^Color white
]

{ #category : 'colors' }
LaserGameColors class >> confirmationBackgroundColor [
	"Answer the color of the box a question is asked in. The game asks inside itself rather than
	in a dialog of its own, so the box takes the flat window color that the window ramp leaves
	unused."

	^ self gameWindowColor
]

{ #category : 'colors' }
LaserGameColors class >> confirmationShadeColor [
	"Answer the color laid over the whole game while it asks a question, so that the board behind
	it is visibly out of reach."

	^ Color black alpha: 0.6
]

{ #category : 'colors' }
LaserGameColors class >> confirmationTextColor [
	"Answer the color of the text of a question."

	^ Color veryVeryLightGray
]

{ #category : 'colors' }
LaserGameColors class >> controlPanelColor [
	"Answer the color of the control panel beside the board: transparent, so that the ramp behind
	the whole window shows through it."

	^ Color transparent
]

{ #category : 'colors' }
LaserGameColors class >> counterBodyColor [
	"Answer the color of the slab a counter shows its digits on: a dark lavender. A segment that
	is not lit is painted this same color, so only the lit segments are seen."

	^ Color r: 0.33 g: 0.33 b: 0.52
]

{ #category : 'colors' }
LaserGameColors class >> counterBorderColor [
	"Answer the color of the frame around a counter. The frame is a flat two pixel border, and it
	takes the color of the label beside it."

	^ Color veryVeryLightGray
]

{ #category : 'colors' }
LaserGameColors class >> counterDigitColor [
	"Answer the color a counter lights its segments in."

	^ Color r: 0.674 g: 0.674 b: 0.96
]

{ #category : 'colors' }
LaserGameColors class >> counterDigitHighlightColor [
	"Answer the color a counter lights its segments in while it is highlighted. The counter of the
	beam is highlighted while the laser fires, so this is almost white, against the lavender of
	the counter beside it."

	^ Color r: 0.95 g: 1.0 b: 1.0
]

{ #category : 'colors' }
LaserGameColors class >> counterDigitOffColor [
	"Answer the color of a segment that is not lit: the slab behind it, which is how a segment is
	hidden."

	^ self counterBodyColor
]

{ #category : 'colors' }
LaserGameColors class >> counterLabelColor [
	"Answer the color of the text under a counter."

	^ Color veryVeryLightGray
]

{ #category : 'colors' }
LaserGameColors class >> denyActionArrowColor [
	"Answer the colour of a hint arrow for a move that is refused. An arrow that promises a move
	the grid would not make is worse than no arrow, so the colour is the warning."

	^Color red
]

{ #category : 'colors' }
LaserGameColors class >> gameBoardBackgroundColor [
	^Color r: 0.860 g: 0.860 b: 0.860
]

{ #category : 'colors' }
LaserGameColors class >> gameWindowColor [
	"Answer the color behind the whole game: the margin around the board and the control panel."

	^ Color r: 0.369 g: 0.369 b: 0.505
]

{ #category : 'colors' }
LaserGameColors class >> laserBeamCenterColor [
	"Answer the color of the bright core that runs along the middle of the laser beam."

	^Color r: 0.909 g: 1.0 b: 0.27
]

{ #category : 'colors' }
LaserGameColors class >> laserBeamSplatterColor [
	"Answer the color of the wide, pale part of the laser beam."

	^Color r: 1.0 g: 1.0 b: 0.71
]

{ #category : 'colors' }
LaserGameColors class >> mirrorColor [
	^Color blue
]

{ #category : 'colors' }
LaserGameColors class >> panelDividerDarkColor [
	"Answer the darker end of the bar drawn across the control panel above the buttons. The bar is
	a gradient between two near whites."

	^ Color r: 0.847 g: 0.847 b: 0.85
]

{ #category : 'colors' }
LaserGameColors class >> panelDividerLightColor [
	"Answer the lighter end of the bar drawn across the control panel above the buttons."

	^ Color r: 0.972 g: 0.972 b: 0.976
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
	"Answer the ramp the window is filled with: two stops, each a fraction of the way along the
	fill paired with the color there. Bloc calls them the stops of a gradient paint."

	^ {
		  (0.0 -> (Color r: 0.3 g: 0.8 b: 0.9)).
		  (1.0 -> (Color r: 0.2 g: 0.1 b: 0.7)) }
]

{ #category : 'colors' }
LaserGameColors class >> windowColorRampDirection [
	"Answer the direction the window ramp runs in, as a fraction of the window in each direction.
	The first stop sits at the top left corner and the last one that fraction of the way across
	and down."

	^ 0.3 @ 0.8
]
