"
I am the game board: the element that shows every cell of one grid.

I hold a grid and one child element per cell of it, built by the CellRenderer of each cell. A BlGridLayout places those children, one column per grid column, so a cell never computes where it sits: that was the job of the offsets the original tutorial needed when all cells drew into one shared Form.

The original tutorial computed the extent of that shared Form from the cell size, the border width and the grid dimensions. I keep the arithmetic as `LaserGameBoardElement class >> extentForGrid:`, because a window still has to be given a size, but nothing depends on it internally: I take the size of my cells through fitContent constraints, and cell borders are painted inside the cells, so they cost no space.

I also hold what the mouse is doing to my cells. Each cell element handles its own mouse events and tells me: `hoverCellElement:` and `unhoverCellElement:` keep `hoveredCellElement` current, `clickCellElement:` records `clickedCell`, and `moveMade` says that a click changed the grid. So `hoveredCell` answers the cell under the pointer, which the original had to compute from the hand position, the board offset and the cell size, and printed to the Transcript on page 078.

`moveMade` draws my cells again and then evaluates `moveAction`, which is how the game hears that its counters are out of date. Nothing is registered there when I am opened on my own.

`LaserGameBoardElement openExample` opens the demo grid in a space.

Instance variables:
	grid	<Grid>	the model I show; setting it rebuilds my children
	hoveredCellElement	<LaserGameCellElement>	the cell element under the pointer, nil when the pointer is off the board
	clickedCell	<Cell>	the cell of the last click, nil until a cell is clicked
	moveAction	<BlockClosure>	evaluated after a move, nil when nobody listens

"
Class {
	#name : 'LaserGameBoardElement',
	#superclass : 'BlElement',
	#instVars : [
		'grid',
		'hoveredCellElement',
		'clickedCell',
		'moveAction'
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
LaserGameBoardElement class >> openExampleWithLaserFired [
	"Open the demo grid with the laser already fired, which lights the target. The beam itself is
	not drawn yet: that is the work of Section 4.

	LaserGameBoardElement openExampleWithLaserFired"

	<sampleInstance>
	| grid |
	grid := GridFactory demoGrid.
	grid fireLaser.
	^ self openOn: grid
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

{ #category : 'interaction' }
LaserGameBoardElement >> clickCellElement: aCellElement [
	"Record the cell of aCellElement as the one just clicked. A cell tells me this when a click
	lands on it, that is when a press and a release fall in the same cell."

	clickedCell := aCellElement cell
]

{ #category : 'accessing' }
LaserGameBoardElement >> clickedCell [
	"Answer the cell of the last click, or nil while no cell has been clicked. Nothing acts on
	the click yet: the click regions decide what a click does from Section 3.5 on."

	^ clickedCell
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

{ #category : 'interaction' }
LaserGameBoardElement >> hoverCellElement: aCellElement [
	"Remember that the pointer is over aCellElement. A cell tells me this when the pointer enters
	it and while it moves inside it. The cell I hovered before loses its hint here: page 116 shows
	that mouse moves are samples, so cells the pointer crossed quickly are never told they were
	left, and page 117 answers that with a sweep over the cells marked dirty. One cell can hold a
	hint at a time, so the sweep is this one line."

	hoveredCellElement == aCellElement ifTrue: [ ^ self ].
	hoveredCellElement ifNotNil: [ :each | each clearPositionHint ].
	hoveredCellElement := aCellElement
]

{ #category : 'accessing' }
LaserGameBoardElement >> hoveredCell [
	"Answer the cell the pointer is over, or nil when the pointer is off the board. This is what
	the original wrote to the Transcript on page 078, and it took a hand position, a board offset
	and a division by the cell size to find it."

	^ hoveredCellElement ifNotNil: [ :element | element cell ]
]

{ #category : 'accessing' }
LaserGameBoardElement >> hoveredCellElement [
	"Answer the cell element the pointer is over, or nil when the pointer is off the board."

	^ hoveredCellElement
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

{ #category : 'interaction' }
LaserGameBoardElement >> moveMade [
	"A move was made on one of my cells. Every cell is drawn again, and whoever asked to hear
	about moves is told. Page 142 ends its mouse up handler with #updateCounters; the counters
	belong to the panel and not to me, so I announce the move instead of reaching for them, and a
	board opened on its own still works."

	self redrawCells.
	moveAction ifNotNil: [ :anAction | anAction value ]
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

{ #category : 'drawing' }
LaserGameBoardElement >> redrawCells [
	"Draw every cell again. One action on one cell changes more than that cell: a turned mirror
	sends the beam somewhere else, and a pushed mirror leaves its old place empty, so nothing
	tries to work out which cells are affected."

	self children do: [ :each | each redraw ]
]

{ #category : 'interaction' }
LaserGameBoardElement >> unhoverCellElement: aCellElement [
	"Forget the pointer position, but only when aCellElement is the cell I hover. Moving from
	one cell to the next can deliver the enter of the new cell before the leave of the old one."

	hoveredCellElement == aCellElement ifTrue: [ hoveredCellElement := nil ]
]

{ #category : 'interaction' }
LaserGameBoardElement >> whenMoveMadeDo: aBlock [
	"Evaluate aBlock after every move made on one of my cells."

	moveAction := aBlock
]
