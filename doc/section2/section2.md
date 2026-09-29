<!-- Tutorial Section 2 covers pages 035B to 073 of tut2007/html.
     Pages 035B-048A (the beam path work) are not ported into this file yet;
     their text lives in SectionOne/11-BeamPath.pier.
     This file starts at page 049. -->

# Game Graphics

<!-- http://squeak.preeminent.org/tut2007/html/049.html
     http://squeak.preeminent.org/tut2007/html/050.html -->

A lot of our basic model is coded, so we can take a crack at the graphics now. To keep things simple we focus on the two dimensional graphics for the game grid and its cells. User interaction comes later.

A good place to start is working out how we draw a cell. What do we know about it? It is square. We have not decided on its size yet. It has a border, and a background color we can pick freely.

## A decision the original tutorial made differently

The original tutorial was written for Squeak 3.9 and used Morphic. It considered two designs. The first was one graphical object for the board and one for each cell. The second was a single `SketchMorph` for the whole board, holding one `Form` — a bitmap — with every cell drawing its borders and contents directly into that shared bitmap at a computed offset. The tutorial chose the second design.

We take the first one, and we use Bloc instead of Morphic.

The reason is not fashion. A cell that owns its own element gets three things for free that the shared bitmap design has to compute by hand:

- **Hit testing.** Bloc delivers a click to the element under the pointer. With one bitmap for the whole board, every click has to be turned into a board offset and then into a cell location by arithmetic. Section 3 of the original tutorial spends several pages on that arithmetic.
- **Redrawing.** Changing one cell means marking one element as dirty. In the bitmap design the cell has to redraw itself into the board form, and the board has to be told it changed.
- **Overlays.** The hint arrows of Section 3 become child elements that are added and removed. In the bitmap design they are pixels that have to be painted, remembered and painted over again.

Bloc draws with Alexandrie, a vector engine. That has a second consequence we will use repeatedly: shapes are described by geometry, not by pixels. The mirror is a line, the target is a circle, the hint arrows are polygons. None of them needs a bitmap, and none of them needs the flood fill the original tutorial used to make its arrow masks — which is just as well, since `Form >> floodFill:at:` no longer exists in Pharo.

## The rendering class

What we keep from the original is the idea of a renderer: an object that knows how to represent one cell. It holds the location of the cell inside the grid, and the grid itself, so it can always ask the model for the cell it represents.

```smalltalk
Object << #CellRenderer
	slots: { #cellLocation . #grid };
	tag: 'Graphics';
	package: 'Laser-Game'
```

Note what is *not* there: the original had a third instance variable for the board form. We do not need it. A renderer answers its own element, and the board holds those elements as children.

> **Porting note.** If you are reading the code of this project rather than typing it yourself, the class still carries a third instance variable `targetForm` and the `Form` based drawing methods of the 2007 version. They are dead ends on the new stack and they disappear step by step, as each one gets its Bloc replacement. Nothing new uses them.

Create the accessors for the two instance variables before continuing. The cell itself is not stored, it is read from the model:

```smalltalk
CellRenderer >> cell
	^self grid at: self cellLocation.
```

## A rendering hierarchy

Just as we did with the grid direction hierarchy, each subclass says how it is selected. Create three subclasses of `CellRenderer`: `BlankCellRenderer`, `MirrorCellRenderer` and `TargetCellRenderer`. Each one answers the model class it renders:

```smalltalk
BlankCellRenderer class >> modelClass
	^ BlankCell
```

The mirror and target renderers do the same thing with their own model class. On the superclass side, the method is left to the subclasses:

```smalltalk
CellRenderer class >> modelClass
	"Answer the Cell subclass I render. Each concrete renderer answers exactly one."

	^ self subclassResponsibility
```

## Finding the right renderer

The technique for finding the renderer of a cell is the one we met before: no case statement, just ask the subclasses.

```smalltalk
CellRenderer class >> rendererFor: aCell
	"Answer the renderer class that renders aCell."

	^ self subclasses
		  detect: [ :each | each modelClass = aCell class ]
		  ifNone: [ self error: 'No renderer for ' , aCell class name ]
```

And a renderer is created for a cell within its grid:

```smalltalk
CellRenderer class >> rendererFor: aCell grid: aGrid
	"Answer a renderer for aCell positioned within aGrid. Cell geometry needs no target form."

	| renderer |
	renderer := (self rendererFor: aCell) new.
	renderer
		cellLocation: aCell gridLocation;
		grid: aGrid.
	^ renderer
```

## Unit tests

We can write tests to validate that renderer selection works as we expect. The first is the test from the original tutorial:

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

That test names the three pairs by hand, so it stops telling the truth the day we add a fourth cell kind and forget its renderer. This one does not:

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

And selection has to fail loudly for anything that is not a cell, rather than answering some arbitrary renderer:

```smalltalk
CellRendererTestCase >> testRendererForUnsupportedModelIsAnError

	self should: [ CellRenderer rendererFor: 42 ] raise: Error
```

Run the unit tests and check the results. Make sure the new test case is included in the tests you run. Everything should be green before going on.

We have the hierarchy and the selection. What a renderer actually draws is the subject of the next pages.

# Rendering The Cells

<!-- http://squeak.preeminent.org/tut2007/html/051.html
     http://squeak.preeminent.org/tut2007/html/052.html -->

What do we want these new renderer classes to do? Draw a cell. We begin with the blank cell, because it is the one with nothing inside it: if we can draw a blank cell we have the background and the border, and every other cell is that plus its own contents.

When it comes to graphics, my own style of work is to get something visual quickly and then find out what is right and what is wrong by changing the code and looking again. Pharo is an excellent environment for that, and it is normal to throw code away as we learn.

## Something on the screen first

The original tutorial opened a workspace, made a grid and a `Form`, and displayed that form near the corner of the World. There is no World on the new stack, and no form. The equivalent is a `BlSpace`: a window with a root element we can add children to.

We put the experiment in a method rather than a workspace, so that it stays with the code and keeps working:

```smalltalk
CellRenderer class >> openExample
	"Open one blank cell in a space of its own, to look at it and change it.
	This is the Bloc equivalent of the workspace experiment of the original tutorial.

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

The default grid is full of blank cells, so an arbitrary location gives us a blank cell to draw without any setup. The space is three cells wide and three cells tall, so that the single cell we draw sits inside it with room around it and we can see its edges.

Evaluate `CellRenderer openExample`. It fails, because `newElement` does not exist yet. Let us write it.

## One element per cell

Every cell has a background and a border, and every cell kind has its own contents. That is exactly the split the original tutorial made, and we keep it: the abstract class draws what all cells share, and each subclass draws its own contents.

```
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

That is the method as this chapter writes it. Section 3 changes its second line: a cell element becomes an object of its own, `LaserGameCellElement`, so that a click can be answered by the cell it landed on. Everything else about the method stays as it is here, and the block above is shown untagged because it is no longer what the image holds.

A cell is a square, so the geometry is a rectangle and the size is the cell extent. The three `render...On:` messages are the three things worth varying. The first two are the same for every cell:

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

The third does nothing here. A blank cell has nothing inside it, so the method that draws the contents is an empty hook that the other renderers override:

```smalltalk
CellRenderer >> renderContentsOn: anElement
	"Draw what is inside the cell, as children of anElement. A cell with nothing inside
	draws nothing, so this is empty here and overridden by the subclasses that have
	contents."
```

An empty method is a deliberate statement here, not an oversight: it says a blank cell is complete. Do not give `BlankCellRenderer` its own empty override — a method identical to the one it inherits is a defect the code critic reports, and rightly.

Evaluate `CellRenderer openExample` again. A grey square with a thin border appears in a small window. That is the first cell of the game.

## Two decisions that came from the pixels

The original tutorial reached this point and had to answer two questions. We have to answer them too, and the answers are different because the drawing is different.

**How big is a cell?** The original chose 30x30 pixels here, and raised it to 50x50 much later, in Section 5, once its unit tests had stopped depending on the number. We start at 50x50, because the code we inherited already carries that value and because it leaves room for the mirror, the target and the hint arrows to be legible. Nothing in the tests below depends on the number either — each one asks `CellRenderer cellExtent` rather than writing a size down:

```
CellRenderer class >> cellExtent
	^50@50
```

This is the method as this chapter writes it; Section 4.3 gives it the comment that says every other size in the package is derived from it.

**Who pays for the border?** In the original, the border was a pixel drawn along the inside edge of each cell, so that the borders did not add to the size of the board. We get that property from Bloc for free: a Bloc border is painted inside the bounds of its element. A one pixel border changes nothing about the size of the cell or the spacing of the grid.

```smalltalk
CellRenderer class >> borderWidth
	"Answer the width, in pixels, of the border drawn inside the edges of every cell."

	^ 1
```

That is also the end of a whole computation the original needed. Its next step was a class method to work out how large the target form must be, from the cell size, the border width and the grid dimensions. We never allocate a bitmap for the board, so there is no size to compute: the board will be a Bloc layout holding one element per cell, and the layout works out its own extent. The page of the original tutorial that adds `formExtentForGrid:` has no counterpart on this stack.

## A test for a blank cell

The experiment is a method, but it is not a test — it proves nothing without a pair of eyes. This does:

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

The comment at the top of that test is worth expanding on, because it is the first Bloc trap we walk into. Setting the extent of a fresh element does not give it bounds. It records a layout constraint, and the extent stays `0@0` until a layout pass runs. Asking a fresh element for its extent answers zero, which makes for a confusing failure.

There are three ways out, and only one of them is right here.

- Send `forceLayout`. It works on an unattached element, and it is forbidden: Bloc ships a code critic rule, `ReBlocDoNotSendForceLayoutRule`, that reports it. Laying out by hand is how Bloc code ends up fighting the space it lives in.
- Put the element in a space and settle the space. That is the sanctioned way to get a laid out element, and it is what we do when we check the rendering by hand. In a unit test it is a heavy way to find out whether we typed `50@50`.
- Read the constraint we set, which is what the test above does. No layout, no space, and the assertion is about the thing the method under test actually decided.

Run the tests. All green, and the code critic on the new methods is quiet.

The next pages give the blank cells a board to sit on.

# The Game Board

<!-- http://squeak.preeminent.org/tut2007/html/053.html
     http://squeak.preeminent.org/tut2007/html/054.html -->

The original tutorial creates its game class here, `LaserGame`, as a subclass of `Morph`. It holds the grid in an instance variable, and it carries a class method that computes how large the target form has to be, from the cell size, the border width and the grid dimensions.

We create the same thing on the new stack, and the differences are worth naming before the code.

- There is no `Morph`. A board is a `BlElement`, and the board element *is* the thing that shows the cells; it does not own a bitmap that cells draw into.
- The cells are children of the board, placed by a layout. The original had to translate each grid location into a form-relative offset, which is what page 054 sets out to do. We do not compute offsets at all.
- The extent of the board is still worth a method, because a window has to be given a size, but nothing inside the board depends on it.

## The board element

```smalltalk
BlElement << #LaserGameBoardElement
	slots: { #grid };
	tag: 'Graphics';
	package: 'Laser-Game'
```

A board lays its cells out in a grid and takes exactly the size of the cells it holds:

```
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
> **Note.** *Minor Cosmetic Tweaks*, the ninth chapter of Section 5, gives the board the drop shadow of page 201 here.

`BlGridLayout horizontal` fills row by row, and `fitContent` is what replaces the computed form extent: the board asks its children how big they are instead of being told.

## The grid, and rebuilding from it

Create the accessor pair for the instance variable. Setting the grid is not a plain store: a board that shows another grid has to show another set of cells.

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

And a board is built on a grid in one message:

```smalltalk
LaserGameBoardElement class >> on: aGrid
	"Answer a board element showing aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
```

That method is the whole answer to page 054 of the original. The question there was how a cell finds its place on the board; here the cells are added in row-major order and `BlGridLayout` places them. There is no offset arithmetic to write and none to test.

Finding the element of a location is then arithmetic on the child list:

```smalltalk
LaserGameBoardElement >> cellElementAt: aPoint
	"Answer the element showing the cell at aPoint, x being the column and y the row."

	| index |
	index := aPoint y - 1 * self grid numberOfColumns + aPoint x.
	^ self children at: index
```

## The extent, which survives as a convenience

```smalltalk
LaserGameBoardElement class >> extentForGrid: aGrid
	"Answer the extent a board showing aGrid occupies. Cells are laid out edge to edge and
	their borders are painted inside them, so the borders add nothing to this."

	^ CellRenderer cellExtent
	  * (aGrid numberOfColumns @ aGrid numberOfRows)
```

This is the original's form extent calculation, minus the border term. In the original, borders were drawn along the inside edges of cells and therefore added nothing to the total; on Bloc a border is painted inside the bounds of its element, so the same is true for the same reason.

The original put that method on its game morph rather than on the grid, to keep display concerns off the model. We keep that choice: the grid still knows nothing about pixels.

## Opening it

```smalltalk
LaserGameBoardElement class >> openOn: aGrid

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
```

```smalltalk
LaserGameBoardElement class >> openExample
<sampleInstance>
	"Open the demo grid of the tests, which holds mirrors and a target.

	LaserGameBoardElement openExample"

	^ self openOn: GridFactory demoGrid
```

Evaluate `LaserGameBoardElement openExample`. A board of 25 bordered squares appears. The mirror and the target of the demo grid are there in the model, but they are still drawn as blank cells: `renderContentsOn:` is only implemented on the abstract class so far. Their contents come next.

## Tests

The board is tested without opening a window. Every assertion is about structure, and none of it needs a layout pass:

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

One thing is deliberately not asserted. `BlGridLayout` takes its column count through `columnCount:` and keeps it privately, with no reader, so a test cannot ask a layout how many columns it has. Reaching into its instance variables to find out would be testing Bloc, not the game. The placement it produces is checked by opening the example instead: with the 5x5 demo grid, the board settles at 250x250 and the cell at 5@5 sits at 200@200.

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

One test of the previous pages goes away with this step: `testCellOffsetCalculations`, which checked that a renderer computed the right offset for its cell inside the board form. There is no board form and there are no offsets, so the test has nothing to say. The board tests above cover what replaced it.

> **Porting note.** The 2007 `LaserGame` class, a `Morph` with 884 lines covering the control panel, the counters, the undo stack and the mouse handling of Sections 3 to 5, is still in the package, untouched and unused. It is the source we port from, page by page, and it goes away when the last of its pages has a Bloc counterpart.

# Drawing The Mirror

*Pages 055 to 060 of the 2007 tutorial.*

## The factory that is already there

The original writes `GridFactory` on page 055, by moving the grid that `GridTestCase` built by hand into a class of its own, so that both the tests and the game can ask for a board to work with. That class is part of the code we inherited, so nothing has to be written here. Two of its methods carry the whole chapter:

```smalltalk
GridFactory class >> demoGrid
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
	^self randomizedGridOfExtent: 8@10
```

`demoGrid` is a 5 by 5 board holding ten mirrors and one target, which is exactly what this chapter needs: every mirror leans one way or the other, and the target is the one cell that will still be blank when the chapter ends.

> **Porting note.** These methods are quoted as the captured image has them, in the 2007 formatting, without the blank line and the leading space that Pharo's formatter would add today. Code that the port rewrites is shown in the new style; code that the port only reads keeps its original shape.

## Three pages that dissolve

Pages 056 to 059 are about offsets on a shared bitmap. Page 056 finishes `testCellOffsetCalculations` and adds `offsetWithinGridForm` so that a renderer can find its own square on the board form. Pages 057 and 058 draw the four borders at those offsets, then correct the arithmetic of the right and bottom sides, because adjacent cells each painted their own edge and the shared edges came out one pixel thick instead of two. Page 059 points the drawing code at `GridFactory demoGrid` and observes that the mirror and target cells already have their borders, since they inherit them.

None of that has any work left in it here. There is no board form, so there is no offset to compute, and the offset test went away with the previous chapter. Each cell is its own element and its border belongs to it, so the correction of pages 057 and 058 has no subject: `BlGridLayout` places the cells edge to edge, and every cell paints its border inside its own square. What page 059 checks by eye we have already had on the screen since the board element existed.

So the work of this chapter is the one thing pages 056 to 059 were clearing the way for: the contents of a mirror cell.

## How thick, and how far in

A mirror is a diagonal line across its cell, not touching the corners. Two numbers say where it goes and how heavy it is, and both get a name.

```smalltalk
MirrorCellRenderer >> cornerInset
	^8@8
```

```smalltalk
MirrorCellRenderer class >> mirrorWidth
	"Answer the thickness, in pixels, of the mirror. The original drew its diagonal with a two
	pixel pen, and this is that pen."

	^ 2
```

`cornerInset` is the original's, unchanged: the mirror starts eight pixels in from the corner it points at and stops eight pixels short of the opposite one. `mirrorWidth` is new only as a name — the 2007 code drew its diagonal with a two pixel pen, and this is that pen.

## Two leans, one line

`renderContentsOn:` is the hook `newElement` already calls. A mirror asks its cell which way it leans and draws accordingly.

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

`delta` is the last pixel of the cell, one less than the extent, so a 50 by 50 cell runs from 0@0 to 49@49. With an inset of 8@8, a left leaning mirror runs from 8@8 to 41@41, and a right leaning one from 41@8 to 8@41. Those are the original's numbers. What changed is that they are coordinates inside the cell, not inside a board form, so they say the same thing for every cell of the grid.

## Adding the stroke

Both methods end in one place, which is the only method here that knows anything about Bloc.

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

A line has no inside, so nothing about it is filled: the visible mirror is entirely its border. `BlBorder paint:width:` is what makes it blue and two pixels heavy.

`BlOutskirts centered` puts the stroke half on each side of the line. Bloc's default, `BlOutskirtsInside`, would push the whole two pixels to one side, and the mirror would sit off the diagonal by a pixel — the same complaint the original makes on page 060, that the mirror does not look quite centred in its cell.

The child is given the full cell extent rather than the bounding box of the line. Bloc positions a child by its own origin, so a child the size of the cell lets `aPoint` and `anotherPoint` be read straight off the cell, with no offset arithmetic anywhere. That is the last trace of pages 056 to 058 gone.

## Four methods leave

The `Form` versions of this drawing go with the step, since their replacements are in place: `renderContents`, `renderContentsLeanLeft`, `renderContentsLeanRight` and `renderMirror`. `MirrorCellRenderer` keeps its laser masks for now, because the laser is a later chapter.

## Tests

The tests build one mirror cell in a one by one grid, render it, and look at the child.

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

No test writes 8, 41 or 49 down. Every expected point is built from `cornerInset` and `cellExtent`, so raising the cell size, as the original does much later on page 196, moves the mirrors without touching a test.

The last test is the one the original could not easily write: the renderer reads the cell every time it renders, so rotating the cell and rendering again gives the other diagonal, with the ends swapped along x and left where they were along y.

Opening the example shows it: the demo grid renders as 25 cells, ten of which hold one line each, which is the ten mirrors of `GridFactory demoGrid`. The target at 5@1 is still an empty bordered square, because its contents are the next chapter.

```smalltalk
LaserGameBoardElement openExample
```

# Management of Colors

*Page 061 of the 2007 tutorial.*

The original spends this page gathering the colors it has been choosing as it went — the arbitrary board background from the workspace, the black border, the black mirror — into one class, so that they can be tweaked later, or one day chosen by the player. `LaserGameColors` is that class, and it came with the code we inherited:

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

Three more are there for later pages: `laserBeamCenterColor` and `laserBeamSplatterColor` for the beam of Section 4, and `allowActionArrowColor` and `denyActionArrowColor` for the push hints of Section 3.

Nothing has to be written, then, but the page is still worth a step, because it states a rule that the port has to keep. The colors live in one place, and every element asks for its paint by name. That rule holds on the Bloc side as it stood: the board background, the cell border, the mirror and now the target all name a `LaserGameColors` method, and no `Color` literal appears in any of the new code. The literals that remain in the package are all inside the `Form` and `Morph` methods that have not been ported yet, and they go with them.

What did change is that these answers are handed to Bloc rather than to a `Form`. `LaserGameColors` answers plain `Color` instances, and Bloc wraps them itself: `BlBorder paint:width:` makes a paint out of one, `BlElement >> background:` makes a background out of one. So the class needs no Bloc knowledge at all, and the ten methods were only filed under a `colors` protocol and given a class comment saying that they are the one place colors are written down.

> **Porting note.** The colors are the original's, including the slight changes page 061 makes "just for fun". The port does not retune them. A color the new drawing needs and the original does not have would be added here; so far there is none.

# Drawing The Target

*Pages 062 and 063 of the 2007 tutorial.*

The target has more in it than the mirror: a crosshair, a ring around the middle of the cell, and the inside of the ring filled with one of two colors depending on whether the laser reaches the cell. The original draws all four with `Form` and a `Circle`, and asks the renderer where its cell sits on the board form to place them. Here they are four children of the cell element, placed in cell coordinates.

## Numbers with names

Three numbers say where the parts of the target go. Two are new names for numbers the original writes inline, and one, the radius, is the original's method unchanged.

```
TargetCellRenderer >> radius
	^(self class cellExtent x // 2 - 8) min: 10
```

This is the method as this chapter writes it; Section 4.3 gives it the comment that explains the clamp of page 137.

```smalltalk
TargetCellRenderer >> crossHairInset
	"Answer how far, in pixels, each end of the crosshairs stays inside the edge of the cell."

	^ 6 @ 6
```

```smalltalk
TargetCellRenderer class >> outlineWidth
	"Answer the thickness, in pixels, of the target outline: the crosshairs and the ring. The
	original drew both with a two pixel pen."

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

`radius` is the original's: half the cell, less eight pixels, and never more than ten. With a 50 pixel cell it answers 10, so `innerRadius` answers 6.

## The contents, in three parts

```smalltalk
TargetCellRenderer >> renderContentsOn: anElement
	"A target is a crosshair, a ring around the middle of the cell, and a disc inside the ring
	showing whether the laser reaches my cell."

	self renderCrossHairsOn: anElement.
	self renderRingOn: anElement.
	self renderCenterOn: anElement
```

The order is the drawing order: the crosshair first, then the ring over it, then the disc over both.

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

That is the mirror's `addMirrorFrom:to:on:` again, with another color, and the original says as much: "drawing the crosshairs is a lot like drawing the mirrors". The two methods are not merged, because a mirror and a target outline are two ideas that happen to be drawn the same way today, and each renderer already owns its own drawing.

## Circles

A circle geometry in Bloc has no center and no radius of its own. It inscribes a circle in the bounds of its element, so the way to ask for a circle of a given radius around a given point is to give the element a square of the diameter and put it a radius up and to the left of that point.

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

Both circles come from there, and they differ only in what paints them.

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

The ring has a border and no background, so it is an outline and the crosshair shows through the middle of it. The disc has a background and no border, so it is solid. The original needs two different pen forms and a `Circle` for the same effect, and it fills its circle by flood-filling the bitmap afterwards — one of the calls that Pharo 13 no longer has.

## On or off

```smalltalk
TargetCellRenderer >> centerColor
	"Answer the fill of the target center: one color while the laser reaches my cell, another
	while it does not."

	^ self cell isOn
		  ifTrue: [ LaserGameColors targetCenterColorActive ]
		  ifFalse: [ LaserGameColors targetCenterColorIdle ]
```

The original writes this as two methods, `renderContentsOn` and `renderContentsOff`, each drawing the same circle in a different color. Here the drawing does not change with the state, only one paint does, so the choice becomes an answer and the drawing is written once.

## Nine methods leave

Everything the `Form` version of this page needed goes: `renderContents`, `drawTargetOutlines`, `drawCrossHairsOutlines`, `drawCircleOutline`, `drawCircleOutlineOn:color:`, `drawCircleOutlineOn:color:offset:`, `renderInnerCircleColor:`, `renderContentsOn` and `renderContentsOff`. `radius` stays, because the new code uses it. `maskOffHorizontalOn:` and `maskOffVerticalOn:` stay until the beam is drawn, and so does `renderLaser`.

## Firing the laser

Page 063 changes the workspace to fire the laser before drawing, and the target lights up although no beam graphics exist yet: the demo grid is built so that the mirrors lead the beam to the target. The same check belongs on the board element.

```
LaserGameBoardElement class >> openExampleWithLaserFired
	"Open the demo grid with the laser already fired, which lights the target. The beam itself is
	not drawn yet: that is the work of Section 4.

	LaserGameBoardElement openExampleWithLaserFired"

	<sampleInstance>
	| grid |
	grid := GridFactory demoGrid.
	grid fireLaser.
	^ self openOn: grid
```

> **Note.** *Laser On Blank Cell*, in Section 4, draws the beam over the blank cells the laser crosses, and the comment of this method says so from there on.

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

Page 063 gets a test of its own, on the board rather than on the renderer, since it is the whole board that the original looks at.

```
LaserGameBoardElementTestCase >> testFiringTheLaserLightsTheTargetOfANewBoard
	"Page 063 of the original: the laser is fired and the target turns on, even though no beam is
	drawn yet. The cells are built from the model, so a board built after the shot shows the lit
	target."

	| grid board center |
	grid := GridFactory demoGrid.
	grid fireLaser.
	board := LaserGameBoardElement on: grid.
	center := (board cellElementAt: 5 @ 1) children fourth.
	self assert: (grid at: 5 @ 1) isOn.
	self
		assert: center background paint color
		equals: LaserGameColors targetCenterColorActive
```
> **Note.** *Laser On Target Cell*, in Section 4, draws the beam under the picture of the target, so this test reads the disc as the last child of the cell and its comment says so.

That test also marks the limit of what the board can do so far. It fires the laser *before* the board is built. A board already on the screen does not notice a change in its model, because nothing tells it to rebuild; the refresh path is a later step, at pages 065 to 067.

Opening the two examples shows the state of the port at the end of the chapter: 25 cells, ten of them holding a mirror, and one holding a crosshair, a ring and a disc that is blue-grey in the first example and pale yellow in the second.

```smalltalk
LaserGameBoardElement openExampleWithLaserFired
```

# Progress So Far

*Page 064 of the 2007 tutorial.*

This page writes no game code. The original stops to tidy the image: it moves the cell rendering classes into the graphics system category, saves the image, and notes that saving erases the drawn form, which the workspace can redraw. It also states the thought that the game is playable before the beam is drawn, since the target already turns on or off according to where the mirrors are — which is what the previous chapter ended with.

## The recategorisation is already done

Pharo replaced Squeak's system categories with packages and tags, so the move the page describes is a move between tags of one package. The `Laser-Game` package carries three:

| Tag | Holds |
|---|---|
| `Model` | `Cell` and its subclasses, `Grid`, `GridFactory`, `GridDirection` and its subclasses, `LaserPathElement`, the seven `Reverse…LaserGameAction` classes |
| `Graphics` | `CellRenderer` and its three subclasses, `LaserGameColors`, `LaserGameBoardElement`, the seven `CellClickRegion` classes, and the four captured Squeak display classes that are on their way out |
| `Tests` | the twelve test cases |

So the cell renderers are where this page wants them, and the classes the port has added since — `LaserGameBoardElement` and the two new test cases — went to the right tag as they were created.

> **Porting note.** In Pharo a class is put in a tag from code with
> `(Smalltalk packageOrganizer packageNamed: 'Laser-Game') ensureTag: 'Graphics'` and then
> `tag addClass: TheClass`. Sending `category:` to a class no longer works, and `Package` has no
> `moveClasses:toTag:`.

## Saving the image

The advice to save is worth keeping, and it is the one thing on this page the reader still has to do by hand. Nothing here erases a drawing, though: the board is an element tree, not a bitmap on the display, so a saved and restarted image reopens it by running the example again, and the window is closed rather than blanked.

## Where the port stands

The board of the original's screenshot is on the screen, complete: a 5 by 5 grid, ten mirrors leaning both ways, one target with its crosshair and ring, all colors from `LaserGameColors`, all four visible parts of a cell drawn by elements with geometries and no bitmap anywhere on the path.

What the original has at this point and the port does not:

- the beam of the laser, which the original also has not drawn yet. Both stop at the target turning on.
- a control panel, the counters and the undo buttons. Those are Section 3 onwards in both.
- any reaction to the mouse. Clicking a cell does nothing yet, in either.

And what the port carries that the original does not: the 2007 `Form` and `Morph` code, still in the package, being read from and deleted page by page. Forty-five methods still name one of `Form`, `Morph`, `Display`, `World`, `Circle`, `Line`, `Arc`, `MorphPath`, `LaserGameForms` or `Cursor`, against seventy-two when the port started:

| Class | Methods left on the old stack | Goes at |
|---|---|---|
| `LaserGameForms` | 13 | 3.4 |
| `CellRenderer` | 10 | 3.x and 4.x |
| `MirrorCellRenderer` | 5 | 3.x and 4.x |
| `LaserGame` | 4, and it is still a `Morph` subclass | retires group by group across Sections 3 to 5 |
| `TargetCellRenderer` | 2 | 4.x |
| `Arc`, `Line`, `MorphPath` | 5 together | deleted, not ported |
| the seven `CellClickRegion` classes | 1 each, all `arrowForm` | 3.x |

None of the ported code names any of them. Every class written or rewritten since page 049 — `LaserGameBoardElement`, `LaserGameColors`, the four renderers' Bloc methods and the three test cases added since — depends on Bloc alone.

## No commit for this step

This step changes no code, so it produces no commit. The recategorisation it asks for was done when the package was reorganised into tags, before the port reached page 049.

# Back to the LaserGame Morph

*Pages 065 to 067 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/065.html
     http://squeak.preeminent.org/tut2007/html/066.html
     http://squeak.preeminent.org/tut2007/html/067.html -->

Everything we have drawn so far, we have drawn from a workspace. The original tutorial has been doing the same, and on this page it goes back to the class it created at the very beginning — `LaserGame` — and makes that class open the board itself. Opening it as it stands gives, in the original's words, "a little colored rectangle on the screen". Ours is the same story with a different name: there is no game object on the new stack yet, only a board element that a class method opens for us.

## A morph catalogue we do not have

The original opens its game from the World menu: *new morph…*, *from alphabetical list*, then `LaserGame`. Pharo has no equivalent for our class, and we do not want one — the game is a Bloc element, and a Bloc element is shown by putting it in a space. So the step of this page is not "find it in a menu", it is "write the class that owns the whole window", and the way to see it is to send it a message.

## The class

The whole game gets one element:

```smalltalk
BlElement << #LaserGameElement
	slots: { #grid . #board . #controlPanel };
	tag: 'Graphics';
	package: 'Laser-Game'
```

Three instance variables, and one of them is the original's. Page 065 adds `grid` and `boardForm` to `LaserGame`; we keep the grid and drop the form, for the reason the very first chapter gave: there is no shared bitmap to draw into. What the original keeps in a form, we keep in two children — the board element, and the control panel beside it — so those get a slot each.

> **Porting note.** The inherited `LaserGame` class is still in the package, still a `Morph` subclass, and still carries `boardForm` with its accessors. `LaserGameElement` is a new class beside it, not a rewrite of it in place: the old one holds the rules, the counters and the mouse handling that Sections 3 to 5 port, and it retires a group of methods at a time. The two never talk to each other.

## The numbers

Page 066 asks for a constant for the width of the control panel, and for the arithmetic that sizes the window, so that we do not get the tiny rectangle again. The original's numbers are `^110` for the panel and `^10` for the margin, and we keep both:

> **Note.** The chapter *Buttons Of One Width*, at the end of Section 5, states this width from the buttons rather than beside them, and the number becomes a hundred and thirty. It is quoted here as it read before that.

```
LaserGameElement class >> panelWidth
	"Answer the width, in pixels, of the control panel beside the board. The original's number."

	^ 110
```

```smalltalk
LaserGameElement class >> gameMargin
	"Answer the margin, in pixels, between the edge of the game and what it holds. The original's
	number."

	^ 10
```

They sit on the class side, because the size of a game can be asked for before one exists. The original's `calculatedExtent` reads the extent of the board form, adds the panel width to the horizontal, then adds one margin on each side. Ours reads the extent of the board element instead, and the rest of the sum is the same:

```
LaserGameElement class >> extentForGrid: aGrid
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side. This is the original's calculatedExtent, with the board element
	standing in for the board form."

	^ (LaserGameBoardElement extentForGrid: aGrid) + (self panelWidth @ 0)
	  + (2 * self gameMargin)
```
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, takes the height of the taller of the board and the panel, since four counters can stand taller than a board of few rows.

That is the third time this shape of arithmetic appears — `CellRenderer cellExtent` for a cell, `LaserGameBoardElement extentForGrid:` for the board, `LaserGameElement extentForGrid:` for the window — and each one is written in terms of the one below it. Nobody multiplies a cell size by a grid size twice.

## Two panes, no layout policy

The original sets a `ProportionalLayout` on the morph and adds its children with layout frames: fractions for the part of the morph each one claims, offsets in pixels for the margins. Bloc says the same thing with a linear layout and padding, and the padding is where the margin lives:

```
LaserGameElement >> initialize
	"A game is a row of two: the board, and the control panel beside it. The margin around both is
	padding, and the color behind them shows through it."

	super initialize.
	self background: LaserGameColors gameWindowColor.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin)
```

This is the method as this chapter writes it; Section 4.4 moves the control panel to the left of the board and fills the window with a colour ramp instead of a flat colour.

Padding is exactly the right tool here. In the original, the margin is spelled out four times over — `gameMargin @ gameMargin`, `gameMargin negated`, and the same again for the second pane — and a change to the constant has to be right in all of them. As padding, the element reserves the margin once and every child is inside it.

Setting the grid builds the two panes, so that the same game element can be handed another grid later:

```smalltalk
LaserGameElement >> grid: aGrid
	"Play on aGrid. Setting the grid rebuilds what I hold, so the same game element can show
	another grid."

	grid := aGrid.
	self rebuild
```

```
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

This is the method as this chapter writes it; Section 4.4 adds the panel before the board, since page 139 moves it to the left, and registers the block that keeps the counters current.

Write the three accessors — `grid`, `board` and `controlPanel` — as reading methods; only the grid has a setter, and it is the one above.

The last line does the work of the original's `setExtent`, which sends `self extent: self calculatedExtent`. It is part of rebuilding rather than a step of initialization, because a game with no grid has no size to ask for.

## The blank panel

Page 066 is explicit that the control panel starts as nothing more than a blank white rectangle, and that the buttons come later. So it does:

```
newControlPanel
	"Answer the control panel: a blank column of a fixed width, as tall as the board beside it. The
	controls go in at the next step."

	| panel |
	panel := BlElement new.
	panel background: LaserGameColors controlPanelColor.
	panel extent: self class panelWidth
		@ (LaserGameBoardElement extentForGrid: self grid) y.
	^ panel
```

That is the version this page ends with, and it is the only method of the port that a later page replaces
outright: the next chapter gives the panel a class of its own, and `newControlPanel` becomes one line that
answers an instance of it. It is printed here without the usual `LaserGameElement >>` heading because it is
no longer what the image holds.

Two more colors join `LaserGameColors`, both taken from the original's `setWindowColors` and `makeControlPanelMorph`:

```smalltalk
LaserGameColors class >> gameWindowColor
	"Answer the color behind the whole game: the margin around the board and the control panel.
	This is the window color the original gives its morph."

	^ Color r: 0.369 g: 0.369 b: 0.505
```

```
LaserGameColors class >> controlPanelColor
	"Answer the color of the control panel beside the board. The original starts with a blank white
	rectangle there, and the buttons come later."

	^ Color white
```

This is the method as this chapter writes it; page 140 paints the panel transparent so that the window ramp runs behind it, and Section 4.4 follows it.

Page 061 asked for every color of the game to be written down in one place, and the rule holds: neither of these two is a `Color` literal anywhere else.

> **Which side is the panel on?** Page 066 says "I'd like to place the game board on the left side of the morph and have a vertical control panel on the right", and that is the order we use: the board is the first child, the panel the second. The finished 2007 code does the opposite — its `setupMorphs` gives the control panel the fractions `0@0 corner: 0@1` at the left edge and offsets the board by `gameMargin + panelWidth` — so somewhere after this page the author changed their mind. We follow the sentence on the page, and turning the game around later means swapping two `addChild:` sends.

There is a third pane in the original's `setupMorphs`, a four pixel strip under the left edge of the board called the laser-home morph. It marks where the beam enters. It belongs with the beam, so it arrives in Section 4 with the rest of the drawing of the laser.

## Opening it

The original opens its morph from a menu. We give the class the two messages the board element already has — one to build, one to open — plus an example:

```smalltalk
LaserGameElement class >> on: aGrid
	"Answer a game element playing on aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
```

```
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

*A Window The Player Can Resize*, at the end of Section 4, rewrites this method: the space is still opened at the size the game asks for, but the game then follows the window when the player drags its corner. The version above is the one this page leaves in the image.

```smalltalk
LaserGameElement class >> openExample
	"Open the demo grid of the tests, as the original opens its morph on the grid of the factory.

	LaserGameElement openExample"

	<sampleInstance>
	^ self openOn: GridFactory demoGrid
```

The space is given the size the game asks for, so the window fits the game exactly and there is no second margin around it.

## Rendering all the cells

Page 067 takes the loop that has been sitting in the workspace since page 053 — walk the columns, walk the rows, ask `CellRenderer` for a renderer, tell it to render — and writes it as a method on the game, then calls it from `#initialize`. That method is `drawGameBoard`, and it is the last thing the workspace was needed for.

We have nothing to do here, because that loop became a method three chapters ago, when the board element was written:

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

It is called from `grid:` for the same reason `rebuild` is: the cells exist because the board has a grid, not because a window opened. And where the original has to remember to call `drawGameBoard` after `setupMorphs`, and later has to call it again whenever anything moves, our board rebuilds when it is given a grid and a single cell element is replaced when a single cell changes.

## Checking it

Six tests, and none of them opens a window. The arithmetic first, both as the sum of its parts and as the plain number it comes to for the demo grid:

```
LaserGameElementTestCase >> testExtentIsTheBoardPlusThePanelPlusTheMargins
	"The game is as wide as the board, the panel beside it and a margin on each side, and as
	tall as the board with a margin above and below. This is the original's calculatedExtent."

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
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, takes the height of the taller of the board and the panel, since four counters can stand taller than a board of few rows.

Then the two panes, in order:

```
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

This is the test as this chapter writes it; Section 4.4 turns the two children around, since page 139 puts the panel on the left.

The panel keeps its width whatever the grid is, which is the point of a constant:

```
LaserGameElementTestCase >> testControlPanelIsAFixedColumnAsTallAsTheBoard
	"The panel keeps the original's width whatever the grid is, and it is as tall as the board
	beside it. Sizes are read from the layout constraints, since nothing is laid out yet."

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
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, replaces this test with `testControlPanelIsAFixedColumnAsTallAsTheBoardOrItsContents`, since the panel keeps the height of what it holds when the board is shorter than that.

And handing the game another grid replaces what it holds, rather than adding to it:

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

Two more do the remaining checks: `testBoardShowsTheGridOfTheGame` — the board renders the game's own grid, twenty five cell elements for the demo grid — and `testGameTakesTheExtentItCalculates`, which reads back the size, the padding and the window color of the game itself.

Sizes are read from the layout constraints throughout, never from `extent`, for the reason given when the board was written: a fresh element measures `0.0@0.0` until a layout pass runs, and `forceLayout` is forbidden by a Renraku rule.

## What it looks like

```smalltalk
LaserGameElement openExample
```

A window 380 by 270: the demo board, 250 by 250, on the left, the white panel 110 wide beside it, and a ten pixel margin of the window color around both. The original's screenshot of this page is the same picture with the panel on the other side, and with its note that the white panel on the right "may not be easy to tell" — ours is easy enough to tell, since the board no longer has to share a bitmap with anything.

The workspace has done its job. From here the game opens itself, and the pages that follow put the controls in that white column.

# Adding Controls

*Pages 068 to 072 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/068.html
     http://squeak.preeminent.org/tut2007/html/069.html
     http://squeak.preeminent.org/tut2007/html/070.html
     http://squeak.preeminent.org/tut2007/html/071.html
     http://squeak.preeminent.org/tut2007/html/072.html -->

The white column beside the board has been waiting since the last chapter. Two buttons go in it now. One quits the game, which is easy to describe and easy to write. The other fires the laser, which the original admits has not really been thought about yet: does the beam stay on, or only while the button is held down? It settles on a toggle, and so do we.

## A class of its own

The panel was a plain `BlElement` a chapter ago. Now that it holds things and has to keep them up to date, it becomes a class:

```smalltalk
BlElement << #LaserGameControlPanelElement
	slots: { #game . #quitButton . #fireButton };
	tag: 'Graphics';
	package: 'Laser-Game'
```

It keeps a reference to the game rather than to the grid. A button is an instruction from the player — *quit*, *fire* — and instructions go to the game, which decides what that means for the model and then shows the result. The panel never touches the grid.

```smalltalk
LaserGameControlPanelElement >> initialize
	"A panel is a blank column with its buttons at the bottom left corner, as the original places
	them. A frame layout puts a child where it is aligned, which is what the original's layout
	frames do."

	super initialize.
	self background: LaserGameColors controlPanelColor.
	self layout: BlFrameLayout new
```

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

`BlFrameLayout` is the Bloc layout that matches Morphic's `ProportionalLayout`: a child says where in the frame it wants to be, and the layout puts it there. Write the readers `game`, `quitButton` and `fireButton`; only the game has a setter.

## One method makes a button

The original writes `makeButton:action:state:` and builds a `PluggableButtonMorph` with a `StringMorph` label, rounded corners, an on color, an off color, a border width and a border color — nine messages of appearance before the button does anything. Toplo has all of that in its theme, so what is left is the label, the size and the action:

> **Note.** The chapter *Buttons Of One Width*, at the end of Section 5, adds a line to this method, so that a button centres its label. It is quoted here as it read before that.

```
LaserGameControlPanelElement >> newButton: aLabel action: aBlock
	"Answer a labelled button of the original's size that evaluates aBlock when it is clicked. The
	original builds a PluggableButtonMorph with a StringMorph label and paints its colors by hand;
	Toplo gives the look and the click, so only the label, the size and the action are left."

	| button |
	button := ToButton labelText: aLabel.
	button extent: self class buttonWidth @ self class buttonHeight.
	button clickAction: aBlock.
	^ button
```

> **Porting note.** The original's third argument, `state:`, is a selector that `PluggableButtonMorph` polls to decide whether to paint itself in its on color or its off color. Page 068 stubs those state methods out. A `ToButton` gets its pressed, hovered and disabled looks from the skin of the current theme, so there is nothing to poll and no stub to write. The state the game actually cares about — is the laser firing? — shows up in the *label* of the fire button, which is what pages 070 and 071 are about.

The two buttons are then one line each:

```smalltalk
LaserGameControlPanelElement >> newQuitButton
	"Answer the button that closes the game. The original sends #delete to its morph."

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

The rule in that last method is the one page 069 states: the label names the action the click will cause, not the state the game is in. Beam off, the button says *Fire*. Beam on, it says *Stop*.

## Where the buttons sit

Three numbers, all the original's:

> **Note.** The chapter *Buttons Of One Width*, at the end of Section 5, widens a button to fifty pixels, so that its longest labels fit inside it. It is quoted here as it read before that.

```
LaserGameControlPanelElement class >> buttonWidth
	"Answer the width, in pixels, of a control panel button. The original's number."

	^ 40
```

```smalltalk
LaserGameControlPanelElement class >> buttonHeight
	"Answer the height, in pixels, of a control panel button. The original's number."

	^ 20
```

```smalltalk
LaserGameControlPanelElement class >> buttonGap
	"Answer the gap, in pixels, between the buttons and around the row they sit in. The original
	spaces its buttons ten pixels apart, and the horizontal gap its arithmetic produces for two
	buttons in a panel of this width comes to the same ten."

	^ 10
```

The original turns those into a position with `buttonLayoutFrameForRow:column:`, which takes a row counted from the bottom and a column counted from the left and returns a `LayoutFrame`: nine lines of arithmetic, including `xOffset := (self panelWidth - (2 * buttonWidth)) // 3`, which for a panel 110 wide and buttons 40 wide comes to 10 — the same gap it uses vertically. We let a layout do the arithmetic instead. The buttons go in a row, and the row goes in the corner:

```
LaserGameControlPanelElement >> newButtonRow
	"Answer the row of buttons: Quit first, then Fire, one gap apart. The original puts these two
	in the bottom row of its panel, and the rest of its buttons come later."

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

```
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with a fresh row of buttons for my game, and take the width of a panel and
	the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	self addChild: self newButtonRow.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y
```

Both are shown as this chapter writes them. Section 4.4 adds the counter of page 141 above the buttons, and Section 4.5 adds a third button and puts each row of buttons in a column, so the row in the image today is built by `newRowOfButtons:` and `rebuild` fills more variables than these two.

`cellSpacing:` is the gap between the buttons, the margin is the gap between the row and the two edges of the panel it is aligned to, and `alignLeft` with `alignBottom` is the corner. Three numbers in, no offsets computed by hand, and the next three buttons the original adds will be three more `addChild:` sends rather than three more calls into the arithmetic.

Sizing the panel moves here too, out of the game: a panel knows it is `panelWidth` wide and as tall as the board beside it, so it can say so itself.

## What the buttons do

The game gains the two actions, and the question the buttons ask it:

```smalltalk
LaserGameElement >> laserIsActive
	"Answer whether the laser is firing. The grid knows; I only ask."

	^ self grid laserIsActive
```

```smalltalk
LaserGameElement >> toggleLaser
	"Fire the laser, or stop it if it is already firing, and show the result. This is what the fire
	button does, and it is the original's #fireLaser on the morph."

	self laserIsActive
		ifTrue: [ self grid stopLaser ]
		ifFalse: [ self grid fireLaser ].
	self refresh
```

```
LaserGameElement >> quit
	"Close the game. The original sends #delete to its morph."

	self space ifNotNil: [ :aSpace | aSpace close ]
```

Page 144 makes Quit ask before it closes, so from Section 4.5 on this method is called `close` and `quit` is the question.

```
LaserGameElement >> refresh
	"Show what the model says now: redraw the cells and put the right label on the fire button.
	This is the original's #updateGameBoardAndControls, without the counters it does not have yet."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel
```

This is the method as this chapter writes it; page 142 adds the counters to it, and Section 4.4 with it.

Page 070 pauses over a design choice in the middle of `toggleLaser`: one method that looks at the state and does one of two things, or a button that is given a different action each time its label changes. It keeps the single method, and so do we — the button asks the game to toggle, and the game is the one place that decides what toggling means. Its name here is `toggleLaser` rather than the original's `fireLaser`, because a method that may stop the laser should not be called firing it, and because `Grid >> fireLaser` already has that name for the thing that really does fire it.

And `newControlPanel` on the game now answers the new class:

```smalltalk
LaserGameElement >> newControlPanel
	"Answer the control panel: the fixed-width column of buttons that sits beside the board."

	^ LaserGameControlPanelElement on: self
```

## A lookup we do not need

Page 071 hits the problem that the label does not change when the beam does. Its fix is to name the button — `btn name: 'fireButton'` — then find it again by walking the submorphs:

```
findFireButton
	^self allMorphs detect: [:m | m knownName = 'fireButton'] ifNone: []
```

We hold the button in an instance variable, so there is nothing to search for and nothing to name:

```smalltalk
LaserGameControlPanelElement >> updateFireButtonLabel
	"Make the fire button say what a click will do now. The original has to find the button among
	its submorphs by name; I hold it in an instance variable."

	self fireButton labelText: self fireButtonLabel
```

That is the whole of page 071 on this side of the port. The reason the original needs the lookup is that its buttons are created inside `addButtonsToPanel:` and handed to a layout, and nobody keeps them; the panel being a class of its own is what makes keeping them natural.

## The model work of page 069 is already here

Page 069 spends most of its length in the model: it checks the senders of `laserIsActive` and `laserIsActive:`, finds that the flag is only ever read and never turned on, writes unit tests for two new methods, then writes them. All four methods are in the code we inherited, which is the finished 2007 version:

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

```smalltalk
Grid >> clearCellsInPath
	self calculatePath.
	self laserBeamPath do: [:pe |
		pe clearCell]
```

`clearCellsInPath` is the method the page arrives at by noticing that `stopLaser` cannot use `activateCellsInPath`: the path has to be walked to know which cells to touch, but their segments have to be cleared rather than lit. The two differ in one message, `clearCell` against `activateCell`.

Its tests are here too, and they are page 069's tests:

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

> **Porting note.** Where the page clicks the *senders* button in the browser, the same question is one call in an image driven from the outside: `find_senders` for `laserIsActive:`, which answers `fireLaser`, `stopLaser`, `initialize` and `reset`. The answer is longer than the page's, because the page is looking at the code *before* `fireLaser` and `stopLaser` were written.

## Deleting what the panel replaces

The 2007 button code has a Bloc counterpart now, so it goes, the way each `Form` drawing method went as its element arrived. Nine methods leave `LaserGame`:

| Deleted | Replaced by |
|---|---|
| `makeQuitGameButton`, `makeFireLaserButton` | `newQuitButton`, `newFireButton` |
| `fireButtonLabel` | `LaserGameControlPanelElement >> fireButtonLabel` |
| `findFireButton`, `updateFireButtonLabel` | `updateFireButtonLabel`, with the button held in a slot |
| `laserActive` | `LaserGameElement >> laserIsActive` |
| `fireLaser` (the morph's, not the grid's) | `LaserGameElement >> toggleLaser` |
| `quitGame`, `quitGameAction` | `LaserGameElement >> quit` |

What stays is what later pages still need to be read from: `makeButton:action:state:` builds five buttons, three of which arrive in Section 3; `addButtonsToPanel:`, `makeControlPanelMorph`, `buttonLayoutFrameForRow:column:` and the counter methods go with those pages. They are dead code either way — nothing instantiates the morph — and three of them now send a method that no longer exists, which the critics report and which this project accepts for the same reason as before: a broken method on the old stack is a method with a deadline, and the deadline is the page that replaces it.

## Page 072: the bug that is not there any more

The original opens its morph, clicks *Fire*, clicks *Stop*, and finds the target cell still reporting `isOn`. Page 072 is the diagnosis: halos, *inspect morph*, into the grid, into the cells, down to the target at `5@1`, and the conclusion that the graphic is right and the model is wrong. Page 073 then writes the unit test that reproduces it.

That test is in the package already:

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

And it passes. The code we inherited is the tutorial's *finished* code, so the fix the following pages arrive at is already in it: `Cell >> clearCell` resets the whole segment dictionary, which puts every side of the cell out, and `isOn` answers whether any side is lit. So the symptom the original is about to chase does not reproduce here, and clicking *Fire* then *Stop* in our window leaves the target idle.

This is the first place where the port cannot follow the tutorial's story, only its conclusion. The next step reads page 073 against the code and confirms that: nothing to fix, and a test that already covers the bug.

## Checking it

The panel's own tests are in `LaserGameControlPanelElementTestCase`, built on one helper:

```smalltalk
LaserGameControlPanelElementTestCase >> newPanel
	"Answer the control panel of a game playing on the demo grid, with the laser not firing."

	^ (LaserGameElement on: GridFactory demoGrid) controlPanel
```

```
LaserGameControlPanelElementTestCase >> testPanelHoldsARowOfTwoButtons
	"The game's panel is a control panel element. It holds one child, the row, and the row holds the
	Quit button then the Fire button. The rest of the original's buttons arrive with their own pages."

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

This is the test as this chapter writes it; Section 4.4 gives the panel a second child, so the row is read from `buttonRow` rather than from the children.

```
LaserGameControlPanelElementTestCase >> testButtonRowSitsAtTheBottomLeftOneGapIn
	"The row is aligned to the bottom left corner of the panel, one gap away from both edges, and
	the buttons inside it are one gap apart. That is where the original's layout frames put them."

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

This is the test as this chapter writes it; Section 4.4 gives the panel a second child, so the row is read from `buttonRow` rather than from the children.

The label rule gets two tests, one for what it answers and one for it reaching the button. They are separate on purpose: the label follows the grid only when something updates it, and forgetting to update is exactly the mistake of page 071.

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

Two more check the sizes: `testButtonsKeepTheOriginalSize`, for forty by twenty on both buttons, and `testPanelIsAPanelWideColumnAsTallAsTheBoard`, which is the sizing that moved out of the game.

On the game side, one test does the whole round trip a player makes — click, look, click again — without a window:

```
LaserGameElementTestCase >> testTogglingTheLaserFiresItAndStopsItAgain
	"The fire button toggles: the first click fires the laser and lights the target, the second
	stops it and puts the target out. The board and the button label both follow."

	| game target |
	game := LaserGameElement on: GridFactory demoGrid.
	target := game grid at: 5 @ 1.
	game toggleLaser.
	self assert: game laserIsActive.
	self assert: target isOn.
	self
		assert: (game board cellElementAt: 5 @ 1) children fourth background paint color
		equals: LaserGameColors targetCenterColorActive.
	self assert: game controlPanel fireButton labelText asString equals: 'Stop'.
	game toggleLaser.
	self deny: game laserIsActive.
	self assert: target isOff.
	self
		assert: (game board cellElementAt: 5 @ 1) children fourth background paint color
		equals: LaserGameColors targetCenterColorIdle.
	self assert: game controlPanel fireButton labelText asString equals: 'Fire'
```
> **Note.** *Laser On Target Cell*, in Section 4, draws the beam under the picture of the target, so this test reads the disc as the last child of the cell and its comment says so.

That single test is page 069, page 070, page 071 and the check of page 072 together: the model toggles, the drawing follows, the label follows, and the target goes out again when the beam stops. And quitting a game nobody opened is harmless, which is worth one test because `space` is `nil` until a space adopts the element:

```
LaserGameElementTestCase >> testQuittingAGameThatIsNotOpenDoesNothing
	"Quit closes the space the game is in. A game that was never opened has no space, and asking it
	to quit is harmless."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game space isNil.
	game quit.
	self assert: game children size equals: 2
```

Section 4.5 drops this test: once Quit asks first, a game that was never opened answers the question rather than closing, and a test of that answer takes its place.

## What it looks like

```smalltalk
LaserGameElement openExample
```

The same window as the last chapter, with two buttons in the bottom left of the white column: *Quit* and *Fire*. Click *Fire* and the target lights up and the button becomes *Stop*; click it again and the target goes out and the button is *Fire* once more. Click *Quit* and the window closes.

The beam is still invisible — it is the target reacting that tells us the laser reached it. Drawing the beam is Section 4.

# A Unit Test To Demonstrate A Bug

*Pages 073 and 073A of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/073.html
     http://squeak.preeminent.org/tut2007/html/073A.html -->

Section 2 ends with a bug hunt. The fire button works, but stopping the laser leaves the target lit, so the author goes back to `GridTestCase`, adds cell assertions to the two laser tests, writes a third test that fires and then stops, watches it fail, opens the debugger on it, steps until the fault shows itself, and repairs it in three small methods.

The port inherits the finished 2007 code, which is the code *after* that repair. So this chapter has nothing to write. It reads the page against the image, shows that the test the page asks for is already there and green, shows where the fix lives, and — since a bug nobody can see is a poor lesson — reproduces the 2007 failure in a workspace without touching a single method.

## The tests the page writes

The page first strengthens the two existing tests, so that they check the cells and not only the flag. Both are in the image exactly so:

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

Then the test that is supposed to fail:

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

It does not fail. `Laser-Game` runs 85 tests, 85 passed, 0 failed, 0 errored, and this is one of them.

## Where the fix already is

The original's `clearCellsInPath` calculated the path and then did nothing with it:

```
clearCellsInPath
	self calculatePath.
```

That is the whole bug. The debugger sequence of the page — restart, over, into — ends on this method, and the page's conclusion is that it "works as written": a correct path, built and dropped.

The repair is to make it the mirror image of its template, which the page quotes first:

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

One selector apart. The page then follows `activateCell` down and writes the same chain for clearing, and both halves of it are in the image:

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

The last of those is the page's "reset the cell segments by reusing the initialization technique", and this is the method it reuses:

```smalltalk
Cell >> initializeActiveSegments
	self activeSegments: Dictionary new.
	self activeSegments at: #north put: false.
	self activeSegments at: #east put: false.
	self activeSegments at: #south put: false.
	self activeSegments at: #west put: false.
```

## Reproducing the 2007 bug without breaking the image

The bug is easy to see without putting it back. `stopLaser` is three statements, and the 2007 version is the same three with the last one doing nothing, so a workspace can play that version directly against a demo grid:

```smalltalk
| grid |
grid := GridFactory demoGrid.
grid fireLaser.
"What stopLaser did in 2007: lower the flag, calculate the path, clear nothing."
grid laserIsActive: false.
grid calculatePath.
grid laserBeamPath count: [ :pe | pe cell isOn ]
```

It answers `9`: every cell on the beam path is still on, the starting cell among them. That is precisely what page 073's debugger shows, and why the page notes that the fault is not specific to the target cell.

The same snippet with the real `stopLaser` in the middle answers `0`:

```smalltalk
| grid |
grid := GridFactory demoGrid.
grid fireLaser.
grid stopLaser.
grid calculatePath.
grid laserBeamPath count: [ :pe | pe cell isOn ]
```

> **Porting note.** The original writes this fix inside the debugger, which is the Squeak and Pharo habit the tutorial teaches in Section 1. Nothing here fails, so there is no debugger to code in. The habit still applies to every method the port writes for itself: a failing test first, then the method.

## The Section 2 inventory of page 073A

Page 073A closes the section with an inventory: every class and method a reader's image should hold at this point. It is 179 entries, counting the class definitions, and it can be checked against the image mechanically rather than by eye.

157 of the 179 are present. The 22 that are not divide into four groups, and each was recorded when it happened:

| Absent from the image | Why |
|---|---|
| `LaserGame >> makeQuitGameButton`, `makeFireLaserButton`, `fireButtonLabel`, `findFireButton`, `updateFireButtonLabel`, `laserActive`, `fireLaser`, `quitGame` | deleted at 2.16, when `LaserGameControlPanelElement` and the game element took over the buttons and the firing |
| `MirrorCellRenderer >> renderContents`, `renderContentsLeanLeft`, `renderContentsLeanRight` | replaced at 2.12 by `renderContentsOn:`, `renderContentsLeanLeftOn:`, `renderContentsLeanRightOn:`, which add child elements to a cell element instead of drawing into a `Form` |
| `TargetCellRenderer >> renderContents`, `renderContentsOn`, `renderContentsOff`, `drawTargetOutlines`, `drawCircleOutline`, `drawCrossHairsOutlines`, `renderInnerCircleColor:` | replaced at 2.13 by `renderContentsOn:`, `renderRingOn:`, `renderCrossHairsOn:`, `renderCenterOn:`, `newCircleOfRadius:` and `addOutlineLineFrom:to:on:` |
| `CellRendererTestCase >> testCellOffsetCalculations` | deleted at 2.11: it built a `Form` to assert offsets that the board layout now computes |
| `CellRendererTestCase >> testRenderSelection`, `GridTestCase >> testNonDefaultGridSizeConditions` | renamed before the port began. The captured source has `testRendererSelection` and `testNonDefaultGridSizeInitialConditions`, so these are the 2007 author's own later edits, not ours |
| `Object >> revisit:` | never captured. The 2007 image carried a one-line marker method on `Object`; the source this port started from does not have it, and no ported code sends it |

The inventory is also much shorter than the package, because it is a snapshot of the reader's image at the end of Section 2 while the captured source is the finished game: `Grid` alone holds pushing, rotation, undo and the counters that Sections 3 and 4 add, and the package holds the seven `CellClickRegion` classes and the reverse-action classes on top of that.

## No commit for this step

This step changes no code, so it produces no commit — the second such step in the section, after 2.14. The page's test, `GridTestCase >> testToggleLaser`, passes; the fix it leads to is in `Cell >> clearCell`, `LaserPathElement >> clearCell` and `Grid >> clearCellsInPath`; and the bug is visible on demand from a workspace.

Section 2 is finished. Page 074 opens Section 3, where the cells start listening to the mouse.
