Class {
	#name : #BlankCellRenderer,
	#superclass : #CellRenderer,
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
BlankCellRenderer class >> modelClass [
	^BlankCell
]

{ #category : #drawing }
BlankCellRenderer >> maskOffHorizontalOn: aMask [
	^aMask
]

{ #category : #drawing }
BlankCellRenderer >> maskOffVerticalOn: aMask [
	^aMask
]

{ #category : #drawing }
BlankCellRenderer >> renderContents [
	self fillBackground

]

{ #category : #drawing }
BlankCellRenderer >> renderLaser [
	self cell isOff ifTrue: [^self].
	(self cell activeSegments at: #north) ifTrue: [self renderLaserVertical].
	(self cell activeSegments at: #west) ifTrue: [self renderLaserHorizontal].
	((self cell activeSegments at: #north) and: [self cell activeSegments at: #west]) ifTrue: [
		self renderLaserVerticalCenter]
]
