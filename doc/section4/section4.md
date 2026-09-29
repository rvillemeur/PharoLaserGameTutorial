<!-- Tutorial Section 4 covers pages 130 to 173 of tut2007/html.
     This file starts at page 130, the first page of the section. -->

# Communicate With Arrow Colors

*Pages 130 to 133 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/130.html
     http://squeak.preeminent.org/tut2007/html/131.html
     http://squeak.preeminent.org/tut2007/html/132.html
     http://squeak.preeminent.org/tut2007/html/133.html -->

The game works. Section 4 is a list of things that could be better, and page 130 starts with the one the player notices first:

> For the existing code we are painting grey arrows. What if we made the color of the arrows dependent on whether the choice was valid or not?

A hint arrow says which way a click would move the cell, and says nothing about whether it could. The mirror at 4@1 in the demo grid offers four push arrows, and only two of those pushes can happen: north is off the board and east is the target, which never moves. The arrow that promises the impossible is worse than no arrow, because the player has to click to find out.

## Two colours

```smalltalk
LaserGameColors class >> allowActionArrowColor
	^Color green
```
```smalltalk
LaserGameColors class >> denyActionArrowColor
	^Color red
```

Page 130 knows what it is asking for:

> We can begin with those 2 primary colors (red and green). After we get things working we'll probably regret these color choices since they will likely look very bright and harsh over our game cells. But we'll worry about that later.

The port keeps both, and keeps the regret too: these are the colours Section 4.4 comes back to when the window gets its own palette.

## Asking whether a move is allowed

The model already refuses a push it cannot make. `pushCell:fromLocation:`, quoted in full in Section 3.13, tests the same four things in a row — the cell is a mirror, there is a neighbour that way, that neighbour is blank — and answers the cell unchanged when any of them fails. Page 130 turns those tests into a question that answers a Boolean and changes nothing:

```smalltalk
Grid >> canPushCell: aGridDirection fromLocation: aPoint
	| cell vector swapLoc swapCell |
	cell := self at: aPoint.
	cell class = MirrorCell ifFalse: [^false].
	vector := aGridDirection vector.
	swapLoc := aPoint + vector.
	swapCell := self at: swapLoc.
	swapCell isNil ifTrue: [^false].
	swapCell class = BlankCell ifFalse: [^false].
	^true
```

> There's probably some refactoring we can do in here but I'm going to press onward.

Page 131 wraps it in the four direction methods, as it did for the push itself:

```smalltalk
Grid >> canPushCellNorthFromLocation: aPoint
	| direction |
	direction := GridDirection directionFor: #north.
	^self canPushCell: direction fromLocation: aPoint.
```
```smalltalk
Grid >> canPushCellEastFromLocation: aPoint
	| direction |
	direction := GridDirection directionFor: #east.
	^self canPushCell: direction fromLocation: aPoint.
```
```smalltalk
Grid >> canPushCellSouthFromLocation: aPoint
	| direction |
	direction := GridDirection directionFor: #south.
	^self canPushCell: direction fromLocation: aPoint.
```
```smalltalk
Grid >> canPushCellWestFromLocation: aPoint
	| direction |
	direction := GridDirection directionFor: #west.
	^self canPushCell: direction fromLocation: aPoint.
```

and maps them back onto the click regions, one class method each, so that no caller has to work out a direction:

```smalltalk
CellClickRegionPushNorth class >> canPushCell: aCell withinGrid: aGrid
	^aGrid canPushCellNorthFromLocation: aCell gridLocation
```
```smalltalk
CellClickRegionPushEast class >> canPushCell: aCell withinGrid: aGrid
	^aGrid canPushCellEastFromLocation: aCell gridLocation
```
```smalltalk
CellClickRegionPushSouth class >> canPushCell: aCell withinGrid: aGrid
	^aGrid canPushCellSouthFromLocation: aCell gridLocation
```
```smalltalk
CellClickRegionPushWest class >> canPushCell: aCell withinGrid: aGrid
	^aGrid canPushCellWestFromLocation: aCell gridLocation
```

> We're using polymorphism here and letting the click region classes work out the direction.

The inside region asks the push region the point falls in, and the outside region — rotation, which nothing ever forbids — answers the easiest method of the section:

```smalltalk
CellClickRegionInside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid

	| pushRegion |
	pushRegion := self pushRegionForPoint: aPoint.
	^ pushRegion canPushCell: aCell withinGrid: aGrid
```
```smalltalk
CellClickRegionOutside class >> canActOnCellAtPoint: aPoint cell: aCell withinGrid: aGrid
	^true
```

None of this is new here. The port wrote all of it in Section 3.10, because page 114 had already sent `mouseUpForCell:withinGrid:` down the same chain and the guard had to be in place before a click could push anything. Section 3.10 also added the one method the original never needs, `CellClickRegion class >> canActOnCellAtPoint:cell:withinGrid:` answering `^ false`, so that the ignore margin answers the question without a special case around it. What Section 4.1 has to write is the part that uses the answer.

## The renderer answers the colour

This is the method page 132 changes, in its Form-era form: it finds the region, asks it for a scaled arrow and an offset, asks it for permission, picks a colour, and paints the arrow onto the board form in that colour.

```
showPositionHintFromWithinBoardOffset: aPoint
	| cellPosn offsetWithinCell regionClass arrow offset arrowAndOffset permissionToActOnCell arrowColor |
	cellPosn := self offsetWithinGridForm.
	offsetWithinCell := aPoint - cellPosn.
	regionClass := CellClickRegion clickRegionForPoint: offsetWithinCell.
	arrowAndOffset := regionClass scaledHintArrowAndOffsetFromWithinCell: offsetWithinCell.
	arrowAndOffset isNil ifTrue: [^self].
	permissionToActOnCell := regionClass canActOnCellAtPoint: offsetWithinCell cell: self cell withinGrid: self grid.
	arrowColor := permissionToActOnCell
		ifTrue: [LaserGameColors allowActionArrowColor]
		ifFalse: [LaserGameColors denyActionArrowColor].
	arrow := arrowAndOffset value.
	offset := arrowAndOffset key.
	offset := self offsetWithinGridForm + offset.
	arrow
		displayOn: self targetForm
		at: offset
		clippingBox: self targetForm computeBoundingBox
		rule: Form oldPaint
		fillColor: arrowColor.
```

That method was deleted in Section 3.6, where each of its lines found a new home. Two of its lines are the ones this section adds, and they land in the same two places the rest did. Which colour a point deserves is a question about the cell, so the renderer answers it, next to `hintRegionAt:` and split the same way — the base renderer for a cell that reacts to nothing, the mirror renderer for the one that does:

```smalltalk
CellRenderer >> hintColorAt: aPoint
	"Answer the colour a hint arrow is painted in at aPoint, in the coordinates of my cell. My
	cell reacts to nothing, so the question does not arise here and the neutral grey of page 081
	is answered; the mirror renderer asks the click region whether the move is allowed."

	^ LaserGameShapes arrowColor
```
```smalltalk
MirrorCellRenderer >> hintColorAt: aPoint
	"Answer the colour of the hint arrow at aPoint, in the coordinates of my cell: page 130 wants
	the arrow to say whether the move it offers could actually be made. The region the point
	falls in knows — the outside region always allows a turn, and the inside region asks the
	push region whether the cell beside mine would let my cell through."

	^ ((CellClickRegion clickRegionForPoint: aPoint)
		   canActOnCellAtPoint: aPoint
		   cell: self cell
		   withinGrid: self grid)
		  ifTrue: [ LaserGameColors allowActionArrowColor ]
		  ifFalse: [ LaserGameColors denyActionArrowColor ]
```

`clickRegionForPoint:` is asked twice on the way to an arrow, once for the picture and once for the colour, exactly as page 132 asks `regionClass` for both. The neutral answer is the grey of page 081, which `LaserGameShapes` has held since Section 3.4:

```smalltalk
LaserGameShapes class >> arrowColor
	"Answer the colour an arrow is painted in when nobody says otherwise: the grey of page 081.
	A caller that knows more sets its own, as the hints do from Section 4 on."

	^ Color gray
```

Only a mirror ever has a hint to paint, so the grey is never seen on the board; it is what the method answers when a renderer that offers no hints is asked anyway.

## The element paints it

The arrow is a child element, not a shape painted into a form, so colouring it is setting a background. The point the pointer was last seen at is already kept — Section 3.14 added `hintPosition` so that a redraw could ask for the hint again — and that is the point the colour is read at:

```
LaserGameCellElement >> updateHintElement
	"Show the picture of the hint I hold, and no other, in the colour of what a click there would
	do. The original drew its arrow straight onto the board form, which is why page 093 warns
	that old arrows have to be cleaned off; here the arrow is a child of mine, so the previous
	one goes when it is removed. The colour comes from page 130: my renderer answers green when
	the move is allowed and red when it is refused. A region without a picture, such as the
	ignore margin, answers nothing and leaves me with no hint at all."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each
			background: (self renderer hintColorAt: hintPosition);
			position: CellRenderer hintArrowOffset.
		self addChild: each ]
```

This is the method as this chapter writes it; Section 4.2 adds the cross hair under the pointer to it.

The `background:` goes inside the guarded block on purpose. `hintElementOfExtent:` answers `nil` for a region with no picture, such as the ignore margin, and a cascade on the outer expression would send `background:` to that `nil`.

Nothing else changes. `showPositionHintAt:` still compares regions and rebuilds only on a change,

```
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing, so the arrow is built once. The point
	itself is kept, because a redraw has to ask the question again for the cell that stands in me
	then."

	| region |
	hintPosition := aPoint.
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self ].
	hintRegion := region.
	self updateHintElement
```

This is the method as this chapter writes it; Section 4.2 moves the cross hair on the path that returns early here.

which is enough here: the colour can only change when the region does, because the board is still while the pointer moves over one region. A push that empties the cell under the pointer goes through `redraw`, which Section 3.14 made ask for the hint again, so the arrow of the new cell is built from scratch and coloured from scratch.

One method goes: `MirrorCellRenderer >> hintArrowColorFor:offset:`, the last piece of the captured 2007 source that computed an arrow colour for the Form drawing. Nothing sent it, and `hintColorAt:` is what it would have become.

## Two tests

The first one is page 130 in one cell. The mirror at 4@1 can go south, where 4@2 is blank, and cannot go east, where the target stands — same cell, same pointer, two colours:

```smalltalk
LaserGameCellElementTestCase >> testAPushArrowIsColouredByWhetherThePushIsAllowed
	"Page 130: the arrow says which way a click would move the cell, and nothing says whether it
	could. The mirror at 4@1 can be pushed south, where 4@2 is blank, and cannot be pushed east,
	where the target stands. Same cell, same pointer, two colours."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle topCenter + (0 @ 1);
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushSouth.
	self
		assert: element hintElement background paint color
		equals: LaserGameColors allowActionArrowColor.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle leftCenter + (1 @ 0);
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushEast.
	self
		assert: element hintElement background paint color
		equals: LaserGameColors denyActionArrowColor
```

Both assertions failed to begin with, with `Got Color gray instead of Color green.`, which is the grey that page 130 wants rid of.

The second one holds the other half, the one line of page 131 that says a rotation is never refused:

```smalltalk
LaserGameCellElementTestCase >> testARotateArrowIsAlwaysColouredAsAllowed
	"A mirror can always be turned, in either direction, whatever stands around it. Page 131 says
	so in one line — the outside region answers true — so both rotate arrows are drawn in the
	colour of a move that is allowed, even on a mirror that is boxed in."

	| board element |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 3 @ 3.
	{ (CellClickRegionOutside regionRectangle topLeft
	  -> CellClickRegionRotateClockwise).
	(CellClickRegionOutside regionRectangle bottomLeft - (0 @ 1)
	 -> CellClickRegionRotateCounterClockwise) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element hintRegion equals: each value.
		self
			assert: element hintElement background paint color
			equals: LaserGameColors allowActionArrowColor ]
```

The cell it uses, 3@3, is a mirror with a mirror on each side of it, so every push from it is refused; both rotate arrows are still green.

## Checking it

```
152 run, 152 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

And on screen, in a space opened on a board over the demo grid: move the pointer around the mirror at 4@1 and the arrow turns from green to red as it crosses from the lower triangle of the inside region to the left one.

> The hint arrows are now in color and they show the correct colors (although a little too brightly I think) depending on whether the action is permitted or not. And of course, the rotation hints are the correct color too.

## The page this port does not follow

Page 133 ends the section by saving version 2 of the package in Monticello. As in Section 3.16, that step belongs to Iceberg and Git here, and to the booklet that covers them:

<https://books.pharo.org/booklet-ManageCode/pdf/2024-05-16-ManageCode.pdf>

The commit for this section is the equivalent, and it is the reader's to make.

# Better Cursor Management

*Pages 134 to 136 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/134.html
     http://squeak.preeminent.org/tut2007/html/135.html
     http://squeak.preeminent.org/tut2007/html/136.html -->

> One of the things I don't like about the current implementation of our LaserGame morph is that the cursor arrow gets in the way when your moving around over a mirror cell. The hint arrows draw themselves on the cell but in some situations it's difficult to see them because the mirror cell is relatively small and the cursor/arrow is almost the same size.

The pointer hides the very thing it is asking for. Page 134 answers by replacing the pointer itself while it is over a hint: a small cross hair instead of the system arrow.

## The cross hair the original draws

Page 134 draws it as a form of one cell with two ten-pixel lines through the middle, caches it under `#crossHair`, and adds an `initialize` class method so that a package load rebuilds the cache:

```
drawCrossHair
	"LaserGameForms initializeCachedForms"
	| form pen startPoint endPoint line lineLength inset |
	lineLength := 10.
	form := Form extent: CellRenderer cellExtent depth: 32.
	form fillColor: Color transparent.
	pen := Form extent: 1@1 depth: 1.
	pen fillColor: Color black.
	inset := ((form width - lineLength) // 2)@((form height - lineLength) // 2).
	startPoint := (inset x)@(form height // 2).
	endPoint := (form width - (inset x))@(form height // 2).
	line := Line from: startPoint to: endPoint withForm: pen.
	line displayOn: form.
	startPoint := (form width // 2)@(inset y).
	endPoint := (form width // 2)@(form height - (inset y)).
	line := Line from: startPoint to: endPoint withForm: pen.
	line displayOn: form.
	^form
```

Section 3.4 ported that drawing already, as two bars in an element, since the port keeps no pixels:

```smalltalk
LaserGameShapes class >> crossHairElementOfExtent: anExtent
	"Answer a cross hair of anExtent: two bars crossing at the centre. Page 083 drew the same
	figure as two lines in a form of one cell, and Section 4.2 puts it under the pointer while
	the pointer is over a hint of a mirror."

	| span thickness |
	span := (anExtent x min: anExtent y) // 3.
	thickness := (span // 5) max: 1.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self crossHairBarOfExtent: span @ thickness within: anExtent);
		  addChild: (self crossHairBarOfExtent: thickness @ span within: anExtent);
		  yourself
```

So this section deletes page 134's own code instead of writing it: `LaserGameForms class >> drawCrossHair` and `crossHair` go, and the two lines that cached the form go with them. `initializeCachedForms` and page 134's `initialize` stay a while longer — the beam masks of Section 4.7 are the last things in that dictionary.

Page 134's warning about the cache is worth keeping in mind even so, because it is an argument for having no cache at all:

> As we extend the code in the #initializeCachedForms method, remember that we need to be certain to re-initialize those cached forms otherwise our new forms will not be present in the cached dictionary.

A shape that is built when it is used cannot go stale, and `LaserGameShapes` builds one every time.

## Where the port diverges

Page 135 makes the swap in two places: the mirror renderer sets the cross hair as a temporary cursor whenever it draws a hint, and the game morph puts the default back when the pointer leaves the board.

```
self currentHand
	showTemporaryCursor: LaserGameForms crossHair
	hotSpotOffset: (LaserGameForms crossHair extent // 2)
```
```
mouseLeave: evt forMorph: aSketchMorph
	evt hand removeMouseListener: self.
	self sweepDirtyCells.
	self changed.
	self currentHand showTemporaryCursor: nil
```

Bloc can do the same thing. `BlElement >> mouseCursor:` sets the cursor an element asks for, and the mouse processor walks up from the element under the pointer to find the first one that names a cursor and hands it to the host window. What it hands over is a `Cursor`, and `Cursor` is a subclass of `Form`. This port has one rule that outranks following the page: no class in the package binds `Form`, `Morph` or `Cursor`. Page 135 is therefore ported by its intent rather than by its means.

The intent is that the pointer should not hide the answer, and that the player should see exactly which point the click will be judged by — the cell is divided into six regions, and a pixel decides between them. So the port draws the cross hair **in the cell, centred on the point under the pointer**, and shows it exactly when a hint arrow is shown, which is exactly when page 135 swaps the cursor.

The size is the one number page 134 chose, in the proportion it chose it:

```smalltalk
CellRenderer class >> crossHairExtent
	"Answer the size the cross hair under the pointer is drawn at. Page 134 draws it into a form
	of one cell, with arms of ten pixels in the thirty pixel cell of the time, and the shape
	makes its arms a third of what it is given, so a cell is the size that keeps those
	proportions."

	^ self cellExtent
```

and the cell element gains a slot, `crossHairElement`, beside `hintElement`, `hintRegion` and `hintPosition`:

```smalltalk
LaserGameCellElement >> updateCrossHairElement
	"Mark the point the pointer is at, whenever I show a hint, and mark no point when I show
	none. Page 134 wants that mark because the pointer hides the arrow it asks for: the original
	replaces the cursor picture with a cross hair while the pointer is over a hint, and puts the
	default back when it is not. The port cannot replace the cursor picture, since every cursor
	in the image is a Form and no class here may depend on one, so the cross hair is drawn in the
	cell instead, centred on the point a click would use. It is built when the hint is and then
	only moved, since the pointer sends an event for every pixel it crosses."

	hintElement ifNil: [
		crossHairElement ifNotNil: [ :each |
			self removeChild: each.
			crossHairElement := nil ].
		^ self ].
	crossHairElement ifNil: [
		crossHairElement := LaserGameShapes crossHairElementOfExtent:
			                    CellRenderer crossHairExtent.
		self addChild: crossHairElement ].
	crossHairElement position:
		hintPosition - (CellRenderer crossHairExtent // 2)
```
```smalltalk
LaserGameCellElement >> crossHairElement
	"Answer the cross hair I show under the pointer, or nil when I show none."

	^ crossHairElement
```

Three methods call it, and each is one line longer than it was. `updateHintElement` ends with it, so a hint that appears, changes or goes takes the cross hair with it; it also drops the cross hair first, so that the new one is added after the arrow and is drawn on top of it rather than under it:

```smalltalk
LaserGameCellElement >> updateHintElement
	"Show the picture of the hint I hold, and no other, in the colour of what a click there would
	do. The original drew its arrow straight onto the board form, which is why page 093 warns
	that old arrows have to be cleaned off; here the arrow is a child of mine, so the previous
	one goes when it is removed. The colour comes from page 130: my renderer answers green when
	the move is allowed and red when it is refused. A region without a picture, such as the
	ignore margin, answers nothing and leaves me with no hint at all. The cross hair of page 134
	is shown exactly when the arrow is, and is dropped here so that it is added after the arrow
	and stays the child on top of it."

	hintElement ifNotNil: [ :each | self removeChild: each ].
	hintElement := hintRegion ifNotNil: [ :region |
		               region hintElementOfExtent: CellRenderer hintArrowExtent ].
	hintElement ifNotNil: [ :each |
		each
			background: (self renderer hintColorAt: hintPosition);
			position: CellRenderer hintArrowOffset.
		self addChild: each ].
	crossHairElement ifNotNil: [ :each |
		self removeChild: each.
		crossHairElement := nil ].
	self updateCrossHairElement
```

`showPositionHintAt:` calls it on the path it used to return early on. That early return is what makes the arrow cheap — a pointer crossing one region sends an event per pixel, and the arrow is the same for all of them — but the cross hair is different for every one of them, because it marks the point:

```smalltalk
LaserGameCellElement >> showPositionHintAt: aPoint
	"Keep the hint my renderer answers for aPoint, which is in my own coordinates, and show it.
	My renderer decides: a mirror answers the region the point falls in, every other cell answers
	nothing. A move within the same region changes nothing about the arrow, so it is built once;
	the cross hair of page 134 marks the point itself and moves with every event. The point is
	kept, because a redraw has to ask the question again for the cell that stands in me then."

	| region |
	hintPosition := aPoint.
	region := self renderer hintRegionAt: aPoint.
	region = hintRegion ifTrue: [ ^ self updateCrossHairElement ].
	hintRegion := region.
	self updateHintElement
```

and `redraw`, which rebuilds a cell from the model, forgets the old cross hair along with the old arrow before asking for the hint again:

```
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because page 126 of the original is the
	tale of a view that went on believing in the cell that had moved away. A blank cell offers no
	push, so the arrow of the mirror that left goes with it, and the cross hair with the arrow.
	The original repainted a rectangle of the board form and called it redrawCell."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	crossHairElement := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```
> **Note.** *Laser On Blank Cell*, later in this section, adds one line to this method, so that a cell drawn again after the laser was fired draws the beam with it.


Page 135's other half needs nothing. `clearPositionHint` already runs when the pointer leaves a cell, and it goes through `updateHintElement`, so the mark goes with the arrow:

```smalltalk
LaserGameCellElement >> mouseLeave: anEvent
	"The pointer left me: my board hovers me no longer, and my hint goes with it."

	self board ifNotNil: [ :board | board unhoverCellElement: self ].
	self clearPositionHint
```
```smalltalk
LaserGameCellElement >> clearPositionHint
	"Forget my hint: the pointer is no longer in me, so the arrow goes too, and so does the point
	it was read at."

	hintPosition := nil.
	hintRegion ifNil: [ ^ self ].
	hintRegion := nil.
	self updateHintElement
```

## Three tests

The mark is at the point, and it is the size the constant says:

```smalltalk
LaserGameCellElementTestCase >> testACrossHairMarksThePointWhereAHintIsShown
	"Page 134: the pointer itself gets in the way of the hint it asks for. The port cannot swap
	the system cursor, since every cursor in the image is a Form, so it draws the cross hair of
	page 134 in the cell, centred on the point a click would use. An element is measured in a
	layout pass, so what it was asked for is read from its constraints."

	| board element point extent |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	point := CellClickRegionInside regionRectangle center.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: point;
			 yourself).
	extent := CellRenderer crossHairExtent.
	self assert: element crossHairElement isNotNil.
	self
		assert:
		element crossHairElement constraints horizontal resizer size
		@ element crossHairElement constraints vertical resizer size
		equals: extent.
	self
		assert: element crossHairElement constraints position + (extent // 2)
		equals: point
```

It moves with the pointer inside one region, which is the case the arrow deliberately ignores:

```
LaserGameCellElementTestCase >> testTheCrossHairFollowsThePointerWithinOneRegion
	"The arrow is built once per region, since it does not change while the pointer stays in one,
	but the cross hair marks a point and moves with every event."

	| board element first second extent |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	extent := CellRenderer crossHairExtent.
	first := CellClickRegionInside regionRectangle center.
	second := first + (0 @ 4).
	element dispatchEvent: (BlMouseMoveEvent new
			 position: first;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: second;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionPushNorth.
	self
		assert: element crossHairElement constraints position + (extent // 2)
		equals: second
```
> **Note.** *A Missed Bug*, the first chapter of Section 5, steps down by a quarter of the inside region instead of four pixels, so that the second point is in the same push region at any cell size.

And it is shown exactly when a hint is: not in the ignore margin, not after the pointer leaves, and never on a cell that offers nothing:

```smalltalk
LaserGameCellElementTestCase >> testTheCrossHairIsShownExactlyWhenAHintIs
	"Page 135 sets the cursor back to the default in the two places the hint goes: a point that
	offers no action, and the pointer leaving. A cell that offers nothing, like the blank one at
	2@2, never shows either."

	| board mirror blank |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	mirror := board cellElementAt: 4 @ 1.
	blank := board cellElementAt: 2 @ 2.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: mirror crossHairElement isNotNil.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: 0 @ 0;
			 yourself).
	self assert: mirror hintRegion equals: CellClickRegionIgnore.
	self assert: mirror hintElement isNil.
	self assert: mirror crossHairElement isNil.
	mirror dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: mirror crossHairElement isNotNil.
	mirror dispatchEvent: BlMouseLeaveEvent new.
	self assert: mirror crossHairElement isNil.
	blank dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionInside regionRectangle center;
			 yourself).
	self assert: blank crossHairElement isNil
```

Two older tests count the children of a cell, and a hint now brings two of them. Both say so:

```smalltalk
LaserGameCellElementTestCase >> testAMirrorCellShowsOneArrowAtATime
	"The fourth design consideration of page 093: old arrows must not clutter the board. The
	original had to redraw the cell before drawing the new arrow; here the cell has one hint
	child, and moving to another push region replaces it. Two children come with a hint since
	Section 4.2: the arrow and the cross hair under the pointer."

	| board element rect childCount |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	rect := CellClickRegionInside regionRectangle.
	{ (rect leftCenter + (1 @ 0) -> LaserGameShapes eastArrowPoints).
	(rect topCenter + (0 @ 1) -> LaserGameShapes southArrowPoints).
	(rect rightCenter - (1 @ 0) -> LaserGameShapes westArrowPoints) } do: [ :each |
		element dispatchEvent: (BlMouseMoveEvent new
				 position: each key;
				 yourself).
		self assert: element children size equals: childCount + 2.
		self
			assert: element hintElement geometry vertices
			equals: (LaserGameShapes
					 pointsOf: each value
					 scaledToExtent: CellRenderer hintArrowExtent) ]
```
```smalltalk
LaserGameCellElementTestCase >> testTheArrowStaysWhenTheCellUnderThePointerStillOffersIt
	"The other half of the same rule: a turn leaves the mirror where it is, so the hint under the
	pointer is still the right one and the arrow survives the redraw. The hint is read from the
	cell that stands there after the action, not kept and not dropped. The cross hair of Section
	4.2 comes back with it, which is the second of the two children counted here."

	| board element childCount |
	board := LaserGameBoardElement on: GridFactory demoGrid.
	element := board cellElementAt: 4 @ 1.
	childCount := element children size.
	element dispatchEvent: (BlMouseMoveEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	element dispatchEvent: (BlClickEvent new
			 position: CellClickRegionOutside regionRectangle topLeft;
			 yourself).
	self assert: element cell class equals: MirrorCell.
	self assert: element hintRegion equals: CellClickRegionRotateClockwise.
	self assert: (element children includes: element hintElement).
	self assert: (element children includes: element crossHairElement).
	self assert: element children size equals: childCount + 2
```

## Checking it

```
155 run, 155 passes, 0 skipped, 0 expected failures,
0 failures, 0 errors, 0 unexpected passes
```

On screen, over a mirror cell: the arrow appears as before, and a small cross follows the pointer inside it, jumping to the arrow of the next region as the pointer crosses a boundary. Over a blank or a target cell, nothing.

> We should now be seeing a cross-hair cursor when we travel over mirror cells. This will be true only during the times we are hovering over one of the clikc regions.

Page 136 ends by saving a third package version in Monticello, which is a commit here, and Section 3.16 says why that chapter is not repeated.

# Making Larger Cells

*Pages 137 and 138 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/137.html
     http://squeak.preeminent.org/tut2007/html/138.html -->

> For our next enhancement I want to change the size of our cells. Making them bigger will make the game cells easier to see, as well as any hint arrows within the mirror cells. It should also "illuminate" (pardon the pun) any issues we may have with unintended constants in our code.

The pun is the whole chapter. Raising the cell size is one line of work; finding everything that quietly assumed the old size is the rest of it, and the original spends both pages on it.

This port arrives at the chapter from the other end. The source it inherited is the finished 2007 game, in which the author had already enlarged the cells twice, so `CellRenderer class >> cellExtent` has answered fifty by fifty since Section 3.1, and every size derived from it was written as a derivation when it was first quoted. There is nothing here left to fix.

That makes this chapter a proof rather than a change: the cell size is raised and lowered again, and the geometry is asked whether it followed. The chapter does add something, though, because a promise nobody checks is not a promise. The experiment the original runs by eye is written down as a test, and the constants it is about get the comments that say what they are.

## The one number

Page 137 changes the size, and nothing else:

```
cellExtent

    ^40@40
```

The port has had this since the beginning, and this section gives it the comment it deserves:

```smalltalk
CellRenderer class >> cellExtent
	"Answer the size, in pixels, of one cell. Every other size in the package is derived from
	this one, so a cell of another size needs no other change anywhere: page 137 of the original
	raises it from thirty pixels to forty and then goes looking for the sizes that had been
	written down instead. The port has been at fifty since Section 3.1, because the source it
	inherits is the finished game, where the author had already enlarged the cells a second time
	on page 196."

	^50@50
```

The two nested regions of a cell and the margin around them were quoted in Section 3.1, where only two of the four were numbers. They are the same methods now, with comments:

```smalltalk
CellRenderer class >> insideRegionExtent
	"Answer the size of the square in the middle of a cell where a click asks for a push. Page
	138 of the original writes it as the cell less twenty pixels, so the ring around it keeps its
	width while the cell grows."

	^self cellExtent - 20
```
```smalltalk
CellRenderer class >> outsideRegionExtent
	"Answer the size of the square where a click asks for a rotation: the cell less the ignore
	margin on each side. The margin is what is written down, not the region."

	^self cellExtent - (2 * self ignoreRegionOffset)
```
```smalltalk
CellRenderer class >> ignoreRegionOffset
	"Answer the width, in pixels, of the margin along the edges of a cell where a click does
	nothing. Page 075 of the original picks four pixels, and four is right at any cell size: the
	margin is there to keep a click aimed at the neighbouring cell from turning this one."

	^4
```

Page 138 writes `insideRegionExtent` exactly as it stands above, which is why Section 3.1 could already quote it that way: the inherited source was ahead of the text.

## What the larger cell illuminates

The original opens the game and finds its target cell wrong:

> That's pretty good. The Target Cell circle looks like it didn't scale with the new larger cell.

Its circle was drawn with a radius of seven pixels, written into the drawing method:

```
drawCircleOutline

    | delta offset fillForm circle |

    delta := CellRenderer cellExtent - 1.

    offset := self offsetWithinGridForm.

    circle := Circle new.

    fillForm := Form extent: 2@2 depth: 8.

    fillForm fillColor: LaserGameColors targetCenterColor.

    circle form: fillForm.

    circle radius: 7.

    circle center: (offset + (delta // 2)).

    circle displayOn: self targetForm.
```

> The radius is hard-coded at 7. We should probably make the radius dependent on the over-all size of our cell. I'm inclined to pull the radius calculation out into a separate method because we should use it for our circle fill color code too.

The method it pulls out is one the port already has, because the inherited source already had it. This section only adds the comment:

```smalltalk
TargetCellRenderer >> radius
	"Answer the radius of the ring drawn in a target cell. Page 137 of the original replaces a
	hard coded seven with this calculation, so that the ring grows with the cell, and clamps the
	result at ten so that it stops growing once the cell is large enough."

	^(self class cellExtent x // 2 - 8) min: 10
```

> This calculation uses the size of the cell to calculate a new radius. Notice that I put a "clamp" in the final result. We're going to restrict the radius to be no larger than 10.

The clamp is worth reading twice, because it means the ring stops growing. At a thirty pixel cell the radius is seven, at forty it is ten, and at fifty or eighty it is still ten. The target is deliberately not a circle that fills its cell; it is a small ring in the middle of one, and it looks the same in a large cell as in a medium one.

Page 137 then fixes the fill inside the ring the same way, replacing a hard coded three with `self radius - 4`. In the port that is `innerRadius`, and the four is `centerInset`, a constant of its own since Section 2.2:

```smalltalk
TargetCellRenderer >> innerRadius
	"Answer the radius of the filled center of the target, which stays inside the ring."

	^ self radius - self class centerInset
```

Both circles are placed by one method, which is where the last of page 137's arithmetic lives. Nothing in it is a size:

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

## Page 138: the lines that cut a cell up

> The cells look good after we scaled-up our cell extent. However the arrow hints appear to be trigger based upon old cell sizes.

Three of the tests that classify a point were written against the thirty pixel cell. The first is the rotate line, which divides the outside region into a clockwise half and a counter-clockwise one. Page 138 rewrites both halves:

```
containsPoint: aPoint

    ^aPoint y <= (CellRenderer cellExtent y)
```
```
containsPoint: aPoint

    ^aPoint y > (CellRenderer cellExtent y)
```

Read those two as printed and the first is true everywhere in the cell and the second nowhere: the halving is missing. The page means half the height, which is what the port writes, and what the tests of Section 3.8 pin down:

```smalltalk
CellClickRegionRotateClockwise class >> containsPoint: aPoint
	"Answer whether aPoint is in the upper half of the cell. The line is half the height of the
	cell rather than a number of pixels, so it follows the cell size of page 138. A point exactly
	on the line is mine, which is what page 103 asks for."

	^aPoint y <= (CellRenderer cellExtent y // 2)
```
```smalltalk
CellClickRegionRotateCounterClockwise class >> containsPoint: aPoint
	"Answer whether aPoint is in the lower half of the cell. My sister takes the line itself, so
	I ask for a strictly greater y, and the two of us cover the region without overlapping."

	^aPoint y > (CellRenderer cellExtent y // 2)
```

The second of the three is one diagonal of the cell. Page 138 writes it against the cell size:

```smalltalk
CellClickRegionInside class >> yForHeadingDownLineWith: x
	"Answer the y of the diagonal running from the top right corner of the cell to the bottom
	left one, at abscissa x. Page 138 of the original writes it against the cell, not against the
	push region, so the diagonal passes through the corners at any cell size."

	^CellRenderer cellExtent x - x
```

and its twin needs nothing, since the other diagonal of a square is `y = x`:

```smalltalk
CellClickRegionInside class >> yForHeadingUpLineWith: x
	"Answer the y of the diagonal running from the top left corner of the cell to the bottom
	right one, at abscissa x. This one needs no cell size: the diagonal of a square is y = x."

	^x
```

Both lines run corner to corner across the whole cell, not across the inside square, so the inside square is cut into four wedges by whatever part of them crosses it. That is why the push regions follow the cell size without knowing it.

Page 138 closes with an apology the port does not need to carry forward:

> The arrows themselves don't seem as nicely positioned as we would like. However I'm not going to address that now. The problem is likely related to how we draw the arrows on the arrow forms. We'll make improvements to the appearance of our arrows later.

The arrows of the original are bitmaps drawn once at 330 pixels and scaled down, which is what puts them slightly out of place. The port builds them from vertices at the size it wants, and Section 3.4 tests them at twelve, fifty and two hundred pixels, so there is nothing here to improve later.

## Proving it instead of looking at it

The original raises the cell size, opens the game, and reads the screen. That is a real experiment, and it can be run by the test suite instead of by eye. One helper sets the cell size for the duration of a block and puts it back:

```
CellRendererTestCase >> withCellExtent: anExtent do: aBlock
	"Run aBlock with the cell size of the whole package set to anExtent, and put the old size
	back afterwards. Page 137 of the original raises the cell size and then looks by eye for the
	sizes that were written down instead of derived from it; this runs that experiment from the
	test suite."

	| previous |
	previous := CellRenderer class >> #cellExtent.
	[
	CellRenderer class
		compile: 'cellExtent' , String cr , String tab , '^ ' , anExtent printString
		classified: 'constants'.
	aBlock value ] ensure: [
		CellRenderer class compile: previous sourceCode classified: 'constants' ]
```
> **Note.** *A Less Brittle Unit Test Design*, the seventh chapter of Section 5, moves this method up to a new abstract `LaserGameTestCase`, where the click tests can reach it too. The body is unchanged apart from its comment.

Recompiling a method inside a test is heavier than a test usually is, and it is the honest way to write this one: the cell size is a class side constant that the whole package reads through `CellRenderer`, so there is no instance to stub and no parameter to pass. The `ensure:` block puts the old method back even if an assertion fails, so a failure here cannot leave the image at the wrong size.

The test then asks the geometry the questions pages 137 and 138 ask by looking:

```smalltalk
CellRendererTestCase >> testEverySizeInACellFollowsTheCellSize
	"Page 137 of the original raises the cell size, and page 138 then finds the sizes that do not
	follow: the inside region, the line between the two rotate regions and one of the two
	diagonals. The port derives all of them from the cell size already, so this section proves
	that rather than changing it. At any cell size the two nested regions stay centred in the
	cell, every point of the cell still falls in a region, the four push regions still divide the
	inside square between them without overlapping, the ring of a target still fits in the cell,
	and a board is still the grid times the cell."

	| grid |
	grid := GridFactory demoGrid.
	#( 30 40 80 ) do: [ :side |
		self withCellExtent: side @ side do: [
			| cell inside outside middle renderer |
			cell := 0 @ 0 extent: side @ side.
			inside := CellClickRegionInside regionRectangle.
			outside := CellClickRegionOutside regionRectangle.
			self assert: inside extent equals: CellRenderer insideRegionExtent.
			self assert: outside extent equals: CellRenderer outsideRegionExtent.
			self assert: inside center equals: cell center.
			self assert: outside center equals: cell center.

			middle := side // 2.
			self assert: (CellClickRegionRotateClockwise containsPoint: 0 @ middle).
			self deny: (CellClickRegionRotateClockwise containsPoint: 0 @ (middle + 1)).
			self assert:
				(CellClickRegionRotateCounterClockwise containsPoint: 0 @ (middle + 1)).

			0 to: side - 1 do: [ :x |
				0 to: side - 1 do: [ :y |
					self assert: (CellClickRegion clickRegionForPoint: x @ y) notNil ] ].
			inside left to: inside right do: [ :x |
				inside top to: inside bottom do: [ :y |
					self
						assert: (CellClickRegionInside subclasses count: [ :each |
								 each containsPoint: x @ y ])
						equals: 1 ] ].

			renderer := CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid.
			self assert: renderer radius > 0.
			self assert: renderer innerRadius > 0.
			self assert: renderer radius * 2 <= side.

			self
				assert: (LaserGameBoardElement extentForGrid: grid)
				equals: side * grid numberOfColumns @ (side * grid numberOfRows) ] ]
```

Four things are checked at each of three cell sizes. The nested regions stay centred in the cell and keep the extents the constants promise. The rotate line stays at half the height, with the line itself on the clockwise side. Every point of the cell falls in exactly one region, which is two assertions really: `clickRegionForPoint:` finds one, and the four push regions divide the inside square between them without overlapping anywhere. And the ring of a target still fits inside its cell, while a board is still the grid times the cell.

The two region rectangles are worth looking at while reading the test, since they are the only place the cell size and the region size meet:

```smalltalk
CellClickRegionInside class >> regionRectangle
	"CellClickRegionInside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer insideRegionExtent.
	^outer insetBy: (delta // 2)
```
```smalltalk
CellClickRegionOutside class >> regionRectangle
	"CellClickRegionOutside regionRectangle"
	| outer delta |
	outer := 0@0 extent: CellRenderer cellExtent.
	delta := CellRenderer cellExtent - CellRenderer outsideRegionExtent.
	^outer insetBy: (delta // 2)
```

## Checking it

The picture is still worth having, and the honest way to get it is to raise the size, look, and lower it again by hand:

```
CellRenderer class compile: 'cellExtent' , String cr , String tab , '^ 80@80' classified: 'constants'.
LaserGameElement openExample
```

```
CellRenderer class compile: 'cellExtent' , String cr , String tab , '^ 50@50' classified: 'constants'
```

The cells are large, the mirrors reach their corners, the target ring stays the small ring the clamp asks for, and the borders are still one pixel.

Close the window before lowering the size again. A cell element is laid out once, at the size that was current when it was built, but the click regions are computed from `CellRenderer class >> cellExtent` on every single mouse move. Lower the size under an open board and the two stop agreeing: the element is eighty pixels wide, the regions are fifty, and the pointer spends most of its time on a point that belongs to no region at all.

## What that turns up

Doing exactly that — opening the board at eighty and restoring fifty while it was still on screen — produced one walkback per mouse move, fifty five of them, all the same:

```
NotFound: [:cls | cls regionRectangle containsPoint: aPoint] not found in SortedCollection
CellClickRegion class>>clickRegionForPoint:
MirrorCellRenderer>>hintRegionAt:
LaserGameCellElement>>showPositionHintAt:
LaserGameCellElement>>mouseMove:
```

The classification was written as a `detect:` with no `ifNone:`, which is safe exactly as long as some region contains the point. The ignore region covers the whole cell, so every point of a cell does find one — and a point outside the cell finds nothing and raises. That is a real hole and not only an artefact of the experiment: a cell element is free to be larger than the cell the regions are computed from, and a mouse move is not a place to raise anything.

A point outside the cell is a point a click can do nothing with, which is precisely what the ignore region already means, so it is the answer:


```smalltalk
CellClickRegion class >> clickRegionForPoint: aPoint
	"Answer the region of a cell aPoint falls in. My subclasses are tried innermost first, and the
	ignore region covers the whole cell, so any point within a cell finds one. A point outside the
	cell finds none, and is ignored: a click there can do nothing, which is what the ignore region
	already means. A mouse event carries such a point whenever the element under the pointer is
	larger than the cell the regions are computed from, and answering it here keeps the case out of
	every mouse handler."

	^self sortedSubclasses
		detect: [ :cls | cls regionRectangle containsPoint: aPoint ]
		ifNone: [ CellClickRegionIgnore ]
```

and the test says so at each of the four ways out of a cell:

```smalltalk
CellClickRegionTestCase >> testAPointOutsideTheCellIsIgnored
	"A point that falls in no region is ignored rather than an error. An element larger than the
	cell the regions are computed from sends such a point on every mouse move, and what happens
	there must be nothing at all, not a walkback out of the event handler."

	| beyond |
	beyond := CellRenderer cellExtent.
	self
		assert: (CellClickRegion clickRegionForPoint: beyond)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: -1 @ -1)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: beyond x @ 0)
		equals: CellClickRegionIgnore.
	self
		assert: (CellClickRegion clickRegionForPoint: 0 @ beyond y)
		equals: CellClickRegionIgnore
```

Nothing else in the classification needs the same treatment. The four push regions answer the four combinations of two booleans, and the two rotate regions split on one, so each of those `detect:` calls always finds exactly one subclass, whatever point it is given. Only the outermost one could fail, and only outside the cell.

Page 138 ends by saving another Monticello version, which Section 3.16 answers once for the whole port.

# Add A Counter and Window Colors

*Pages 139 to 142 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/139.html
     http://squeak.preeminent.org/tut2007/html/140.html
     http://squeak.preeminent.org/tut2007/html/141.html
     http://squeak.preeminent.org/tut2007/html/142.html -->

> It's time to add some really slick looking features. I want to jazz-up the colors of the interface and add an LED panel that shows how long the laser beam path is while you are playing. A little bit of "eye candy" is always a good thing when creating a game.

Four pages, and none of them changes a rule. The game gets a margin, the panel moves to the other side, the window is filled with a colour ramp instead of a flat colour, and a small LED display appears at the top of the panel counting the cells the beam crosses. The last of the four wires that display to the two places where the beam can change.

Three of these the port already has, one it inherits for free, and two are real work: the ramp, and the LED. The LED is the larger of the two, because the original takes its display from the Squeak image and this port cannot.

## What the port already has

Page 139 opens with three changes, and the port arrives with all three.

The first is the margin around the game:

```
gameMargin
    ^4
```

The port has answered ten since Section 2.6, because the source it inherits is the finished game and the author raised the margin later. `LaserGameElement class >> gameMargin` is that method, and nothing here changes it.

The second is the extent that accounts for the margin:

```
calculatedExtent
    | pt |
    pt := self boardForm extent.
    pt := pt + (self panelWidth@0).
    pt := pt + (2 * self gameMargin).
    ^pt
```

`LaserGameElement class >> extentForGrid:` is that arithmetic, quoted in Section 2.6, with the board element standing in for the board form.

The third is a refactoring: the code that adds the buttons moves out of `makeControlPanelMorph` into an `addButtonsToPanel:` of its own, so that the counters can be added beside it. `LaserGameControlPanelElement >> newButtonRow` has been separate from `rebuild` since Section 2.7, for the same reason and one page earlier.

Page 140 adds a fourth:

```
cellBorderColor
    ^Color white
```

`LaserGameColors class >> cellBorderColor` has answered white since Section 2.13. The inherited source was ahead of the text again.

And page 140 changes one method that has no counterpart at all:

```
boardRelativePositionFor: evt
    | evtPosn |
    evtPosn := evt hand position.
    ^evtPosn - self position - ((self gameMargin + self panelWidth) @ self gameMargin)
```

This is the arithmetic that turns the position of the hand into a position within the board, and it has to be corrected here because the board moved. In the port every cell is an element and Bloc hands an event to the element it happened in, already in that element's coordinates, so there is nothing to correct. Section 2.9 is where that method stopped having a counterpart; this page is where the original pays for having one.

## The panel moves to the left

Page 139 rewrites `setupMorphs` to put the control panel on the left and the board on the right, each in a layout frame that subtracts the margin from the edges:

```
setupMorphs
    self layoutPolicy: ProportionalLayout new.
    self
        addMorph: self makeControlPanelMorph
        fullFrame: (LayoutFrame
                fractions: (0 @ 0 corner: 0 @ 1)
                offsets: (self gameMargin @ self gameMargin
                    corner: (self gameMargin + self panelWidth) @ self gameMargin negated)).
    self
        addMorph: self makeGameBoardMorph
        fullFrame: (LayoutFrame
                fractions: (0 @ 0 corner: 1 @ 1)
                offsets: ((self gameMargin + self panelWidth) @ self gameMargin 
                    corner: self gameMargin negated @ self gameMargin negated)).
```

The port holds its two children in a horizontal linear layout with the margin as padding, so the whole of that page is the order the two are added in:

```
LaserGameElement >> rebuild
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. Page 139 moves the panel to the left of the
	board, which here is the order the two are added in. The board tells the panel when a move
	changed the grid, so the counters follow a click as well as the fire button."

	self removeChildren.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: controlPanel.
	self addChild: board.
	board whenMoveMadeDo: [ self controlPanel updateCounters ].
	self extent: (self class extentForGrid: self grid)
```

Section 4.5 counts the move before it sets the counters, so the block registered there is one method call in the image today.

The last line before the extent is the wire of page 142, and it is described at the end of this chapter.

## A ramp instead of a colour

Page 140 fills the window with a gradient:

```
windowColorRamp
    ^ {0.0 -> (Color r: 0.3 g: 0.8 b: 0.9).
        1.0 -> (Color r: 0.2 g: 0.1 b: 0.7)}
```

```
setWindowColors
    self color: (Color
        r: 0.369
        g: 0.369
        b: 0.505).
    self fillWithRamp: self windowColorRamp oriented: 0.3@0.8
```

The ramp is a list of stops: a fraction of the way along the fill, and the colour there. Bloc calls them stops too, so the ramp itself moves across unchanged, into the class that holds every colour of the game:

```smalltalk
LaserGameColors class >> windowColorRamp
	"Answer the ramp the window is filled with: page 140's two stops, each a fraction of the way
	along the fill paired with the color there. The original hands the same array of associations
	to #fillWithRamp:oriented:, and Bloc calls them the stops of a gradient paint."

	^ {
		  (0.0 -> (Color r: 0.3 g: 0.8 b: 0.9)).
		  (1.0 -> (Color r: 0.2 g: 0.1 b: 0.7)) }
```

```smalltalk
LaserGameColors class >> windowColorRampDirection
	"Answer the direction the window ramp runs in, as a fraction of the window in each direction:
	page 140's #oriented: argument. The first stop sits at the top left corner and the last one
	that fraction of the way across and down."

	^ 0.3 @ 0.8
```

The direction is the `oriented:` argument of the original, kept beside the stops it belongs to. A `BlLinearGradientPaint` takes a start and an end rather than an orientation, and the two say the same thing:

```smalltalk
LaserGameElement class >> windowBackgroundPaint
	"Answer the paint behind the whole game: page 140's ramp, running in the direction that page
	orients its fill in. The original sets a flat window color and then fills the morph with the
	ramp on top of it; an element takes one paint, so only the ramp is left, and the flat color
	stays as LaserGameColors gameWindowColor for whatever needs a single color."

	^ BlLinearGradientPaint new
		  stops: LaserGameColors windowColorRamp;
		  start: 0 @ 0;
		  end: LaserGameColors windowColorRampDirection;
		  yourself
```

```
LaserGameElement >> initialize
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin)
```

Section 4.5 adds one line, which starts the move count at zero.

The flat colour of `setWindowColors` survives as `LaserGameColors gameWindowColor`, unused by the window now. The original needs both because `fillWithRamp:oriented:` paints over a morph that already has a colour; an element is given one paint and that is what it draws.

The last colour change of page 140 takes the white out of the panel, so that the ramp runs behind it without a rectangle in the way:

```smalltalk
LaserGameColors class >> controlPanelColor
	"Answer the color of the control panel beside the board. Page 140 paints it transparent, so
	the ramp behind the whole window shows through it; the white of page 068 was only a
	placeholder."

	^ Color transparent
```

## An LED the port has to draw itself

Page 141 builds the counter out of a class the original never writes:

```
makeLaserPathCounterMorph
    | count |
    count := LedMorph new
                digits: 3;
                extent: 3 * 10 @ 15;
                setBalloonText: ''.
    count color: (Color r: 0.674 g: 0.674 b: 0.96).
    count name: 'laserPath'.
    ^ self wrapPanel: count label: 'Laser Path'
```

`LedMorph` comes with Squeak. Pharo has nothing of the kind, and even if it did it would be a `Morph`, which no class here may depend on. So the port draws the display: seven rectangles per digit, and showing a number recolours them.

The segments carry the names a seven segment display has always given them, and one method says which of them each digit lights:

```smalltalk
LaserGameLedElement class >> segmentNames
	"Answer the names of the seven segments, in the order they are held in a digit element."

	^ #( #a #b #c #d #e #f #g )
```

```smalltalk
LaserGameLedElement class >> segmentsForDigit: anInteger
	"Answer the names of the segments the digit anInteger lights."

	^ #( #( #a #b #c #d #e #f ) #( #b #c ) #( #a #b #g #e #d )
	     #( #a #b #g #c #d ) #( #f #g #b #c ) #( #a #f #g #c #d )
	     #( #a #f #g #e #c #d ) #( #a #b #c ) #( #a #b #c #d #e #f #g )
	     #( #a #b #c #d #f #g ) ) at: anInteger + 1
```

Another says where each one sits inside a digit. Every number in it is derived from the digit size and the thickness of a segment, so the display can be drawn at any size — which is the lesson the previous chapter spent two pages on:

```smalltalk
LaserGameLedElement class >> segmentBoundsOf: aSymbol
	"Answer the rectangle segment aSymbol occupies in a digit, in the digit's own coordinates. The
	three bars run across the top, the middle and the bottom, and the four arms fill the two gaps
	the bars leave, so every size follows the digit size and the segment thickness."

	| width height thickness arm |
	width := self digitExtent x.
	height := self digitExtent y.
	thickness := self segmentThickness.
	arm := height - (3 * thickness) // 2.
	aSymbol == #a ifTrue: [ ^ thickness @ 0 extent: width - (2 * thickness) @ thickness ].
	aSymbol == #b ifTrue: [ ^ width - thickness @ thickness extent: thickness @ arm ].
	aSymbol == #c ifTrue: [
		^ width - thickness @ (thickness + arm + thickness) extent: thickness @ arm ].
	aSymbol == #d ifTrue: [
		^ thickness @ (height - thickness) extent: width - (2 * thickness) @ thickness ].
	aSymbol == #e ifTrue: [ ^ 0 @ (thickness + arm + thickness) extent: thickness @ arm ].
	aSymbol == #f ifTrue: [ ^ 0 @ thickness extent: thickness @ arm ].
	aSymbol == #g ifTrue: [
		^ thickness @ (thickness + arm) extent: width - (2 * thickness) @ thickness ].
	^ self error: 'No segment is named ' , aSymbol printString
```

Three constants feed it:

```smalltalk
LaserGameLedElement class >> digitExtent
	"Answer the size, in pixels, of one digit. Page 141 asks for three digits in thirty pixels,
	which is ten each, and fifteen high; the height is one more than the page's, because a bar of
	the segment thickness at the top, the middle and the bottom and an arm between each pair need
	an even number of pixels to divide."

	^ 10 @ 16
```

```smalltalk
LaserGameLedElement class >> segmentThickness
	"Answer the thickness, in pixels, of one segment."

	^ 2
```

```smalltalk
LaserGameLedElement class >> digitGap
	"Answer the gap, in pixels, between two digits. The original's LedMorph leaves the gap inside
	each digit; this one draws it between them, so three digits come to thirty four pixels rather
	than the thirty of page 141."

	^ 2
```

Page 141 asks for `3 * 10 @ 15`: three digits, ten pixels wide each, fifteen high. The width is kept. The height is not, and the comment says why — three bars and two arms of two pixels each need an even number of pixels to divide, and fifteen would leave an arm of four and a half. Sixteen divides, and one pixel of height on a counter is not what this page is about.

A digit is built once and then only recoloured:

```smalltalk
LaserGameLedElement >> newDigitElement
	"Answer one digit: an element of the digit size holding one rectangle per segment, in the
	order the segment names are in. The rectangles stay; showing another number recolours them."

	| digit |
	digit := BlElement new.
	digit extent: self class digitExtent.
	digit background: BlTransparentBackground new.
	self class segmentNames do: [ :name |
		| area segment |
		area := self class segmentBoundsOf: name.
		segment := BlElement new.
		segment extent: area extent.
		segment position: area origin.
		digit addChild: segment ].
	^ digit
```

```
LaserGameLedElement >> rebuildDigits
	"Replace my digits with digitCount fresh ones and take the size they need."

	self removeChildren.
	digitElements := (1 to: digitCount) collect: [ :each | self newDigitElement ].
	digitElements do: [ :each | self addChild: each ].
	self extent: (self class extentForDigits: digitCount).
	self updateDigits
```

*Counters The Player Can Read*, at the end of this section, rewrites this method. The version above is the one this chapter leaves in the image.

```smalltalk
LaserGameLedElement >> updateDigits
	"Color every segment of every digit for the number I show. The number is right aligned, the
	digits in front of it stay blank, and a number too long for me keeps its last digits."

	| text |
	text := value printString.
	text size > digitCount ifTrue: [ text := text last: digitCount ].
	digitElements withIndexDo: [ :digit :index |
		| position segments |
		position := index - (digitCount - text size).
		segments := position > 0
			            ifTrue: [
			            self class segmentsForDigit: (text at: position) digitValue ]
			            ifFalse: [ #(  ) ].
		digit children withIndexDo: [ :segment :segmentIndex |
			segment background:
				((segments includes: (self class segmentNames at: segmentIndex))
					 ifTrue: [ self onColor ]
					 ifFalse: [ self offColor ]) ] ]
```

`updateDigits` is where the display decides what a number looks like. It is right aligned, and the digits in front of it light nothing at all: a counter reading `007` would be a different number from seven. A number too long for the display keeps its last digits, the way an odometer does, rather than going blank or raising.

The highlight of page 142 is the one thing an LED does that a printed number cannot:

```smalltalk
LaserGameLedElement >> highlighted: aBoolean
	"Light my segments brightly, or dimly. Page 142 highlights the counter while the laser fires."

	highlighted := aBoolean.
	self updateDigits
```

```
LaserGameLedElement >> onColor
	"Answer the color of a lit segment: bright while I am highlighted, dim otherwise."

	^ highlighted
		  ifTrue: [ LaserGameColors counterDigitColor ]
		  ifFalse: [ LaserGameColors counterDigitColor darker ]
```

*Counters The Player Can Read*, at the end of this section, rewrites this method. The version above is the one this chapter leaves in the image.

```smalltalk
LaserGameLedElement >> offColor
	"Answer the color of a segment that is not lit."

	^ LaserGameColors counterDigitOffColor
```

The colours are page 141's, in the class that holds them all:

```smalltalk
LaserGameColors class >> counterDigitColor
	"Answer the color a counter lights its segments in. Page 141's color for the LED."

	^ Color r: 0.674 g: 0.674 b: 0.96
```

```
LaserGameColors class >> counterDigitOffColor
	"Answer the color of a segment that is not lit. The original's LedMorph draws those in a
	darkened version of its own color, which is what this is."

	^ self counterDigitColor muchDarker
```

*Counters The Player Can Read*, at the end of this section, rewrites this method. The version above is the one this chapter leaves in the image.

## The frame around it

Page 141 wraps the display and its caption in a column:

```
wrapPanel: aPanel label: aLabel 
    "wrap a panel in an alignmentMorph and put a label above it"
    | column strM |
    column := AlignmentMorph newColumn 
                wrapCentering: #topLeft;
                cellPositioning: #topLeft;
                hResizing: #spaceFill;
                vResizing: #shrinkWrap;
                borderWidth: 2;
                layoutInset: 5;
                color: Color transparent;
                useRoundedCorners;
                borderStyle: (BorderStyle complexAltInset width: 2).
    column addMorph: aPanel.
    strM := StringMorph contents: aLabel.
    strM color: Color veryVeryLightGray.
    column addMorph: strM.
    ^ column
```

The comment says the label goes above the panel. The code adds the panel first and the label second, so it is drawn below. The port follows the code, since that is what the screenshot on the page shows:

```smalltalk
LaserGameCounterElement >> initialize
	"A counter is a transparent rounded frame around a column: the display, then the caption under
	it, one inset apart."

	super initialize.
	self background: BlTransparentBackground new.
	self geometry: (BlRoundedRectangleGeometry cornerRadius: self class cornerRadius).
	self border: (BlBorder
			 paint: LaserGameColors counterBorderColor
			 width: self class borderWidth).
	self padding: (BlInsets all: self class inset).
	self layout: (BlLinearLayout vertical cellSpacing: self class inset).
	self constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ]
```

> **Note.** The chapter *Counters Of One Width*, at the end of Section 5, rewrites this method: every counter of the panel is given one width, so the display and the caption are centred in it. The block below is the method as this page leaves it.

```
LaserGameCounterElement >> digits: anInteger
	"Show anInteger digits."

	led ifNotNil: [ :each | self removeChild: each ].
	led := LaserGameLedElement digits: anInteger.
	self addChild: led
```

> **Note.** The chapter *Counters Of One Width*, at the end of Section 5, rewrites this method: every counter of the panel is given one width, so the display and the caption are centred in it. The block below is the method as this page leaves it.

```
LaserGameCounterElement >> labelText: aString
	"Caption me aString. The caption is added last, so it is drawn under the display."

	label ifNotNil: [ :each | self removeChild: each ].
	label := BlTextElement new text: (aString asRopedText
			         fontSize: self class labelFontSize;
			         foreground: LaserGameColors counterLabelColor;
			         yourself).
	self addChild: label
```

```smalltalk
LaserGameCounterElement class >> labelled: aString digits: anInteger
	"Answer a counter of anInteger digits captioned aString."

	| counter |
	counter := self new.
	counter digits: anInteger.
	counter labelText: aString.
	^ counter
```

Two details of the wrapper do not survive. `hResizing: #spaceFill` makes the column as wide as the panel it is added to; a counter here takes the width of what it holds, because the panel places it rather than stretching it. And `BorderStyle complexAltInset` is a bevel drawn in two shades of the colour behind it, which a Bloc border cannot be — a border there is one paint. The frame is flat, in the colour of the caption:

```smalltalk
LaserGameColors class >> counterBorderColor
	"Answer the color of the frame around a counter. Page 141 asks for a two pixel
	#complexAltInset border, a bevel drawn in two shades of the color behind it; Bloc draws a
	border in one paint, so the frame is flat and takes the color of the label beside it."

	^ Color veryVeryLightGray
```

```smalltalk
LaserGameColors class >> counterLabelColor
	"Answer the color of the text under a counter. Page 141's color for the label."

	^ Color veryVeryLightGray
```

## Hanging it on the panel

The original adds the counter to the panel with a layout frame that pins it four pixels from the top and the left, and gives it forty pixels of height:

```
addCountersToPanel: panel
    panel
        addMorph: self makeLaserPathCounterMorph
        fullFrame: (LayoutFrame
            fractions: (0 @ 0 corner: 1 @ 0)
            offsets: (4 @ 4 corner: -8 @ 44))
```

The panel of the port is a frame layout, so an alignment and a margin say the same thing. The counters go in a column of their own, because page 143 adds a second one under this one:

```smalltalk
LaserGameControlPanelElement class >> counterGap
	"Answer the gap, in pixels, between the counters and around the column they sit in. Page 141
	insets its counter four pixels from the top and the left of the panel."

	^ 4
```

> **Note.** The chapter *Counters Of One Width*, at the end of Section 5, sends `newCounterLabelled:digits:` here instead, which states the width every counter of the panel is given. The block below is the method as this page leaves it.

```
LaserGameControlPanelElement >> newLaserPathCounter
	"Answer the counter showing how long the laser beam is: three digits, captioned as on page
	141. Three digits hold every path a board of this size can produce."

	^ LaserGameCounterElement labelled: 'Laser Path' digits: 3
```

```
LaserGameControlPanelElement >> newCounterColumn
	"Answer the column of counters: one so far, at the top left corner of the panel, one gap away
	from both edges. The original places it with a layout frame of the same offsets, and the
	counters of page 143 fall in under this one."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class counterGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignTop ].
	column margin: (BlInsets all: self class counterGap).
	column addChild: laserPathCounter.
	^ column
```

```
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	laserPathCounter := self newLaserPathCounter.
	counterColumn := self newCounterColumn.
	buttonRow := self newButtonRow.
	self addChild: counterColumn.
	self addChild: buttonRow.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y.
	self updateCounters
```

The buttons keep the bottom left corner they were given in Section 2.7, so the panel now has a column at each end of it. All three of these methods are shown as this chapter writes them: Section 4.5 hangs a move counter under this one and puts a third button in a row above the other two, so the image today builds more than is listed here.

## Telling the counter what happened

Page 142 has to find the display before it can set it:

```
findLaserPathCounter
    ^self allMorphs detect: [:m | m knownName = 'laserPath'] ifNone: []
```

```
updateCounters
    | led |
    led := self findLaserPathCounter.
    led notNil ifTrue: [
        self laserActive
            ifTrue: [led 
                highlighted: true;
                value: self grid laserBeamPath size]
            ifFalse: [led
                highlighted: false;
                value: 0]
            ]
```

`findLaserPathCounter` walks every morph of the game looking for the one named `'laserPath'`, and `updateCounters` has to guard against not finding it. The panel holds its counter, so both the walk and the guard go:

```smalltalk
LaserGameControlPanelElement >> laserPathCounter
	"Answer the counter showing how long the laser beam is. I hold it, so nothing has to search
	for it: page 142 finds it by walking every morph of the game looking for the name
	'laserPath'."

	^ laserPathCounter
```

```
LaserGameControlPanelElement >> updateCounters
	"Show how long the beam is while the laser fires, and nothing while it does not. This is page
	142's #updateCounters, which has to find the LED among the morphs of the game first; I hold
	it."

	self game laserIsActive
		ifTrue: [
			self laserPathCounter
				highlighted: true;
				value: self game grid laserBeamPath size ]
		ifFalse: [
			self laserPathCounter
				highlighted: false;
				value: 0 ]
```

The rule is page 142's, unchanged: while the laser fires the counter is bright and holds the number of path elements the grid built; while it does not, the counter is dim and holds zero. Section 4.5 adds a second counter, and with it three more lines to the end of this method.

What is left is to send that message at the two moments the beam can change. The original adds a line to each of them:

```
fireLaser
    self laserActive
        ifTrue: [self grid stopLaser]
        ifFalse: [self grid fireLaser].
    self drawGameBoard.
    self changed.
    self updateFireButtonLabel.
    self updateCounters.
```

```
mouseUp: evt forMorph: aSketchMorph cell: aCell
    | renderer pixelPositionWithinBoard cellForRedraw |
    renderer := CellRenderer rendererFor: aCell grid: self grid form: self boardForm.
    pixelPositionWithinBoard := self boardRelativePositionFor: evt.
    cellForRedraw := renderer mouseUpWithinBoardOffset: pixelPositionWithinBoard.
    self redrawCell: cellForRedraw.
    self drawGameBoard.
    self updateCounters.
    self changed
```

The first is straightforward, because the game already had a method for showing what the model says now:

```smalltalk
LaserGameElement >> refresh
	"Show what the model says now: redraw the cells, put the right label on the fire button and
	set the counters. This is the original's #updateGameBoardAndControls, and page 142 adds the
	counters to it."

	self board rebuildCells.
	self controlPanel updateFireButtonLabel.
	self controlPanel updateCounters
```

The second is not, and it is the one design decision of this chapter. In the original both methods sit on the same object: the `LaserGame` morph handles the mouse, holds the grid and owns the counter. In the port the click arrives at a cell element, which tells its board, and the board knows nothing about the panel or the game — that is why a board can be opened on its own with `LaserGameBoardElement openExample`.

Giving the board a reference to the game would end that. So the board announces the move instead, and whoever cares listens:

```smalltalk
LaserGameBoardElement >> moveMade
	"A move was made on one of my cells. Every cell is drawn again, and whoever asked to hear
	about moves is told. Page 142 ends its mouse up handler with #updateCounters; the counters
	belong to the panel and not to me, so I announce the move instead of reaching for them, and a
	board opened on its own still works."

	self redrawCells.
	moveAction ifNotNil: [ :anAction | anAction value ]
```

```smalltalk
LaserGameBoardElement >> whenMoveMadeDo: aBlock
	"Evaluate aBlock after every move made on one of my cells."

	moveAction := aBlock
```

```smalltalk
LaserGameCellElement >> clickAt: aPoint
	"Act on a click at aPoint, in my own coordinates. My board records that I was clicked, my
	renderer decides whether my cell acts and which region handles it, and the board is told that a
	move was made when something changed. The original walked the same chain from the morph to the
	renderer to the click region; it started from a board offset, where this starts from a point
	Bloc already expressed in the cell."

	self board ifNotNil: [ :board | board clickCellElement: self ].
	(self renderer mouseUpAt: aPoint) ifNil: [ ^ self ].
	self board ifNotNil: [ :board | board moveMade ]
```

The block is registered in `LaserGameElement >> rebuild`, quoted above: `board whenMoveMadeDo: [ self controlPanel updateCounters ]`. A board opened on its own registers nothing and plays exactly as before.

## The tests

The display is the part with arithmetic in it, so it gets most of them. What the digits look like is checked by reading the colour of each of the seven rectangles back:

```smalltalk
LaserGameLedElementTestCase >> litSegmentsOf: aLed at: anIndex
	"Answer the names of the segments the digit at anIndex of aLed lights, sorted, so that a test
	can compare them against the list of a page without caring about the order."

	| digit |
	digit := aLed digitElements at: anIndex.
	^ ((1 to: digit children size)
		   select: [ :each |
		   (digit children at: each) background paint color = aLed onColor ]
		   thenCollect: [ :each | LaserGameLedElement segmentNames at: each ])
		  asSortedCollection asArray
```

```smalltalk
LaserGameLedElementTestCase >> testEachDigitLightsTheSegmentsOfItsNumber
	"Eight lights all seven segments, one lights the pair on the right, and zero lights every
	segment but the bar in the middle. Those are the shapes the segment names describe."

	| led |
	led := LaserGameLedElement digits: 1.
	led value: 8.
	self
		assert: (self litSegmentsOf: led at: 1)
		equals: #( #a #b #c #d #e #f #g ).
	led value: 1.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #b #c ).
	led value: 0.
	self assert: (self litSegmentsOf: led at: 1) equals: #( #a #b #c #d #e #f )
```

```smalltalk
LaserGameLedElementTestCase >> testANumberIsShownRightAlignedWithoutLeadingZeros
	"A number shorter than the display sits at its right, and the digits in front of it light
	nothing at all. An LED that shows 007 for seven would read as another number."

	| led |
	led := LaserGameLedElement digits: 3.
	led value: 5.
	self assertEmpty: (self litSegmentsOf: led at: 1).
	self assertEmpty: (self litSegmentsOf: led at: 2).
	self assert: (self litSegmentsOf: led at: 3) equals: #( #a #c #d #f #g )
```

The counter is checked for the order page 141 adds its two children in:

```smalltalk
LaserGameCounterElementTestCase >> testCounterShowsADisplayWithItsCaptionUnderIt
	"A counter is the display and then the caption, in that order, which is the order page 141
	adds them in. Its comment says the label goes above the panel, and the code puts it after."

	| counter |
	counter := LaserGameCounterElement labelled: 'Laser Path' digits: 3.
	self assert: counter children size equals: 2.
	self assert: counter children first identicalTo: counter led.
	self assert: counter children second identicalTo: counter label.
	self assert: counter led class equals: LaserGameLedElement.
	self assert: counter led digitCount equals: 3.
	self assert: counter label text asString equals: 'Laser Path'.
	self assert: counter layout class equals: BlLinearLayout
```

The panel is checked for where the counter sits and for the rule of page 142. The first of these two tests is replaced in Section 4.5, which hangs a second counter in the column:

```
LaserGameControlPanelElementTestCase >> testCounterColumnSitsAtTheTopLeftOneGapIn
	"The counters are aligned to the top left corner of the panel, one counter gap away from both
	edges, which is the layout frame page 141 gives them. The buttons keep the bottom."

	| panel column |
	panel := self newPanel.
	column := panel counterColumn.
	self assert: (panel children includes: column).
	self assert: column children asArray equals: { panel laserPathCounter }.
	self
		assert: column constraints frame horizontal alignment
		equals: BlElementAlignment horizontal start.
	self
		assert: column constraints frame vertical alignment
		equals: BlElementAlignment top.
	self
		assert: column margin
		equals: (BlInsets all: LaserGameControlPanelElement counterGap)
```

```smalltalk
LaserGameControlPanelElementTestCase >> testCounterShowsTheBeamLengthOnlyWhileTheLaserFires
	"Page 142: while the laser fires the counter is bright and holds the number of path elements
	of the grid; while it does not the counter is dim and holds zero. The counter follows the grid
	only when it is updated, which is what the fire button and a move do."

	| panel |
	panel := self newPanel.
	self assert: panel laserPathCounter value equals: 0.
	self deny: panel laserPathCounter highlighted.
	panel game grid fireLaser.
	panel updateCounters.
	self assert: panel laserPathCounter highlighted.
	self
		assert: panel laserPathCounter value
		equals: panel game grid laserBeamPath size.
	self assert: panel laserPathCounter value > 0.
	panel game grid stopLaser.
	panel updateCounters.
	self deny: panel laserPathCounter highlighted.
	self assert: panel laserPathCounter value equals: 0
```

And the game is checked for the ramp, for the new order of its children, and for both of the moments that reach the counter:

```smalltalk
LaserGameElementTestCase >> testWindowIsFilledWithTheColorRamp
	"Page 140 fills the window with a ramp of two colors rather than one flat color, running the
	fraction of the way across and down that the page orients it by."

	| game paint |
	game := LaserGameElement on: GridFactory demoGrid.
	paint := game background paint.
	self assert: paint class equals: BlLinearGradientPaint.
	self assert: paint stops equals: LaserGameColors windowColorRamp.
	self assert: paint start equals: 0 @ 0.
	self assert: paint end equals: LaserGameColors windowColorRampDirection
```

```
LaserGameElementTestCase >> testGameHoldsABoardAndAControlPanel
	"A game is a row of two children: the control panel first, the board beside it. Page 139 moves
	the panel to the left of the board."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game children size equals: 2.
	self assert: game children first equals: game controlPanel.
	self assert: game children second equals: game board.
	self assert: game board class equals: LaserGameBoardElement.
	self assert: game layout class equals: BlLinearLayout
```
> **Note.** *Showing Laser Home Visually*, the sixth chapter of Section 5, wraps the board in a column, so the board is no longer the game's second child.

```smalltalk
LaserGameElementTestCase >> testFiringTheLaserSetsTheCounter
	"The fire button reaches the counter: page 142 adds #updateCounters to the method behind it."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game controlPanel laserPathCounter value equals: 0.
	game toggleLaser.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self assert: game controlPanel laserPathCounter highlighted.
	game toggleLaser.
	self assert: game controlPanel laserPathCounter value equals: 0.
	self deny: game controlPanel laserPathCounter highlighted
```

```smalltalk
LaserGameElementTestCase >> testAMoveOnTheBoardSetsTheCounter
	"A move changes the path, so it changes the counter too: page 142 adds #updateCounters to the
	mouse up handler as well. The board says that a move was made and the game asks its panel to
	catch up; a board opened on its own says the same thing to nobody. Turning the mirror at the
	foot of the first column sends the beam somewhere else, and the path gets shorter."

	| game cellElement before |
	game := LaserGameElement on: GridFactory demoGrid.
	game toggleLaser.
	before := game controlPanel laserPathCounter value.
	self assert: before equals: game grid laserBeamPath size.
	cellElement := game board cellElementAt: 1 @ 5.
	cellElement clickAt: CellClickRegionRotateClockwise regionRectangle center.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self deny: game controlPanel laserPathCounter value equals: before
```

The last one turns the mirror at the foot of the first column, which sends the beam off the board earlier and shortens the path from nine cells to four. A test that only asserted that the counter equals the path would pass without the wire ever being sent, so it asserts that the number changed as well.

## Checking it

Open the game:

```smalltalk
LaserGameElement openExample
```

The panel is on the left now, the ramp runs from a pale blue at the top left corner to a dark violet below and to the right, and the counter sits at the top of the panel with `Laser Path` under it, reading zero.

Click Fire. The digits brighten and read the length of the beam. Click Stop and they go dim and read zero again. Fire once more and turn one of the mirrors: the beam takes another route and the counter follows it, without the fire button being touched.

Page 142 ends by saving a Monticello version, which Section 3.16 answers once for the whole port.


# Add Move Counter And Randomizer

*Pages 143 to 146 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/143.html
     http://squeak.preeminent.org/tut2007/html/144.html
     http://squeak.preeminent.org/tut2007/html/145.html
     http://squeak.preeminent.org/tut2007/html/146.html -->

> We will be adding 2 new features. The first will be a Moves counter. The moves counter will show the total number of cell clicks on the game board. The idea is that the player will want to minimize this count as they solve the puzzle. The second feature will be to add a random game generator.

Two features, and a good deal of tidying between them. The move counter is the counter of Section 4.4 again, hung under the first one and fed from the game instead of from the grid. The randomizer is new work on the model side, and it arrives with a New button, which means a third button on a panel that was laid out for two. Page 144 takes that as its cue to re-lay the buttons in rows and to make Quit ask before it closes, since it now sits next to Fire. Page 146 ends by repairing the repainting, because a board that can be dealt again breaks the assumption that a cell only ever gets fuller.

The port arrives at this section holding most of page 145 already, and owing page 144 a dialog it cannot borrow from the image.

## What the port already has

The code in `src/` is the finished 2007 package, so `GridFactory` came with the whole randomizer, and in the *later* shape: page 147 generalizes these methods to any board size, and it is that version the port inherits. Page 145 writes the target in by hand and counts ten mirrors:

```
randomizeGrid: aGrid
    | emptyList loc howMany |
    emptyList := self emptyRandomLocationsFor: aGrid.
    aGrid at: 5@1 put: TargetCell new.
    howMany := 10.
    howMany timesRepeat: [
        loc := self unusedRandomLocationIn: emptyList forGrid: aGrid.
        aGrid at: loc put: self randomizedMirrorCell]
```

The image answers the same thing for the board this section plays on, by arithmetic instead of by hand:

```smalltalk
GridFactory class >> randomizeGrid: aGrid
	self randomizeGrid: aGrid targetAt: (aGrid numberOfColumns@1)
```

```smalltalk
GridFactory class >> randomizeGrid: aGrid targetAt: pt
	| emptyList loc howMany |
	emptyList := self emptyRandomLocationsFor: aGrid.
	aGrid at: pt put: TargetCell new.
	howMany := ((aGrid numberOfColumns * aGrid numberOfRows) / 2.5) rounded.
	howMany timesRepeat: [
		loc := self unusedRandomLocationIn: emptyList forGrid: aGrid.
		aGrid at: loc put: self randomizedMirrorCell]
```

On a five by five board `numberOfColumns@1` is page 145's `5@1`, and twenty-five cells over two and a half is page 145's ten mirrors. Section 4.6 is the page that writes this, so nothing here is changed; the tests below hold both numbers to the page.

Three more things were already done. Page 144 refactors the two update methods into one `updateGameBoardAndControls`, which the port has had as `LaserGameElement >> refresh` since Section 4.4. Page 146 then rewrites `fireLaser` to call it, which the port's `toggleLaser` has done since Section 2.16. And page 144 wants the buttons made smaller: the port took the finished forty by twenty with the rest of the inherited source.

## One Squeak word in the randomizer

The inherited randomizer had never run in this image. It asks its generator for a number with `#nextInt:`, which is Squeak's name; Pharo's `Random` answers `#nextInteger:`. Both answer one of 1 to the number asked for, so the change is the selector and nothing else. Two methods carry it:

```smalltalk
GridFactory class >> randomBoolean
	"Answer true or false, each as likely as the other. Squeak's Random answers #nextInt:, which
	Pharo calls #nextInteger:; both answer one of 1 to the number asked for."

	| int |
	int := self randomNumberGenerator nextInteger: 2.
	^int > 1
```

```smalltalk
GridFactory class >> unusedRandomLocationIn: list forGrid: aGrid
	"Answer a location of aGrid that list does not hold yet, and mark it used. Squeak's #nextInt:
	is Pharo's #nextInteger:; both answer one of 1 to the number asked for, which is a column or a
	row of the grid."

	| x y pt |
	[
	x := self randomNumberGenerator nextInteger: aGrid numberOfColumns.
	y := self randomNumberGenerator nextInteger: aGrid numberOfRows.
	pt := x@y.
	list at: pt
	] whileTrue: [].
	list at: pt put: true.
	^pt
```

That second method is also worth reading against the page. Page 145 prints the loop like this:

```
unusedRandomLocationIn: list forGrid: aGrid
    | x y pt |
    [
    x := self randomNumberGenerator nextInt: aGrid numberOfColumns.
    y := self randomNumberGenerator nextInt: aGrid numberOfRows.
    pt := x@y.
    list includesKey: pt
    ] whileTrue: [].
    list at: pt put: true.
    ^pt
```

`emptyRandomLocationsFor:` puts every location of the board in that dictionary, each mapped to `false`:

```smalltalk
GridFactory class >> emptyRandomLocationsFor: aGrid
	| dict |
	dict := Dictionary new.
	1 to: aGrid numberOfColumns do: [:x |
		1 to: aGrid numberOfRows do: [:y |
			| pt |
			pt := x@y.
			dict at: pt put: false]].
	dict at: (aGrid numberOfColumns)@1 put: true.  "Target Cell"
	^dict
```

So `list includesKey: pt` is true for every point the loop can draw, and the loop never ends. The dictionary is a set of flags, not a set of keys: the value says whether the location is taken. The published source tests the value — `list at: pt` — and that is what the port has. The page is a typo; the shipped code is the fix.

The generator itself is one seeded `Random` for the whole class, and `reSeed` puts it back on the clock:

```smalltalk
GridFactory class >> randomNumberGenerator
	RandomNumberGenerator isNil ifTrue: [
		RandomNumberGenerator := Random new.
		RandomNumberGenerator seed: Time totalSeconds].
	^RandomNumberGenerator
```

```smalltalk
GridFactory class >> reSeed
	self randomNumberGenerator seed: Time totalSeconds
```

## Counting the moves

Page 143 adds a `moves` instance variable to `LaserGame`, its accessors, a line in `initialize`, and:

```
incrementMoves
    self moves: self moves + 1
```

`LaserGame` is the morph, the model and the controller all at once. In this port the game on the screen is `LaserGameElement`, and the model-side `LaserGame` that will own the count belongs to a later section, so the count lives on the element, where the original keeps it:

```
LaserGameElement >> initialize
	"A game is a row of two: the control panel, and the board beside it. The margin around both is
	padding, and the ramp behind them shows through it. No move has been made yet."

	super initialize.
	self background: self class windowBackgroundPaint.
	self layout: BlLinearLayout horizontal.
	self padding: (BlInsets all: self class gameMargin).
	moves := 0
```
> **Note.** *Showing Laser Home Visually*, the sixth chapter of Section 5, takes the bottom margin out of the padding, leaving that band to the mark of the laser's home.

```smalltalk
LaserGameElement >> moves
	"Answer how many moves the player has made. Page 143 counts every click on the board, and the
	player is meant to solve the puzzle in as few as possible."

	^ moves
```

```smalltalk
LaserGameElement >> incrementMoves
	"Count one more move. Page 143's #incrementMoves."

	self moves: self moves + 1
```

Page 144 counts the move at the end of the mouse up handler:

```
mouseUp: evt forMorph: aSketchMorph cell: aCell
    | renderer pixelPositionWithinBoard cellForRedraw |
    renderer := CellRenderer rendererFor: aCell grid: self grid form: self boardForm.
    pixelPositionWithinBoard := self boardRelativePositionFor: evt.
    cellForRedraw := renderer mouseUpWithinBoardOffset: pixelPositionWithinBoard.
    self redrawCell: cellForRedraw.
    self incrementMoves.
    self updateGameBoardAndControls
```

The port has no such handler: a cell element handles its own click, and tells the board when the click changed something. Section 4.4 gave the board a block to evaluate then, and the game registered one that set the counters. It now registers one that counts the move first:

```
LaserGameElement >> rebuild
	"Replace what I hold with a control panel for me and a board showing my grid beside it, and
	take the size the two of them and my margins need. Page 139 moves the panel to the left of the
	board, which here is the order the two are added in. The board tells me when a move changed the
	grid, so the counters follow a click as well as the fire button."

	self removeChildren.
	confirmation := nil.
	board := LaserGameBoardElement on: self grid.
	controlPanel := self newControlPanel.
	self addChild: controlPanel.
	self addChild: board.
	board whenMoveMadeDo: [ self moveMade ].
	self extent: (self class extentForGrid: self grid)
```
> **Note.** *Showing Laser Home Visually*, the sixth chapter of Section 5, puts the board in a column with that mark and gives the panel the bottom margin.

```smalltalk
LaserGameElement >> moveMade
	"A move was made on my board. Page 144 counts it and then updates the whole game; the board has
	already drawn its cells by the time it tells me, so only the counters are left to set."

	self incrementMoves.
	self controlPanel updateCounters
```

This is where the port and the page part company on what a move is. The original counts every mouse up on the board, including a click on a blank cell, which does nothing at all. The board here is only told when something changed, so that click is not counted. The count is the number the player is asked to keep down, and a click that moved nothing is not a move; a test below holds the port to that reading.

## A second counter

The display itself is the one built in Section 4.4. Page 143 builds a second `LedMorph` the same way it built the first, names it `'moves'`, and wraps it in the same panel:

```
makeMovesCounterMorph
    | count |
    count := LedMorph new
            digits: 3;
            extent: 3 * 10 @ 15;
            setBalloonText: ''.
    count color: (Color r: 0.674 g: 0.674 b: 0.96).
    count name: 'moves'.
    ^ self wrapPanel: count label: 'Moves'
```

`LaserGameCounterElement` already holds the digits, the colours and the caption, so the whole method is its one line:

> **Note.** The chapter *Counters Of One Width*, at the end of Section 5, sends `newCounterLabelled:digits:` here instead, which states the width every counter of the panel is given. The block below is the method as this page leaves it.

```
LaserGameControlPanelElement >> newMovesCounter
	"Answer the counter showing how many moves the player has made: three digits, captioned as on
	page 143."

	^ LaserGameCounterElement labelled: 'Moves' digits: 3
```

Page 143 then places it with a layout frame forty-four pixels below the first one, which is the height of a counter plus the gap around it:

```
addCountersToPanel: panel
    panel
        addMorph: self makeLaserPathCounterMorph
        fullFrame: (LayoutFrame
            fractions: (0 @ 0 corner: 1 @ 0)
            offsets: (4 @ 4 corner: -8 @ 44));

        addMorph: self makeMovesCounterMorph
        fullFrame: (LayoutFrame
            fractions: (0 @ 0 corner: 1 @ 0)
            offsets: (4 @ 48 corner: -8 @ 92))
```

The column that Section 4.4 put at the top left corner of the panel was built for this: the second counter is one more child of it, and the gap between them is the same gap that holds the column off the edges.

```
LaserGameControlPanelElement >> newCounterColumn
	"Answer the column of counters: the beam length, and the move count under it, at the top left
	corner of the panel, one gap away from both edges. Page 143 places the second counter with a
	layout frame forty-four pixels below the first, which is the height of one counter and this
	gap."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class counterGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignTop ].
	column margin: (BlInsets all: self class counterGap).
	column addChild: laserPathCounter.
	column addChild: movesCounter.
	^ column
```
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, stacks four counters in this column.

Page 143 needs a second finder to go with the second display, and a longer `updateCounters` to use it:

```
findMovesCounter
    ^self allMorphs detect: [:m | m knownName = 'moves'] ifNone: []
```

```
updateCounters
    | led |
    led := self findLaserPathCounter.
    led notNil ifTrue: [
        self laserActive
            ifTrue: [led 
                highlighted: true;
                value: self grid laserBeamPath size]
            ifFalse: [led
                highlighted: false;
                value: 0]
            ].
    led := self findMovesCounter.
    led notNil ifTrue: [
        led
            highlighted: false;
            value: self moves asString]
```

The panel holds both displays, so there is no finder and no guard against not finding one:

```
LaserGameControlPanelElement >> updateCounters
	"Show how long the beam is while the laser fires, and nothing while it does not, and show how
	many moves have been made. This is page 143's #updateCounters, which has to find each display
	among the morphs of the game first; I hold both. The move count is never bright: only the beam
	says whether the laser is on."

	self game laserIsActive
		ifTrue: [
			self laserPathCounter
				highlighted: true;
				value: self game grid laserBeamPath size ]
		ifFalse: [
			self laserPathCounter
				highlighted: false;
				value: 0 ].
	self movesCounter
		highlighted: false;
		value: self game moves
```
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, sets the two mirror counters here as well.

The move counter is set with `highlighted: false` every time. Only the beam counter brightens, and only while the laser is on.

## A third button

Page 144 wants a New button, and the panel was laid out for two buttons in one row. Its answer is to compute the layout frame of a button from a row and a column, counting rows from the bottom:

```
buttonLayoutFrameForRow: fromBottom column: fromLeft
    | buttonHeight buttonWidth xOffset xOrigin yOrigin xCorner yCorner yOffset |
    buttonHeight := 20.
    buttonWidth := 40.
    xOffset := (self panelWidth - (2 * buttonWidth)) // 3.
    yOffset := 10.

    xOrigin := xOffset * fromLeft.
    xOrigin := xOrigin + ((fromLeft - 1) * buttonWidth).

    yOrigin := yOffset * fromBottom.
    yOrigin := yOrigin + (fromBottom * buttonHeight).
    yOrigin := yOrigin negated.

    xCorner := xOrigin + buttonWidth.
    yCorner := yOrigin + buttonHeight.

    ^LayoutFrame
        fractions: (0 @ 1 corner: 0 @ 1)
        offsets: (xOrigin@yOrigin corner: xCorner@yCorner)
```

and to place each button through it:

```
addButtonsToPanel: panel
    | layout |
    layout := self buttonLayoutFrameForRow: 1 column: 1.
    panel addMorph: self makeQuitGameButton fullFrame: layout.

    layout := self buttonLayoutFrameForRow: 1 column: 2.
    panel addMorph: self makeFireLaserButton fullFrame: layout.

    layout := self buttonLayoutFrameForRow: 2 column: 1.
    panel addMorph: self makeNewGameButton fullFrame: layout.

    ^panel
```

A row of rows says the same thing without the arithmetic. One helper builds a row of buttons:

```smalltalk
LaserGameControlPanelElement >> newRowOfButtons: aCollection
	"Answer a row holding the buttons of aCollection, one gap apart, no wider than they need."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	aCollection do: [ :each | row addChild: each ].
	^ row
```

and the two rows are that helper twice, in the order the page numbers them: row one at the bottom, row two above it.

```smalltalk
LaserGameControlPanelElement >> newButtonRow
	"Answer the bottom row of buttons: Quit first, then Fire. Page 144 calls them row one, columns
	one and two."

	^ self newRowOfButtons: {
			  quitButton.
			  fireButton }
```

```
LaserGameControlPanelElement >> newNewGameRow
	"Answer the row above it, holding the New button on the left. Page 144 calls it row two,
	column one."

	^ self newRowOfButtons: { newGameButton }
```
> **Note.** *Undo*, the third chapter of Section 5, adds the Undo button to this row.

```
LaserGameControlPanelElement >> newButtonColumn
	"Answer the column of button rows: the bottom left corner of the panel, one gap from both
	edges, the rows one gap apart, the last row against the bottom. Page 144 places each button
	itself with #buttonLayoutFrameForRow:column:, which counts rows from the bottom and columns
	from the left; a column of rows says the same thing, and the rows of Section 5 fall in above
	these two. The cell spacing of a linear layout is added around the cells as well as between
	them, so it is the whole of the gap: a margin here would double the gap on the left and push
	the last button of the bottom row against the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class buttonGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
```
> **Note.** *Reset (and a bug fix)*, the fifth chapter of Section 5, adds the Reset row here and names it in the comment.

The column carries what the row carried before: the bottom left corner of the panel, one gap from both edges. The rows of Section 5, Undo and Reset, fall in above these two without touching the arithmetic, because there is none.

The column takes no margin, and that is worth a word, because the row it replaced had one. A linear layout spaces its cells from its own edges as well as from each other, so the cell spacing alone already holds the buttons one gap in on every side. A margin on top of it doubles the gap on the left, and a row of two buttons is then eleven tens wide in a panel of eleven tens: the last button of the bottom row ends exactly on the edge of the panel, touching the board. Two buttons and the three gaps of a row fill the panel exactly, which is what the panel width of the original is for, and a test says so:

```smalltalk
LaserGameControlPanelElementTestCase >> testARowOfTwoButtonsFitsInsideThePanel
	"A row of buttons is as wide as its buttons and the gaps around and between them. Two buttons
	fill the panel exactly, so the last button of a row stops one gap short of the board beside
	the panel; a third button in the same row would not fit."

	| widthOfTwo |
	widthOfTwo := (2 * LaserGameControlPanelElement buttonWidth)
	              + (3 * LaserGameControlPanelElement buttonGap).
	self assert: widthOfTwo equals: LaserGameElement panelWidth.
	self
		assert: widthOfTwo + LaserGameControlPanelElement buttonWidth
			+ LaserGameControlPanelElement buttonGap
			> LaserGameElement panelWidth
```

The panel holds the column and reads the rows back from it, so that the two names the tests and the later pages use still work:

```smalltalk
LaserGameControlPanelElement >> buttonRow
	"Answer the bottom row of buttons. Page 144 counts rows from the bottom, so it is the last row
	of the column."

	^ self buttonColumn children last
```

```
LaserGameControlPanelElement >> newGameRow
	"Answer the row above the buttons, holding the New button. It is the first row of the column,
	since the column reads from the top and page 144 counts from the bottom."

	^ self buttonColumn children first
```
> **Note.** *Reset (and a bug fix)*, the fifth chapter of Section 5, makes this the middle row of three, so it is read as the second child and no longer as the first.

The button itself is the usual one line, and page 144 leaves its action as a stub until page 146 fills it in:

```smalltalk
LaserGameControlPanelElement >> newNewGameButton
	"Answer the button that throws the board away and deals a new one: page 144's
	#makeNewGameButton."

	^ self newButton: 'New' action: [ self game newGame ]
```

```
LaserGameControlPanelElement >> rebuild
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	counterColumn := self newCounterColumn.
	buttonColumn := self newButtonColumn.
	self addChild: counterColumn.
	self addChild: buttonColumn.
	self extent: LaserGameElement panelWidth
		@ (LaserGameBoardElement extentForGrid: self game grid) y.
	self updateCounters
```
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, builds the two mirror counters here, stops holding the two columns, and takes the height of what it holds when the board is shorter than that.

## Asking before quitting

Quit is now small and sits next to Fire, so page 144 makes it ask:

```
quitGame
    (self confirm: 'Are you sure you want to quit?') ifTrue: [self delete]
```

`#confirm:` opens a Morphic dialog and does not return until the player has answered, which is why the answer can be read as the value of the expression. Neither half of that is available here. Nothing in this port draws in Morphic, and a Bloc element cannot stop and wait inside an event handler: the space that would have to draw the dialog is the space it is waiting in.

So the question is asked rather than waited for. A new element covers the game with a shade and a box, and hands its answer to a block:

```smalltalk
LaserGameConfirmElement >> initialize
	"A question is a shade over the game with a box in the middle of it. The shade is ignored by
	the layout of the game, so the game stays the row of two children it was."

	super initialize.
	self background: LaserGameColors confirmationShadeColor.
	self layout: BlFrameLayout new.
	self constraintsDo: [ :aConstraints | aConstraints ignoreByLayout ].
	yesButton := self newButton: 'Yes' answering: true.
	noButton := self newButton: 'No' answering: false.
	box := self newBox.
	self addChild: box
```

```smalltalk
LaserGameConfirmElement >> newBox
	"Answer the box in the middle of the shade: the question, and the two answers under it."

	| element |
	element := BlElement new.
	element background: LaserGameColors confirmationBackgroundColor.
	element geometry:
		(BlRoundedRectangleGeometry cornerRadius: self class cornerRadius).
	element padding: (BlInsets all: self class inset).
	element layout: (BlLinearLayout vertical cellSpacing: self class inset).
	element constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignCenter.
		aConstraints frame vertical alignCenter ].
	messageElement := BlTextElement new.
	element addChild: messageElement.
	element addChild: self newAnswerRow.
	^ element
```

```smalltalk
LaserGameConfirmElement >> newAnswerRow
	"Answer the row holding the two answers, Yes first."

	| row |
	row := BlElement new.
	row background: BlTransparentBackground new.
	row layout: (BlLinearLayout horizontal cellSpacing: self class buttonGap).
	row constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent ].
	row addChild: yesButton.
	row addChild: noButton.
	^ row
```

```smalltalk
LaserGameConfirmElement >> newButton: aLabel answering: aBoolean
	"Answer a button labelled aLabel that answers aBoolean when it is clicked. The buttons of the
	control panel are this size, so the answers look like the rest of the game."

	| button |
	button := ToButton labelText: aLabel.
	button extent: LaserGameControlPanelElement buttonWidth
		@ LaserGameControlPanelElement buttonHeight.
	button clickAction: [ self answer: aBoolean ].
	^ button
```

The two answers are the same Toplo buttons as the panel's, at the same size, so the question looks like the rest of the game. Pressing one calls:

```smalltalk
LaserGameConfirmElement >> answer: aBoolean
	"The player answered aBoolean. Whoever asked the question is told, and it is that object which
	takes me off the game: I do not know what my answer means."

	answerAction ifNotNil: [ :anAction | anAction value: aBoolean ]
```

```smalltalk
LaserGameConfirmElement >> whenAnsweredDo: aBlock
	"Evaluate aBlock with the answer when the player presses one of my buttons."

	answerAction := aBlock
```

The element does not know what its answer means, and it does not take itself off the game: whoever asked does both. The one Bloc detail that matters is in `initialize`. A game lays its children out in a row, and the question is a child; `ignoreByLayout` keeps it out of that row, so it can cover the whole game without pushing the board sideways.

The colours come from the one place the game keeps colours:

```smalltalk
LaserGameColors class >> confirmationShadeColor
	"Answer the color laid over the whole game while it asks a question, so that the board behind
	it is visibly out of reach."

	^ Color black alpha: 0.6
```

```smalltalk
LaserGameColors class >> confirmationBackgroundColor
	"Answer the color of the box a question is asked in. The original asks with #confirm:, a
	Morphic dialog painted by the image; a Bloc game asks inside itself, so the box takes the flat
	window color the ramp of page 140 left unused."

	^ self gameWindowColor
```

`gameWindowColor` is the flat window colour the original paints under its ramp. Section 4.4 left it unused when the ramp took the window; the box behind the question is a use for it.

On the game side, `quit` asks and `close` does what `quit` used to do:

```smalltalk
LaserGameElement >> quit
	"Ask before closing. Page 144 makes the buttons smaller and puts Quit next to Fire, which is
	easy to hit by accident, so #quitGame asks first. The original asks with #confirm:, which opens
	a Morphic dialog and waits for the answer; a Bloc element does not wait, so the question is laid
	over the game and answers back."

	self ask: 'Are you sure you want to quit?' onConfirm: [ self close ]
```

```smalltalk
LaserGameElement >> ask: aString onConfirm: aBlock
	"Lay the question aString over me, and evaluate aBlock if the player answers yes. Either answer
	takes the question off first. One question is asked at a time, so a second click on Quit while
	the question stands does nothing."

	| question |
	self confirmation ifNotNil: [ ^ self ].
	question := LaserGameConfirmElement asking: aString.
	question extent: (self class extentForGrid: self grid).
	question whenAnsweredDo: [ :answer |
		self dismissQuestion.
		answer ifTrue: [ aBlock value ] ].
	confirmation := question.
	self addChild: question
```

```smalltalk
LaserGameElement >> dismissQuestion
	"Take the question off me. Answering does this, whichever answer it was."

	confirmation ifNil: [ ^ self ].
	self removeChild: confirmation.
	confirmation := nil
```

```smalltalk
LaserGameElement >> close
	"Close the game. The original sends #delete to its morph."

	self space ifNotNil: [ :aSpace | aSpace close ]
```

One question at a time: a second click on Quit while the question stands does nothing, which is the nearest thing to the modal dialog the original gets from the image.

## Starting a new game

Page 146 fills in the stub:

```
newGame
    self grid initializeCells.
    self grid stopLaser.
    self moves: 0.
    self activeCellLocation: nil.
    self initializeDirty.
    GridFactory randomizeGrid: self grid.
    self updateGameBoardAndControls
```

Four of those seven lines are the port's:

```smalltalk
LaserGameElement >> newGame
	"Start again on a fresh random grid: page 146's #newGame. Its two other lines have no
	counterpart. The dirty dictionary it initializes is the repaint bookkeeping of a shared board
	form, and every cell here is an element that draws itself; the active cell location it clears
	is the mouse press the original remembers by hand, and Bloc delivers the click instead. The
	stack of moves the grid keeps is left alone: it is emptied where Undo and Reset are added."

	self grid initializeCells.
	self grid stopLaser.
	self moves: 0.
	GridFactory randomizeGrid: self grid.
	self refresh
```

The two that are missing are bookkeeping the port does not keep. `activeCellLocation: nil` forgets the cell the mouse was pressed in, which the original tracks by hand to tell a click from a drag; Bloc delivers the click itself. `initializeDirty` empties the dictionary of cells that still need repainting, which exists because every cell paints into one shared form; here each cell is an element that draws itself.

The order of the first two lines matters, and it is the page's order. `randomizeGrid:` writes a target and its mirrors onto the grid and clears nothing, so the cells have to be emptied first or the new board would be the old board with more mirrors on it. A test below checks exactly that, by counting the mirrors after a new game on the demo board: ten, not twenty.

The stack of moves the grid keeps for the undo of Section 5 is left alone here, as it is on the page. Undo has no button yet, so nothing can reach into the board that was thrown away; the section that adds the button is the section that has to empty the stack.

## What page 146 repaints, and why nothing here does

The last third of page 146 is about repainting:

> With the possibility of a grid being randomized with the new button, we have to ensure that old cells are properly repainting now. Before we relied on the fact that the cells were all initially blank.

Its answer is a new `fillBackground` on `CellRenderer`, called from `redrawCell` and from the `renderContents` of all three renderers:

```
fillBackground
    | offset backgroundRect |
    offset := self offsetWithinGridForm.
    backgroundRect := offset extent: CellRenderer cellExtent - 2.
    self targetForm fill: backgroundRect fillColor: LaserGameColors gameBoardBackgroundColor.
```

This is the cost of one shared board form. A cell that was a mirror and is now blank has to paint over what it drew, and until this page no cell ever had to, because cells only ever gained contents.

The port pays nothing here. A cell is an element with children, `LaserGameBoardElement >> rebuildCells` builds them again from the grid, and `LaserGameCellElement >> redraw` throws its children away and asks the grid which cell stands at its location now. That method was written in Section 3.11, for the same problem in its earlier form: a pushed mirror leaves a blank behind. So `refresh`, which `newGame` ends with, is the whole of page 146's repainting; a test walks the board after a new game and checks that every element draws the cell that is there.

## The tests

Twenty-two, in four test cases. The randomizer gets its own, and it deals from a known seed so that a board is the same board every run, and puts the generator back on the clock afterwards:

```smalltalk
GridFactoryTestCase >> setUp
	"Deal from a known seed, so a randomized board is the same board every run."

	super setUp.
	GridFactory randomNumberGenerator seed: 42
```

```smalltalk
GridFactoryTestCase >> tearDown
	"Put the generator back on the clock, so a game deals a different board every time."

	GridFactory reSeed.
	super tearDown
```

What a dealt board holds is page 145 and page 147 read as numbers:

```smalltalk
GridFactoryTestCase >> testARandomizedGridPutsTheTargetInTheTopRightCorner
	"Page 147 reads the corner from the grid, where page 145 writes 5@1 for the board it has. Both
	are the same cell on a five by five board."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: (grid at: 5 @ 1) class equals: TargetCell.
	self
		assert: ((self cellsOf: grid) count: [ :cell | cell isKindOf: TargetCell ])
		equals: 1
```

```smalltalk
GridFactoryTestCase >> testTheMirrorsStandOneToACellAndAwayFromTheTarget
	"Page 145 deals its mirrors onto locations it has not used yet, and it starts with the target
	marked used, so every mirror it deals is still on the board afterwards and none of them is on
	the target. A five by five board takes ten mirrors, which is the number page 145 writes down
	before page 147 derives it from the size of the board."

	| grid |
	grid := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 10
```

```smalltalk
GridFactoryTestCase >> testTheNumberOfMirrorsFollowsTheSizeOfTheBoard
	"Page 147 asks for one mirror per two and a half cells, which is ten on the board of page 145
	and thirty-two on the standard board."

	| grid |
	grid := Grid newOfSize: 8 @ 10.
	GridFactory randomizeGrid: grid.
	self assert: grid numberOfMirrors equals: 32
```

Ten mirrors on the board is the proof that the loop of `unusedRandomLocationIn:forGrid:` does what it says: every mirror it deals goes to a location it has not used, so none of them is written over, and none of them lands on the target.

That the generator is seeded, and therefore repeatable, is worth a test of its own, since `reSeed` exists on page 145 only to break the repetition:

```smalltalk
GridFactoryTestCase >> testTheSameSeedDealsTheSameBoard
	"The generator is seeded, so the same seed deals the same board. That is what #reSeed is for:
	page 145 adds it to make the next game differ from this one."

	| first second |
	GridFactory randomNumberGenerator seed: 1234.
	first := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: first.
	GridFactory randomNumberGenerator seed: 1234.
	second := Grid newOfSize: 5 @ 5.
	GridFactory randomizeGrid: second.
	1 to: 5 do: [ :x |
		1 to: 5 do: [ :y |
			| here there |
			here := first at: x @ y.
			there := second at: x @ y.
			self assert: here class equals: there class.
			here class = MirrorCell ifTrue: [
				self assert: here isLeft equals: there isLeft ] ] ]
```

The move counter and the new game are checked on the game:

```smalltalk
LaserGameElementTestCase >> testEveryMoveOnTheBoardCountsOne
	"Page 144 counts the click in the mouse up handler of the board. Here the board announces the
	move and the game counts it, so the count is shown without anything searching for the display."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	(game board cellElementAt: 1 @ 5) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 1.
	self assert: game controlPanel movesCounter value equals: 1
```

```smalltalk
LaserGameElementTestCase >> testAClickThatChangesNothingIsNoMove
	"A click on a blank cell does nothing, so the board is never told and nothing is counted. The
	original counts every mouse up on the board, whether or not the board changed; the count is
	what the player is asked to keep down, so only a move that happened counts here."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: (game grid at: 2 @ 2) class equals: BlankCell.
	(game board cellElementAt: 2 @ 2) clickAt:
		CellClickRegionRotateClockwise regionRectangle center.
	self assert: game moves equals: 0
```

```smalltalk
LaserGameElementTestCase >> testANewGameDealsAFreshBoardAndForgetsTheMoves
	"Page 146: a new game clears the cells, stops the laser, sets the count to zero and randomizes
	the grid. The demo grid holds ten mirrors and so does a randomized five by five board, so the
	proof that the old cells went first is the count: the randomizer writes onto the board it is
	given and clears nothing, and ten mirrors is what it deals."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game grid fireLaser.
	game incrementMoves.
	game newGame.
	self assert: game moves equals: 0.
	self deny: game grid laserIsActive.
	self assert: game grid numberOfMirrors equals: 10.
	self assert: (game grid at: 5 @ 1) class equals: TargetCell.
	self assert: game controlPanel movesCounter value equals: 0.
	self assert: game controlPanel laserPathCounter value equals: 0
```

```smalltalk
LaserGameElementTestCase >> testANewGameIsShownOnTheBoard
	"Every cell element is built again from the cell that stands at its location now, so a cell
	that was a mirror and is now blank draws itself blank. Page 146 needs three new rendering
	methods for that, because its cells paint onto one shared form and a cell used to be able to
	assume it was blank underneath."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game newGame.
	1 to: game grid numberOfRows do: [ :row |
		1 to: game grid numberOfColumns do: [ :column |
			self
				assert: (game board cellElementAt: column @ row) renderer cell
				equals: (game grid at: column @ row) ] ]
```

And the question, which is tested by answering it the way a button does. A Toplo button needs a live space to turn a click into its action, so the tests send `answer:` instead of pressing:

```smalltalk
LaserGameConfirmElementTestCase >> testTheAnswerGoesToWhoeverAsked
	"The original reads the answer as the value of #confirm:, which blocks until the player
	answers. A Bloc element cannot block, so the answer is handed to a block instead."

	| question answers |
	answers := OrderedCollection new.
	question := LaserGameConfirmElement asking: 'Really?'.
	question whenAnsweredDo: [ :each | answers add: each ].
	question answer: true.
	question answer: false.
	self assert: answers asArray equals: #( true false )
```

```smalltalk
LaserGameElementTestCase >> testQuittingAsksBeforeItCloses
	"Page 144 makes the buttons smaller and puts Quit beside Fire, so #quitGame asks first. The
	question covers the game and is not one of the two children the game lays out in a row. A
	second click on Quit while the question stands asks nothing more."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game quit.
	self assert: game confirmation class equals: LaserGameConfirmElement.
	self assert: game children size equals: 3.
	self assert: game children last equals: game confirmation.
	game quit.
	self assert: game children size equals: 3
```

```
LaserGameElementTestCase >> testAnsweringNoLeavesTheGameAsItWas
	"No takes the question away and does nothing else."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game quit.
	game confirmation answer: false.
	self assert: game confirmation isNil.
	self assert: game children asArray equals: {
			game controlPanel.
			game board }
```
> **Note.** *Showing Laser Home Visually*, the sixth chapter of Section 5, reads the second child as the board's column.

The panel tests follow the two new children: the second counter under the first, and the New button in the row above the other two.

```
LaserGameControlPanelElementTestCase >> testCounterColumnHoldsTheBeamCounterAboveTheMoveCounter
	"Page 143 adds the move counter under the beam counter, one counter lower in the same column."

	| panel |
	panel := self newPanel.
	self assert: panel counterColumn children asArray equals: {
			panel laserPathCounter.
			panel movesCounter }
```
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, replaces this test with `testCounterColumnHoldsTheFourCountersInOrder`, which asserts all four counters.

```
LaserGameControlPanelElementTestCase >> testNewGameButtonHasTheRowAboveTheOthers
	"Page 144 puts New in the second row from the bottom, first column: here the column of rows
	holds the New row first and the Quit and Fire row last, which is lowest."

	| panel |
	panel := self newPanel.
	self assert: panel buttonColumn children asArray equals: {
			panel newGameRow.
			panel buttonRow }.
	self assert: panel newGameRow children asArray equals: { panel newGameButton }.
	self assert: panel newGameButton labelText asString equals: 'New'
```
> **Note.** *Undo*, the third chapter of Section 5, drops the assertion that this row holds New alone, since Undo joins it there.

```smalltalk
LaserGameControlPanelElementTestCase >> testMovesCounterShowsTheMoveCountAndIsNeverBright
	"Page 143 sets the move counter with #highlighted: false every time: only the beam says whether
	the laser is on."

	| panel |
	panel := self newPanel.
	self assert: panel movesCounter value equals: 0.
	panel game incrementMoves.
	panel game grid fireLaser.
	panel updateCounters.
	self assert: panel movesCounter value equals: 1.
	self deny: panel movesCounter highlighted.
	self assert: panel laserPathCounter highlighted
```

## Checking it

Open the game:

```smalltalk
LaserGameElement openExample
```

Two counters at the top of the panel now, `Laser Path` over `Moves`, both reading zero, and three buttons at the bottom: New on its own row above Quit and Fire.

Turn a mirror. The move counter reads one, and it climbs with every turn and every push. Click a blank cell and it stands still. Fire the laser and the beam counter brightens beside it, as it did in Section 4.4.

Click New. The board is dealt again: ten mirrors in new places, the target back in its corner, the laser off, the move counter back to zero. Deal a few times and look for a board with no mirror on the beam's first column — the randomizer can deal one, and it is a puzzle with nothing to solve.

Click Quit. The game darkens and asks whether you are sure. No takes the question away and leaves the game as it was; Yes closes the window.

Page 146 ends by saving a Monticello version, which Section 3.16 answers once for the whole port.

# A Bigger Game Board

*Pages 147 and 148 of the 2007 tutorial.*

<!-- http://squeak.preeminent.org/tut2007/html/147.html
     http://squeak.preeminent.org/tut2007/html/148.html -->

> Our next enhancement will deal with making the game board larger. We're going to be enhancing the GridFactory class mostly.

Two pages, seven methods on the page, and the port owes five of them nothing: the package it inherits is the finished 2007 game, so every generalization page 147 makes to `GridFactory` was already there when Section 4.5 read the randomizer. What is left is the other half of the page — the half that lets the game be handed a board instead of building one — and the question of whether anything in the port quietly assumed a five by five grid.

## The randomizer the port already reads from the grid

Page 147 starts by making a board of any size:

```
randomizedGridOfExtent: ext
    | grid |
    grid := Grid newOfSize: ext.
    self randomizeGrid: grid targetAt: ((ext x)@1).
    ^grid
```

which is in the image already, character for character:

```smalltalk
GridFactory class >> randomizedGridOfExtent: ext
	| grid |
	grid := Grid newOfSize: ext.
	self randomizeGrid: grid targetAt: ((ext x)@1).
	^grid
```

Then it moves the target out of the middle of the randomizer. The dictionary of free locations marks the corner used before a mirror is dealt:

```smalltalk
GridFactory class >> emptyRandomLocationsFor: aGrid
	| dict |
	dict := Dictionary new.
	1 to: aGrid numberOfColumns do: [:x |
		1 to: aGrid numberOfRows do: [:y |
			| pt |
			pt := x@y.
			dict at: pt put: false]].
	dict at: (aGrid numberOfColumns)@1 put: true.  "Target Cell"
	^dict
```

the deal takes the corner as an argument:

```smalltalk
GridFactory class >> randomizeGrid: aGrid targetAt: pt
	| emptyList loc howMany |
	emptyList := self emptyRandomLocationsFor: aGrid.
	aGrid at: pt put: TargetCell new.
	howMany := ((aGrid numberOfColumns * aGrid numberOfRows) / 2.5) rounded.
	howMany timesRepeat: [
		loc := self unusedRandomLocationIn: emptyList forGrid: aGrid.
		aGrid at: loc put: self randomizedMirrorCell]
```

and the old one-argument method becomes one line that reads the corner from the board:

```smalltalk
GridFactory class >> randomizeGrid: aGrid
	self randomizeGrid: aGrid targetAt: (aGrid numberOfColumns@1)
```

Section 4.5 explained the two numbers in the middle of that: `numberOfColumns@1` is the top right corner of any board, and one mirror per two and a half cells is ten on a five by five board and thirty-two on eight by ten. So the whole of the randomizer side of page 147 is read, not written. What this section adds are tests that say so, since until now nothing asked the factory for a board that was not five by five:

```smalltalk
GridFactoryTestCase >> testAGridOfAnyExtentIsDealtReadyToPlay
	"Page 147 builds a board of any size and deals it in one message: the grid is made, the target
	goes in the top right corner of that grid, and the mirrors follow the size of the board.
	Eight by ten is the board of page 148."

	| grid |
	grid := GridFactory randomizedGridOfExtent: 8 @ 10.
	self assert: grid numberOfColumns equals: 8.
	self assert: grid numberOfRows equals: 10.
	self assert: (grid at: 8 @ 1) class equals: TargetCell.
	self assert: grid numberOfMirrors equals: 32.
	self
		assert: ((self cellsOf: grid) count: [ :cell | cell isKindOf: TargetCell ])
		equals: 1
```

```smalltalk
GridFactoryTestCase >> testTheTargetCornerIsMarkedUsedOnABoardOfAnySize
	"Page 147 marks the top right corner of the board used before a single mirror is dealt, so the
	target keeps its cell whatever the size of the board. The dictionary holds one flag per
	location, false for the locations still free."

	| grid flags |
	grid := Grid newOfSize: 8 @ 10.
	flags := GridFactory emptyRandomLocationsFor: grid.
	self assert: flags size equals: 80.
	self assert: (flags at: 8 @ 1).
	self
		assert: (flags keys count: [ :each | flags at: each ])
		equals: 1
```

That second one is the page's one-line change on its own. Every location of the board goes in the dictionary with `false`, and the corner is then set to `true`, so `unusedRandomLocationIn:forGrid:` draws around it and the target keeps its cell. On the five by five board of Section 4.5 the same line was invisible: the target went in at `5@1` either way.

## Handing the game a board

The other half of page 147 is about the game rather than the grid. The 2007 `LaserGame` builds its own grid in `#initialize`, so the only board it can ever have is the demo board. The page splits that method in two — a worker that takes a grid, and an `#initialize` that calls it with the old one:

```
initializeForGrid: aGrid
    super initialize.
    self moves: 0.
    self grid: aGrid.
    self boardForm: (Form extent: (self class boardExtentFor: self grid) depth: Display depth).
    self boardForm fillColor: LaserGameColors gameBoardBackgroundColor.
    self setExtent.
    self setupMorphs.
    self drawGameBoard.
```

```
initialize
    self initializeForGrid: GridFactory demoGrid
```

and adds a class-side maker for the randomized case:

```
randomizedGridOfExtent: aPoint
    | model grid |
    model := self basicNew.
    grid := GridFactory randomizedGridOfExtent: aPoint.
    model initializeForGrid: grid.
    ^model
```

The port has had that split since Section 2.11, because a Bloc element cannot do it any other way: `#initialize` runs when the element is made, before anything can hand it a grid, so the grid arrives afterwards through a setter, and the setter rebuilds:

```smalltalk
LaserGameElement >> grid: aGrid
	"Play on aGrid. Setting the grid rebuilds what I hold, so the same game element can show
	another grid."

	grid := aGrid.
	self rebuild
```

```smalltalk
LaserGameElement class >> on: aGrid
	"Answer a game element playing on aGrid."

	| element |
	element := self new.
	element grid: aGrid.
	^ element
```

`on:` is `initializeForGrid:`, and `grid:` is the line of it that matters. So the new work is one line long, twice: the page's class-side maker, and the opener page 148 puts in its workspace.

```smalltalk
LaserGameElement class >> onRandomOfExtent: aPoint
	"Answer a game on a freshly dealt board of aPoint columns by aPoint rows. This is page 147's
	LaserGame class >> randomizedGridOfExtent:, which builds the model with #basicNew and hands it
	the grid through #initializeForGrid:. A game here takes its grid from outside already, so #on:
	is that method, and this one only deals the board."

	^ self on: (GridFactory randomizedGridOfExtent: aPoint)
```

```smalltalk
LaserGameElement class >> openRandomOfExtent: aPoint
	"Open a game on a freshly dealt board of aPoint columns by aPoint rows and answer the space.
	Page 148 changes its workspace to this, so that the game opens on a board of the size asked
	for instead of the demo board.

	LaserGameElement openRandomOfExtent: 8@10"

	^ self openOn: (GridFactory randomizedGridOfExtent: aPoint)
```

```smalltalk
LaserGameElement class >> openStandardExample
	"Open the standard board of page 148: eight columns by ten rows, dealt. The demo board of
	#openExample is the five by five one the earlier sections play on.

	LaserGameElement openStandardExample"

	<sampleInstance>
	^ self openOn: GridFactory defaultGrid
```

`GridFactory defaultGrid` is the board of page 148, and like the rest of the randomizer it came with the inherited source:

```smalltalk
GridFactory class >> defaultGrid
	^self randomizedGridOfExtent: 8@10
```

`openExample` keeps the demo board. The earlier chapters are written around it, and a hand-made board a reader can check by eye is worth keeping next to one that is different every time.

## Does anything still think the board is five by five?

This is the question the page does not have to ask, because in 2007 the answer is written into the code: the board is one `Form` whose extent is computed from the grid, and every renderer paints into it at an offset. In the port the answer is in the layouts, and it is worth checking rather than assuming.

Three sizes are derived, and all three read the grid. The board element is a `BlGridLayout` of one element per cell, and it asks for as many columns as the grid has; the panel takes the width of a panel and the height of the board; and the window is the two of them and the margins:

```
LaserGameElement class >> extentForGrid: aGrid
	"Answer the extent a game showing aGrid occupies: the board, the control panel beside it, and
	one margin on each side. This is the original's calculatedExtent, with the board element
	standing in for the board form."

	^ (LaserGameBoardElement extentForGrid: aGrid) + (self panelWidth @ 0)
	  + (2 * self gameMargin)
```
> **Note.** *Adding More Game Stats*, the second chapter of Section 5, takes the height of the taller of the board and the panel, since four counters can stand taller than a board of few rows.

The test is the arithmetic of a board that is neither square nor five wide, checked against the constraints the elements were given:

```smalltalk
LaserGameElementTestCase >> testAGameTakesTheSizeOfWhateverBoardItIsGiven
	"Page 147 hands the game a grid instead of building one, so the size of the board is the size
	of the grid. The game is one cell per location, the panel keeps its width and takes the height
	of the board beside it, and the window is the two of them and the margins. The sizes are read
	from the layout constraints, since nothing is laid out until a space shows it."

	| game wanted |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	wanted := LaserGameElement extentForGrid: game grid.
	self assert: game board children size equals: 80.
	self
		assert: wanted
		equals: (8 * CellRenderer cellExtent x + LaserGameElement panelWidth
		         + (2 * LaserGameElement gameMargin))
			        @ (10 * CellRenderer cellExtent y
				         + (2 * LaserGameElement gameMargin)).
	self assert: game constraints horizontal resizer size equals: wanted x.
	self assert: game constraints vertical resizer size equals: wanted y.
	self
		assert: game controlPanel constraints horizontal resizer size
		equals: LaserGameElement panelWidth.
	self
		assert: game controlPanel constraints vertical resizer size
		equals: 10 * CellRenderer cellExtent y
```

Eight columns of fifty, plus a panel of a hundred and ten, plus two margins of ten, is five hundred and thirty; ten rows of fifty plus the margins is five hundred and twenty. The sizes are read from `constraints horizontal resizer size` rather than from `extent`, which stays `0.0@0.0` until a space lays the element out.

New deals the board the game is already playing on, so it keeps that size too:

```smalltalk
LaserGameElement >> newGame
	"Start again on a fresh random grid: page 146's #newGame. Its two other lines have no
	counterpart. The dirty dictionary it initializes is the repaint bookkeeping of a shared board
	form, and every cell here is an element that draws itself; the active cell location it clears
	is the mouse press the original remembers by hand, and Bloc delivers the click instead. The
	stack of moves the grid keeps is left alone: it is emptied where Undo and Reset are added."

	self grid initializeCells.
	self grid stopLaser.
	self moves: 0.
	GridFactory randomizeGrid: self grid.
	self refresh
```

```smalltalk
LaserGameElementTestCase >> testANewGameKeepsTheSizeOfTheBoard
	"New deals the grid the game already plays on, so a bigger board stays bigger: the cells are
	emptied and dealt again, one target in the corner and the mirrors of that size."

	| game |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	game newGame.
	self assert: game grid numberOfColumns equals: 8.
	self assert: game grid numberOfRows equals: 10.
	self assert: game grid numberOfMirrors equals: 32.
	self assert: (game grid at: 8 @ 1) class equals: TargetCell.
	self assert: game board children size equals: 80
```

One number in the port is not derived from the grid: the counters of Section 4.4 are three digits wide, which was chosen for a five by five board. A bigger board makes a longer beam, so it is worth knowing how much longer. Eighty cells with thirty-two mirrors on them give paths in the tens, nowhere near the hundreds, and the counter shows whatever the grid answers:

```smalltalk
LaserGameElementTestCase >> testTheCountersStillHoldWhatABiggerBoardProduces
	"A bigger board makes a longer beam, and the counter of page 141 has three digits. Eighty
	cells cannot make a path of a thousand, so the beam counter still shows the whole number the
	grid answers, whatever board the game was dealt."

	| game |
	game := LaserGameElement onRandomOfExtent: 8 @ 10.
	game toggleLaser.
	self assert: game grid laserBeamPath size < 1000.
	self
		assert: game controlPanel laserPathCounter value
		equals: game grid laserBeamPath size.
	self
		assert: game controlPanel laserPathCounter led digitCount
		equals: 3
```

A board large enough to overflow three digits would have to be some hundreds of cells across. If Section 5 or a player ever asks for one, `LaserGameCounterElement labelled:digits:` already takes the digit count as an argument, and the panel is the only caller.

## Checking it

Page 148 changes its workspace to the new size and opens the game:

```smalltalk
LaserGameElement openStandardExample
```

A window of 530 by 520, a board of eight by ten with thirty-two mirrors, the target in the top right corner, the counters at the top of the panel and the three buttons at the bottom of it, one gap from the edges as before. The panel is the same width it was on the small board; only its height follows.

Everything the earlier sections added still works on it: a click turns or pushes a mirror and counts a move, Fire lights the beam and the beam counter, New deals another eight by ten board, and Quit asks first.

Or ask for a size of your own:

```smalltalk
LaserGameElement openRandomOfExtent: 12@12
```

Page 148 ends by saving a Monticello version, which Section 3.16 answers once for the whole port.

# Drawing The Laser Beam

The game plays without the beam being drawn. The counter says how many cells the beam runs through, the target lights up when the beam reaches it, and the player works the rest out. Pages 149 to 155 draw the beam itself, and they are the longest detour in the tutorial: seven pages, of which the last half page is the only one the port keeps.

## Seven pages in a paint tool

Page 149 opens a `RectangleMorph`, makes it large, sets its colour to white from an inspector, and drags the paint tool out of the objects tool onto it. The author then paints the beam by hand: a wide band of light yellow with the fattest brush, no effort made to keep the edges smooth, two nearly white lines outside it that overlap the yellow so there are no gaps, and on page 150 some dabbing with smaller brushes and brighter colours until it looks right. The sketch is kept, dropped on the white panel, and made thinner, with the deep yellow part centred as well as the hand can centre it.

The drawing now exists only on the screen. Page 150 captures it from an inspector on the panel:

```
(Form fromDisplay: (self bounds insetBy: 6))
	scaledToSize: CellRenderer cellExtent;
	displayAt: 0@0
```

and page 151 writes the captured form out as source, which is the trick the whole chapter turns on:

```
(Form fromDisplay: (self bounds insetBy: 6))
	storeOn: Transcript.
Transcript show: ''; cr
```

A `Form` can print itself as the expression that rebuilds it. What lands in the Transcript is one array of 368 by 196 pixels, thirty-two bits each, and the page says plainly that it is a pretty big chunk of code and that Squeak takes a few seconds to compile it. Pasted into a class method it becomes the artwork:

```
LaserGameForms class >> drawLaserBeamForm
	^(Form
		extent: 368@196
		depth: 32
		fromArray: #( 4294967295 4294967295 4294967295 ... )
		offset: 0@0)
```

The cache of page 083 gains a line for it, and an accessor answers it:

```
form := self drawLaserBeamForm.
CachedForms at: #laserBeam put: form.
```

```
LaserGameForms class >> laserBeam
	CachedForms isNil ifTrue: [self initializeCachedForms].
	^CachedForms at: #laserBeam
```

## Two masks out of one drawing

One painted form cannot be recoloured, and page 152 wants the two parts of the beam to be separate things. The drawing has four colours: white around it, a very faint yellow furthest from the middle, the soft yellow splatter, and the bright core. The faint one is given up. The other two are pulled out as masks in a workspace, a screenful at a time: draw the beam onto two copies, sample the pale colour at `10@60` and paint it white on both, make a black and white form of one copy and reverse it for the splatter mask, sample the splatter colour at `10@90` and paint it black on the other copy, and make a black and white form of that for the core mask. Each mask is then drawn with `Form oldPaint` and a fill colour, which paints the colour wherever the mask is black.

Page 153 does two more things with the workspace. It shows that the colours are now free — the core is drawn in a colour that was never painted, `Color r: 0.909 g: 1.0 b: 0.27` — and it fixes the symmetry. The beam was drawn freehand, so laid end to end it does not match itself; the fix is to make a form twice as wide and mirror the drawing into the second half, so that whichever way two cells meet, the two halves that meet are the same half. Page 154 saves the workspace as `extractLaserBeamMaskForms`, a class method that exists so the masks can be made again, and then writes both masks to the Transcript the same way the beam was written, complete with their method headers. Page 155 adds the two masks to the cache, adds an accessor for each, and ends the chapter with the two colours the drawing settled on.

## What the port keeps

Those two colours are the whole of it. They came into the port with the captured package and are already in `LaserGameColors`:

```smalltalk
LaserGameColors class >> laserBeamSplatterColor
	^Color r: 1.0 g: 1.0 b: 0.71
```

```smalltalk
LaserGameColors class >> laserBeamCenterColor
	^Color r: 0.909 g: 1.0 b: 0.27
```

Everything else on the seven pages is the cost of putting a picture into a program that can only hold pixels. A pale band with a brighter band along its middle is two rectangles and two colours. Written that way it needs no paint tool, no capture from the screen, no `storeOn:`, no mask, no reversal, no cache, and no mirroring: two rectangles are symmetric to begin with, and two of them laid end to end meet exactly. It also scales, which the form does not — page 152 is careful about which pixel it samples because the bitmap is one size and the cells are another.

The shapes go where the arrows and the cross hair of Section 3.4 went, into `LaserGameShapes`, and they are built the way the cross hair is built: bars centred in the cell.

## The tests

A beam that crosses a cell from side to side is a pale band the whole way across with a thinner, brighter bar on it, both centred:

```
LaserGameShapesTestCase >> testABeamIsAPaleBandWithABrightCentreOnIt
	"Page 152 takes two masks out of the painted beam, a wide splatter and a narrow centre, and
	page 153 paints them in two colours. Here the beam is an element holding two bars: the pale
	one first, the bright one on top of it, both running the whole length and both centred across
	it."

	| extent element splatter centre |
	extent := 50 @ 50.
	element := LaserGameShapes horizontalLaserBeamElementOfExtent: extent.
	self assert: (self requestedExtentOf: element) equals: extent.
	self assert: element children size equals: 2.
	splatter := element children first.
	centre := element children second.
	self
		assert: splatter background paint color
		equals: LaserGameColors laserBeamSplatterColor.
	self
		assert: centre background paint color
		equals: LaserGameColors laserBeamCenterColor.
	self assert: (self requestedExtentOf: splatter) x equals: extent x.
	self assert: (self requestedExtentOf: centre) x equals: extent x.
	self
		assert: (self requestedExtentOf: centre) y
		< (self requestedExtentOf: splatter) y.
	element children do: [ :each |
		self
			assert: each constraints position + ((self requestedExtentOf: each) / 2)
			equals: extent / 2 ]
```
> **Note.** *Laser On Mirror Cell*, at the end of this section, replaces the three beam builders with one that takes the lit sides of the cell, so this test asks `laserBeamElementOfExtent:fromSides:` for `#( #west #east )`.

`requestedExtentOf:` is the helper the other shape tests use, since an element has no extent until it is laid out:

```smalltalk
LaserGameShapesTestCase >> requestedExtentOf: anElement
	"Answer the extent anElement was built with, read from its resizers. An element measures
	itself only in a layout pass, so its extent is zero until it is laid out."

	^ anElement constraints horizontal resizer size
	  @ anElement constraints vertical resizer size
```

A beam that crosses a cell from top to bottom is the same beam with its sides exchanged. This is what page 153 works at with its mirrored form, and what the renderer of the original gets by rotating a strip of the mask by ninety degrees:

```
LaserGameShapesTestCase >> testAVerticalBeamIsTheHorizontalOneTurned
	"A beam runs across a cell or down it. The original has one painted form and turns the drawing
	by asking the mask for a vertical strip instead of a horizontal one; here the two bars are the
	same two bars with their sides exchanged, so the two beams meet at the same thickness where a
	path turns."

	| extent horizontal vertical |
	extent := 50 @ 50.
	horizontal := LaserGameShapes horizontalLaserBeamElementOfExtent: extent.
	vertical := LaserGameShapes verticalLaserBeamElementOfExtent: extent.
	self assert: (self requestedExtentOf: vertical) equals: extent.
	self assert: vertical children size equals: 2.
	vertical children asArray
		with: horizontal children asArray
		do: [ :down :across |
			self
				assert: (self requestedExtentOf: down)
				equals: (self requestedExtentOf: across) transposed.
			self
				assert: down background paint color
				equals: across background paint color.
			self
				assert: down constraints position + ((self requestedExtentOf: down) / 2)
				equals: extent / 2 ]
```
> **Note.** *Laser On Mirror Cell*, at the end of this section, replaces the three beam builders with one that takes the lit sides of the cell, so this test asks `laserBeamElementOfExtent:fromSides:` for `#( #west #east )`.

And the beam follows the size of the cell, which the original gets by scaling the bitmap and the port gets by computing the two thicknesses:

```
LaserGameShapesTestCase >> testTheBeamGetsThickerWithTheCell
	"The original paints one beam form of one cell size and scales the bitmap when the cell grows,
	so the beam keeps its proportions. Here the two thicknesses are computed from the extent, which
	comes to the same thing: twice the cell, twice the beam."

	| small large |
	small := LaserGameShapes horizontalLaserBeamElementOfExtent: 30 @ 30.
	large := LaserGameShapes horizontalLaserBeamElementOfExtent: 60 @ 60.
	self
		assert: (self requestedExtentOf: large children first) y
		equals: (self requestedExtentOf: small children first) y * 2.
	self
		assert: (self requestedExtentOf: large children second) y
		equals: (self requestedExtentOf: small children second) y * 2.
	self
		assert: (self requestedExtentOf: small children first) y
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: 30 @ 30).
	self
		assert: (self requestedExtentOf: small children second) y
		equals: (LaserGameShapes laserBeamCenterThicknessFor: 30 @ 30).
	self
		assert: (LaserGameShapes laserBeamCenterThicknessFor: 2 @ 2)
		equals: 1
```
> **Note.** *Laser On Mirror Cell*, at the end of this section, replaces the three beam builders with one that takes the lit sides of the cell, so this test asks `laserBeamElementOfExtent:fromSides:` for `#( #west #east )`.

## The shapes

The two thicknesses are fractions of the cell. A third of it for the pale band, a sixth for the core, and never less than one pixel, so that a hint-sized beam is still a beam:

```smalltalk
LaserGameShapes class >> laserBeamSplatterThicknessFor: anExtent
	"Answer how thick the pale part of the beam is in a cell of anExtent. The original paints one
	beam of one cell size and scales the bitmap; the port keeps the proportion instead of the
	pixels, and a beam is never thinner than one pixel."

	^ ((anExtent x min: anExtent y) // 3) max: 1
```

```smalltalk
LaserGameShapes class >> laserBeamCenterThicknessFor: anExtent
	"Answer how thick the bright core of the beam is in a cell of anExtent: half the pale band it
	sits on. Page 153 pulls the same core out of the painted beam as a mask of its own."

	^ ((anExtent x min: anExtent y) // 6) max: 1
```

One bar, centred, in a colour the caller names. It is `crossHairBarOfExtent:within:` of Section 3.4 with the colour added:

```
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent within: anExtent color: aColor
	"Answer one bar of a beam, of aBarExtent and painted in aColor, centred in a cell of anExtent."

	^ BlElement new
		  extent: aBarExtent;
		  position: (anExtent - aBarExtent) / 2;
		  background: aColor;
		  yourself
```
> **Note.** *Laser On Target Cell* has one bar of a beam start at a corner of the cell instead of its middle, so this method hands the work to `laserBeamBarOfExtent:at:color:` and keeps only the centring.

And the two beams:

```
LaserGameShapes class >> horizontalLaserBeamElementOfExtent: anExtent
	"Answer an element of anExtent drawing the beam where it crosses a cell from side to side: a
	pale band the whole way across, and a brighter, thinner bar along its middle. Pages 149 to 152
	paint the same picture by hand in a paint tool, store the form in a class method and reload it
	from a workspace; page 153 pulls the bright part out of it again as a mask so that the two can
	be painted in different colours. Two rectangles and two colours say all of that, and they join
	without a seam where one cell meets the next, which the painted form does not."

	| splatter centre |
	splatter := self
		            laserBeamBarOfExtent:
		            anExtent x @ (self laserBeamSplatterThicknessFor: anExtent)
		            within: anExtent
		            color: LaserGameColors laserBeamSplatterColor.
	centre := self
		          laserBeamBarOfExtent:
		          anExtent x @ (self laserBeamCenterThicknessFor: anExtent)
		          within: anExtent
		          color: LaserGameColors laserBeamCenterColor.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: splatter;
		  addChild: centre;
		  yourself
```
> **Note.** *Laser On Mirror Cell*, at the end of this section, replaces this method with `laserBeamElementOfExtent:fromSides:`, which draws a bar the whole way across when both sides of an axis are lit.

```
LaserGameShapes class >> verticalLaserBeamElementOfExtent: anExtent
	"Answer an element of anExtent drawing the beam where it crosses a cell from top to bottom: the
	horizontal beam with its sides exchanged. The original has one painted beam and asks its mask
	for a vertical strip of it."

	| splatter centre |
	splatter := self
		            laserBeamBarOfExtent:
		            (self laserBeamSplatterThicknessFor: anExtent) @ anExtent y
		            within: anExtent
		            color: LaserGameColors laserBeamSplatterColor.
	centre := self
		          laserBeamBarOfExtent:
		          (self laserBeamCenterThicknessFor: anExtent) @ anExtent y
		          within: anExtent
		          color: LaserGameColors laserBeamCenterColor.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: splatter;
		  addChild: centre;
		  yourself
```
> **Note.** *Laser On Mirror Cell* replaces this method too: one builder draws both axes, so the turned copy goes.

## The artwork leaves LaserGameForms

With the beam drawn from geometry, the painted beam and its two masks have no reader left. Seven class methods go out of `LaserGameForms` — `drawLaserBeamForm`, `drawCenterLaserBeamMask`, `drawSplatterLaserBeamMask`, the three accessors `laserBeam`, `centerBeamMask` and `splatterBeamMask`, and the `extractLaserBeamMaskForms` of page 154 — and with them the three arrays that pages 151 and 154 pasted in, which are most of the weight of the file. The cache loses its last three lines:

```
LaserGameForms class >> initializeCachedForms
	"LaserGameForms initializeCachedForms"
	| form |
	CachedForms := Dictionary new.
	form := self arrowFormFromPointsArray: self northArrowPoints.
	CachedForms at: #north put: form.
	form := self arrowFormFromPointsArray: self eastArrowPoints.
	CachedForms at: #east put: form.
	form := self arrowFormFromPointsArray: self southArrowPoints.
	CachedForms at: #south put: form.
	form := self arrowFormFromPointsArray: self westArrowPoints.
	CachedForms at: #west put: form.
	form := self drawCounterClockwiseArrow.
	CachedForms at: #counterClockwise put: form.
	form := self drawClockwiseArrow.
	CachedForms at: #clockwise put: form.
```
> **Note.** *Better Hint Arrows Alignment*, the eighth chapter of Section 5, deletes `LaserGameForms` entirely, this method with it.

What is left in the class is the arrow drawing of pages 081 to 083 and 099, which the rotate regions still ask for. The old `CellRenderer` methods that painted the masks onto the board form — `renderLaserHorizontalMask:color:`, `renderLaserVerticalMask:color:` and the six methods around them — are already unreachable, since nothing sends `render` on the Bloc path; they go with the rest of that drawing protocol when the cells learn to draw the beam themselves.

## Checking it

Nothing on the board draws a beam yet — that is the next chapter's work. The shapes can be looked at on their own:

```smalltalk
| strip cell |
cell := 60.
strip := BlElement new
	extent: (cell * 4) @ (cell * 2);
	background: (Color r: 0.1 g: 0.1 b: 0.1);
	yourself.
0 to: 3 do: [ :i |
	strip addChild: ((LaserGameShapes horizontalLaserBeamElementOfExtent: cell @ cell)
		position: (i * cell) @ 0;
		yourself) ].
0 to: 3 do: [ :i |
	strip addChild: ((LaserGameShapes verticalLaserBeamElementOfExtent: cell @ cell)
		position: (i * cell) @ cell;
		yourself) ].
strip openInSpace
```

Four beams laid end to end make one unbroken band across the top, with no seam where one cell ends and the next begins, which is the thing page 153 mirrors its form to get. Under it, four vertical beams show the same two bars turned.


# Laser On Blank Cell

The shapes of the last chapter are drawn by nobody. Pages 156 to 158 put the beam on the board, and they start with the easiest cell: a blank one, which the beam goes straight through. What the beam does at a mirror and at the target is the work of the two chapters after this one.

## What the original writes

Three pages of it, and all three are about the masks. Page 156 gives `BlankCellRenderer` a method that takes a mask and a colour and paints one line of the beam:

```
BlankCellRenderer >> renderLaserHorizontalMask: aMaskForm color: aColor
	| cellPosn scaledBeam scale trimmedBeam offset |
	cellPosn := self offsetWithinGridForm.
	scale := CellRenderer cellExtent * 6.
	scaledBeam := aMaskForm scaledToSize: scale.
	trimmedBeam := Form extent: (CellRenderer cellExtent x)@(scaledBeam height) depth: scaledBeam depth.
	scaledBeam
		displayOn: trimmedBeam
		at: 0@0
		clippingBox: trimmedBeam boundingBox
		rule: Form paint
		fillColor: nil.
	offset := 0@(4 + (CellRenderer cellExtent y - trimmedBeam height) // 2).
	trimmedBeam
		displayOn: self targetForm
		at: (cellPosn + offset)
		clippingBox: self targetForm boundingBox
		rule: Form oldPaint
		fillColor: aColor
```

The mask of page 154 is twice as wide as one cell and much larger than it, so it is scaled by six, cut down to the width of a cell, shifted by four pixels plus half of what is left over, and painted onto the shared board form at the offset of the cell. Two methods name the two masks and their colours, and a third draws one after the other, splatter first so the core lies on top of it:

```
BlankCellRenderer >> renderLaserHorizontalSplatter
	self
		renderLaserHorizontalMask: LaserGameForms splatterBeamMask
		color: LaserGameColors laserBeamSplatterColor
```

```
BlankCellRenderer >> renderLaserHorizontal
	self renderLaserHorizontalSplatter.
	self renderLaserHorizontalCenter.
```

Page 157 writes the four vertical methods, which differ by one line — `rotatedBeam := trimmedBeam rotateBy: 90` — and by another offset, this one three pixels and half a cell negated, since the rotation turns the strip about its own corner. Then the method that chooses between them:

```
BlankCellRenderer >> renderLaser
	| rotate |
	self cell isOff ifTrue: [^self].
	rotate := self cell activeSegments at: #south.
	rotate
		ifTrue: [self renderLaserVertical]
		ifFalse: [self renderLaserHorizontal].
```

Page 158 fires the laser and shows the board with the beam on it, and sends the reader off to save version 8.

## One question and one child

Eight methods of the original are the scaling, the trimming, the rotating and the two offsets. The port has none of that to do: the beam is an element of the size of the cell, it is a child of the cell element, and Bloc places it. What is left is the question page 157 asks — is the south segment lit — and the answer, one child:

```
BlankCellRenderer >> renderBeamOn: anElement
	"A beam goes straight through a blank cell, so it is one line: down the cell when the south
	segment is lit, across it otherwise. Page 157 asks the same one question. The original had to
	build the drawing out of two masks, scale them to the cell, trim them, rotate them for the
	vertical case and paint each one onto the board form with its own colour; the shapes of Section
	4.7 hold all of that, so what is left here is the question and one child."

	anElement addChild: ((self cell isSegmentOnFor: #south)
			 ifTrue: [
				 LaserGameShapes verticalLaserBeamElementOfExtent:
					 self class cellExtent ]
			 ifFalse: [
				 LaserGameShapes horizontalLaserBeamElementOfExtent:
					 self class cellExtent ])
```
> **Note.** *Laser On Mirror Cell* draws every kind of cell from one `renderBeamOn:` on `CellRenderer`, so this method goes.

The two pixel fudges of the original, the four and the three, have no counterpart either. They exist because the mask is a hand-painted band whose middle is not quite the middle of the form it was captured from; the bars of the last chapter are centred by construction.

## Where the cell asks for it

The original asks in `render`: border, contents, and then the beam if the laser is firing. Every renderer answers `renderLaser`, and every implementation of it begins by asking whether its cell is lit. The port keeps both questions, in one place, and leaves the drawing to a hook:

```
CellRenderer >> renderLaserOn: anElement
	"Draw the beam where it crosses my cell, as children of anElement. Nothing is drawn while the
	laser is off or while no light reaches my cell: the original asks the first question in
	#render, before it sends #renderLaser at all, and the second at the head of every #renderLaser.
	What a lit cell draws is the business of my subclasses, so #renderBeamOn: is theirs."

	self grid laserIsActive ifFalse: [ ^ self ].
	self cell isOff ifTrue: [ ^ self ].
	self renderBeamOn: anElement
```
> **Note.** *Laser On Mirror Cell* moves the drawing itself onto `CellRenderer`, so the last line of this comment changes to say that one `renderBeamOn:` serves every kind of cell.

```
CellRenderer >> renderBeamOn: anElement
	"Draw the beam my lit cell shows, as children of anElement. Empty here: a cell whose kind has
	not learned to draw the beam yet shows none, which is how Section 4 adds the three kinds one
	at a time."
```
> **Note.** *Laser On Mirror Cell* makes this the method that draws the beam of every cell, so it is no longer empty.

`renderBeamOn:` is empty here, so a mirror and the target draw no beam yet, which is exactly what the original does at this point in the tutorial: `CellRenderer >> renderLaser` is empty, and only `BlankCellRenderer` overrides it so far.

Two places build a cell, and both gain a line. A cell built for the first time:

```
CellRenderer >> newElement
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children:
	the contents of the cell first, then the beam over them, as the original's #render does."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderContentsOn: element.
	self renderLaserOn: element.
	^ element
```
> **Note.** *Laser On Target Cell* swaps the last two lines: the beam is drawn first and the contents over it.

and a cell drawn again after something changed, which is the one that matters here — firing the laser changes no cell, it lights a row of them, and every cell of the board is redrawn:

```
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because page 126 of the original is the
	tale of a view that went on believing in the cell that had moved away. A blank cell offers no
	push, so the arrow of the mirror that left goes with it, and the cross hair with the arrow.
	The beam is drawn here too, since firing the laser changes no cell but lights many of them.
	The original repainted a rectangle of the board form and called it redrawCell."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	crossHairElement := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderContentsOn: self.
	self renderer renderLaserOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```
> **Note.** *Laser On Target Cell* swaps the last two render lines: the beam is drawn first and the contents over it, and the comment says so.

The beam is added after the contents and before the hint, so a hint arrow and its cross hair stay on top of the beam. A blank cell draws no contents, so the two orders look alike here; *Laser On Target Cell* has a reason to prefer the other one and swaps them. Nothing else had to be told about the laser: `toggleLaser` already refreshed the game, and `moveMade` already redrew every cell, because a move can send the beam somewhere else.

## The tests

The demo grid runs the beam along the bottom row and then up the fourth column, so it has a blank cell of each kind. A cell crossed from side to side:

```smalltalk
CellRendererTestCase >> testTheBeamCrossesABlankCellFromSideToSide
	"Page 156 draws the beam on the blank cells, which is the easiest case: the beam goes straight
	through, so it is one line. The demo grid sends the beam along the bottom row from west to
	east, and the blank cell at 2@5 is one the beam crosses that way."

	| grid element beam |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: CellRenderer cellExtent x
			@ (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent).
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
```

A cell crossed from top to bottom, which is page 157's question answered the other way:

```smalltalk
CellRendererTestCase >> testTheBeamCrossesABlankCellFromTopToBottom
	"Page 157 asks one question to choose between the two drawings: is the south segment lit. The
	demo grid turns the beam north at 4@5, so the blank cell at 4@4 is crossed from top to bottom."

	| grid element beam |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 4) grid: grid)
		           newElement.
	self assert: element children size equals: 1.
	beam := element children first.
	self
		assert: (self requestedExtentOf: beam)
		equals: CellRenderer cellExtent.
	self
		assert: (self requestedExtentOf: beam children first)
		equals: (LaserGameShapes laserBeamSplatterThicknessFor: CellRenderer cellExtent)
			@ CellRenderer cellExtent y.
	self
		assert: beam children second background paint color
		equals: LaserGameColors laserBeamCenterColor
```

And the two cases that draw nothing at all — the laser off, and a cell the beam never reaches:

```smalltalk
CellRendererTestCase >> testABlankCellDrawsNoBeamUnlessTheLaserReachesIt
	"A cell draws a beam only while the laser is firing and only where the beam runs. The original
	asks the first question in #render and the second at the head of #renderLaser."

	| grid |
	grid := GridFactory demoGrid.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children.
	grid fireLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 1 @ 1) grid: grid) newElement
				children.
	grid stopLaser.
	self
		assertEmpty:
			(CellRenderer rendererFor: (grid at: 2 @ 5) grid: grid) newElement
				children
```

## What goes

`BlankCellRenderer` loses the whole of its `Form` drawing: `renderLaser`, which page 157 wrote, and `maskOffHorizontalOn:` and `maskOffVerticalOn:`, the two do-nothing masks it answered so that the shared painting methods could ask every cell what to keep. The class is now two methods, one of which is the old `renderContents`, waiting for the rest of the drawing protocol to go. The shared `renderLaserHorizontalMask:color:` family on `CellRenderer` stays for the moment, because the mirror and the target still send it, and nothing sends them.

## Checking it

The board example fires the laser, and now shows it:

```smalltalk
LaserGameBoardElement class >> openExampleWithLaserFired
	"Open the demo grid with the laser already fired, which lights the target and draws the beam
	over the blank cells it crosses. The mirrors and the target still show no beam of their own:
	that is the work of the two sections after page 158.

	LaserGameBoardElement openExampleWithLaserFired"

	<sampleInstance>
	| grid |
	grid := GridFactory demoGrid.
	grid fireLaser.
	^ self openOn: grid
```

```smalltalk
LaserGameBoardElement openExampleWithLaserFired
```

The beam comes in at the bottom left corner, runs east across two blank cells, and goes up the fourth column through three more. The mirrors it turns at, and the target it ends in, are still blank of beam — the screenshot of page 158 shows the same gaps, since the original draws them in the pages that follow.


# Laser On Target Cell

Pages 159 to 165 draw the beam on the cell it ends in. A target swallows the light, so the beam crosses only half of the cell, and the target itself has to stay visible through it: two differences from the blank cell of the last chapter, and both of them are about the half of the picture that is not drawn.

## What the original writes

Page 159 refactors the ring drawing so that it can be asked for a position and a form:

```
drawCircleOutlineOn: aForm color: aColor offset: offset
    | delta fillForm circle |
    delta := self class cellExtent - 1.
    circle := Circle new.
    fillForm := Form extent: 2@2 depth: 8.
    fillForm fillColor: aColor.
    circle form: fillForm.
    circle radius: self radius.
    circle center: (offset + (delta // 2)).
    circle displayOn: aForm
```

Pages 160 and 161 then give `TargetCellRenderer` the eight beam methods the blank cell already had, with one line added to each of the two that paint: the trimmed strip is masked a second time before it is painted, and the second mask keeps only the half the light arrives from.

```
maskOffHorizontalOn: aMask
    | newMask halfExtent halfRect offset |
    halfExtent := (aMask width // 2)@(aMask height).
    newMask := Form extent: aMask extent depth: aMask depth.
    newMask fillColor: Color white.
    (self cell activeSegments at: #west)
        ifTrue: [offset := 0]
        ifFalse: [offset := halfExtent x].
    halfRect := (aMask boundingBox origin + (offset@0)) extent: halfExtent.
    aMask
        displayOn: newMask
        at: offset@0
        clippingBox: halfRect
        rule: Form paint
        fillColor: Color black.
    ^newMask
```

`maskOffVerticalOn:` is the same method turned a quarter: it asks about `#south` instead of `#west`, and cuts the mask across instead of along. Page 162 pulls it together:

```
renderLaser
    | horizontal |
    self cell isOff ifTrue: [^self].
    horizontal := (self cell activeSegments at: #east) or: [self cell activeSegments at: #west].
    horizontal
        ifTrue: [self renderLaserHorizontal]
        ifFalse: [self renderLaserVertical].
    self drawTargetOutlines.
    self renderContentsOn.
```

The last two lines are the second difference: the beam is painted onto the shared board form over the target, so the target is painted again on top of it.

## Half a beam

A mask that blacks out half a band is, in a world of elements, a bar half as long. The shapes of *Drawing The Laser Beam* gain a pair of methods that take the side the light comes from:

```
LaserGameShapes class >> horizontalLaserBeamElementOfExtent: anExtent enteringFrom: aSymbol
	"Answer an element of anExtent drawing the beam where it enters a cell from the side aSymbol
	names, west or east, and stops in the middle of it, which is what a cell that swallows the
	light shows. Pages 160 and 162 of the original draw the whole beam and then black out the half
	the light never reaches, with a mask built for the purpose; half a bar needs no mask. The bars
	are as thick as the ones of a whole beam, since the cell they cross is the same size."

	| length left splatter centre |
	length := anExtent x // 2.
	left := aSymbol = #west
		        ifTrue: [ 0 ]
		        ifFalse: [ anExtent x - length ].
	splatter := self laserBeamSplatterThicknessFor: anExtent.
	centre := self laserBeamCenterThicknessFor: anExtent.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self
				   laserBeamBarOfExtent: length @ splatter
				   at: left @ ((anExtent y - splatter) / 2)
				   color: LaserGameColors laserBeamSplatterColor);
		  addChild: (self
				   laserBeamBarOfExtent: length @ centre
				   at: left @ ((anExtent y - centre) / 2)
				   color: LaserGameColors laserBeamCenterColor);
		  yourself
```
> **Note.** *Laser On Mirror Cell* replaces this method with `laserBeamElementOfExtent:fromSides:`, where a single lit side gives the same half beam.

```
LaserGameShapes class >> verticalLaserBeamElementOfExtent: anExtent enteringFrom: aSymbol
	"Answer an element of anExtent drawing the beam where it enters a cell from the side aSymbol
	names, north or south, and stops in the middle of it. Page 161 is the same picture turned a
	quarter, and asks one question, the south segment, to choose which half it keeps."

	| length top splatter centre |
	length := anExtent y // 2.
	top := aSymbol = #north
		       ifTrue: [ 0 ]
		       ifFalse: [ anExtent y - length ].
	splatter := self laserBeamSplatterThicknessFor: anExtent.
	centre := self laserBeamCenterThicknessFor: anExtent.
	^ BlElement new
		  extent: anExtent;
		  background: Color transparent;
		  addChild: (self
				   laserBeamBarOfExtent: splatter @ length
				   at: (anExtent x - splatter) / 2 @ top
				   color: LaserGameColors laserBeamSplatterColor);
		  addChild: (self
				   laserBeamBarOfExtent: centre @ length
				   at: (anExtent x - centre) / 2 @ top
				   color: LaserGameColors laserBeamCenterColor);
		  yourself
```
> **Note.** *Laser On Mirror Cell* replaces this method for the same reason as the one above it.

The bars are as thick as the ones of a whole beam, because the thickness is read from the cell and not from the bar. Placing a bar at a corner of the cell rather than in its middle is the one thing the bar builder of the last chapter could not do, so it gains a method under it and keeps the centring for itself:

```smalltalk
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent at: aPoint color: aColor
	"Answer one bar of a beam, of aBarExtent and painted in aColor, at aPoint of the cell."

	^ BlElement new
		  extent: aBarExtent;
		  position: aPoint;
		  background: aColor;
		  yourself
```

```
LaserGameShapes class >> laserBeamBarOfExtent: aBarExtent within: anExtent color: aColor
	"Answer one bar of a beam, of aBarExtent and painted in aColor, centred in a cell of anExtent."

	^ self
		  laserBeamBarOfExtent: aBarExtent
		  at: (anExtent - aBarExtent) / 2
		  color: aColor
```
> **Note.** *Laser On Mirror Cell* places every bar with `laserBeamBarOfExtent:at:color:`, which leaves this method without a sender, so it goes.

## The side the light comes from

Page 162 asks two questions: is this cell crossed the long way or the tall way, and, inside the mask, which half is kept. One question answers both, since the side the light arrives by says which pair of drawings applies and which half of the cell it covers:

```
TargetCellRenderer >> renderBeamOn: anElement
	"The target swallows the light, so the beam stops in the middle of my cell: half a beam,
	running from the side the light arrives by. Page 162 asks whether east or west is lit to choose
	between the two drawings, and pages 160 and 161 cut the other half off with a mask; the side
	the light comes from answers both questions at once."

	| side |
	side := #( #west #east #north #south ) detect: [ :each |
		        self cell isSegmentOnFor: each ].
	anElement addChild: ((#( #west #east ) includes: side)
			 ifTrue: [
				 LaserGameShapes
					 horizontalLaserBeamElementOfExtent: self class cellExtent
					 enteringFrom: side ]
			 ifFalse: [
				 LaserGameShapes
					 verticalLaserBeamElementOfExtent: self class cellExtent
					 enteringFrom: side ])
```
> **Note.** *Laser On Mirror Cell* draws every kind of cell from one `renderBeamOn:` on `CellRenderer`, so this method goes.

A target is lit for exactly one side, because it swallows the light instead of passing it on, so `detect:` finds one. The guards stay where the last chapter put them, on `CellRenderer >> renderLaserOn:`: a target that no beam reaches, or a board whose laser is off, never reaches this method.

## Under the target, not over it

The original paints the beam and then paints the target again. The port has an order instead of a repetition, and the two places that build a cell swap their last two lines:

```smalltalk
CellRenderer >> newElement
	"Answer a new element rendering my cell. The element is square, keeps me as its renderer,
	carries the cell background and border, and holds whatever my subclass draws as children: the
	beam first, then the contents of the cell over it, since page 162 draws the target again after
	the beam so that the light does not hide what it hits."

	| element |
	element := LaserGameCellElement new.
	element renderer: self.
	element extent: self class cellExtent.
	element geometry: BlRectangleGeometry new.
	self renderBackgroundOn: element.
	self renderBorderOn: element.
	self renderLaserOn: element.
	self renderContentsOn: element.
	^ element
```

```smalltalk
LaserGameCellElement >> redraw
	"Draw my cell again after the model changed. The cell standing at my location may be another
	one than before, since a push swaps two cells, so the renderer is chosen again — and so is
	the hint, at the point the pointer was last seen at, because page 126 of the original is the
	tale of a view that went on believing in the cell that had moved away. A blank cell offers no
	push, so the arrow of the mirror that left goes with it, and the cross hair with the arrow.
	The beam is drawn here too, since firing the laser changes no cell but lights many of them,
	and it is drawn under the contents, as page 162 asks.
	The original repainted a rectangle of the board form and called it redrawCell."

	| grid location point |
	grid := self renderer grid.
	location := self gridLocation.
	point := hintPosition.
	self removeChildren.
	hintElement := nil.
	hintRegion := nil.
	crossHairElement := nil.
	self renderer: (CellRenderer rendererFor: (grid at: location) grid: grid).
	self renderer renderBackgroundOn: self.
	self renderer renderBorderOn: self.
	self renderer renderLaserOn: self.
	self renderer renderContentsOn: self.
	point ifNotNil: [ self showPositionHintAt: point ]
```

A blank cell draws no contents, so nothing about the last chapter changes; a target draws four children over the beam, and a mirror will draw its line over it in the chapter after this one. The hint arrow and its cross hair are added later still, so they stay on top of everything.

## The tests

The shapes are tested on their own, for both of the sides each pair of methods knows:

```
LaserGameShapesTestCase >> testAHalfBeamCrossesHalfTheCellFromTheSideItComesFrom
	"A cell that swallows the light shows the beam only as far as its middle. Pages 160 and 162 of
	the original draw the whole beam and then black out the half the light never reaches, keeping
	the west half when the west segment is lit and the east half otherwise."

	| extent half |
	extent := 40 @ 40.
	half := extent x // 2.
	{ #west -> 0. #east -> half } do: [ :each |
		| beam |
		beam := LaserGameShapes
			        horizontalLaserBeamElementOfExtent: extent
			        enteringFrom: each key.
		self assert: (self requestedExtentOf: beam) equals: extent.
		self assert: beam children size equals: 2.
		beam children do: [ :bar |
			self assert: (self requestedExtentOf: bar) x equals: half.
			self assert: bar constraints position x equals: each value.
			self
				assert: bar constraints position y + ((self requestedExtentOf: bar) y / 2)
				equals: extent y / 2 ] ]
```
> **Note.** *Laser On Mirror Cell* asks `laserBeamElementOfExtent:fromSides:` with the one lit side instead of the pair of builders this test was written against.

`testAHalfBeamGoingUpOrDownKeepsTheHalfTheLightComesFrom` asks the same of the vertical pair, and `testAHalfBeamIsAsThickAsAWholeOne` pins the thickness, which is what the original loses when it cuts a mask in half and keeps the pixels it kept.

The demo grid ends its beam in the target at 5@1, entered from the west:

```smalltalk
TargetCellRendererTestCase >> testTheBeamStopsInTheMiddleOfTheTargetItReaches
	"Page 160 draws the beam on the target the light arrives at, and stops it in the middle of the
	cell, since the target swallows the light. The demo grid sends the beam into the target at 5@1
	from the west, so the beam covers the west half of the cell."

	| grid element beam half |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
		           newElement.
	beam := element children first.
	half := CellRenderer cellExtent x // 2.
	self assert: (self requestedExtentOf: beam) equals: CellRenderer cellExtent.
	self assert: beam children size equals: 2.
	beam children do: [ :bar |
		self assert: (self requestedExtentOf: bar) x equals: half.
		self assert: bar constraints position x equals: 0 ]
```

Page 163 reaches the other three sides by opening an inspector on the running game and swapping the target with another cell, then hovering over both so that they repaint. The test asks the grid for the same swap, and needs no hovering, since a renderer is built from the model whenever it is asked for:

```smalltalk
TargetCellRendererTestCase >> testTheBeamReachesTheTargetFromTheSideItTravelsBy
	"Page 163 tests the other ways in by dragging another cell onto the target from an inspector;
	here the grid is asked to hold a target where the beam runs upwards, and the beam covers the
	south half of the cell it now ends in."

	| grid element beam half |
	grid := GridFactory demoGrid.
	grid at: 4 @ 3 put: TargetCell new.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 3) grid: grid)
		           newElement.
	beam := element children first.
	half := CellRenderer cellExtent y // 2.
	self assert: ((grid at: 4 @ 3) isSegmentOnFor: #south).
	self assert: beam children size equals: 2.
	beam children do: [ :bar |
		self assert: (self requestedExtentOf: bar) y equals: half.
		self assert: bar constraints position y equals: half ]
```

And the order page 162 is careful about:

```smalltalk
TargetCellRendererTestCase >> testTheTargetIsDrawnOverTheBeam
	"Page 162 draws the beam and then the ring, the crosshairs and the disc again over it, so that
	the light does not hide the target it hits. Here the beam is simply the first child and the
	four pieces of the target come after it."

	| grid element children |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 5 @ 1) grid: grid)
		           newElement.
	children := element children.
	self assert: children size equals: 5.
	self assert: (children at: 1) children size equals: 2.
	self assert: (children at: 2) geometry class equals: BlLineGeometry.
	self assert: (children at: 3) geometry class equals: BlLineGeometry.
	self assert: (children at: 4) geometry class equals: BlCircleGeometry.
	self assert: (children at: 5) geometry class equals: BlCircleGeometry
```

Three tests written earlier read the disc of the target as the fourth child of the cell element. A lit target now has five children, so those three ask for the last child instead.

## What goes

`TargetCellRenderer` loses `renderLaser`, `maskOffHorizontalOn:` and `maskOffVerticalOn:`, which is the whole of what pages 160 to 162 wrote. The class is now the target picture and one `renderBeamOn:`.

Page 159 has no counterpart at all: its refactoring exists so that the ring can be painted onto a form at an offset, and the port draws the ring as an element that is placed by its parent.

Page 165 is a refactoring, and the port arrived at its result three chapters early. It moves `renderLaserHorizontal`, `renderLaserVertical`, their four splatter and centre methods and the two masked painting methods up to `CellRenderer`, and gives `BlankCellRenderer` two masks that answer their argument unchanged, so that one painting method serves both classes. Here the shared part is `renderLaserOn:` with its two guards, the varying part is `renderBeamOn:`, and a blank cell needs no do-nothing mask because it asks for a whole beam and a target asks for half of one.

## Checking it

```smalltalk
LaserGameBoardElement openExampleWithLaserFired
```

The beam now ends where the light does: it comes in at the west edge of the target and stops under the ring. Pages 163 and 164 look at the result with the cursor and then with a Magnifier Morph at four times, and find that the beam does not quite line up with the crosshair of the target. The port has a smaller version of the same thing: the beam is centred on the cell, at 25 of 50, and the crosshair is drawn along `cellExtent - 1 // 2`, at 24, which is the original's own arithmetic kept as it was written on page 137. One pixel, and page 165 is right that the place to settle it is the mirror, where two beams have to meet; the chapters that follow draw them.


# Laser On Mirror Cell

Pages 166 to 173 draw the beam on the cell that turns it, and close Section 4. A mirror is lit on two sides at a right angle to each other, so two half beams have to meet in the middle of the cell, and the two quadrants the light never reaches have to stay empty. The original spends eight pages on that. The port spends one method, and the same method draws every other kind of cell as well.

## What the original writes

Page 166 plans the work: draw both whole beams, mask off the part of the cell where the light does not belong, and draw the mirror again on top. It starts with two masks that do nothing, a refactoring that gives the mirror drawing a name of its own, and a first `renderLaser`:

```
renderLaser
    self cell isOff ifTrue: [^self].
    self renderLaserVertical.
    self renderLaserHorizontal.
    self renderMirror.
```

Page 167 looks at the result under a magnifier and finds two things. The bright cores have to be drawn after both pale bands, which it gets by painting the vertical core a second time; and the beams are not centred in the cell:

```
renderLaser
    self cell isOff ifTrue: [^self].
    self renderLaserVertical.
    self renderLaserHorizontal.
    self renderLaserVerticalCenter.
    self renderMirror.
```

Pages 168 and 169 settle the centring with two numbers written into the offset arithmetic of `CellRenderer`: `offset := 0@(5 + (CellRenderer cellExtent y - trimmedBeam height) // 2)` for the horizontal beam, and `(-3 + ...)@(3 + ...)` for the vertical one. They are the one-pixel drift that page 165 promised would be settled at the mirror.

Page 170 finds a mirror on the board whose two sides are both active, because the beam crosses its own path there, and observes that the drawing of that case is already correct. It also notes that a blank cell can be crossed twice too, and leaves that for page 173.

Page 171 writes the four quadrant masks. Each builds a one-bit form, draws the cell diagonal on it with a one-pixel pen, floods one side of the diagonal from a point chosen five pixels in, paints the result onto the board form in the background colour, and repairs the two borders it has just painted over:

```
maskForNorthEast
    	| mask pen line cellPosn |
    	mask := Form extent: CellRenderer cellExtent depth: 1.
    	mask fillColor: Color white.
    	pen := Form extent: 1@1 depth: 1.
    	pen fillColor: Color black.
    	line := Line
        			from: 0@0
        			to: mask extent
        			withForm: pen.
    	line displayOn: mask.
    	mask floodFill: Color black at: 5@1.
    	cellPosn := self offsetWithinGridForm.
    	mask
        		displayOn: self targetForm
        		at: cellPosn
        		clippingBox: self targetForm boundingBox
        		rule: Form oldPaint
        		fillColor: LaserGameColors gameBoardBackgroundColor.
    	self renderBorderTop.
    	self renderBorderRight
```

`maskForNorthWest`, `maskForSouthEast` and `maskForSouthWest` are the same method with the other diagonal, another flood point and the other two borders. Page 172 chooses among them by the lean of the mirror and the segments that are dark:

```
removeLaserFromInactiveLeftSide
    (self cell activeSegments at: #west) ifFalse: [self maskForSouthWest].
    (self cell activeSegments at: #east) ifFalse: [self maskForNorthEast].

removeLaserFromInactiveRightSide
    (self cell activeSegments at: #west) ifFalse: [self maskForNorthWest].
    (self cell activeSegments at: #east) ifFalse: [self maskForSouthEast].

removeLaserFromInactiveSide
    self cell isLeft
        ifTrue: [self removeLaserFromInactiveLeftSide]
        ifFalse: [self removeLaserFromInactiveRightSide]
```

And page 173 goes back to the blank cell, which was drawing a whole beam along both axes whenever any side was lit:

```
renderLaser
    self cell isOff ifTrue: [^self].
    (self cell activeSegments at: #north) ifTrue: [self renderLaserVertical].
    (self cell activeSegments at: #west) ifTrue: [self renderLaserHorizontal].
    ((self cell activeSegments at: #north) and: [self cell activeSegments at: #west]) ifTrue: [
        self renderLaserVerticalCenter]
```

## The lit sides say the whole picture

Read those eight pages together and one fact runs through all of them. A cell that turns the light is lit on two sides at a right angle; a cell the beam goes straight through is lit on two opposite sides; a target is lit on one; a cell crossed twice is lit on four. In every case the sides that carry light are exactly what is drawn, and nothing else about the cell matters — not its kind, not the lean of its mirror. So the cell is asked for them:

```smalltalk
Cell >> litSides
	"Answer the sides of me that carry light, in a fixed order. A cell the beam crosses is lit on
	the side it arrives by and on the side it leaves by, a cell that swallows the light is lit on
	one side, and a cell the beam crosses twice is lit on all four. Nothing else is needed to draw
	the beam, which is why the renderers ask this and nothing else."

	^ #( #north #east #south #west ) select: [ :each |
		  self isSegmentOnFor: each ]
```

## One bar for each axis

A beam bar runs the whole way across when both sides of its axis are lit, and from the lit side to the middle when only one of them is. That is the whole of the geometry, for every case the eight pages enumerate:

```smalltalk
LaserGameShapes class >> horizontalLaserBeamBarOfExtent: anExtent sides: aCollection thickness: aThickness color: aColor
	"Answer the bar of a beam that runs across a cell of anExtent, as thick as aThickness and
	painted in aColor. It runs the whole way when both the west and the east side of the cell are
	lit, and half the way, from the lit side to the middle, when only one of them is."

	| length left |
	length := ((aCollection includes: #west) and: [
		           aCollection includes: #east ])
		          ifTrue: [ anExtent x ]
		          ifFalse: [ anExtent x // 2 ].
	left := (aCollection includes: #west)
		        ifTrue: [ 0 ]
		        ifFalse: [ anExtent x - length ].
	^ self
		  laserBeamBarOfExtent: length @ aThickness
		  at: left @ ((anExtent y - aThickness) / 2)
		  color: aColor
```

```smalltalk
LaserGameShapes class >> verticalLaserBeamBarOfExtent: anExtent sides: aCollection thickness: aThickness color: aColor
	"Answer the bar of a beam that runs up and down a cell of anExtent, as thick as aThickness and
	painted in aColor. It runs the whole way when both the north and the south side of the cell are
	lit, and half the way, from the lit side to the middle, when only one of them is."

	| length top |
	length := ((aCollection includes: #north) and: [
		           aCollection includes: #south ])
		          ifTrue: [ anExtent y ]
		          ifFalse: [ anExtent y // 2 ].
	top := (aCollection includes: #north)
		       ifTrue: [ 0 ]
		       ifFalse: [ anExtent y - length ].
	^ self
		  laserBeamBarOfExtent: aThickness @ length
		  at: (anExtent x - aThickness) / 2 @ top
		  color: aColor
```

The builder above them draws at most four bars, the two pale bands first and the two bright cores over them, which is the order page 167 reaches by painting one core twice:

```smalltalk
LaserGameShapes class >> laserBeamElementOfExtent: anExtent fromSides: aCollection
	"Answer an element of anExtent drawing the beam of a cell lit on the sides aCollection names.
	One bar is drawn for each of the two axes light runs along: the whole way across when both
	sides of that axis are lit, and from the lit side to the middle otherwise. Two opposite sides
	are a cell the beam goes straight through, two sides at a right angle are the turn at a mirror,
	one side is the half beam a cell that swallows the light shows, and four sides are a beam that
	crosses its own path. The pale bands are drawn first and the bright cores over them, so a
	crossing shows both cores; page 167 of the original reaches that by painting one core twice."

	| element across down |
	across := aCollection select: [ :each | #( #west #east ) includes: each ].
	down := aCollection select: [ :each | #( #north #south ) includes: each ].
	element := BlElement new
		           extent: anExtent;
		           background: Color transparent;
		           yourself.
	{
		(self laserBeamSplatterThicknessFor: anExtent)
		-> LaserGameColors laserBeamSplatterColor.
		(self laserBeamCenterThicknessFor: anExtent)
		-> LaserGameColors laserBeamCenterColor } do: [ :each |
		across ifNotEmpty: [
			element addChild: (self
					 horizontalLaserBeamBarOfExtent: anExtent
					 sides: across
					 thickness: each key
					 color: each value) ].
		down ifNotEmpty: [
			element addChild: (self
					 verticalLaserBeamBarOfExtent: anExtent
					 sides: down
					 thickness: each key
					 color: each value) ] ].
	^ element
```

The three builders of the last two chapters — the whole beam of *Laser On Blank Cell* and the two half beams of *Laser On Target Cell* — are cases of this one, so they go.

## One method for every kind of cell

`renderBeamOn:` was a method the subclasses answered differently. It is now one method on `CellRenderer`, and the subclasses have none:

```smalltalk
CellRenderer >> renderBeamOn: anElement
	"Draw the beam my lit cell shows, as one child of anElement. The sides of my cell that carry
	light say the whole of what is drawn, so every kind of cell is drawn here: a blank cell the
	beam crosses, the target it ends in, the mirror it turns at, and any of them crossed twice.
	Pages 156 to 172 of the original need three renderers and a dozen masks for that, because it
	paints whole beams onto one shared form and then blacks out what does not belong."

	anElement addChild: (LaserGameShapes
			 laserBeamElementOfExtent: self class cellExtent
			 fromSides: self cell litSides)
```

```smalltalk
CellRenderer >> renderLaserOn: anElement
	"Draw the beam where it crosses my cell, as children of anElement. Nothing is drawn while the
	laser is off or while no light reaches my cell: the original asks the first question in
	#render, before it sends #renderLaser at all, and the second at the head of every #renderLaser.
	What a lit cell draws is #renderBeamOn:, which is the same for every kind of cell."

	self grid laserIsActive ifFalse: [ ^ self ].
	self cell isOff ifTrue: [ ^ self ].
	self renderBeamOn: anElement
```

The mirror needs no drawing code of its own at all. Page 166 refactors `renderContents` so that the mirror can be drawn again after the beam; here `MirrorCellRenderer >> renderContentsOn:` already exists and already draws the mirror, and the order is the one *Laser On Target Cell* settled: the beam is added before the contents, so the mirror line lies over the light it turns.

The four quadrant masks of page 171 have no counterpart, and neither do the two pixel adjustments of pages 168 and 169. Nothing is painted that has to be taken away again, so nothing has to be blacked out, no border has to be repaired, and the drift those two numbers correct never happens: a bar is placed by `(anExtent - aThickness) / 2`, which is exact.

## The tests

The shapes answer for the turn and for the crossing:

```smalltalk
LaserGameShapesTestCase >> testABeamThatArrivesFromTwoSidesTurnsInTheMiddle
	"A mirror sends the beam on by another side, so two half beams meet in the middle of the cell:
	one from the side the light arrives by, one to the side it leaves by. Pages 166 to 172 of the
	original draw two whole beams instead and then black out the two quadrants of the cell the
	light never reaches."

	| extent beam half |
	extent := 40 @ 40.
	half := extent x // 2.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #west #north ).
	self assert: beam children size equals: 4.
	self assert: (self requestedExtentOf: beam children first) x equals: half.
	self assert: beam children first constraints position x equals: 0.
	self assert: (self requestedExtentOf: beam children second) y equals: half.
	self assert: beam children second constraints position y equals: 0.
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
```

```smalltalk
LaserGameShapesTestCase >> testABeamThatCrossesItsOwnPathDrawsBothCoresOverBothBands
	"A cell all four sides of which are lit is crossed twice, which page 170 finds on the board and
	page 173 fixes for the blank cell. Both bands run the whole way across, and both bright cores
	are drawn after them, so neither core is buried under the other band. Page 167 arrives at the
	same order by painting one of the cores a second time."

	| extent beam |
	extent := 40 @ 40.
	beam := LaserGameShapes
		        laserBeamElementOfExtent: extent
		        fromSides: #( #north #east #south #west ).
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	(beam children asArray first: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamSplatterColor ].
	(beam children asArray last: 2) do: [ :bar |
		self
			assert: bar background paint color
			equals: LaserGameColors laserBeamCenterColor ]
```

The demo grid turns the beam at 4@5, which is the mirror the board was built around:

```smalltalk
MirrorCellRendererTestCase >> testTheBeamTurnsAtAMirror
	"The demo grid turns the beam north at the mirror of 4@5, which is lit on its west side, where
	the light arrives, and on its north side, where it leaves. The cell shows two half beams, and
	nothing at all in the two quadrants pages 171 and 172 have to black out."

	| grid element beam half extent |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 5) grid: grid)
		           newElement.
	extent := CellRenderer cellExtent.
	half := extent x // 2.
	beam := element children first.
	self assert: beam children size equals: 4.
	self assert: (self requestedExtentOf: beam children first) x equals: half.
	self assert: beam children first constraints position x equals: 0.
	self assert: (self requestedExtentOf: beam children second) y equals: half.
	self assert: beam children second constraints position y equals: 0
```

```smalltalk
MirrorCellRendererTestCase >> testTheMirrorIsDrawnOverTheBeam
	"Page 166 draws the mirror again after the beam, so the light does not hide the thing that
	turns it. Here the beam is the first child and the mirror is the last."

	| grid element |
	grid := GridFactory demoGrid.
	grid fireLaser.
	element := (CellRenderer rendererFor: (grid at: 4 @ 5) grid: grid)
		           newElement.
	self assert: element children size equals: 2.
	self assert: element children first children size equals: 4.
	self
		assert: element children last geometry class
		equals: BlLineGeometry
```

Page 170 finds a mirror lit on both sides by playing the game. A test can simply build one, since a cell can be told that the light enters it and a grid can be told that its laser is on:

```smalltalk
MirrorCellRendererTestCase >> testAMirrorCrossedTwiceShowsBothBeamsWhole
	"Page 170 finds a mirror on the board both sides of which are active: the beam crosses its own
	path there. All four segments are lit, so both beams run the whole way across, and the original
	says of that case that the drawing is already correct."

	| grid cell element beam extent |
	grid := Grid new.
	cell := MirrorCell new.
	cell leanLeft.
	grid at: 1 @ 1 put: cell.
	cell laserEntersFrom: #west.
	cell laserEntersFrom: #north.
	grid laserIsActive: true.
	extent := CellRenderer cellExtent.
	element := (CellRenderer rendererFor: cell grid: grid) newElement.
	beam := element children first.
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ]
```

And page 173, on the blank cell:

```smalltalk
CellRendererTestCase >> testABlankCellCrossedTwiceShowsBothBeams
	"Page 173 finds the same on a blank cell: the beam can cross its own path there too, and the
	original then draws the vertical beam when north is lit, the horizontal one when west is lit,
	and the vertical core once more so that the crossing looks right. The port asks nothing extra:
	the cell is lit on four sides, so both bands are drawn and both cores go over them."

	| grid cell element beam extent |
	grid := Grid new.
	cell := BlankCell new.
	grid at: 1 @ 1 put: cell.
	cell laserEntersFrom: #west.
	cell laserEntersFrom: #north.
	grid laserIsActive: true.
	extent := CellRenderer cellExtent.
	element := (CellRenderer rendererFor: cell grid: grid) newElement.
	beam := element children first.
	self assert: beam children size equals: 4.
	beam children do: [ :bar |
		self
			assert: ((self requestedExtentOf: bar) x max: (self requestedExtentOf: bar) y)
			equals: extent x ].
	self
		assert: beam children last background paint color
		equals: LaserGameColors laserBeamCenterColor
```

The six beam tests written in the last two chapters now ask `laserBeamElementOfExtent:fromSides:` for what they used to ask the three builders, with `#( #west #east )` for a whole beam across, `#( #north #south )` for a whole beam up and down, and one side for a half beam. What they assert is unchanged.

## What goes

This is the chapter where the 2007 beam drawing leaves the image. `MirrorCellRenderer` loses `renderLaser`, the four quadrant masks, the three `removeLaserFromInactive...` methods and the two `maskOff...` stubs — the whole of pages 166 to 172. `BlankCellRenderer` and `TargetCellRenderer` lose their `renderBeamOn:`. `CellRenderer` loses `renderLaser` and the eight `renderLaserHorizontal...` and `renderLaserVertical...` methods that page 165 had moved up into it, and with them `render`, which was the only thing that still called them and which nothing has called since the board became elements. `LaserGameShapes` loses the four beam builders of the last two chapters.

What is left of the beam is three methods on `LaserGameShapes`, one `renderBeamOn:` and one `renderLaserOn:`.

## Checking it

```smalltalk
LaserGameBoardElement openExampleWithLaserFired
```

The beam leaves the laser, turns at the mirror of 4@5, turns again at 4@1 and stops in the middle of the target — and the elbows are square, with no notch between the end of one bar and the side of the other, because the two bars overlap in the middle of the cell instead of being cut apart there. Page 165 promised that the mirror was the place where the centring would have to be right; it is, and it cost no pixels.


# A Window The Player Can Resize

*Not in the 2007 tutorial: an addition of the port.*

The board can be any size since the last chapter, but the window it opens in cannot: `openOn:` gives the space the extent the grid asks for, and dragging the corner of that window leaves the game the size it was, with the desktop colour filling the rest. The original has the same limit for a better reason. A Morph draws into a form of a fixed number of pixels, and the game draws its cells into a shared board form, so growing the window would mean re-rendering every cell into a bigger form and re-deriving the click regions from a bigger cell size.

A Bloc element has neither problem. The cells are geometries rather than bitmaps, so they are drawn from their own coordinates every frame and have no resolution of their own, and an element carries a transformation the whole subtree is drawn and hit-tested through. Scaling the game is therefore a matter of setting one matrix, and the beam, the arrows and the LED digits all follow it at full sharpness. Nothing in the drawing code changes, and no number written down in the earlier chapters moves: the cell is still fifty pixels, the panel still a hundred and ten, and the margin still ten.

## The size the game is drawn at

The extent the board asks for stops being the size of the window and becomes the size the drawing is scaled from, which is worth its own name:

```smalltalk
LaserGameElement >> naturalExtent
	"Answer the extent the game is drawn at: the board, the panel and the margins, in the pixel
	sizes every page of the tutorial writes down. The window can be any size; this one is the
	size the drawing is scaled from."

	^ self class extentForGrid: self grid
```

A window of another size wants a scale factor, and a window of another shape wants the tighter of the two directions, so that the cells stay square:

```smalltalk
LaserGameElement >> scaleToFitIn: anExtent
	"Answer how much the game has to be scaled by to fill a window of anExtent without changing
	its shape: the tighter of the two directions, so the whole board stays in view and the cells
	stay square."

	| natural |
	natural := self naturalExtent.
	^ ((anExtent x / natural x) min: (anExtent y / natural y)) asFloat
```

Taking the tighter direction leaves the looser one with a strip of space over, and the game looks least out of place with that strip split between the two sides:

```smalltalk
LaserGameElement >> positionToCenterIn: anExtent
	"Answer where the scaled game sits in a window of anExtent: in the middle of it, with the
	leftover of the looser direction split between the two sides."

	^ (anExtent - (self naturalExtent * (self scaleToFitIn: anExtent))) / 2
```

The two together are the whole of the feature:

```smalltalk
LaserGameElement >> fitIn: anExtent
	"Scale the game to a window of anExtent and centre it there. The original is a Morph of a
	fixed size and has nothing like this: it is the port's answer to a window the player can
	resize, and it costs nothing, because every cell is drawn from geometries rather than from a
	bitmap. A window of no size is left alone, since a space announces one while it opens."

	(anExtent x > 0 and: [ anExtent y > 0 ]) ifFalse: [ ^ self ].
	self transformDo: [ :aBuilder |
		aBuilder
			topLeftOrigin;
			scaleBy: (self scaleToFitIn: anExtent) ].
	self position: (self positionToCenterIn: anExtent)
```

`transformDo:` hands out a builder rather than a matrix, and `topLeftOrigin` says which point of the element the scale keeps still — the top left corner, since the position set on the next line is where that corner goes. A builder replaces the transformation rather than adding to it, so calling `fitIn:` again with another extent scales from the natural size again and not from the size it is already at.

The guard on the first line is not defensive programming. A space announces its extent while it is opening, and the extent it announces first is `0@0`; scaling by zero would collapse the game to a point it never comes back from.

## Following the window

Bloc puts the root element of a space under a resizer that matches the space, so the root extent is the window extent, and it announces a `BlElementExtentChangedEvent` whenever the player drags the corner. `openOn:` subscribes to it:

```smalltalk
LaserGameElement class >> openOn: aGrid
	"Open a space showing a game on aGrid and answer it. The space starts at the size the game is
	drawn at, and the game follows it from there: a window the player resizes scales the game to
	match, which the original, a Morph of a fixed size, does not do.

	LaserGameElement openOn: GridFactory demoGrid"

	| space element |
	space := BlSpace new.
	element := self on: aGrid.
	space extent: (self extentForGrid: aGrid).
	space title: 'Laser Game'.
	space root addChild: element.
	space root
		addEventHandlerOn: BlElementExtentChangedEvent
		do: [ :anEvent | element fitIn: space root extent ].
	element fitIn: space extent.
	space show.
	^ space
```

The space is still opened at the natural extent, so a game that is never resized looks exactly as it did in the earlier chapters. The `fitIn:` before `show` is there for the same reason the guard is: it sets the scale once from the extent the space was given, rather than waiting for a resize that may never come.

The game keeps its own place in the window, so `LaserGameElement` is no longer added and forgotten — `openOn:` holds on to it in a temporary to hand it to the handler.

## The tests

Four tests, all headless. None of them opens a space: `fitIn:` is asked of a detached element, and what it does is read back from the transformation matrix and from `constraints position`, which is where `position:` writes and what a layout pass later reads. The `position` of a detached element is still `0@0`, and `extent` likewise, which is why neither is asserted.

A window of exactly twice the extent is the simple case:

```
LaserGameElementTestCase >> testAGameScalesToFillTheWindowItIsGiven
	"The game is drawn at the size the board asks for and scaled to whatever the window is, so a
	window of twice the extent shows the same game twice as big, filling it."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	self assert: game naturalExtent equals: 380 @ 270.
	game fitIn: 760 @ 540.
	self assert: (game scaleToFitIn: 760 @ 540) equals: 2.0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game transformation matrix sy equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
```
> **Note.** *A Missed Bug*, the first chapter of Section 5, reads this size from the game instead of writing it down, so that the test holds at any cell size.

A window of another shape is the case the `min:` is there for. The demo board is 380 by 270. Twice as wide but no taller scales by 1.0 and leaves 380 pixels over, so the game sits 190 in; as tall as the doubled board but no wider scales by 1.0 again and leaves 270, so it sits 135 down:

```
LaserGameElementTestCase >> testAGameKeepsItsShapeInAWindowOfAnotherShape
	"A board is as wide and as tall as it is. A window of another shape scales the game by the
	tighter of the two directions and centres what is left over, so the cells stay square and the
	game is never stretched."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game fitIn: 760 @ 270.
	self assert: (game scaleToFitIn: 760 @ 270) equals: 1.0.
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: 190 @ 0.
	game fitIn: 380 @ 540.
	self assert: game transformation matrix sx equals: 1.0.
	self assert: game constraints position equals: 0 @ 135
```
> **Note.** *A Missed Bug*, the first chapter of Section 5, reads this size from the game instead of writing it down, so that the test holds at any cell size.

Shrinking is the same arithmetic in the other direction, and is worth its own test because the alternative — clipping the board — is what a window that holds a fixed drawing usually does:

```
LaserGameElementTestCase >> testAGameShrinksWithASmallerWindow
	"A window smaller than the board scales the game down rather than cutting it off, so the whole
	board is always in view."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game fitIn: 190 @ 135.
	self assert: game transformation matrix sx equals: 0.5.
	self assert: game constraints position equals: 0 @ 0
```
> **Note.** *A Missed Bug*, the first chapter of Section 5, reads this size from the game instead of writing it down, so that the test holds at any cell size.

And the opening extent, which asserts that a window of no size changes nothing rather than that it scales to nothing:

```
LaserGameElementTestCase >> testAGameIgnoresAWindowOfNoSize
	"A space announces its extent while it is being opened, and that extent can be nothing at all.
	Scaling by zero would take the game off the screen, so a window of no size is left alone."

	| game |
	game := LaserGameElement on: GridFactory demoGrid.
	game fitIn: 760 @ 540.
	game fitIn: 0 @ 0.
	self assert: game transformation matrix sx equals: 2.0.
	self assert: game constraints position equals: 0 @ 0
```
> **Note.** *A Missed Bug*, the first chapter of Section 5, reads this size from the game instead of writing it down, so that the test holds at any cell size.

## Checking it

```smalltalk
LaserGameElement openStandardExample
```

Drag the corner of the window. The board, the panel, the buttons and the counters grow and shrink together, the cells stay square, and the game stays in the middle of whatever shape the window is left in. Clicking still works where the cells are seen to be: Bloc runs a hit test through the same transformation it draws through, so a mirror at twice the size is clicked at twice the coordinates without a line of the click code knowing about it.

# Counters The Player Can Read

*Not in the 2007 tutorial: a correction of the port.*

Open the game and the two counters read `88E` rather than a number. They are not broken — both hold the right value, and `updateCounters` sets them on every move and every shot — but nothing of that can be seen, and this chapter is the reading of that screen against the original.

## What the original does that this did not

The screenshot of page 148 shows the two counters against the ramp: a dark slab with `027` on it in white, and under it a second slab with `012` in lavender. The segments that are not lit are not there at all. Sampling the picture explains why. The slab is the colour `(0.33, 0.33, 0.52)` — which is, to a rounding, the colour this port paints an unlit segment in. In the original the two are the same colour on purpose: `LedMorph` draws itself on that slab and paints the segments it does not light in the slab colour, so they disappear into it.

The port took the two colours from page 141 and left the display transparent, so the unlit segments sat on the window ramp of page 140 instead, where a dark lavender on bright cyan is the most visible thing on the panel. Every digit showed all seven segments, six of them dark and however many lit ones pale on top, which is why a zero reads as an eight and the whole display reads as `88E`. The colour that hides a segment in the original is the colour that shows it here.

So the display carries the slab:

```smalltalk
LaserGameColors class >> counterBodyColor
	"Answer the color of the slab a counter shows its digits on. The original's LedMorph draws
	itself on this dark lavender, and a segment that is not lit is painted the same color, so only
	the lit segments are seen. Sampled from the screenshot of page 148."

	^ Color r: 0.33 g: 0.33 b: 0.52
```

```smalltalk
LaserGameColors class >> counterDigitOffColor
	"Answer the color of a segment that is not lit: the slab behind it, which is how the original
	hides it."

	^ self counterBodyColor
```

```smalltalk
LaserGameLedElement >> initialize
	"A display is a dark slab with a row of digits on it, one gap apart. The slab is the color the
	original's LedMorph draws itself in, and an unlit segment takes it too, so that only the lit
	segments are seen. The gap is a margin on each digit but the first rather than the cell spacing
	of the layout, since a linear layout spaces the cells from its own edges as well and the last
	digit would then be clipped."

	super initialize.
	value := 0.
	digitCount := 0.
	highlighted := false.
	digitElements := #(  ).
	self background: LaserGameColors counterBodyColor.
	self layout: BlLinearLayout horizontal
```

That is the whole of the visibility fix: an unlit segment is still painted, still in its own place, and still the colour it always was — only now the thing behind it is that colour too.

The same screenshot settles the second colour. Page 142 highlights the counter of the beam while the laser fires, and the port drew the highlight as the LED colour against the same colour darkened, two shades of lavender a few per cent apart. On the page the highlighted counter is nearly white:

```smalltalk
LaserGameColors class >> counterDigitHighlightColor
	"Answer the color a counter lights its segments in while it is highlighted. Page 142 brightens
	the counter of the beam while the laser fires, and the screenshot of page 148 has it almost
	white, against the lavender of the counter beside it."

	^ Color r: 0.95 g: 1.0 b: 1.0
```

```smalltalk
LaserGameLedElement >> onColor
	"Answer the color of a lit segment: almost white while I am highlighted, the lavender of the
	LED otherwise."

	^ highlighted
		  ifTrue: [ LaserGameColors counterDigitHighlightColor ]
		  ifFalse: [ LaserGameColors counterDigitColor ]
```

## The last digit was outside the display

Reading the digit positions turned up a second fault. A display of three digits is thirty four pixels wide — three tens and two gaps — and its digits stood at 2, 14 and 26, so the third ended two pixels past the right edge and Bloc, which clips an element to its own bounds, cut it off. The gap was the cell spacing of the row, and a `BlLinearLayout` puts its cell spacing around the cells as well as between them: a gap before the first digit, one between each pair, and one after the last. This is the same fault the Fire button had in Section 4.5, in the same layout.

The gap belongs to the digits that have one in front of them:

```smalltalk
LaserGameLedElement >> rebuildDigits
	"Replace my digits with digitCount fresh ones and take the size they need. Every digit but the
	first carries the gap in front of it as a margin."

	self removeChildren.
	digitElements := (1 to: digitCount) collect: [ :each | self newDigitElement ].
	digitElements allButFirst do: [ :each |
		each margin: (BlInsets left: self class digitGap) ].
	digitElements do: [ :each | self addChild: each ].
	self extent: (self class extentForDigits: digitCount).
	self updateDigits
```

and the row spaces nothing of its own, so `extentForDigits:` is the width it always claimed.

## The tests

Three tests hold the three facts. What is behind an unlit segment is as much a part of the display as the segment:

```smalltalk
LaserGameLedElementTestCase >> testUnlitSegmentsVanishIntoTheBody
	"The original's display is a dark slab, and a segment that is not lit is the color of that
	slab, so only the lit ones are seen. The port paints the same two colors, which means the
	display has to carry the slab as its own background: on the ramp of page 140 an unlit segment
	would otherwise read as a lit one."

	| led unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	unlit := led digitElements first children first.
	self
		assert: led background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterBodyColor.
	self
		assert: LaserGameColors counterDigitOffColor
		equals: LaserGameColors counterBodyColor
```

The arithmetic that was wrong is the arithmetic the test does — the width the row asks for against the width its cells, their margins and its own spacing take:

```smalltalk
LaserGameLedElementTestCase >> testTheDigitsFitInsideTheDisplay
	"Every digit has to be inside the display, which clips what sticks out of it. A linear layout
	adds its cell spacing around the cells as well as between them, so the gap between two digits
	is a margin on each digit but the first, and the row comes to exactly the width the display
	takes."

	| led spacing used |
	led := LaserGameLedElement digits: 3.
	spacing := led layout cellSpacing.
	used := (led digitElements size + 1 * spacing)
	        + (led digitElements inject: 0 into: [ :sum :each |
			         sum + each constraints horizontal resizer size + each margin left
			         + each margin right ]).
	self assert: used equals: (LaserGameLedElement extentForDigits: 3) x.
	self assert: led digitElements first margin left equals: 0.
	self
		assert: led digitElements second margin left
		equals: LaserGameLedElement digitGap
```

And the highlight test of Section 4.4 keeps its name and its shape, with the two colours it now expects:

```smalltalk
LaserGameLedElementTestCase >> testHighlightingBrightensTheLitSegments
	"Page 142 highlights the counter while the laser fires. Highlighting changes the color of the
	segments that are lit and leaves the others alone. The two colors are the ones the screenshot
	of page 148 shows: the counter of the beam is almost white while the laser fires, and the move
	counter beside it stays the lavender of the LED."

	| led digit lit unlit |
	led := LaserGameLedElement digits: 1.
	led value: 1.
	digit := led digitElements first.
	lit := digit children second.
	unlit := digit children first.
	self deny: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitColor.
	led highlighted: true.
	self assert: led highlighted.
	self
		assert: lit background paint color
		equals: LaserGameColors counterDigitHighlightColor.
	self
		assert: unlit background paint color
		equals: LaserGameColors counterDigitOffColor
```

## Checking it

```smalltalk
LaserGameElement openExample
```

Both counters read `0` on a dark slab, with two blank digits in front of it. Fire the laser and the beam counter turns white and shows the length of the path; stop it and it goes back to zero and to lavender. Click a mirror and the move counter follows, one digit at a time, up to three digits.
