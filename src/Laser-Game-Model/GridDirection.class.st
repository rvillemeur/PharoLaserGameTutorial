Class {
	#name : #GridDirection,
	#superclass : #Object,
	#category : #'Laser-Game-Model'
}

{ #category : #'as yet unclassified' }
GridDirection class >> directionFor: aSymbol [
	^self subclasses detect: [:cls | cls directionSymbol = aSymbol]
]
