"
I am the control panel of the game: the column beside the board that holds its buttons and its counters.

I replace the panel the 2007 `LaserGame` morph built in `makeControlPanelMorph` and filled through `addButtonsToPanel:` and `addCountersToPanel:`. I hold Toplo buttons instead of `PluggableButtonMorph`s, and I hold what I am asked about in an instance variable, so nothing has to search the children by name the way `findFireButton`, `findLaserPathCounter` and `findMovesCounter` do.

Five buttons: Quit, which asks the game to close, and Fire, whose label says what a click will do — `'Fire'` while the laser is off, `'Stop'` while it fires, both from page 068 — New, from page 144, which deals a new randomized board, Undo, from page 186, which takes the last move back, and Reset, from page 188, which unwinds the whole undo stack at once. Quit and Fire share the bottom row, New and Undo the row above it, and Reset has the top row to itself, which is how pages 144 and 188 number them. Four counters, from pages 141, 143 and 181: the length of the beam, the number of moves made, the number of mirrors standing on the board, and the number of those the beam lights. Only the first is ever bright, since it alone says whether the laser is on. The buttons sit at my bottom left corner and the counters at my top left corner, which is where the original's layout frames put them. Page 140 paints me transparent, so the window ramp behind me shows through. The divider comes with its own page.

Instance variables:
- `game`: the `LaserGameElement` I control. Setting it builds everything I show.
- `quitButton`, `fireButton`, `newGameButton`, `undoButton`: four of the five buttons. The fifth, Reset, is not held: a tenth instance variable would trip `ReExcessiveVariablesRule`, and `resetButton` reads it from `resetRow`, which is the only button of its row.
- `laserPathCounter`, `movesCounter`, `mirrorsCounter`, `activeMirrorsCounter`: the four counters, in the order they are stacked.
The two columns I stack are not held: `counterColumn` is my first child and `buttonColumn` my last, and `resetRow`, `newGameRow` and `buttonRow` read the three rows of the button column the same way.

I ask the game what to display and I tell the game what the player did. What I read from the grid is the length of the beam and the two mirror counts, which is where pages 143 and 182 read them too.
"
Class {
	#name : 'LaserGameControlPanelElement',
	#superclass : 'BlElement',
	#instVars : [
		'game',
		'quitButton',
		'fireButton',
		'newGameButton',
		'laserPathCounter',
		'movesCounter',
		'mirrorsCounter',
		'activeMirrorsCounter',
		'undoButton'
	],
	#category : 'Laser-Game-Graphics',
	#package : 'Laser-Game',
	#tag : 'Graphics'
}

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonGap [
	"Answer the gap, in pixels, between the buttons and around the row they sit in. The original
	spaces its buttons ten pixels apart, and the horizontal gap its arithmetic produces for two
	buttons in a panel of this width comes to the same ten."

	^ 10
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonHeight [
	"Answer the height, in pixels, of a control panel button. The original's number."

	^ 20
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonRowCount [
	"Answer how many rows of buttons I stack. Page 144 opens with two, and page 188 adds the row
	Reset has to itself."

	^ 3
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> buttonWidth [
	"Answer the width, in pixels, of a control panel button. The original's number."

	^ 40
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> contentHeight [
	"Answer the height, in pixels, of everything I hold: my counters, stacked with a gap between
	them and a gap above and below, and under them the divider bar and the rows of buttons,
	spaced the same way. A counter takes the size of its caption, so one is built and measured;
	nothing is laid out and nothing is opened. The original never needs this number, since it
	places its counters at fixed offsets from the top of a panel that is always taller than they
	are, and it hangs the divider of page 201 off the bottom edge at an offset of its own."

	| counter |
	counter := LaserGameCounterElement labelled: 'Active Mirrors' digits: 3.
	counter measure: BlExtentMeasurementSpec unspecified.
	^ ((self counterCount * counter measuredExtent y)
	   + ((self counterCount + 3) * self counterGap)
	   + (self buttonRowCount * self buttonHeight)
	   + self dividerHeight
	   + ((self buttonRowCount + 2) * self buttonGap)) ceiling
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> counterCount [
	"Answer how many counters I stack. Page 141 opens with one, page 143 adds the second, and page
	181 the last two."

	^ 4
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> counterGap [
	"Answer the gap, in pixels, between the counters and around the column they sit in. Page 141
	insets its counter four pixels from the top and the left of the panel."

	^ 4
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> dividerHeight [
	"Answer the height, in pixels, of the bar page 201 draws across me above the buttons. The
	original states it as the five pixels between the two offsets of the layout frame it places
	the RectangleMorph with."

	^ 5
]

{ #category : 'constants' }
LaserGameControlPanelElement class >> heightForGrid: aGrid [
	"Answer how tall I am beside a board showing aGrid: as tall as that board, or as tall as what I
	hold when the board is shorter than that. The original has the first half of this only: its
	board is never short enough for the counters to reach the buttons, and a board that was would
	have them overlap."

	^ (LaserGameBoardElement extentForGrid: aGrid) y max: self contentHeight
]

{ #category : 'instance creation' }
LaserGameControlPanelElement class >> on: aGame [
	"Answer a control panel for aGame."

	| panel |
	panel := self new.
	panel game: aGame.
	^ panel
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> activeMirrorsCounter [
	"Answer the counter showing how many mirrors the beam lights. I hold it, so nothing has to
	search for it: page 182 finds it by walking every morph of the game looking for the name
	'activeMirrors'."

	^ activeMirrorsCounter
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> buttonColumn [
	"Answer the column of button rows at the bottom of me. It is my last child, since #rebuild
	adds it after the counters."

	^ self children last
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> buttonRow [
	"Answer the bottom row of buttons. Page 144 counts rows from the bottom, so it is the last row
	of the column."

	^ self buttonColumn children last
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> counterColumn [
	"Answer the column of counters at the top of me. It is my first child, since #rebuild adds the
	counters before the buttons; the rows of the button column are read by position in the same
	way."

	^ self children first
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> fireButton [
	"Answer the button that fires and stops the laser. I hold it, so nothing has to search for it
	by name."

	^ fireButton
]

{ #category : 'updating' }
LaserGameControlPanelElement >> fireButtonLabel [
	"Answer what the fire button says: what a click will do, not what the laser is doing."

	^ self game laserIsActive
		  ifTrue: [ 'Stop' ]
		  ifFalse: [ 'Fire' ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> game [
	"Answer the game this panel controls."

	^ game
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> game: aGame [
	"Control aGame. Setting the game builds the buttons, since a button acts on a game."

	game := aGame.
	self rebuild
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> initialize [
	"A panel is a blank column with its buttons at the bottom left corner, as the original places
	them. A frame layout puts a child where it is aligned, which is what the original's layout
	frames do."

	super initialize.
	self background: LaserGameColors controlPanelColor.
	self layout: BlFrameLayout new
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> laserPathCounter [
	"Answer the counter showing how long the laser beam is. I hold it, so nothing has to search
	for it: page 142 finds it by walking every morph of the game looking for the name
	'laserPath'."

	^ laserPathCounter
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> mirrorsCounter [
	"Answer the counter showing how many mirrors stand on the board. I hold it, so nothing has to
	search for it: page 182 finds it by walking every morph of the game looking for the name
	'mirrors'."

	^ mirrorsCounter
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> movesCounter [
	"Answer the counter showing how many moves the player has made. I hold it, so nothing has to
	search for it: page 143 finds it by walking every morph of the game looking for the name
	'moves'."

	^ movesCounter
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newActiveMirrorsCounter [
	"Answer the counter showing how many mirrors the beam lights: three digits, captioned as on
	page 181. That caption is the longest of the four, and it is why the original widens its panel
	on the same page."

	^ LaserGameCounterElement labelled: 'Active Mirrors' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButton: aLabel action: aBlock [
	"Answer a labelled button of the original's size that evaluates aBlock when it is clicked. The
	original builds a PluggableButtonMorph with a StringMorph label and paints its colors by hand;
	Toplo gives the look and the click, so only the label, the size and the action are left."

	| button |
	button := ToButton labelText: aLabel.
	button extent: self class buttonWidth @ self class buttonHeight.
	button clickAction: aBlock.
	^ button
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButtonColumn [
	"Answer the column of button rows: the bottom left corner of the panel, one gap from both
	edges, the rows one gap apart, the last row against the bottom. Page 144 places each button
	itself with #buttonLayoutFrameForRow:column:, which counts rows from the bottom and columns
	from the left; a column of rows says the same thing, and the third row, page 188's, falls in
	above the other two. Page 201's divider bar is the first child, so it sits above every row
	of buttons, which is where the original's offset from the bottom edge puts it. The cell
	spacing of a linear layout is added around the cells as well as between them, so it is the
	whole of the gap: a margin here would double the gap on the left and push the last button of
	the bottom row against the board."

	| column |
	column := BlElement new.
	column background: BlTransparentBackground new.
	column layout: (BlLinearLayout vertical cellSpacing: self class buttonGap).
	column constraintsDo: [ :aConstraints |
		aConstraints horizontal fitContent.
		aConstraints vertical fitContent.
		aConstraints frame horizontal alignLeft.
		aConstraints frame vertical alignBottom ].
	column addChild: self newPanelDivider.
	column addChild: self newResetRow.
	column addChild: self newNewGameRow.
	column addChild: self newButtonRow.
	^ column
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newButtonRow [
	"Answer the bottom row of buttons: Quit first, then Fire. Page 144 calls them row one, columns
	one and two."

	^ self newRowOfButtons: {
			  quitButton.
			  fireButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newCounterColumn [
	"Answer the column of counters, at the top left corner of the panel, one gap away from both
	edges: the beam length, the move count, the number of mirrors, and the number of mirrors the
	beam lights. Page 143 places the second counter with a layout frame forty-four pixels below
	the first, which is the height of one counter and this gap, and page 181 places the other two
	forty-eight pixels apart again. Here the layout stacks them, so no offset is counted."

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
	column addChild: mirrorsCounter.
	column addChild: activeMirrorsCounter.
	^ column
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newFireButton [
	"Answer the button that fires the laser, or stops it if it is already firing. Its label says
	which of the two a click will do."

	^ self newButton: self fireButtonLabel action: [ self game toggleLaser ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> newGameButton [
	"Answer the button that starts a new game."

	^ newGameButton
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> newGameRow [
	"Answer the middle row of buttons, holding New and Undo. Page 144 calls it row two, so it is
	the third child of the column, which reads from the top and starts with page 201's divider
	bar."

	^ self buttonColumn children third
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newLaserPathCounter [
	"Answer the counter showing how long the laser beam is: three digits, captioned as on page
	141. Three digits hold every path a board of this size can produce."

	^ LaserGameCounterElement labelled: 'Laser Path' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newMirrorsCounter [
	"Answer the counter showing how many mirrors stand on the board: three digits, captioned as on
	page 181."

	^ LaserGameCounterElement labelled: 'Mirrors' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newMovesCounter [
	"Answer the counter showing how many moves the player has made: three digits, captioned as on
	page 143."

	^ LaserGameCounterElement labelled: 'Moves' digits: 3
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newNewGameButton [
	"Answer the button that throws the board away and deals a new one: page 144's
	#makeNewGameButton."

	^ self newButton: 'New' action: [ self game newGame ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newNewGameRow [
	"Answer the row above it, holding the New button on the left and Undo on its right. Page 144
	calls them row two, column one and page 186 adds row two, column two."

	^ self newRowOfButtons: {
			  newGameButton.
			  undoButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newPanelDivider [
	"Answer the bar that separates my counters from my buttons: as wide as I am but for a gap on
	each side, five pixels tall, filled with the gradient of page 201. The original builds a
	RectangleMorph with a raised border and a GradientFillStyle, and hangs it off the bottom edge
	of the panel at an offset counted in pixels from there; here it is a child of the button
	column, so it stands above the buttons wherever they end up."

	| divider |
	divider := BlElement new.
	divider background: (BlLinearGradientPaint vertical stops: {
					 (0 -> LaserGameColors panelDividerDarkColor).
					 (1 -> LaserGameColors panelDividerLightColor) }).
	divider constraintsDo: [ :aConstraints |
		aConstraints horizontal exact:
			LaserGameElement panelWidth - (2 * self class buttonGap).
		aConstraints vertical exact: self class dividerHeight ].
	^ divider
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newQuitButton [
	"Answer the button that closes the game. The original sends #delete to its morph."

	^ self newButton: 'Quit' action: [ self game quit ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newResetButton [
	"Answer the button that puts the board back where it started: page 188's #makeResetButton.
	Like Undo it takes no state block, its label never changing."

	^ self newButton: 'Reset' action: [ self game reset ]
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newResetRow [
	"Answer the top row of buttons, holding Reset alone. Page 188 calls it row three, column one.
	Its button is built here and not kept in an instance variable: a tenth would trip
	ReExcessiveVariablesRule, whose limit is ten, and #resetButton reads it back from the row the
	way #buttonRow and #newGameRow read the rows from the column."

	^ self newRowOfButtons: { self newResetButton }
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newRowOfButtons: aCollection [
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
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> newUndoButton [
	"Answer the button that takes the last move back: page 186's #makeUndoButton. The original
	passes action: #undo state: nil, the state being the block a toggling button reads its label
	from; Undo never changes its label, so only the action is left."

	^ self newButton: 'Undo' action: [ self game undo ]
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> panelDivider [
	"Answer the bar page 201 draws across me above the buttons. It is the first child of the
	button column, which reads from the top."

	^ self buttonColumn children first
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> quitButton [
	"Answer the button that closes the game."

	^ quitButton
]

{ #category : 'initialization' }
LaserGameControlPanelElement >> rebuild [
	"Replace what I hold with fresh counters at my top and fresh buttons at my bottom, both acting
	on my game, and take the width of a panel and the height of the board beside me, or the height
	of what I hold when that is more. The counter column goes in first and the button column
	second, which is the order #counterColumn and #buttonColumn read them back in."

	self removeChildren.
	quitButton := self newQuitButton.
	fireButton := self newFireButton.
	newGameButton := self newNewGameButton.
	undoButton := self newUndoButton.
	laserPathCounter := self newLaserPathCounter.
	movesCounter := self newMovesCounter.
	mirrorsCounter := self newMirrorsCounter.
	activeMirrorsCounter := self newActiveMirrorsCounter.
	self addChild: self newCounterColumn.
	self addChild: self newButtonColumn.
	self extent: LaserGameElement panelWidth
		@ (self class heightForGrid: self game grid).
	self updateCounters
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> resetButton [
	"Answer the button that puts the board back where it started. It is the only button of its
	row, and the only one I do not hold."

	^ self resetRow children first
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> resetRow [
	"Answer the top row of buttons. Page 144 counts rows from the bottom and this is the third of
	them, so it is the second child of the column, which reads from the top and starts with page
	201's divider bar."

	^ self buttonColumn children second
]

{ #category : 'accessing' }
LaserGameControlPanelElement >> undoButton [
	"Answer the button that takes the last move back."

	^ undoButton
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateCounters [
	"Show how long the beam is while the laser fires, and nothing while it does not, show how many
	moves have been made, and show how many mirrors stand on the board and how many of them the
	beam lights. This is page 143's #updateCounters as page 182 extends it, which has to find each
	display among the morphs of the game first; I hold all four. Only the beam counter is ever
	bright: it alone says whether the laser is on."

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
		value: self game moves.
	self mirrorsCounter
		highlighted: false;
		value: self game grid numberOfMirrors.
	self activeMirrorsCounter
		highlighted: false;
		value: self game grid numberOfActiveMirrors
]

{ #category : 'updating' }
LaserGameControlPanelElement >> updateFireButtonLabel [
	"Make the fire button say what a click will do now. The original has to find the button among
	its submorphs by name; I hold it in an instance variable."

	self fireButton labelText: self fireButtonLabel
]
