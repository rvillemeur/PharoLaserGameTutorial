Class {
	#name : #ReversePushCellSouthLaserGameAction,
	#superclass : #ReverseLaserGameAction,
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
ReversePushCellSouthLaserGameAction class >> actionSymbol [
	^#south
]

{ #category : #accessing }
ReversePushCellSouthLaserGameAction class >> reverseActionSymbol [
	^#pushCellNorthFromLocation:
]
