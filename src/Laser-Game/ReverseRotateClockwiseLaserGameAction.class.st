Class {
	#name : #ReverseRotateClockwiseLaserGameAction,
	#superclass : #ReverseLaserGameAction,
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
ReverseRotateClockwiseLaserGameAction class >> actionSymbol [
	^#clockwise
]

{ #category : #accessing }
ReverseRotateClockwiseLaserGameAction class >> reverseActionSymbol [
	^#rotateCellCounterClockwiseAt:
]
