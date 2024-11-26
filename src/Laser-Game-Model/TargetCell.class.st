Class {
	#name : #TargetCell,
	#superclass : #Cell,
	#category : #'Laser-Game-Model'
}

{ #category : #'initialize-release' }
TargetCell >> initialize [
	super initialize.
	self initializeExitSides.
	
]

{ #category : #'initialize-release' }
TargetCell >> initializeExitSides [
	self exitSides: Dictionary new.
	self exitSides at: #north put: nil.
	self exitSides at: #east put: nil.
	self exitSides at: #south put: nil.
	self exitSides at: #west put: nil.
	
]
