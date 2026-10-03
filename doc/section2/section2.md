# Game graphics

The model of the game is written, and every part of it has a test. Nothing of it is visible yet.
This section draws the board on the screen. Clicking on it comes in the next one.

> **A word on frameworks.** Pharo has drawn its windows and widgets with Morphic for many years,
> so you will meet Morphic in older books and in older parts of the image. This book uses Bloc,
> the current graphics framework, and nothing in the game needs Morphic.

A good place to start is a single cell. What do we already know about one? It is square. It has a
border. It has a background colour we may choose. We have not decided how big it is.

## One element per cell

A Bloc interface is a tree of elements. An element is a rectangle that can draw itself, hold
children, and answer clicks. So we have a choice to make: does the whole board draw itself as one
big element, or does every cell get an element of its own?

We give every cell its own element. That costs one object per cell, and it buys three things:

- **Clicks land in the right place.** Bloc delivers a click to the element under the pointer. The
  cell under the pointer is the element that hears about it, so no arithmetic turns a point on the
  board into a row and a column.
- **Redrawing is cheap and local.** When one cell changes, that one element is redrawn. The rest of
  the board is untouched.
- **Things can be laid on top.** The hint arrows of the next section are child elements. They are
  added when the pointer arrives and removed when it leaves, and nothing has to repair the pixels
  underneath them.

Bloc draws through Alexandrie, a vector engine. That gives us a second thing we will use over and
over: a shape is described by its geometry, not by its pixels. The mirror is a line, the target is
a circle, the hint arrows are polygons. Nothing in this game is a bitmap, and nothing has to be
painted pixel by pixel.

## The rendering class

The model knows the rules of the game. It should not also know how thick a mirror is drawn. So the
drawing goes in a class of its own: a *renderer*, which knows how to show one cell.

A renderer holds the location of its cell inside the grid, and the grid itself:

```smalltalk
Object << #CellRenderer
	slots: { #cellLocation . #grid };
	tag: 'Graphics';
	package: 'Laser-Game'
```

Note that it does not hold the cell. It holds where the cell is, and asks the grid for the cell
whenever it needs it:

```smalltalk
CellRenderer >> cell
	"Answer the cell I render, read from the grid every time. I hold a location and not a cell, so
	a cell that is replaced in the grid does not leave me showing the old one."

	^ self grid at: self cellLocation
```

That is worth a moment. Pushing a mirror replaces cells in the grid; it does not change their
contents. A renderer that had kept the cell it was given would go on showing a mirror that has
moved away. Holding the location instead makes that bug impossible.

Write the accessors for the two instance variables before going on.

## A rendering hierarchy

There are three kinds of cell, so there are three kinds of renderer. Create three subclasses of
`CellRenderer`: `BlankCellRenderer`, `MirrorCellRenderer` and `TargetCellRenderer`.

Each one answers the model class it draws, the same way the directions of the previous section
each answered their own vector:

```smalltalk
BlankCellRenderer class >> modelClass
	^ BlankCell
```

The mirror and the target renderers do the same with their own model class. The superclass has
nothing to answer, and says so:

```smalltalk
CellRenderer class >> modelClass
	"Answer the Cell subclass I render. Each concrete renderer answers exactly one."

	^ self subclassResponsibility
```

`subclassResponsibility` is how a Pharo class says *my subclasses must answer this, I cannot*. If a
subclass forgets, the error names the method and the class, which is far easier to read than
whatever the missing answer would have broken later.

## Finding the right renderer

Now, given a cell, which renderer draws it? The answer is the pattern we have already used for the
directions: do not write a case statement, ask the subclasses.

```smalltalk
CellRenderer class >> rendererFor: aCell
	"Answer the renderer class that renders aCell."

	^ self subclasses
		  detect: [ :each | each modelClass = aCell class ]
		  ifNone: [ self error: 'No renderer for ' , aCell class name ]
```

A fourth kind of cell will need a fourth renderer, and this method will find it without being
edited. That is the whole point of writing it this way.

`detect:ifNone:` takes two blocks. The first says what we are looking for. The second says what to
do when nothing matches — here, fail loudly. An error that names the cell class is a bug report;
silently answering some other renderer would be a mystery.

The method above answers a renderer *class*. One more method answers a renderer ready to use:

```smalltalk
CellRenderer class >> rendererFor: aCell grid: aGrid
	"Answer a renderer for aCell, which stands at its own location within aGrid."

	| renderer |
	renderer := (self rendererFor: aCell) new.
	renderer
		cellLocation: aCell gridLocation;
		grid: aGrid.
	^ renderer
```

## Unit tests

Create a test case class `CellRendererTestCase` and let us check that the selection works. The
first test states the three pairs by hand:

```smalltalk
CellRendererTestCase >> testRendererSelection

	| renderer cell |
	cell := BlankCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: BlankCellRenderer.


	cell := MirrorCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: MirrorCellRenderer.

	cell := TargetCell new.
	renderer := CellRenderer rendererFor: cell.
	self assert: renderer equals: TargetCellRenderer
```

That test does its job today, and it stops telling the truth the day we add a fourth kind of cell
and forget its renderer: it only knows the three pairs we typed into it. This one does not have
that weakness, because it asks the image what the kinds of cell are:

```smalltalk
CellRendererTestCase >> testEveryCellClassHasExactlyOneRenderer

	Cell allSubclasses do: [ :cellClass |
		| renderers |
		renderers := CellRenderer allSubclasses select: [ :each |
			             each modelClass = cellClass ].
		self
			assert: renderers size = 1
			description: cellClass name , ' must have exactly one renderer, found '
				, renderers size printString ]
```

A test like that is worth looking at twice. `Cell allSubclasses` is the list of cell kinds *as the
image has them now*, so adding a cell kind adds a case to the test by itself. The `description:`
argument is the message you will read when it fails, and a failure that says which class has no
renderer saves you the hunt.

The last test checks the loud failure:

```smalltalk
CellRendererTestCase >> testRendererForUnsupportedModelIsAnError

	self should: [ CellRenderer rendererFor: 42 ] raise: Error
```

`should:raise:` passes when the block raises the error, and fails when it does not. It is how you
test that something is refused.

Run the tests. Make sure the new test case is among the ones you run. Everything should be green
before going on.

We can now say which renderer draws a cell. What a renderer actually draws is the next chapter.

# Rendering the cells

What should these renderer classes do? Draw a cell. We start with the blank cell, because it is the
one with nothing inside it. Once a blank cell is drawn we have the background and the border, and
every other cell is that plus its own contents.

Graphics work differently from model work. With the model, you write a test, you make it pass, and
the test tells you the answer is right. With graphics, some of the answer is *does that look
right*, and the only way to find out is to put it on the screen and look. So the habit in this
section is: get something visible quickly, then change it and look again. Expect to throw a little
code away while you learn what the drawing should be.

## Something on the screen first

Bloc draws into a `BlSpace`: a window with a root element you can add children to. A space of our
own, holding one cell, is enough to look at.

Put the experiment in a method rather than in a Playground. A method stays with the code, it can be
run again a month later, and if a change breaks it you find out:

```smalltalk
CellRenderer class >> openExample
	"Open one blank cell in a space of its own, to look at it and change it.

	CellRenderer openExample"

	| grid renderer space |
	grid := Grid new.
	renderer := self rendererFor: (grid at: 1 @ 1) grid: grid.
	space := BlSpace new.
	space extent: self cellExtent * 3.
	space title: 'Laser Game cell'.
	space root addChild: renderer newElement.
	space show.
	^ space
```

A new grid is full of blank cells, so any location at all gives us a blank cell to draw with no
setup. The space is three cells wide and three cells tall, so the one cell we draw has room around
it and we can see its edges.

The comment holds the expression that runs the method. That is a Pharo habit worth picking up: a
comment you can select and evaluate is a comment that does not go stale.

Evaluate `CellRenderer openExample`. It fails, because `newElement` does not exist yet. Write it.

## One element per cell

Every cell has a background and a border, and every kind of cell has its own contents. That is the
split: the abstract renderer draws what all cells share, and each subclass draws its own contents.

```st
CellRenderer >> newElement
	"Answer a new element rendering my cell. The element is square, carries the cell
	background and border, and holds whatever my subclass draws as children."

	| element |
	element := BlElement new.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderContentsOn: element.
	^ element
```

That is the first version. Later, in *The cell becomes the thing you click*, the second line
changes: a cell element becomes a class of its own, so that a click can be answered by the cell it
landed on. The shape of the method stays exactly as it is here.

A cell is a square, so the geometry is a rectangle and the size is the cell extent. The three
`render...On:` messages are the three things worth varying. The first two are the same for every
cell:

```smalltalk
CellRenderer >> renderBackgroundOn: anElement
	"Paint the cell background. Every cell shares the game board background color."

	anElement background: LaserGameColors gameBoardBackgroundColor
```

```smalltalk
CellRenderer >> renderBorderOn: anElement
	"Draw the cell border. Bloc draws a border inside the bounds of the element, so the
	border costs no space and the cells of a grid stay exactly cellExtent apart."

	anElement border: (BlBorder
			 paint: LaserGameColors cellBorderColor
			 width: self class borderWidth)
```

The third does nothing here. A blank cell has nothing inside it, so the method that draws the
contents is an empty hook for the other renderers to override:

```smalltalk
CellRenderer >> renderContentsOn: anElement
	"Draw what is inside the cell, as children of anElement. A cell with nothing inside
	draws nothing, so this is empty here and overridden by the subclasses that have
	contents."
```

An empty method with a comment is a statement, not an oversight: it says *a blank cell is
complete*. And do not give `BlankCellRenderer` an empty override of its own. A method identical to
the one it inherits says nothing, and the code critic reports it, rightly.

Evaluate `CellRenderer openExample` again. A grey square with a thin border appears in a small
window. That is the first cell of the game.

## Two numbers to decide

**How big is a cell?** Fifty pixels square. It leaves room for the mirror, the target, and the hint
arrows to be legible, and it is small enough that a board of them fits on a screen.

```smalltalk
CellRenderer class >> cellExtent
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere."

	^50@50
```

The comment makes a promise, and it is a promise worth keeping from the start: nothing anywhere
else writes a cell size down. Everything asks this method, or asks something that asks this method.
The tests below do the same. Changing fifty to sixty should change the game and break nothing, and
much later in the book we check exactly that.

**Who pays for the border?** Nobody. A Bloc border is painted *inside* the bounds of its element, so
a one pixel border changes nothing about the size of a cell or the spacing of the grid. Borders that
grow an element are a common source of layouts that are a few pixels off; Bloc spares us that.

```smalltalk
CellRenderer class >> borderWidth
	"Answer the width, in pixels, of the border drawn inside the edges of every cell."

	^ 1
```

## A test for a blank cell

The experiment is a method, but it is not a test: it proves nothing without a pair of eyes. This
does:

```smalltalk
CellRendererTestCase >> testBlankCellElement
	"A blank cell is a square of the board background with a border and nothing inside.
	The element is checked before any layout pass, so the size is read from the layout
	constraints rather than from the extent, which stays zero until the element is laid out."

	| grid element |
	grid := Grid new.
	element := (CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid)
		           newElement.
	self
		assert: element constraints horizontal resizer size
		equals: CellRenderer cellExtent x.
	self
		assert: element constraints vertical resizer size
		equals: CellRenderer cellExtent y.
	self assert: element geometry class equals: BlRectangleGeometry.
	self
		assert: element background paint color
		equals: LaserGameColors gameBoardBackgroundColor.
	self assert: element border width equals: CellRenderer borderWidth.
	self
		assert: element border paint color
		equals: LaserGameColors cellBorderColor.
	"A blank cell draws nothing inside its border."
	self assertEmpty: element children
```

The comment at the top of that test deserves unpacking, because it is the first Bloc trap we walk
into, and it will catch you again later.

> **Setting the extent of a fresh element does not give it bounds.** `element extent: 50@50` records
> a layout constraint. The extent itself stays `0@0` until a layout pass runs, and a fresh element
> that is in no space is never laid out. So asking a new element for its extent answers zero, and a
> test that asserts on it fails with a message that tells you nothing about what is wrong.

There are three ways out, and only one of them is right here.

- **Send `forceLayout`.** It works, and it is forbidden. Bloc ships a code critic rule,
  `ReBlocDoNotSendForceLayoutRule`, that reports it. Laying out by hand is how Bloc code ends up
  fighting the space it lives in.
- **Put the element in a space and settle the space.** That is the proper way to get a laid out
  element, and it is what we do when we want to look at the drawing. In a unit test it is a heavy
  way to find out whether we typed `50@50`.
- **Read the constraint we set**, which is what the test above does. No layout, no space, and the
  assertion is about the thing the method under test actually decided.

That last point is the general lesson. A test is clearest when it asks about the decision the code
made, not about a consequence that something else has to compute first.

Run the tests. All green, and the code critic quiet on the new methods.

The next chapter gives these blank cells a board to sit on.

# The game board

One cell is drawn. A game needs twenty-five of them, in rows and columns, and something has to hold
them. That something is the board.

The board is a `BlElement` with the cells as its children, and a *layout* puts the children in
their places. This is the moment to say what a layout is, because the rest of the section leans on
it: a layout is an object you give to an element, and it decides where that element's children go
and how big they are. The element does not place its children itself, and neither do we.

## The board element

```smalltalk
BlElement << #LaserGameBoardElement
	slots: { #grid };
	tag: 'Graphics';
	package: 'Laser-Game'
```

A board lays its cells out in a grid and takes exactly the size of the cells it holds:

```st
LaserGameBoardElement >> initialize
	"A board lays its cells out in a grid, one column per grid column, and takes exactly the
	size of the cells it holds."

	super initialize.
	self background: LaserGameColors gameBoardBackgroundColor.
	self layout: BlGridLayout horizontal.
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
```

That is the first version; *Minor cosmetic tweaks*, near the end of the book, adds a drop shadow
here.

`BlGridLayout horizontal` fills the grid row by row: you add children one after another, and the
layout starts a new row every time it has as many as the column count. So the order in which we add
the cells is the order they appear on the screen, and no cell is ever told where it is.

`fitContent` is the other half. It tells the board to take the size of its children instead of
being given a size. We never compute how wide the board is; we ask the cells, and they already
know.

## The grid, and rebuilding from it

Create the accessor pair for the instance variable. Setting the grid is not a plain store, though: a
board that shows another grid has to show another set of cells.

```smalltalk
LaserGameBoardElement >> grid: aGrid
	"Show aGrid. Setting the grid rebuilds the cells, so the same board can show another game."

	grid := aGrid.
	self rebuildCells
```

```smalltalk
LaserGameBoardElement >> rebuildCells
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
```

Read the two loops once more. They walk the grid row by row, and for each cell they ask
`CellRenderer` for the right renderer and the renderer for an element. That is the pattern of the
previous chapter paying off: the board does not know that there are three kinds of cell, and it
will not have to be edited when there is a fourth.

A board is built on a grid in one message:

```smalltalk
LaserGameBoardElement class >> on: aGrid
	"Answer a board element showing aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
```

Because the cells are added in row order, the element of a location is found by arithmetic rather
than by searching:

```smalltalk
LaserGameBoardElement >> cellElementAt: aPoint
	"Answer the element showing the cell at aPoint, x being the column and y the row."

	| index |
	index := aPoint y - 1 * self grid numberOfColumns + aPoint x.
	^ self children at: index
```

## How big the board is

A window has to be given a size, so the board answers one. Nothing inside the board depends on it:

```smalltalk
LaserGameBoardElement class >> extentForGrid: aGrid
	"Answer the extent a board showing aGrid occupies. Cells are laid out edge to edge and
	their borders are painted inside them, so the borders add nothing to this."

	^ CellRenderer cellExtent
	  * (aGrid numberOfColumns @ aGrid numberOfRows)
```

Two things in three lines. Multiplying two points multiplies them coordinate by coordinate, so
`50@50 * (5@5)` is `250@250`. And the borders are not in the sum, because a Bloc border is painted
inside the element that carries it.

Note where this method lives: on the board element, not on the grid. The grid is the model, and the
model knows nothing about pixels. Keeping it that way is what lets the whole model be tested without
a screen.

## Opening it

```smalltalk
LaserGameBoardElement class >> openOn: aGrid
	"Open a space showing aGrid and answer it. The space is sized from the grid.

	LaserGameBoardElement openOn: GridFactory demoGrid"

	| space |
	space := BlSpace new.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: (self on: aGrid).
	space show.
	^ space
```

```smalltalk
LaserGameBoardElement class >> openExample
<sampleInstance>
	"Open the demo grid of the tests, which holds mirrors and a target.

	LaserGameBoardElement openExample"

	^ self openOn: GridFactory demoGrid
```

The `<sampleInstance>` line is a *pragma*: a mark on the method that tools look for. It tells Pharo
that this method opens an example, so the browser offers to run it for you.

Evaluate `LaserGameBoardElement openExample`. A board of twenty-five bordered squares appears. The
demo grid holds a mirror and a target, and the model knows it, but they are still drawn as blank
cells: only the abstract renderer implements `renderContentsOn:` so far. Their contents come next.

## Tests

The board is tested without opening a window. Every assertion is about structure, and none of it
needs a layout pass:

```smalltalk
LaserGameBoardElementTestCase >> testBoardHasOneElementPerCell
	"Every cell of the grid gets exactly one element, and no element is left over."

	| grid board |
	grid := GridFactory demoGrid.
	board := LaserGameBoardElement on: grid.
	self
		assert: board children size
		equals: grid numberOfRows * grid numberOfColumns
```

```smalltalk
LaserGameBoardElementTestCase >> testCellElementsAreInRowMajorOrder
	"Cells are added row by row, so the element of a location is found by arithmetic and
	every location answers a different element."

	| grid board elements |
	grid := GridFactory demoGrid.
	board := LaserGameBoardElement on: grid.
	self
		assert: (board cellElementAt: 1 @ 1)
		equals: board children first.
	self
		assert:
			(board cellElementAt:
				 grid numberOfColumns @ grid numberOfRows)
		equals: board children last.
	elements := IdentitySet new.
	1 to: grid numberOfRows do: [ :row |
		1 to: grid numberOfColumns do: [ :column |
			elements add: (board cellElementAt: column @ row) ] ].
	self assert: elements size equals: board children size
```

The last four lines of that test are a trick worth keeping. Collecting every answer into an
`IdentitySet` and checking its size proves that no two locations answer the *same* element — which
is the way an off-by-one in `cellElementAt:` would show up.

```smalltalk
LaserGameBoardElementTestCase >> testExtentForGridComesFromTheCellSize
	"The board extent is the cell extent times the grid dimensions. Borders are painted inside
	the cells, so they add nothing, and the number is never written down as a literal."

	| grid |
	grid := GridFactory demoGrid.
	self
		assert: (LaserGameBoardElement extentForGrid: grid)
		equals:
			CellRenderer cellExtent x * grid numberOfColumns
			@ (CellRenderer cellExtent y * grid numberOfRows)
```

```smalltalk
LaserGameBoardElementTestCase >> testSettingAnotherGridRebuildsTheCells
	"The same board can show another game. Nothing of the previous grid is left behind."

	| board first second |
	first := GridFactory demoGrid.
	second := Grid new.
	board := LaserGameBoardElement on: first.
	board grid: second.
	self assert: board grid equals: second.
	self
		assert: board children size
		equals: second numberOfRows * second numberOfColumns.
	self
		assert: (board cellElementAt: 1 @ 1)
		equals: board children first
```

One thing is deliberately not asserted. `BlGridLayout` takes its column count through
`columnCount:` and keeps it to itself, with no reader, so a test cannot ask a layout how many
columns it has. Reaching into its instance variables to find out would be testing Bloc, not the
game. The placement it produces is checked by opening the example instead: with the five by five
demo grid, the board settles at 250x250 and the cell at 5@5 sits at 200@200.

```smalltalk
LaserGameBoardElementTestCase >> testBoardLaysCellsOutInAGridAndFitsThem
	"The layout does the placing, and the board takes the size of the cells it holds. Both are
	read without a layout pass. BlGridLayout keeps its column count privately, so the number of
	columns is not asserted here; the placement it produces is checked by opening the example."

	| grid board |
	grid := GridFactory demoGrid.
	board := LaserGameBoardElement on: grid.
	self assert: board layout class equals: BlGridLayout.
	self
		assert: board constraints horizontal resizer class
		equals: BlLayoutFitContentResizer.
	self
		assert: board constraints vertical resizer class
		equals: BlLayoutFitContentResizer
```

Knowing what *not* to assert is part of writing tests. A test that asserts on the private state of
a framework fails the day the framework is tidied up, and it never told you anything about your own
code in the first place.

# Drawing the mirror

Twenty-five bordered squares are a board, but they are not a game. The mirrors have to be visible.
A mirror is a diagonal line across its cell, and this chapter draws it.

## A board to look at

Before drawing anything, we need a board worth drawing. Building one by hand in every test and
every example would be tiresome, so the grids the game and the tests work with come from one place,
`GridFactory`:

```smalltalk
GridFactory class >> demoGrid
	"Answer a five by five grid holding ten mirrors and one target, always the same ones. The
	tests use it whenever a board with something on it is needed, and so do the examples."

	| grid |
	grid := Grid newOfSize: 5@5.
	grid at: 4@1 put: MirrorCell leanRight.
	grid at: 5@1 put: TargetCell new.
	grid at: 1@2 put: MirrorCell leanRight.
	grid at: 5@2 put: MirrorCell leanLeft.
	grid at: 2@3 put: MirrorCell leanLeft.
	grid at: 3@3 put: MirrorCell leanRight.
	grid at: 5@3 put: MirrorCell leanLeft.
	grid at: 2@4 put: MirrorCell leanLeft.
	grid at: 3@4 put: MirrorCell leanLeft.
	grid at: 1@5 put: MirrorCell leanRight.
	grid at: 4@5 put: MirrorCell leanRight.
	^grid
```

```smalltalk
GridFactory class >> defaultGrid
	"Answer the board a new game is dealt on: eight columns by ten rows, randomized."

	^self randomizedGridOfExtent: 8@10
```

`demoGrid` is worth the few lines it costs. It always holds the same ten mirrors and the same
target, so a test that asserts something about it keeps asserting the same thing next year, and a
drawing that looks wrong looks wrong in the same place twice. A randomized grid cannot do either,
which is why `defaultGrid` is for playing and `demoGrid` is for working.

## How thick, and how far in

A mirror is a diagonal across its cell that does not reach the corners. Two numbers say where it
goes and how heavy it is, and both get a name of their own rather than being typed into the drawing
code:

```smalltalk
MirrorCellRenderer >> cornerInset
	"Answer how far, in pixels, the ends of the mirror stay clear of the corners of the cell."

	^8@8
```

```smalltalk
MirrorCellRenderer class >> mirrorWidth
	"Answer the thickness, in pixels, of the mirror: a two pixel stroke."

	^ 2
```

Naming a number is not ceremony. It gives you one place to change, a word to search for, and a
comment that says what the number means — three things a literal `8` buried in a method does not
give you.

## Two leans, one line

`renderContentsOn:` is the hook `newElement` already calls, and that the blank renderer leaves
empty. A mirror asks its cell which way it leans and draws accordingly:

```smalltalk
MirrorCellRenderer >> renderContentsOn: anElement
	"A mirror is one diagonal, leaning the way my cell leans."

	self cell isLeft
		ifTrue: [ self renderContentsLeanLeftOn: anElement ]
		ifFalse: [ self renderContentsLeanRightOn: anElement ]
```

```smalltalk
MirrorCellRenderer >> renderContentsLeanLeftOn: anElement
	"Draw the mirror from the top left corner of the cell to the bottom right one, inset from
	both."

	| inset delta |
	inset := self cornerInset.
	delta := self class cellExtent - 1.
	self
		addMirrorFrom: inset
		to: delta - inset
		on: anElement
```

```smalltalk
MirrorCellRenderer >> renderContentsLeanRightOn: anElement
	"Draw the mirror from the top right corner of the cell to the bottom left one, inset from
	both."

	| inset delta |
	inset := self cornerInset.
	delta := self class cellExtent - 1.
	self
		addMirrorFrom: delta x - inset x @ inset y
		to: inset x @ (delta y - inset y)
		on: anElement
```

Work the numbers through once. `delta` is the last pixel of the cell, one less than the extent,
because a fifty pixel cell runs from 0@0 to 49@49. With an inset of 8@8, a left leaning mirror runs
from 8@8 to 41@41, and a right leaning one from 41@8 to 8@41.

Those coordinates are *inside the cell*. Every cell element has its own origin at its own top left
corner, so the same two points describe the mirror in the first cell of the board and in the last
one. Nothing has to know where on the board the cell ended up.

## Adding the stroke

Both methods end in one place, and it is the only method in the chapter that mentions Bloc:

```smalltalk
MirrorCellRenderer >> addMirrorFrom: aPoint to: anotherPoint on: anElement
	"Add the mirror to anElement as a child carrying a line geometry. The child covers the whole
	cell, so both points are cell local, and the stroke is centered on the line so that the
	mirror is as thick on one side of it as on the other."

	| mirror |
	mirror := BlElement new.
	mirror extent: self class cellExtent.
	mirror geometry: (BlLineGeometry from: aPoint to: anotherPoint).
	mirror outskirts: BlOutskirts centered.
	mirror border: (BlBorder
			 paint: LaserGameColors mirrorColor
			 width: self class mirrorWidth).
	anElement addChild: mirror
```

Three things in there are worth a sentence each.

**A line has no inside.** Nothing about it is filled, so the visible mirror is entirely its border.
`BlBorder paint:width:` is what makes it blue and two pixels heavy. If you ever draw a line and see
nothing, check that you gave it a border and not only a background.

**`BlOutskirts centered` puts the stroke half on each side of the line.** Bloc's default,
`BlOutskirtsInside`, would push the whole two pixels to one side, and the mirror would sit a pixel
off its own diagonal. On a two pixel line in a fifty pixel cell, that is the difference between a
drawing that looks right and one you keep squinting at.

**The child is given the whole cell extent**, not the bounding box of the line. Bloc positions a
child by its own origin, so a child the size of the cell lets both end points be read straight off
the cell. A tighter child would be correct too, and every coordinate in the two methods above would
have to be shifted by the offset of its corner. One of those two is easier to get right.

## Tests

The tests build one mirror cell in a one by one grid, render it, and look at the child. Two helper
methods keep the rest short:

```smalltalk
MirrorCellRendererTestCase >> rendererLeaning: aSymbol
	"Answer a mirror renderer for a mirror cell leaning aSymbol, #left or #right, sitting at 1@1
	of a fresh grid."

	| grid cell |
	grid := Grid new.
	cell := MirrorCell new.
	aSymbol = #left
		ifTrue: [ cell leanLeft ]
		ifFalse: [ cell leanRight ].
	grid at: 1 @ 1 put: cell.
	^ CellRenderer rendererFor: cell grid: grid
```

```smalltalk
MirrorCellRendererTestCase >> mirrorElementLeaning: aSymbol
	"Answer the mirror child of the element rendered for a mirror cell leaning aSymbol."

	^ (self rendererLeaning: aSymbol) newElement children first
```

Helper methods in a test case are not clutter; they are what keeps the tests readable. A test whose
first six lines are setup hides what it is actually asserting.

```smalltalk
MirrorCellRendererTestCase >> testMirrorCellHoldsOneMirror
	"A mirror cell draws one diagonal, whichever way it leans."

	self assert: (self rendererLeaning: #left) newElement children size equals: 1.
	self assert: (self rendererLeaning: #right) newElement children size equals: 1
```

```smalltalk
MirrorCellRendererTestCase >> testLeanLeftMirrorRunsFromTopLeftToBottomRight
	"A left leaning mirror goes down and to the right, inset from both corners it points at."

	| renderer mirror inset delta |
	renderer := self rendererLeaning: #left.
	mirror := renderer newElement children first.
	inset := renderer cornerInset.
	delta := MirrorCellRenderer cellExtent - 1.
	self assert: mirror geometry class equals: BlLineGeometry.
	self assert: mirror geometry from equals: inset.
	self assert: mirror geometry to equals: delta - inset
```

```smalltalk
MirrorCellRendererTestCase >> testLeanRightMirrorRunsFromTopRightToBottomLeft
	"A right leaning mirror goes down and to the left, inset from both corners it points at."

	| renderer mirror inset delta |
	renderer := self rendererLeaning: #right.
	mirror := renderer newElement children first.
	inset := renderer cornerInset.
	delta := MirrorCellRenderer cellExtent - 1.
	self assert: mirror geometry class equals: BlLineGeometry.
	self assert: mirror geometry from equals: delta x - inset x @ inset y.
	self assert: mirror geometry to equals: inset x @ (delta y - inset y)
```

```smalltalk
MirrorCellRendererTestCase >> testMirrorIsAStrokeInTheMirrorColor
	"The diagonal is painted by the border of the child, since a line has no inside to fill. The
	stroke is centered on the line, so the mirror is as thick on one side of it as on the other."

	| mirror |
	mirror := self mirrorElementLeaning: #left.
	self
		assert: mirror border paint color
		equals: LaserGameColors mirrorColor.
	self
		assert: mirror border width
		equals: MirrorCellRenderer mirrorWidth.
	self assert: mirror outskirts equals: BlOutskirts centered
```

```smalltalk
MirrorCellRendererTestCase >> testMirrorCoversTheWholeCell
	"The child carrying the line is the size of the cell, so both ends of the diagonal are cell
	local coordinates."

	| mirror |
	mirror := self mirrorElementLeaning: #right.
	self
		assert: mirror constraints horizontal resizer size
		equals: MirrorCellRenderer cellExtent x.
	self
		assert: mirror constraints vertical resizer size
		equals: MirrorCellRenderer cellExtent y
```

```smalltalk
MirrorCellRendererTestCase >> testRotatingTheCellTurnsTheMirrorOver
	"Rendering follows the cell. Rotating a mirror cell and rendering it again draws the other
	diagonal, so the two ends swap corners along the x axis."

	| renderer before after |
	renderer := self rendererLeaning: #left.
	before := renderer newElement children first geometry.
	renderer cell rotate.
	after := renderer newElement children first geometry.
	self assert: after from y equals: before from y.
	self assert: after to y equals: before to y.
	self assert: after from x equals: before to x.
	self assert: after to x equals: before from x
```

Look at what none of those tests contains: the numbers 8, 41, and 49. Every expected point is built
from `cornerInset` and `cellExtent`. That is deliberate, and it is the second half of the promise
`cellExtent` made in the last chapter: when the cell grows, the mirrors move with it and no test has
to be edited. A test that writes `8@8` down would have to be.

The last test is the one that pays for the design of the first chapter. The renderer reads its cell
from the grid every time it renders, so rotating the cell and rendering again draws the other
diagonal — the ends swapped along x, left where they were along y. A renderer that had cached the
cell, or cached its element, would fail this test, and the game would be unplayable in a way that is
hard to see.

Open the example:

```smalltalk
LaserGameBoardElement openExample
```

Twenty-five cells, ten of them with a diagonal across them: the ten mirrors of `demoGrid`. The
target at 5@1 is still an empty bordered square. It is the next chapter.

# Management of colours

Three colours have been chosen so far: a grey board background, a white cell border, a blue mirror.
Each was picked where it was needed. That is how colours always get chosen, and it is how a program
ends up with the same grey written down in nine places and a tenth that is almost the same grey.

So the colours live in one class, `LaserGameColors`, with one method each, and every element asks
for its paint by name:

```smalltalk
LaserGameColors class >> gameBoardBackgroundColor
	^Color r: 0.860 g: 0.860 b: 0.860
```

```smalltalk
LaserGameColors class >> cellBorderColor
	^Color white
```

```smalltalk
LaserGameColors class >> mirrorColor
	^Color blue
```

```smalltalk
LaserGameColors class >> targetCenterColor
	^Color r: 0.0 g: 0.0 b: 0.92
```

```smalltalk
LaserGameColors class >> targetCenterColorIdle
	^Color r: 0.313 g: 0.753 b: 0.976
```

```smalltalk
LaserGameColors class >> targetCenterColorActive
	^Color r: 1.0 g: 1.0 b: 0.634
```

The last three are the target: the colour of its outline, and the two fills that say whether the
laser reaches it. We use them in the next chapter.

The rule this class exists to enforce is short: **no `Color` literal anywhere else in the game.**
Grep the package for `Color r:` when you think you have finished a drawing, and if you find one
outside this class, move it here and give it a name. The payoff arrives later in the book, when the
game grows a window, a control panel, and a counter, and every one of them has to look like it
belongs to the same program.

Two more pairs are already here for chapters to come: `allowActionArrowColor` and
`denyActionArrowColor` for the hint arrows of the next section, and `laserBeamCenterColor` and
`laserBeamSplatterColor` for the beam.

Note what the class does *not* know. It answers plain `Color` instances, and Bloc wraps them
itself: `BlBorder paint:width:` makes a paint from one, and `BlElement >> background:` makes a
background from one. So the colour class has no Bloc in it at all, which is why it can be read,
changed and tested without a window.

# Drawing the target

The target has more in it than the mirror: two crossing lines, a ring around the middle of the cell,
and the inside of the ring filled with one of two colours, depending on whether the laser reaches
the cell. Four children of the cell element, all of them placed in cell coordinates.

## Numbers with names

Five methods hold the geometry. None of the drawing code below contains a number:

```smalltalk
TargetCellRenderer >> radius
	"Answer the radius of the ring drawn in a target cell. It is worked out from the cell size, so
	that the ring grows with the cell, and clamped at ten so that it stops growing once the cell
	is large enough."

	^(self class cellExtent x // 2 - 8) min: 10
```

```smalltalk
TargetCellRenderer >> crossHairInset
	"Answer how far, in pixels, each end of the crosshairs stays inside the edge of the cell."

	^ 6 @ 6
```

```smalltalk
TargetCellRenderer class >> outlineWidth
	"Answer the thickness, in pixels, of the target outline: the crosshairs and the ring. Both are
	two pixel strokes."

	^ 2
```

```smalltalk
TargetCellRenderer class >> centerInset
	"Answer how far, in pixels, the filled center of the target stays inside the ring around it."

	^ 4
```

```smalltalk
TargetCellRenderer >> innerRadius
	"Answer the radius of the filled center of the target, which stays inside the ring."

	^ self radius - self class centerInset
```

`radius` is the interesting one. It is half the cell, less eight pixels, and never more than ten. The
first part makes the ring grow with the cell; the `min: 10` stops it growing past a size that looks
right. With a fifty pixel cell it answers 10, so `innerRadius` answers 6.

## The contents, in three parts

```smalltalk
TargetCellRenderer >> renderContentsOn: anElement
	"A target is a crosshair, a ring around the middle of the cell, and a disc inside the ring
	showing whether the laser reaches my cell."

	self renderCrossHairsOn: anElement.
	self renderRingOn: anElement.
	self renderCenterOn: anElement
```

A method like that is worth aiming for: three lines, each naming one part of the picture, and the
order of the lines is the order the parts are drawn in. Children added later are drawn on top, so
the crosshair goes down first, the ring over it, the disc over both.

```smalltalk
TargetCellRenderer >> renderCrossHairsOn: anElement
	"Two lines crossing in the middle of the cell, each inset from the two edges it points at."

	| inset delta middle |
	inset := self crossHairInset.
	delta := self class cellExtent - 1.
	middle := delta // 2.
	self
		addOutlineLineFrom: inset x @ middle y
		to: delta x - inset x @ middle y
		on: anElement.
	self
		addOutlineLineFrom: middle x @ inset y
		to: middle x @ (delta y - inset y)
		on: anElement
```

```smalltalk
TargetCellRenderer >> addOutlineLineFrom: aPoint to: anotherPoint on: anElement
	"Add one line of the target outline to anElement. Both points are cell local, and the stroke is
	centered on the line, as the mirror's is."

	| line |
	line := BlElement new.
	line extent: self class cellExtent.
	line geometry: (BlLineGeometry from: aPoint to: anotherPoint).
	line outskirts: BlOutskirts centered.
	line border: (BlBorder
			 paint: LaserGameColors targetCenterColor
			 width: self class outlineWidth).
	anElement addChild: line
```

That is the mirror's `addMirrorFrom:to:on:` again with another colour. You may be tempted to merge
the two into one shared method. Resist it for now. A mirror and a target outline are two ideas that
happen to be drawn the same way today, and each renderer owns its own drawing; merging them would
tie the two pictures together for the sake of six identical lines. Duplication is worth removing
when the two copies have to change together — and these two do not.

## Circles

A `BlCircleGeometry` has no centre and no radius of its own. It inscribes a circle in the bounds of
its element. So a circle of a given radius around a given point is an element that is a square of
the *diameter*, placed one radius up and to the left of that point:

```smalltalk
TargetCellRenderer >> newCircleOfRadius: aRadius
	"Answer a circular element of aRadius, placed around the middle of the cell. A circle geometry
	inscribes its circle in the bounds of its element, so the element is a square of the diameter
	and sits one radius up and to the left of the middle."

	| middle circle |
	middle := self class cellExtent - 1 // 2.
	circle := BlElement new.
	circle geometry: BlCircleGeometry new.
	circle extent: (aRadius * 2) asPoint.
	circle position: middle - aRadius.
	^ circle
```

This is the second Bloc habit of the section, after the line. **Geometry describes a shape inside
the bounds of an element; the bounds say where the shape is and how big it is.** Once that clicks,
circles, ellipses, and rounded rectangles all stop being special.

Both circles come from that one method, and they differ only in what paints them:

```smalltalk
TargetCellRenderer >> renderRingOn: anElement
	"The ring of the target: an outline, with nothing painted inside it, so the crosshairs stay
	visible through it."

	| ring |
	ring := self newCircleOfRadius: self radius.
	ring outskirts: BlOutskirts centered.
	ring border: (BlBorder
			 paint: LaserGameColors targetCenterColor
			 width: self class outlineWidth).
	anElement addChild: ring
```

```smalltalk
TargetCellRenderer >> renderCenterOn: anElement
	"The filled disc inside the ring. Its color is the whole of what the target says about the
	state of the game."

	| center |
	center := self newCircleOfRadius: self innerRadius.
	center background: self centerColor.
	anElement addChild: center
```

Border and no background is an outline, and the crosshair shows through the middle of it. Background
and no border is a solid disc. That is the whole difference between the two.

## On or off

```smalltalk
TargetCellRenderer >> centerColor
	"Answer the fill of the target center: one color while the laser reaches my cell, another
	while it does not."

	^ self cell isOn
		  ifTrue: [ LaserGameColors targetCenterColorActive ]
		  ifFalse: [ LaserGameColors targetCenterColorIdle ]
```

Notice how small the state makes the code. There is no *draw the lit target* method and no *draw
the unlit target* method. The drawing is the same either way; one paint differs, so one method
answers that paint and the drawing is written once. When you catch yourself writing two methods
that differ in a single expression, look for the expression that could be answered instead.

## Firing the laser

The demo grid is built so that the mirrors lead the beam to the target, so firing the laser should
light it, even though no beam is drawn yet. That is worth an example of its own:

```smalltalk
LaserGameBoardElement class >> openExampleWithLaserFired
	"Open the demo grid with the laser already fired, which lights the target and draws the beam
	over the blank cells it crosses.

	LaserGameBoardElement openExampleWithLaserFired"

	<sampleInstance>
	| grid |
	grid := GridFactory demoGrid.
	grid fireLaser.
	^ self openOn: grid
```

The comment mentions the beam, which this chapter does not draw. *Laser on blank cell*, much later,
does, and the same example shows it then.

## Tests

```smalltalk
TargetCellRendererTestCase >> rendererForTarget: aTargetCell
	"Answer a renderer for aTargetCell, sitting at 1@1 of a fresh grid."

	| grid |
	grid := Grid new.
	grid at: 1 @ 1 put: aTargetCell.
	^ CellRenderer rendererFor: aTargetCell grid: grid
```

```smalltalk
TargetCellRendererTestCase >> testTargetHasCrossHairsARingAndACenter
	"A target draws four things: two crossing lines, the ring, and the disc inside it."

	| children |
	children := (self rendererForTarget: TargetCell new) newElement children.
	self assert: children size equals: 4.
	self assert: (children at: 1) geometry class equals: BlLineGeometry.
	self assert: (children at: 2) geometry class equals: BlLineGeometry.
	self assert: (children at: 3) geometry class equals: BlCircleGeometry.
	self assert: (children at: 4) geometry class equals: BlCircleGeometry
```

```smalltalk
TargetCellRendererTestCase >> testCrossHairsCrossInTheMiddleInsetFromTheEdges
	"The horizontal line runs along the middle row of the cell and the vertical one along the
	middle column, each stopping short of the two edges it points at."

	| renderer children inset delta middle |
	renderer := self rendererForTarget: TargetCell new.
	children := renderer newElement children.
	inset := renderer crossHairInset.
	delta := TargetCellRenderer cellExtent - 1.
	middle := delta // 2.
	self assert: children first geometry from equals: inset x @ middle y.
	self
		assert: children first geometry to
		equals: delta x - inset x @ middle y.
	self
		assert: (children at: 2) geometry from
		equals: middle x @ inset y.
	self
		assert: (children at: 2) geometry to
		equals: middle x @ (delta y - inset y)
```

```smalltalk
TargetCellRendererTestCase >> testRingIsAnEmptyOutlineAroundTheMiddleOfTheCell
	"The ring is a circle of the renderer's radius, centered on the cell, with nothing painted
	inside it, so the crosshairs stay visible through it."

	| renderer ring middle |
	renderer := self rendererForTarget: TargetCell new.
	ring := renderer newElement children at: 3.
	middle := TargetCellRenderer cellExtent - 1 // 2.
	self
		assert: ring constraints horizontal resizer size
		equals: renderer radius * 2.
	self
		assert: ring constraints vertical resizer size
		equals: renderer radius * 2.
	self
		assert: ring constraints position
		equals: middle - renderer radius.
	self
		assert: ring border width
		equals: TargetCellRenderer outlineWidth.
	self assert: ring background class equals: BlTransparentBackground
```

That last assertion is the one that would catch a mistake you cannot see: an element with no
background answers a `BlTransparentBackground`, and a ring that had accidentally been given a fill
would hide the crosshair under it.

```smalltalk
TargetCellRendererTestCase >> testCenterSitsInsideTheRing
	"The disc is centered where the ring is and is one centerInset smaller in radius."

	| renderer center middle |
	renderer := self rendererForTarget: TargetCell new.
	center := renderer newElement children at: 4.
	middle := TargetCellRenderer cellExtent - 1 // 2.
	self
		assert: renderer innerRadius
		equals: renderer radius - TargetCellRenderer centerInset.
	self
		assert: center constraints horizontal resizer size
		equals: renderer innerRadius * 2.
	self
		assert: center constraints vertical resizer size
		equals: renderer innerRadius * 2.
	self
		assert: center constraints position
		equals: middle - renderer innerRadius
```

```smalltalk
TargetCellRendererTestCase >> testOutlinesAreDrawnInTheTargetColor
	"Both crosshairs and the ring share one color, and all three are strokes of the same width."

	| children |
	children := (self rendererForTarget: TargetCell new) newElement children.
	1 to: 3 do: [ :index |
		self
			assert: (children at: index) border paint color
			equals: LaserGameColors targetCenterColor.
		self
			assert: (children at: index) border width
			equals: TargetCellRenderer outlineWidth.
		self
			assert: (children at: index) outskirts
			equals: BlOutskirts centered ]
```

```smalltalk
TargetCellRendererTestCase >> testAnUnlitTargetIsFilledWithTheIdleColor
	"A target no laser reaches shows the idle fill."

	| cell renderer |
	cell := TargetCell new.
	renderer := self rendererForTarget: cell.
	self assert: cell isOff.
	self
		assert: renderer centerColor
		equals: LaserGameColors targetCenterColorIdle.
	self
		assert: (renderer newElement children at: 4) background paint color
		equals: LaserGameColors targetCenterColorIdle
```

```smalltalk
TargetCellRendererTestCase >> testALitTargetIsFilledWithTheActiveColor
	"A target the laser reaches shows the active fill, and rendering the cell again picks the new
	color up."

	| cell renderer |
	cell := TargetCell new.
	renderer := self rendererForTarget: cell.
	cell activeSegments at: #west put: true.
	self assert: cell isOn.
	self
		assert: renderer centerColor
		equals: LaserGameColors targetCenterColorActive.
	self
		assert: (renderer newElement children at: 4) background paint color
		equals: LaserGameColors targetCenterColorActive
```

And one test on the board rather than on the renderer, because lighting the target is something the
whole board shows:

```smalltalk
LaserGameBoardElementTestCase >> testFiringTheLaserLightsTheTargetOfANewBoard
	"Firing the laser turns the target on. The cells are built from the model, so a board built
	after the shot shows the lit target. The disc is the last child of the target, since a lit
	target draws the beam under its picture."

	| grid board center |
	grid := GridFactory demoGrid.
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	center := (board cellElementAt: 5 @ 1) children last.
	self assert: (grid at: 5 @ 1) isOn.
	self
		assert: center background paint color
		equals: LaserGameColors targetCenterColorActive
```

Read the order of that test carefully, because it marks the edge of what we have built. It fires the
laser **and then** builds the board. A board already on the screen would show nothing new: the cells
were built from the model as it was, and nothing tells them the model has changed. Making a board
notice is the job of the next chapter.

Open both examples and compare them:

```smalltalk
LaserGameBoardElement openExample
```

```smalltalk
LaserGameBoardElement openExampleWithLaserFired
```

Twenty-five cells, ten with a mirror, and one with a crosshair, a ring and a disc that is pale blue
in the first window and pale yellow in the second.

# Assembling the game window

Everything so far has been opened by a class method on a renderer or on the board. That is right for
working on a drawing, and it is not a game. A game is a window: the board, a panel beside it for the
controls, and a margin around both. Something has to own that window, and this chapter writes it.

## The class

```smalltalk
BlElement << #LaserGameElement
	slots: { #grid . #board . #controlPanel };
	tag: 'Graphics';
	package: 'Laser-Game'
```

The game plays on a grid, and it holds its two children: the board element, and the panel beside it.
Later chapters add a slot or two as the game grows, but these three carry the next several chapters.

Note that the game holds the grid, and the board also holds the grid. That is not a duplicate: the
game is handed a grid and hands it on, which is how it can later be given another one.

## The numbers

Two constants: how wide the panel is, and how much margin there is around everything.

```st
LaserGameElement class >> panelWidth
	"Answer the width, in pixels, of the control panel beside the board."

	^ 110
```

```smalltalk
LaserGameElement class >> gameMargin
	"Answer the margin, in pixels, between the edge of the game and what it holds."

	^ 10
```

The panel width is a first version. In *Buttons of one width*, at the end of the book, the panel
states its width from the buttons it has to hold instead of beside them, and the number becomes a
hundred and thirty. Until then, a hundred and ten.

Both sit on the *class* side, because the size of a game can be asked for before a game exists —
which is exactly what opening a window needs:

```st
LaserGameElement class >> extentForGrid: aGrid
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side."

	^ (LaserGameBoardElement extentForGrid: aGrid) + (self panelWidth @ 0)
	  + (2 * self gameMargin)
```

That is the third time this shape of arithmetic has appeared: `CellRenderer cellExtent` for a cell,
`LaserGameBoardElement extentForGrid:` for the board, and now the window. Each one is written in
terms of the one below it, and nothing multiplies a cell size by a grid size twice. That is the
whole trick to sizes that stay consistent.

This version takes its height from the board. *Adding more game stats*, in the last part of the
book, changes it to the height of the taller of the board and the panel, because four counters can
stand taller than a board of few rows.

## Two panes

```st
LaserGameElement >> initialize
	"A game is a row of two: the board, and the control panel beside it. The margin around both is
	padding, and the color behind them shows through it."

	super initialize.
	self background: LaserGameColors gameWindowColor.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin)
```

`BlLinearLayout horizontal` puts its children in a row, in the order they were added. That is the
second layout of the book, after the grid layout of the board, and between them they do nearly
everything this game needs.

The margin is **padding** on the game, not an offset on each child. Padding is reserved by the
element once, and every child is placed inside it. Had we given each child a margin instead, the
same constant would appear twice, and a change to it would have to be right in both places. Reach
for padding when the space belongs to the container, and for a margin when it belongs to the child.

*Add a counter and window colours*, later in the book, replaces this method: the panel moves to the
left of the board, and the flat background becomes a colour ramp.

Setting the grid builds the two panes, so the same game element can be handed another grid:

```smalltalk
LaserGameElement >> grid: aGrid
	"Play on aGrid. Setting the grid rebuilds what I hold, so the same game element can show
	another grid."

	grid := aGrid.
	self rebuild
```

```st
LaserGameElement >> rebuild
	"Replace what I hold with a board showing my grid and a control panel beside it, and take the
	size the two of them and my margins need."

	self removeChildren.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: board.
	self addChild: controlPanel.
	self extent: (self class extentForGrid: self grid)
```

Write the three accessors — `grid`, `board` and `controlPanel`. Only the grid has a setter, and it
is the one above.

The last line asks for the size the arithmetic gives. It belongs to rebuilding rather than to
`initialize`, because a game with no grid has no size to ask for. That ordering — *a thing takes its
size when it knows what it holds* — comes back every time the game grows.

## The blank panel

The panel starts as nothing but a coloured rectangle. The controls go in next chapter:

```st
LaserGameElement >> newControlPanel
	"Answer the control panel: a blank column of a fixed width, as tall as the board beside it. The
	controls go in at the next step."

	| panel |
	panel := BlElement new.
	panel background: LaserGameColors controlPanelColor.
	panel extent: self class panelWidth
		@ (LaserGameBoardElement extentForGrid: self grid) y.
	^ panel
```

Writing it this way, and not waiting until there is something to put in it, is worth a word. The
window arithmetic, the layout, and the margins are all exercised *now*, with a rectangle standing in
for the panel. When the real panel arrives, the only new thing to get wrong is the panel itself.

Two colours join `LaserGameColors`:

```smalltalk
LaserGameColors class >> gameWindowColor
	"Answer the color behind the whole game: the margin around the board and the control panel."

	^ Color r: 0.369 g: 0.369 b: 0.505
```

```st
LaserGameColors class >> controlPanelColor
	"Answer the color of the control panel beside the board: a blank white rectangle, with the
	buttons still to come."

	^ Color white
```

The panel colour is a first version too: *Add a counter and window colours* paints the panel
transparent, so that the ramp behind the window runs behind it. The rule of the colours chapter
holds in both versions — neither colour is written as a literal anywhere else.

The board goes in first and the panel second, so the board is on the left. Turning the game around
later means swapping two `addChild:` sends, and that is what a later chapter does.

## Opening it

The game gets the same two class methods the board element has, one to build and one to open, plus
an example:

```smalltalk
LaserGameElement class >> on: aGrid
	"Answer a game element playing on aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
```

```st
LaserGameElement class >> openOn: aGrid
	"Open a space showing a game on aGrid and answer it.

	LaserGameElement openOn: GridFactory demoGrid"

	| space |
	space := BlSpace new.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: (self on: aGrid).
	space show.
	^ space
```

```smalltalk
LaserGameElement class >> openExample
	"Open the demo grid of the tests: the five by five board with ten mirrors and one target.

	LaserGameElement openExample"

	<sampleInstance>
	^ self openOn: GridFactory demoGrid
```

The space is given the size the game asks for, so the window fits the game exactly and there is no
second margin around it. *A window the player can resize* rewrites `openOn:` so that the game
follows the window when the player drags its corner; the version above is the one this chapter
leaves in the image.

## Checking it

Six tests, and not one of them opens a window. The arithmetic first, both as the sum of its parts
and as the plain number it comes to for the demo grid:

```st
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins
	"The game is as wide as the board, the panel beside it and a margin on each side, and as
	tall as the board with a margin above and below."

	| grid expected |
	grid := GridFactory demoGrid.
	expected := (LaserGameBoardElement extentForGrid: grid)
	            + (LaserGameElement panelWidth @ 0)
	            + (2 * LaserGameElement gameMargin).
	self assert: (LaserGameElement extentForGrid: grid) equals: expected.
	self
		assert: (LaserGameElement extentForGrid: grid)
		equals: 5 * CellRenderer cellExtent + (110 @ 0) + 20
```

Two assertions about one answer, and they are not redundant. The first says the sum is built from
the right parts; it would still pass if every part were wrong. The second says the answer is 380 by
270, which is a number you can check against the window on your screen. A test that only restates
the implementation proves nothing, and a test that only states a number does not say where the
number came from.

Then the two panes, in order:

```st
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel
	"A game is a row of two children: the board first, the control panel beside it."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game children size equals: 2.
	self assert: game children first equals: game board.
	self assert: game children second equals: game controlPanel.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
```

The panel keeps its width whatever the grid is, which is the point of a constant:

```st
LaserGameElementTestCase >> testControlPanelIsAFixedColumnAsTallAsTheBoard
	"The panel keeps its width whatever the grid is, and it is as tall as the board beside it.
	Sizes are read from the layout constraints, since nothing is laid out yet."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: (LaserGameBoardElement extentForGrid: grid) y.
	self
		assert: game controlPanel background paint color
		equals: LaserGameColors controlPanelColor
```

And handing the game another grid replaces what it holds rather than adding to it:

```smalltalk
LaserGameElementTestCase >> testSettingAnotherGridRebuildsTheGame
	"Handing the game another grid throws away the board and the panel it held and builds them
	again for the new grid, so its size follows."

	| game oldBoard smallGrid |
	game := LaserGameElement on: GridFactory demoGrid.
	oldBoard := game board.
	smallGrid := Grid new.
	game grid: smallGrid.
	self assert: game children size equals: 2.
	self deny: game board identicalTo: oldBoard.
	self assert: game board grid equals: smallGrid.
	self assert: game board children size equals: 1.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: smallGrid) x
```

`deny:identicalTo:` is the assertion that matters there. A board that had merely been emptied and
refilled would pass an equality check; this one insists that it is a *different* board, which is
what `rebuild` promises.

```smalltalk
LaserGameElementTestCase >> testBoardShowsTheGridOfTheGame
	"The board the game holds renders the game's own grid, one element per cell."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self assert: game grid equals: grid.
	self assert: game board grid equals: grid.
	self assert: game board children size equals: 25
```

The last test reads back the size, the padding, and the colour of the game itself:

```st
LaserGameElementTestCase >> testGameTakesTheExtentItCalculates
	"The game asks for exactly the size its own arithmetic gives, and the margin around its two
	children is padding, so the color behind them shows through it."

	| grid game |
	grid := GridFactory demoGrid.
	game := LaserGameElement on: grid.
	self
		assert: game constraints horizontal resizer size
		equals: (LaserGameElement extentForGrid: grid) x.
	self
		assert: game constraints vertical resizer size
		equals: (LaserGameElement extentForGrid: grid) y.
	self assert: game padding top equals: LaserGameElement gameMargin.
	self assert: game padding left equals: LaserGameElement gameMargin.
	self assert: game padding right equals: LaserGameElement gameMargin
```

Sizes are read from the layout constraints throughout, never from `extent`, for the reason the blank
cell test gave: a fresh element measures `0.0@0.0` until a layout pass runs, and `forceLayout` is
forbidden by a Renraku rule.

## What it looks like

```smalltalk
LaserGameElement openExample
```

A window 380 by 270. The demo board, 250 by 250, on the left. The white panel, 110 wide, beside it.
A ten pixel margin of the window colour around both.

The examples on the renderers and on the board have done their job. From here the game opens itself,
and the next chapter puts the controls in that white column.

# Adding controls

The white column beside the board has been waiting since the last chapter. Two buttons go in it now.
One quits the game, which is easy to describe and easy to write. The other fires the laser, and that
one needs a decision first: should the beam stay on until the player says otherwise, or only while
the button is held down? A button held down is a fiddly thing to play with, so the beam stays on, and
the same button turns it off again. One button, two meanings, and a label that says which one is
waiting.

## A class of its own

The panel was a plain `BlElement` a chapter ago. Now that it holds things and has to keep them up to
date, it becomes a class of its own:

```smalltalk
BlElement << #LaserGameControlPanelElement
	slots: { #game . #quitButton . #fireButton };
	tag: 'Graphics';
	package: 'Laser-Game'
```

Three slots for now. The panel gains more of them as it gains buttons and counters, so this is the
definition as this chapter leaves it and not the one the finished game has.

It keeps a reference to the game and not to the grid. A button is an instruction from the player —
*quit*, *fire* — and an instruction goes to the game, which decides what it means for the model and
then shows the result. The panel never touches the grid.

```st
LaserGameControlPanelElement >> initialize
	"A panel is a blank column with its buttons at the bottom left corner. A frame layout puts a
	child where it is aligned, which is what that corner needs."

	super initialize.
	self background: LaserGameColors controlPanelColor.
	self layout: BlFrameLayout new
```

`BlFrameLayout` is the third layout in the book, and the simplest to describe: every child says
which corner, edge, or centre of the frame it wants, and the layout puts it there. A grid layout
places children in rows and columns, a linear layout places them one after another, and a frame
layout places each one on its own. Buttons in the bottom left corner is one child in one corner, so
a frame is what that needs. The counters that arrive in Section 4 take the top left corner of the
same frame, and that is the reason a frame was chosen over a second linear layout.

This version has no counters in its comment yet. *Add a counter and window colours* adds them.

```smalltalk
LaserGameControlPanelElement class >> on: aGame
	"Answer a control panel for aGame."

	| panel |
	panel := self new.
	panel game: aGame.
	^ panel
```

```smalltalk
LaserGameControlPanelElement >> game: aGame
	"Control aGame. Setting the game builds the buttons, since a button acts on a game."

	game := aGame.
	self rebuild
```

That setter is the same pattern as `LaserGameBoardElement >> grid:`: being given what you work on is
the moment you can build what shows it. Write the readers `game`, `quitButton` and `fireButton` as
well; only the game gets a setter.

## One method makes a button

Toplo, the widget library that sits on Bloc, has the button. `ToButton` already knows how to look
pressed, how to look hovered, how to look disabled, and how to draw a label, because all of that
comes from the skin of the current theme. What is left for us is the label, the size, and what a
click does:

> **Note.** *Buttons of one width*, at the end of the book, adds one line to this method so that a
> button centres its label. It is quoted here as it reads before that.

```st
LaserGameControlPanelElement >> newButton: aLabel action: aBlock
	"Answer a labelled button that evaluates aBlock when it is clicked. Toplo gives the look and
	the click, so only the label, the size and the action are left here."

	| button |
	button := ToButton labelText: aLabel.
	button extent: self class buttonWidth @ self class buttonHeight.
	button clickAction: aBlock.
	^ button
```

`clickAction:` takes a block — a piece of code kept for later and run when the button is clicked.
Nothing in the block runs now. It runs on the click, which is why the block can mention a game that
has not been played yet.

The two buttons are then one line each:

```smalltalk
LaserGameControlPanelElement >> newQuitButton
	"Answer the button that closes the game."

	^ self newButton: 'Quit' action: [ self game quit ]
```

```smalltalk
LaserGameControlPanelElement >> newFireButton
	"Answer the button that fires the laser, or stops it if it is already firing. Its label says
	which of the two a click will do."

	^ self newButton: self fireButtonLabel action: [ self game toggleLaser ]
```

```smalltalk
LaserGameControlPanelElement >> fireButtonLabel
	"Answer what the fire button says: what a click will do, not what the laser is doing."

	^ self game laserIsActive
		  ifTrue: [ 'Stop' ]
		  ifFalse: [ 'Fire' ]
```

That last method is the whole rule of a toggle button, and it is worth stating out loud because it
is easy to get backwards: **the label names the action the click will cause, not the state the game
is in.** Beam off, the button says *Fire*. Beam on, it says *Stop*. A button labelled with the state
instead would say *Fire* while the beam is already firing, and the player would click it to fire
again and watch the beam go out.

## Where the buttons sit

Three numbers. A button is forty wide and twenty tall, and everything is ten pixels from everything
else:

> **Note.** *Buttons of one width*, at the end of the book, widens a button to fifty pixels, so that
> its longest labels fit inside it. It is quoted here as it reads before that.

```st
LaserGameControlPanelElement class >> buttonWidth
	"Answer the width, in pixels, of a control panel button."

	^ 40
```

```smalltalk
LaserGameControlPanelElement class >> buttonHeight
	"Answer the height, in pixels, of a control panel button."

	^ 20
```

```smalltalk
LaserGameControlPanelElement class >> buttonGap
	"Answer the gap, in pixels, between the buttons and around the row they sit in."

	^ 10
```

Now the placing. There is a way to do this by hand: ask where the bottom left corner of the panel
is, subtract a button height and a gap, place the first button there, add a button width and a gap,
place the second one. It works, and every later button costs another line of that arithmetic, and
every change to a number means reading all of it again.

The alternative is to let a layout do the arithmetic. The two buttons go in a row, the row says which
corner it wants, and nothing is computed here at all:

```st
LaserGameControlPanelElement >> newButtonRow
	"Answer the row of buttons: Quit first, then Fire, one gap apart."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	row margin: (BlInsets all: self class buttonGap).
	row addChild: quitButton.
	row addChild: fireButton.
	^ row
```

Four Bloc things in one method, and each is worth a sentence:

- `BlLinearLayout horizontal` lays children out side by side, and `cellSpacing:` is the gap it leaves
  between them. Ten pixels between *Quit* and *Fire*, stated once.
- `fitContent` on both axes means the row is exactly as big as the buttons inside it. A row is not a
  thing the player sees; it is a bag that holds two buttons in order, so it should have no size of
  its own.
- `frame horizontal alignLeft` with `frame vertical alignBottom` is the corner. These are the
  constraints the frame layout of the panel reads, which is why they are `frame` constraints and the
  two above are not.
- `margin:` is the gap *outside* the row — between the row and the two panel edges it is aligned to.
  Padding would be inside, between the row's edge and the buttons, and would push the buttons
  without moving the row. The distinction turns up again in the next section, on the game itself.

Then the panel builds its buttons and its row, and takes its own size:

```st
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with a fresh row of buttons for my game, and take the width of a panel
	and the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	self addChild: self newButtonRow.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y
```

Both of those are shown as this chapter writes them. *Add a counter and window colours* puts a
counter above the buttons, and *Add move counter and randomizer* adds a third button and gives the
panel a column of button rows rather than one row, so the finished game builds a row with
`newRowOfButtons:` and `rebuild` fills a good many more variables than these two.

Sizing the panel moves here too, out of the game: a panel knows it is `panelWidth` wide and as tall
as the board beside it, so it is the panel that should say so. The game asked for that size in the
last chapter; now it only has to leave room for it.

## What the buttons do

The game gains the two actions the buttons send it, and the question they ask it:

```smalltalk
LaserGameElement >> laserIsActive
	"Answer whether the laser is firing. The grid knows; I only ask."

	^ self grid laserIsActive
```

```smalltalk
LaserGameElement >> toggleLaser
	"Fire the laser, or stop it if it is already firing, and show the result. This is what the fire
	button does."

	self laserIsActive
		ifTrue: [ self grid stopLaser ]
		ifFalse: [ self grid fireLaser ].
	self refresh
```

```st
LaserGameElement >> quit
	"Close the game, by closing the space it is shown in."

	self space ifNotNil: [ :aSpace | aSpace close ]
```

`space` is the window the element is shown in, and it is `nil` until a space adopts the element.
A game built in a test has no space, so `ifNotNil:` is not caution for its own sake: it is the
difference between a test that passes and a test that errors.

*Add move counter and randomizer* makes Quit ask before it closes, because by then Quit sits next to
four other buttons and is easy to hit by accident. This method keeps its body and takes the name
`close` there, and `quit` becomes the question.

```st
LaserGameElement >> refresh
	"Show what the model says now: redraw the cells and put the right label on the fire button."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel
```

One method that shows everything the model currently says. Every action on the game ends by sending
it, which is why no action has to remember what it changed. `refresh` grows as the window grows —
*Add a counter and window colours* adds the counters to it — and the callers never change.

There is a design choice hiding in the middle of `toggleLaser`, and it is worth naming. The
alternative to one method that looks at the state is a button whose action block is *replaced* every
time the label changes: a Fire button whose block fires, swapped for a Stop button whose block stops.
That works, and it puts the knowledge of what state the game is in into two places — the label and
the block — which then have to agree. One method that asks the model keeps it in one place. The
model is the thing that knows.

The name is `toggleLaser` and not `fireLaser`, for two reasons. A method that may *stop* the laser
should not be called firing it. And `Grid >> fireLaser` already has that name, for the thing that
really does fire it.

Finally, the game's `newControlPanel` answers the new class instead of a blank element:

```smalltalk
LaserGameElement >> newControlPanel
	"Answer the control panel: the fixed-width column of buttons that sits beside the board."

	^ LaserGameControlPanelElement on: self
```

## Holding the button instead of looking for it

Run the game now and the button works, but the label does not change. Clicking *Fire* lights the
target and the button still says *Fire*. This is the bug every toggle has at least once: something
has to put the new label on the button, and nothing does.

```smalltalk
LaserGameControlPanelElement >> updateFireButtonLabel
	"Make the fire button say what a click will do now. I hold the button in an instance variable,
	so it does not have to be looked for."

	self fireButton labelText: self fireButtonLabel
```

Two methods, one word apart in their names, and the difference between them is the whole lesson:
`fireButtonLabel` *answers* the label, and `updateFireButtonLabel` *puts it on the button*. The first
is a question with no side effect, and can be asked in a test without a window. The second changes
something, and is sent from `refresh`.

That `self fireButton` is the reason the panel became a class with slots in it. A panel that built
its buttons and handed them straight to a layout would have to go looking for the fire button among
its children when the label changed — walk the children, find the one whose label is *Fire* or
*Stop*, hope no other button ever says that. Holding the button in an instance variable the moment
it is built costs one slot and removes the search entirely.

## Checking it

The panel's tests are built on one helper, so that no test has to assemble a game:

```smalltalk
LaserGameControlPanelElementTestCase >> newPanel
	"Answer the control panel of a game playing on the demo grid, with the laser not firing."

	^ (LaserGameElement on: GridFactory demoGrid) controlPanel
```

The first test is the shape of the panel: what it holds, in what order, and what the buttons say.

```st
LaserGameControlPanelElementTestCase >> testPanelHoldsARowOfTwoButtons
	"The game's panel is a control panel element. It holds one child, the row, and the row holds
	the Quit button then the Fire button."

	| panel row |
	panel := self newPanel.
	self assert: panel class equals: LaserGameControlPanelElement.
	self assert: panel children size equals: 1.
	row := panel children first.
	self assert: row children asArray
		equals: { panel quitButton. panel fireButton }.
	self assert: panel quitButton class equals: ToButton.
	self assert: panel fireButton class equals: ToButton.
	self assert: panel quitButton labelText asString equals: 'Quit'.
	self assert: panel fireButton labelText asString equals: 'Fire'
```

The second is where the row sits:

```st
LaserGameControlPanelElementTestCase >> testButtonRowSitsAtTheBottomLeftOneGapIn
	"The row is aligned to the bottom left corner of the panel, one gap away from both edges, and
	the buttons inside it are one gap apart."

	| panel row |
	panel := self newPanel.
	row := panel children first.
	self
		assert: row constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: row constraints frame vertical alignment
		equals: BlElementAlignment bottom.
	self
		assert: row margin
		equals: (BlInsets all: LaserGameControlPanelElement buttonGap).
	self
		assert: row layout cellSpacing
		equals: LaserGameControlPanelElement buttonGap
```

Both are quoted as this chapter writes them. Once the panel holds a counter column as well as a
button column, `panel children first` is no longer the row, and both tests read it from
`panel buttonRow` instead.

Notice what these two tests do *not* do: they never ask where the row actually ended up in pixels.
They assert the alignment, the margin, and the spacing — the three numbers we wrote — and leave the
arithmetic to Bloc. A test that asserted a pixel position would be asserting Bloc's layout code,
would need a laid-out element to do it, and would break the first time the panel changed width.

The label rule gets two tests, one for what it answers and one for it reaching the button:

```smalltalk
LaserGameControlPanelElementTestCase >> testFireButtonSaysWhatAClickWillDo
	"The label names the action, not the state: Fire while the laser is off, Stop while it fires."

	| panel |
	panel := self newPanel.
	self deny: panel game laserIsActive.
	self assert: panel fireButtonLabel equals: 'Fire'.
	panel game grid fireLaser.
	self assert: panel fireButtonLabel equals: 'Stop'.
	panel game grid stopLaser.
	self assert: panel fireButtonLabel equals: 'Fire'
```

```smalltalk
LaserGameControlPanelElementTestCase >> testUpdatingTheLabelPutsItOnTheButton
	"The label on the button follows the grid only when it is updated, which is what a click does."

	| panel |
	panel := self newPanel.
	panel game grid fireLaser.
	self assert: panel fireButton labelText asString equals: 'Fire'.
	panel updateFireButtonLabel.
	self assert: panel fireButton labelText asString equals: 'Stop'
```

They are separate on purpose, and the second one is the more interesting of the two. Look at its
third line: the grid is already firing and the button still says *Fire*. That assertion is not a
mistake — it is the bug of the previous section, written down and kept. The label follows the model
only when something updates it, and forgetting to update is the mistake that is easy to make twice.
A test that fires the grid and then expects *Stop* without an update would hide exactly the thing
worth remembering.

Two more tests check the sizes: `testEveryButtonIsFortyByTwenty`, which reads both numbers from the
layout constraints of each button, and `testPanelIsAPanelWideColumnAsTallAsTheBoardOrItsContents`,
which is the sizing that moved out of the game and into `rebuild`.

Sizes are read from `constraints horizontal resizer size` and not from `extent`, for the reason the
cell element chapter gave: nothing in these tests is laid out, so the extent of a fresh element is
still `0@0`, and what a test can read is the size the element *asked for*.

On the game side, one test does the whole round trip a player makes — click, look, click again —
with no window anywhere:

```smalltalk
LaserGameElementTestCase >> testTogglingTheLaserFiresItAndStopsItAgain
	"The fire button toggles: the first click fires the laser and lights the target, the second
	stops it and puts the target out. The board and the button label both follow. The disc is the
	last child of the target, since a lit target draws the beam under its picture."

	| game target |
	game := LaserGameElement on: GridFactory demoGrid.
	target := game grid at: 5 @ 1.
	game toggleLaser.
	self assert: game laserIsActive.
	self assert: target isOn.
	self
		assert: (game board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorActive.
	self assert: game controlPanel fireButton labelText asString equals: 'Stop'.
	game toggleLaser.
	self deny: game laserIsActive.
	self assert: target isOff.
	self
		assert: (game board cellElementAt: 5 @ 1) children last background paint color
		equals: LaserGameColors targetCenterColorIdle.
	self assert: game controlPanel fireButton labelText asString equals: 'Fire'
```

That single test is this whole chapter: the model toggles, the drawing follows, the label follows,
and the target goes out again when the beam stops. It is also the first test in the book that reads
through three objects to check one click — the game, its board, the cell element — and it is worth
pausing on how cheap that is. No window is opened. No click is simulated. The action a button sends
is a message, so a test can send the same message, and everything the player would see is an object
it can ask.

And quitting a game nobody opened should be harmless, which is worth a test of its own because
`space` is `nil` until a space adopts the element:

```st
LaserGameElementTestCase >> testQuittingAGameThatIsNotOpenDoesNothing
	"Quit closes the space the game is in. A game that was never opened has no space, and asking
	it to quit is harmless."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game space isNil.
	game quit.
	self assert: game children size equals: 2
```

That last assertion is the test's real point: after quitting a game that is not open, the game is
still intact — board and panel, two children. *Add move counter and randomizer* drops this test:
once Quit asks before it closes, a game that was never opened answers the question instead of
closing, and a test of that answer takes its place.

## What it looks like

```smalltalk
LaserGameElement openExample
```

The same window as the last chapter, with two buttons in the bottom left of the white column: *Quit*
and *Fire*. Click *Fire* and the target lights up and the button becomes *Stop*. Click it again and
the target goes out and the button is *Fire* once more. Click *Quit* and the window closes.

The beam itself is still invisible — it is the target reacting that tells us the laser reached it.
Drawing the beam is Section 4.

# A unit test to demonstrate a bug

The window works. The board is drawn, the buttons are there, *Fire* lights the target and *Stop* puts
it out. That is a good moment to look for the bug, because a game that looks right is exactly where
a bug of this shape hides: the kind where the flag says one thing and the cells say another.

This chapter is about the method for finding it. A symptom on the screen is not something you can
work with. A failing test is. So the shape of the work is always the same: make the symptom into an
assertion, watch it fail, read the chain of methods it runs through, find the one that does less than
its name claims, and fix that one.

## Assert the cells, not only the flag

The two tests written for the laser so far check the flag, and the flag is the least interesting
thing in the grid. `laserIsActive` is one boolean that `fireLaser` sets by hand; it would still be
right if the beam never touched a single cell. What a player sees is the cells. So both tests are
strengthened to check two of them: the cell the beam starts from, and the target at `5@1` the demo
grid's mirrors send it to.

```smalltalk
GridTestCase >> testFireLaser

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	self assert: grid laserIsActive.
	cell := grid startingCell.
	self assert: cell isOn.
	cell := grid at: 5 @ 1.
	self assert: cell isOn
```

```smalltalk
GridTestCase >> testStopLaser

	| grid cell |
	grid := self generateDemoGrid.
	grid stopLaser.
	self shouldnt: [ grid laserIsActive ].
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

`isOn` and `isOff` are the two questions a cell answers about its own segments:

```smalltalk
Cell >> isOn
	^self activeSegments values anySatisfy: [:each | each = true]
```

```smalltalk
Cell >> isOff
	^self isOn not
```

A cell is on when *any* of its four sides is lit. That is worth noting now, because the bug in this
chapter is about sides that stay lit when they should not.

Both tests pass. `testStopLaser` passes for an uninteresting reason, though: it stops a laser that
was never fired, so the cells it checks were off before it started. The test is green, and the path
through the code it exercises is the empty one.

## The test that names the bug

The interesting order is the one a player produces: fire, then stop. One test, three lines longer
than nothing, and it is the whole of the bug hunt:

```smalltalk
GridTestCase >> testToggleLaser

	| grid cell |
	grid := self generateDemoGrid.
	grid fireLaser.
	grid stopLaser.
	self shouldnt: [ grid laserIsActive ].
	cell := grid startingCell.
	self assert: cell isOff.
	cell := grid at: 5 @ 1.
	self assert: cell isOff
```

That is the shape to copy whenever two methods undo each other. Testing each one on a fresh object
proves very little: the second of them only has work to do once the first has run. Fire then stop,
push then pop, open then close, add then remove — the test that matters is the pair, in order, on
the same object.

## The mistake this test catches

Here are the two methods it runs through:

```smalltalk
Grid >> fireLaser
	self laserIsActive: true.
	self activateCellsInPath.
```

```smalltalk
Grid >> stopLaser
	self laserIsActive: false.
	self clearCellsInPath.
```

Each lowers or raises the flag and then does the work on the cells. And the work is a pair of
methods that have to be mirror images of each other:

```smalltalk
Grid >> activateCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe activateCell]
```

```smalltalk
Grid >> clearCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe clearCell]
```

One selector apart: `activateCell` against `clearCell`. Walk the path, light each element, or walk
the same path and put each one out.

Now the mistake. It is the easiest one in this whole game to make, because the first line of
`clearCellsInPath` is the line that *looks* like the method:

```st
clearCellsInPath
	self calculatePath.
```

A correct path, computed and then dropped. The method answers without error, the flag goes down,
`laserIsActive` reports false, and every cell the beam was crossing stays lit. Nothing complains.
The only thing that notices is a test that asks a cell.

Write `clearCellsInPath` that way, run `testToggleLaser`, and the failure is on
`self assert: cell isOff` for the starting cell. From a red test, the way to the method is short:
open the failure in the debugger, step into `stopLaser`, step into `clearCellsInPath`, and look at
what it does with the path it just built. The debugger is the fastest reader of this bug because the
answer is not a wrong value anywhere — it is a line that is missing.

## Seeing the bug without breaking the code

A bug nobody can see is a poor lesson, and putting a broken method back in the image to look at it
is a poor habit. The grid can be made to misbehave from a playground instead, because `stopLaser` is
three statements and the broken version is the same three with the last one doing nothing:

```smalltalk
| grid |
grid := GridFactory demoGrid.
grid fireLaser.
"The broken version of stopLaser: lower the flag, calculate the path, clear nothing."
grid laserIsActive: false.
grid calculatePath.
grid laserBeamPath count: [ :pe | pe cell isOn ]
```

It answers `9`. Every cell along the beam is still lit, the starting cell among them. That is the
useful detail the counting brings out: the fault was not about the target cell at all, even though
the target is where a player notices it. Nine cells are wrong, and the one with a picture on it is
the one that shows.

The same snippet with the real `stopLaser` in the middle answers `0`:

```smalltalk
| grid |
grid := GridFactory demoGrid.
grid fireLaser.
grid stopLaser.
grid calculatePath.
grid laserBeamPath count: [ :pe | pe cell isOn ]
```

A playground that can play a broken version of a method against real objects is worth remembering.
It gives the symptom, and the count, and the answer to *how many* and *which ones*, without a single
edit to the package.

## The chain the fix runs down

`clearCell` is sent to a path element, which hands it to its cell, which resets its segments. Three
one-line methods, and each of them mirrors one on the lighting side:

```smalltalk
LaserPathElement >> activateCell
	self cell laserEntersFrom: self entrySide
```

```smalltalk
LaserPathElement >> clearCell
	self cell clearCell
```

```smalltalk
Cell >> clearCell
	self initializeActiveSegments
```

And the last one does not write any new code at all. Putting every side of a cell out is exactly
what a fresh cell already does, so clearing reuses the method the cell is initialized with:

```smalltalk
Cell >> initializeActiveSegments
	self activeSegments: Dictionary new.
	self activeSegments at: #north put: false.
	self activeSegments at: #east put: false.
	self activeSegments at: #south put: false.
	self activeSegments at: #west put: false.
```

That is worth noticing. "Reset it to how it started" and "initialize it" are the same operation, and
whenever the second one is already written as a method of its own, the first one is a single send.
It is also why `clearCell` is correct for a cell the beam crossed twice: it does not subtract a
side, it puts all four out.

## What this chapter is really teaching

Four habits, and they are the same four every time:

1. **Assert what the player sees, not the flag that implies it.** A boolean the code sets by hand
   agrees with itself. The cells are the thing that can disagree.
2. **Test the pair, in order.** Methods that undo each other are only interesting together.
3. **Let the failing test pick the method.** The debugger opened on a red test puts you inside the
   method with the bug in it, which beats reading the whole class looking for it.
4. **Suspect the method that does less than its name.** `clearCellsInPath` that clears nothing is
   not a wrong calculation; it is a missing line. Those are invisible on a reading and obvious under
   an assertion.

## Checking it

Run the whole package. Every test is green, including the three laser tests of this chapter, and the
grid now toggles correctly however many times it is asked to.

Section 2 is finished. The game can be opened, it draws its board, its mirrors, and its target, and
one button fires the laser and stops it again. What it cannot do is let the player touch anything on
the board. That is the next section, where the cells start listening to the mouse.

