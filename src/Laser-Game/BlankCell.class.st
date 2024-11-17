Class {
	#name : #BlankCell,
	#superclass : #Cell,
	#category : #'Laser-Game-Model'
}

{ #category : #'initialize-release' }
BlankCell >> initialize [
	super initialize.
	self initializeExitSides.
	
]

{ #category : #'initialize-release' }
BlankCell >> initializeExitSides [
	self exitSides: Dictionary new.
	self exitSides at: #north put: #south.
	self exitSides at: #east put: #west.
	self exitSides at: #south put: #north.
	self exitSides at: #west put: #east.
	
]
