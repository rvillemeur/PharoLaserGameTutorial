Class {
	#name : #ReverseLaserGameAction,
	#superclass : #Object,
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
ReverseLaserGameAction class >> reverseActionClassFor: aSymbol [
	^self subclasses detect: [:cls | cls actionSymbol = aSymbol]
]

{ #category : #accessing }
ReverseLaserGameAction class >> reverseActionSymbolFor: aSymbol [
	| cls |
	cls := self reverseActionClassFor: aSymbol.
	^cls reverseActionSymbol
]
