Class {
	#name : #ReversePushCellEastLaserGameAction,
	#superclass : #ReverseLaserGameAction,
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
ReversePushCellEastLaserGameAction class >> actionSymbol [
	^#east
]

{ #category : #accessing }
ReversePushCellEastLaserGameAction class >> reverseActionSymbol [
	^#pushCellWestFromLocation:
]