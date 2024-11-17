Class {
	#name : #CellClickInsideRegionPushTestCase,
	#superclass : #TestCase,
	#category : #'Laser-Game-Tests'
}

{ #category : #tests }
CellClickInsideRegionPushTestCase >> testClicksInPushRegion [

	| pt regionClass pushRegion testTable cls |
	pt := 11 @ 11.
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self should: [ regionClass = CellClickRegionInside ].
	testTable := {
		             (10 @ 10 -> CellClickRegionPushEast).
		             (20 @ 10 -> CellClickRegionPushWest).
		             (15 @ 15 -> CellClickRegionPushNorth ).
		             (10 @ 20 -> CellClickRegionPushNorth).
		             (20 @ 20 -> CellClickRegionPushNorth).
		             (11 @ 13 -> CellClickRegionPushEast).
		             (14 @ 16 -> CellClickRegionPushNorth).
		             (19 @ 17 -> CellClickRegionPushWest).
		             (15 @ 1 -> CellClickRegionPushSouth) }.

	testTable do: [ :assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self should: [ pushRegion = cls ] ]
]

{ #category : #tests }
CellClickInsideRegionPushTestCase >> testClicksInPushRegions [
	| pt regionClass pushRegion testTable cls rect |
	rect := CellClickRegionInside regionRectangle.
	pt := rect topLeft + (1@1).
	regionClass := CellClickRegion clickRegionForPoint: pt.
	self should: [regionClass = CellClickRegionInside].
	testTable := {
		(rect topLeft)				->	CellClickRegionPushEast.
		(rect topRight)				->	CellClickRegionPushWest.
		(rect center)				->	CellClickRegionPushNorth.
		(rect bottomLeft)			->	CellClickRegionPushNorth.
		(rect bottomRight)			->	CellClickRegionPushNorth.
		(rect topLeft + (1@3))		->	CellClickRegionPushEast.
		(rect center + (-1@1))		->	CellClickRegionPushNorth.
		(rect bottomRight + (-1@(-3)))	->	CellClickRegionPushWest.
		(rect topCenter + (0@1))		->	CellClickRegionPushSouth
		}.
	testTable do: [:assoc |
		pt := assoc key.
		cls := assoc value.
		pushRegion := regionClass pushRegionForPoint: pt.
		self should: [pushRegion = cls]]
]
