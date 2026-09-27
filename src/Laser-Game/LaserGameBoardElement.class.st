"
I am the game board: the element that shows every cell of one grid.

I hold a grid and one child element per cell of it, built by the CellRenderer of each cell. A BlGridLayout places those children, one column per grid column, so a cell never computes where it sits: that was the job of the offsets the original tutorial needed when all cells drew into one shared Form.

The original tutorial computed the extent of that shared Form from the cell size, the border width and the grid dimensions. I keep the arithmetic as `LaserGameBoardElement class >> extentForGrid:`, because a window still has to be given a size, but nothing depends on it internally: I take the size of my cells through fitContent constraints, and cell borders are painted inside the cells, so they cost no space.

`LaserGameBoardElement openExample` opens the demo grid in a space.

Instance variables:
	grid	<Grid>	the model I show; setting it rebuilds my children
"
Class {
	#name : 'LaserGameBoardElement',
	#superclass : 'BlElement',
	#instVars : [
		'grid'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'geometry' }
LaserGameBoardElement class >> extentForGrid: aGrid [
	"Answer the extent a board showing aGrid occupies. Cells are laid out edge to edge and
	their borders are painted inside them, so the borders add nothing to this."

	^ CellRenderer cellExtent
	  * (aGrid numberOfColumns @ aGrid numberOfRows)
]

{ #category : 'instance creation' }
LaserGameBoardElement class >> on: aGrid [
	"Answer a board element showing aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
]

{ #category : 'examples' }
LaserGameBoardElement class >> openExample [
<sampleInstance>
	"Open the demo grid of the tests, which holds mirrors and a target.

	LaserGameBoardElement openExample"

	^ self openOn: GridFactory demoGrid
]

{ #category : 'examples' }
LaserGameBoardElement class >> openOn: aGrid [

	"Open a space showing aGrid and answer it. The space is sized from the grid, which is the
	whole of what the original tutorial computed a target form extent for.

	LaserGameBoardElement openOn: GridFactory demoGrid"

	| space |
	space := BlSpace new.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: (self on: aGrid).
	space show.
	^ space
]

{ #category : 'accessing' }
LaserGameBoardElement >> cellElementAt: aPoint [
	"Answer the element showing the cell at aPoint, x being the column and y the row."

	| index |
	index := aPoint y - 1 * self grid numberOfColumns + aPoint x.
	^ self children at: index
]

{ #category : 'accessing' }
LaserGameBoardElement >> grid [
	"Answer the grid I show."

	^ grid
]

{ #category : 'accessing' }
LaserGameBoardElement >> grid: aGrid [
	"Show aGrid. Setting the grid rebuilds the cells, so the same board can show another game."

	grid := aGrid.
	self rebuildCells
]

{ #category : 'initialization' }
LaserGameBoardElement >> initialize [
	"A board lays its cells out in a grid, one column per grid column, and takes exactly the
	size of the cells it holds."

	super initialize.
	self background: LaserGameColors gameBoardBackgroundColor.
	self layout: BlGridLayout horizontal.
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
]

{ #category : 'private' }
LaserGameBoardElement >> rebuildCells [
	"Replace my children with one element per cell of my grid, row by row. The grid layout
	places them, so no cell has to work out where it is on a shared surface."

	self removeChildren.
	self layout columnCount: self grid numberOfColumns.
	1 to: self grid numberOfRows do: [ :row |
		1 to: self grid numberOfColumns do: [ :column |
			| location |
			location := column @ row.
			self addChild: (CellRenderer
					 rendererFor: (self grid at: location)
					 grid: self grid) newElement ] ]
]
