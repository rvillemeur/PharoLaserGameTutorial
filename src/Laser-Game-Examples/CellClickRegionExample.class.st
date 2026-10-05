"
I offer the click regions of a cell to look at.

A region is a class, not an instance, so my example answers `CellClickRegion` and the inspector opens on its Regions tab, which draws the hint each region shows, and on its Map tab, which colours a cell point by point to say which region every point of it belongs to.
"
Class {
	#name : 'CellClickRegionExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
CellClickRegionExample class >> clickRegions [
	"The regions a click inside a cell can land in, drawn on the Regions tab and mapped on the Map tab.
	CellClickRegionExample clickRegions"

	<sampleInstance>
	^ CellClickRegion
]
