Class {
	#name : #LaserGameColors,
	#superclass : #Object,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
LaserGameColors class >> cellBorderColor [

	^ Color darkGray
]

{ #category : #'as yet unclassified' }
LaserGameColors class >> gameBoardBackgroundColor [

	^ Color r: 0.860 g: 0.860 b: 0.860
]

{ #category : #'as yet unclassified' }
LaserGameColors class >> mirrorColor [

	^ Color blue
]

{ #category : #'as yet unclassified' }
LaserGameColors class >> targetCenterColor [

	^ Color r: 0.0 g: 0.0 b: 0.92.
]

{ #category : #'as yet unclassified' }
LaserGameColors class >> targetCenterColorActive [

	^ Color r: 1.0 g: 1.0 b: 0.634.
]

{ #category : #'as yet unclassified' }
LaserGameColors class >> targetCenterColorIdle [

	^ Color r: 0.313 g: 0.753 b: 0.976
]
