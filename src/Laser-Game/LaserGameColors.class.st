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
LaserGameColors class >> denyActionArrowColor [
	^Color red
]

{ #category : 'colors' }
LaserGameColors class >> gameBoardBackgroundColor [
	^Color r: 0.860 g: 0.860 b: 0.860
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
