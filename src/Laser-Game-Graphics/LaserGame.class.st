Class {
	#name : #LaserGame,
	#superclass : #Morph,
	#instVars : [
		'grid'
	],
	#category : #'Laser-Game-Graphics'
}

{ #category : #'as yet unclassified' }
LaserGame class >> boardExtendFor: aGrid [

	| x y |
	x := CellRenderer cellExtent x * aGrid numberOfColumns.
	y := CellRenderer cellExtent y * aGrid numberOfRows.
	^ x @ y
]
