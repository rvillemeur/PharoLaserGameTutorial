Class {
	#name : #ReversePushCellWestLaserGameAction,
	#superclass : #ReverseLaserGameAction,
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
ReversePushCellWestLaserGameAction class >> actionSymbol [
	^#west
]

{ #category : #accessing }
ReversePushCellWestLaserGameAction class >> reverseActionSymbol [
	^#pushCellEastFromLocation:
]
