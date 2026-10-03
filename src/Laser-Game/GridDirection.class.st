"
I am one of the four directions a cell can be pushed in. I have no instances: each of my four subclasses answers, on its class side, everything there is to know about one direction. The direction symbol (#north, #east, #south, #west) names me, the vector is the step to add to a grid location to move one cell my way, and the inversion symbol names the opposite direction, which is the side a laser beam enters a cell from when it leaves the previous cell my way.

Ask me for a direction by its symbol with GridDirection directionFor: #north.
"
Class {
	#name : 'GridDirection',
	#superclass : 'Object',
	#category : 'Laser-Game-Model',
	#package : 'Laser-Game',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
GridDirection class >> directionFor: aSymbol [
	"Answer the subclass of mine whose direction symbol is aSymbol. The four directions know their
	own symbols, so there is no table here to keep in step with them."

	^self subclasses detect: [:cls | cls directionSymbol = aSymbol]
]
