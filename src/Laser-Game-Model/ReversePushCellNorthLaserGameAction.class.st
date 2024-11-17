Class {
	#name : #ReversePushCellNorthLaserGameAction,
	#superclass : #ReverseLaserGameAction,
	#category : #'Laser-Game-Model'
}

{ #category : #accessing }
ReversePushCellNorthLaserGameAction class >> actionSymbol [
	^#north
]

{ #category : #accessing }
ReversePushCellNorthLaserGameAction class >> reverseActionSymbol [
	^#pushCellSouthFromLocation:
]
