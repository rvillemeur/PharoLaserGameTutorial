"
I offer the numbers the control panel is laid out from to look at.

The panel keeps its sizes on the class side, so my example answers `LaserGameControlPanelElement` and the inspector opens on its Measures tab, which lists every width and height it keeps, and on its Labels tab, which measures each button label and says whether it fits inside its button.
"
Class {
	#name : 'LaserGameControlPanelExample',
	#superclass : 'Object',
	#category : 'Laser-Game-Examples-Examples',
	#package : 'Laser-Game-Examples',
	#tag : 'Examples'
}

{ #category : 'examples' }
LaserGameControlPanelExample class >> panelMeasures [
	"Every width and height the panel is laid out from, on the Measures tab, and every button label measured against its button, on the Labels tab.
	LaserGameControlPanelExample panelMeasures"

	<sampleInstance>
	^ LaserGameControlPanelElement
]
