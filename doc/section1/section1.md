# Introduction

This book builds a game, one test at a time.

The game is a puzzle. A laser fires into a grid of cells, bounces off mirrors the player can turn
and push around, and should end up hitting a target. The player's job is to get the beam to the
target by the longest route they can find.

![The game, finished](figures/031.jpg)

Building it is an excuse to practise three things, and those three things are what this book is
really about.

**Writing the test first.** Every piece of behaviour in the game arrives twice: first as a test
that fails, then as the code that makes it pass. By the end you will have written more than two
hundred of them, and you will have felt why they are worth writing — not because a book said so,
but because they catch you being wrong, over and over, in the next chapter.

**Recognising a shape in the code.** Some problems have been solved so many times that their
solutions have names. When the game needs one — asking an object what it is instead of testing its
class, letting two objects decide something together, building an object lazily, sharing the setup
of a test — this book stops and names it, says why that shape fits, and shows what the clumsy
version would have looked like.

**Hunting the bug you just made.** Code goes wrong. A good part of this book is spent in the
debugger, reading a failing assertion, or staring at a game that looks right and is not. These
chapters are the ones kept most carefully, because watching someone find a bug teaches more than
watching them avoid one.

The graphics are built with **Bloc**, which is how you build a user interface in Pharo today. No
previous experience with it is assumed.

## Who this book is for

Someone who is new to Pharo. Possibly new to programming altogether.

You do not need to know Smalltalk. Vocabulary is explained the first time it appears, and the first
chapters go slowly. You do need a Pharo 13 image, and the patience to type the code rather than
copy it — the typing is where the learning happens.

The pace is deliberate. Every step is shown, including the wrong ones, because a tutorial where
nothing goes wrong teaches you nothing about what to do when something does.

## Where the game comes from

In 2007 Stephan Wessels wrote the Laser Game as a tutorial for Squeak, and it became one of the
best-loved teaching projects in that community. Pharo is a descendant of Squeak, and the game has
been rebuilt here in modern Pharo: the model is much as he designed it, and the teaching order is
his. The graphics are new, because the toolkit is. Stéphane Ducasse made an earlier Pharo
adaptation, which this book also draws on.

Thanks are owed to both of them.

## What this book does not cover

The Pharo community has good books on these already, and this one points at them rather than
repeating them:

- installing Pharo and setting up an image — see the **Pharo by Example** book at
  <https://books.pharo.org>;
- saving your code with Git, from inside Pharo — see the booklet **Managing Your Code with
  Iceberg**, at <https://books.pharo.org>;
- packaging an application for someone else to run.

## Conventions used in this book

A class name or a method name in the narrative looks like `Grid` and `rotateClockwise`.

A method is shown with the class it belongs to in front of it:

```smalltalk
MyClass >> myMethod

	^ 1 + 2
```

> **Note.** Do not type the `MyClass >>` part. It tells you which class to select in the browser
> before you type the method. What you actually type is just the method:
>
> ```smalltalk
> myMethod
>
> 	^ 1 + 2
> ```

The caret `^` means *answer this*. The method above answers `3` to whoever called it.

A line of code to run on its own — in a Playground, with the result printed — is shown without a
class in front of it:

```smalltalk
3 + 4
```

Some methods are written more than once. You write a first version that does what the chapter in
front of you needs, and a later chapter replaces it when the game asks for more. The text always
says when that happens, and a version that a later chapter supersedes is shown without syntax
colouring, so a coloured block is always the final one. The last version of a method in the book is
the one the finished game holds.

## Getting the finished code

You can write every line of the game yourself, which is the point of the book. If you would rather
read the finished version alongside it, this loads it into a Pharo 13 image:

```smalltalk
Metacello new
	baseline: 'LaserGame';
	repository: 'github://rvillemeur/PharoLaserGameTutorial/src';
	onConflictUseIncoming;
	load
```

Then evaluate `LaserGameElement openExample` to play.

## License

Copyright 2007 Stephan Wessels. Copyright 2014 Stephan Wessels and Stéphane Ducasse.

This book is available under the Creative Commons Attribution-ShareAlike 3.0 Unported license.

*You are free:*

- to Share — to copy, distribute and transmit the work;
- to Remix — to adapt the work.

*Under the following conditions:*

- **Attribution.** You must attribute the work in the manner specified by the author or licensor,
  but not in any way that suggests they endorse you or your use of the work.
- **Share Alike.** If you alter, transform, or build upon this work, you may distribute the result
  only under the same, a similar, or a compatible license.

For any reuse or distribution you must make the license terms clear to others; a link to
<http://creativecommons.org/licenses/by-sa/3.0/> is the easiest way. Any of these conditions can be
waived with permission from the copyright holder, and nothing in the license impairs the author's
moral rights.

![Creative Commons BY-SA](figures/CreativeCommons-BY-SA.png)

# Game Overview

Before writing any code, let us be clear about what the game does. Not precisely — the design will
change several times as we go, and watching it change is part of the point — but clearly enough to
start.

The game is played on a grid of square cells. A laser fires into the grid from below the first
column, and travels in a straight line until something stops it or turns it. Each cell is one of
three things:

- a **blank cell**, which the beam passes straight through;
- a **mirror cell**, which deflects the beam ninety degrees. A mirror leans one of two ways, left
  or right;
- the **target cell**, drawn as a circle, which lights up when the beam reaches it.

If the beam runs into the edge of the grid, its path simply ends there.

![(a) Starting from its origin, the beam reaches the target. (b) Rotating one mirror changes the
path of the beam.](figures/2-Concept-MirrorRotation.png)

The game lays out the mirrors for you, in random places and random orientations. In figure (a)
above, that random layout happens to send the beam to the target. The player's two moves are:

- **rotate a mirror**, turning it ninety degrees, which changes where it sends the beam — figure
  (b);
- **push a mirror** one cell up, down, left or right. A mirror cannot be pushed through the edge of
  the grid, nor into another mirror, nor into the target.

So a game that already works is not very interesting. What makes it a puzzle is the second goal:
get the beam to the target by the *longest* path you can. Here is one sequence of moves doing
exactly that. First, slide a mirror one cell to its left:

![Finding a longer path: first move, slide a mirror.](figures/2-LongerPath1-Slide.png)

The beam now misses the target, which is fine — a move is allowed to break the path. Next, rotate
another mirror:

![Finding a longer path: second move, rotate a mirror.](figures/2-LongerPath2-Rotate.png)

And one last move brings the beam back to the target, by a route longer than the one we started
with:

![Finding a longer path: last move, slide a mirror.](figures/2-LongerPath3-Slide.png)

That is the whole game. As we build it we will add things that let the player see what is
happening: a count of how many cells the beam crosses, a count of moves made, an undo button, a
reset button.

Now let us find the objects.

# Discovery of Objects

When we look over the game drawings and think about what objects our game may need, a few come immediately to mind. There must be some kind of grid and several cells. There are different kinds of cells too.

Cells and a grid are obvious objects of the game and we will probably discover other objects as we explore a little. It is perfectly fine to explore and then throw code away if we later learn we are not heading in the right direction.

Exploring with objects is easy to do in Pharo. Thinking about a design is time well spent, but you also need to dive in sometimes to understand the objects your design needs. As someone once said, you can read about swimming all you want, but you will never learn about swimming until you actually dive in the water.

The water here is safe. The worst we could do is write some code and throw it away, and that is nothing to worry about: Pharo keeps a version history of every method, so you can review what you had before and put it back in a couple of clicks. Development in Pharo encourages experimentation and quick idea exploration.

## The grid

The grid holds our cells. It also contains the source of our laser beam. Let us go with the idea that the player asks the grid to fire the laser beam.

## The cells

We identify three kinds of cell.

1. Blank, that is to say empty
2. Target
3. Mirror

The basic responsibility of a cell concerns what happens to the laser beam when it enters the cell. The mirror cells also need to know something about their orientation: a mirror cell can be thought of as leaning left or leaning right.

If we dig a little deeper into our understanding of these cells we can imagine that each cell has four internal line segments, something like an LED clock. We use these segments to show the path of the laser beam. Let us explore how that works for each cell type.

### The blank cell

![028](figures/028.jpg)

We label the four segments `#north`, `#east`, `#south` and `#west`. If the laser beam enters by the `#west` segment then we know the `#east` segment lights up. If it enters by `#south` then `#north` lights up.

### The mirror cell

![029](figures/029.jpg)

![030](figures/030.jpg)

Depending on the orientation of the mirror we can also determine the path of the laser beam through the cell. We identify the corresponding segments using the same technique.

For the left leaning mirror cell, a beam entering by the `#west` segment leaves by the `#south` one. For the right leaning mirror cell, a beam entering by the `#west` segment leaves by the `#north` one.

### The target cell

![031](figures/031.jpg)

In the case of the target cell no other segment lights up. The laser beam ends its path here.

## Identifying the classes

Visually, each of the three cell types renders differently. So they have some things in common and some things that are unique to each. Let us define our initial classes to be:

* `Grid`
* `BlankCell`
* `MirrorCell`
* `TargetCell`

We suspect that there may be an abstract class that unifies the behavior common to the three cells. For now let us not do that, and stick with these classes until the need for another one actually exists.

Instances of `Grid` are responsible for the board and the overall management of the cells. Instances of `BlankCell` are the default condition in our grid. `MirrorCell` instances are not as frequent and are also contained in the grid. There is one `TargetCell` instance in the grid.

## A package for the model

First we should define a package to hold our classes. Classes that work together belong together, and a package is what you load, save and commit as a whole.

Open a System Browser, right-click the package list, choose *New package* and name it `Laser-Game`.

Pharo groups code at two levels. A **package** is the unit you load, save and commit as a whole. Inside a package, **tags** sort the class list into groups; a tag is a convenience for whoever reads the class list and has no effect on how the code runs. This book uses one package, `Laser-Game`, with the tags `Model` and `Graphics`, and adds a second package, `Laser-Game-Tests`, once there are enough tests to be worth keeping apart.

> **Note.** Until that split, which is the subject of the chapter *Tests In Their Own Package*, everything lives in `Laser-Game`.

## Creating the model classes

With `Laser-Game` selected, the browser shows a class creation template in its bottom pane. Fill it out and accept it with the context menu or with `Cmd-S` / `Alt-S`. Every class needs a superclass; the easiest thing to do for now is to subclass `Object`. We refactor that later, once the design structure is fleshed out.

```
Object << #Grid
	slots: {};
	tag: 'Model';
	package: 'Laser-Game'
```

> **Note.** Reading that definition: `Object << #Grid` says *make a class named `Grid` whose superclass is `Object`*, and answers a class builder that the three following messages configure. `slots: {}` gives the class no instance variables — no state of its own — for now. `tag: 'Model'` files it under `Model` in the class list, and `package: 'Laser-Game'` says which package owns it. Accepting the definition in the browser is what actually creates the class.
>
> This is the definition as it stands at this point in the book. `Grid` collects six instance variables as we go, and its finished definition is in the chapter *Grid*.

Then define the three cell classes the same way.

```
Object << #BlankCell
	slots: {};
	tag: 'Model';
	package: 'Laser-Game'
```

```
Object << #MirrorCell
	slots: {};
	tag: 'Model';
	package: 'Laser-Game'
```

```
Object << #TargetCell
	slots: {};
	tag: 'Model';
	package: 'Laser-Game'
```

> **Note.** All three definitions are rewritten before this section is over. `MirrorCell` gains a `leansLeft` instance variable in *Enhancing MirrorCell*, and that same chapter puts the three cells under a common superclass `Cell`, which is where the state they share ends up.

Before implementing the behavior of our model we define tests that specify that behavior. The tests help us make sure our implementation is correct, and they document the behavior in a way that can be checked automatically.

# Test Driven Development

We use the SUnit testing framework to implement the game model. We will most likely not write unit tests for the behavior of the user interface, which is tedious to do; but there is plenty we can accomplish by driving the development of the game model from unit tests.

We are not too attached to how we code the very first few lines. One approach many people use is to begin with the tests, even to the point of having no objects to test when the first test is written. Another is to implement some basic model and drive it from that point forward with tests.

What matters is what unit tests accomplish:

1. They help us develop our objects, because writing a test that exercises an object's API makes us consider how that object will be used.
2. They provide a consistency check as we add and evolve code. This tells us quickly when and where we break something that already worked.

Good unit tests capture your requirements and help you as you implement a design. Often, when you write a unit test, you are forced to think about your design as if it were finished.

## A package for the tests

The `BlankCell` is an excellent place to begin. We want a package to hold our test classes, which in turn hold the methods defining our test cases.

Right-click the package list, choose *New package* and name it `Laser-Game-Tests`. The newly created package is selected and a class definition template appears in the code pane.

By convention a test class is named after the class it tests, with `Test` or `TestCase` on the end. This book uses `TestCase`, so the class we are about to write is `BlankCellTestCase`.

```smalltalk
TestCase << #BlankCellTestCase
	slots: {};
	package: 'Laser-Game-Tests'
```

> **Note.** Pay attention to the superclass. A test class must be a subclass of `TestCase`, and it is easy to overlook. If you got it wrong, go back, correct it and accept the definition again.

## The first test

Within a class, methods are sorted into *protocols*, shown in the third pane of the browser. Our tests go in a protocol named `tests`. Select the class, right-click the protocol list, choose *Add protocol*, type `tests` and accept.

> **Note.** Make sure the browser is showing instance methods and not class methods, that is to say that the *Class side* button under the class pane is not pressed. The methods we write now are sent to instances.

Our first test is a simple check that a cell is off by default. Select the `tests` protocol and replace the method template with the test.

```smalltalk
BlankCellTestCase >> testCellOnState

	| cell |
	cell := BlankCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
```

> **Note.** Two things about that test. Its name begins with `test`, which is how the test framework recognises a test method — a method named anything else is never run. And `self shouldnt: [ cell isOn ]` and `self deny: cell isOn` both assert that something is false: `shouldnt:` takes a block, `deny:` takes the value. Either is correct, and later tests in this book mostly use `deny:`.

If the method lands in a protocol named *as yet unclassified*, no protocol was selected when you accepted it. Drag it onto `tests` and it moves.

Before we can run this test we need definitions of `isOn` and `isOff`, so that the methods exist when the test sends them. For now we write dummies that both answer `false`.

Select `BlankCell` in the `Laser-Game` package, add a protocol `testing` and accept the two methods below.

```
isOff
	"dummy definition"
	^ false
```

```
isOn
	"dummy definition"
	^ false
```

> **Note.** These two are deliberately wrong and they do not survive the chapter *Getting Our First Test To Pass*, which gives them their real bodies. The finished code has both on `Cell`, not on `BlankCell`.

While you type, the top right corner of the code pane is tinged with orange: the edit has not been compiled yet. Accepting the method compiles it and the tinge goes away. Each time you edit an existing method and accept it, the old body is replaced by the new one.

## Running the test

Even though we know `isOn` and `isOff` are wrong, we should run `testCellOnState`. Enough code has been written that we want to be sure `BlankCell` objects are created correctly and that the test produces the wrong result we are expecting.

* Open the Test Runner from the World menu.
* Filter the package list by typing `Laser` in the input field at the top left.
* Select the package `Laser-Game-Tests` and the class `BlankCellTestCase`.
* Press *Run Selected*.

> **Note.** If `Laser-Game-Tests` does not appear in the Test Runner at all, you probably made a mistake creating the test class. `BlankCellTestCase` must be a subclass of `TestCase`.

There is a second way to run tests, from the System Browser itself. Next to the name of a test method is a small circle that shows the result of the last run: green for a pass, yellow for a failure, red for an error. Click it and that one test runs. There is a similar circle next to the test class, and clicking it runs every test of the class.

## Getting to the error

The Test Runner reports one failure and lists the method that failed. Click the failed test and a debugger opens on it.

Navigate the call stack by clicking the lines of the top pane, and the variables listed below change with the selected frame. You can inspect any of them from their context menu, and you can select any piece of code in the method and inspect or evaluate it. Later we show that you can also change the method and carry on from where you were.

# Getting Our First Test To Pass

Our first test is currently this one.

```smalltalk
BlankCellTestCase >> testCellOnState

	| cell |
	cell := BlankCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
```

We knew it would fail before we ran it, because we have not really defined `isOff` or `isOn`. Following the LED clock analogy, to know whether a cell is on we have to look at its four internal line segments: if any of them is lit, the cell is on.

## Holding the segments

Before we can finish `isOn` and `isOff` we need somewhere to keep the segments. We add an instance variable holding a dictionary that maps each side to whether it is lit.

Select `BlankCell`, edit its definition to add the slot and accept.

```
Object << #BlankCell
	slots: { #activeSegments };
	tag: 'Model';
	package: 'Laser-Game'
```

Accepting this does not only change what new instances look like: every `BlankCell` that already exists in the running image gets the new instance variable too.

Now use the refactoring tools to write the accessors. Select the class, then *Refactoring > Instance variables > Accessors*, pick `activeSegments` from the list and accept the proposed changes. Two methods appear in the `accessing` protocol.

Since the variable holds a dictionary, rename the argument of the setter to say so. That changes nothing for the compiler; it is documentation.

> **Note.** The two accessors are quoted in the chapter *Enhancing MirrorCell*, which is where they end up: they move to the common superclass `Cell` along with the instance variable itself.

> **Note.** Writing accessors is not mandatory, especially for private state that only the methods of the class touch. Different schools propose different practices with different trade-offs. We write them here for uniformity throughout the book.

## Initializing instances

The new variable has to be initialized. Add an `initialization` protocol to `BlankCell` and define the method that fills the dictionary; every side starts off.

```
initializeActiveSegments
	self activeSegments: Dictionary new.
	self activeSegments at: #north put: false.
	self activeSegments at: #east put: false.
	self activeSegments at: #south put: false.
	self activeSegments at: #west put: false.
```

That method has to be called. There are two ways: specialize the default `initialize` method, or initialize lazily. Let us do the first.

```
initialize
	super initialize.
	self initializeActiveSegments
```

> **Note.** Both of these end up on `Cell`; `initializeActiveSegments` is quoted from the image in *Enhancing MirrorCell*, along with the `initialize` that calls it.

In Pharo, `new` sends `initialize` to the newly created instance, so overriding `initialize` is how a class customizes its own creation. The first thing our `initialize` does is `super initialize`. That is a good habit: since we are overriding a method, it is conceivable that we are hiding an important initialization somewhere up the hierarchy, and calling `super` first gives every superclass the chance to do its part.

### An alternative: lazy initialization

Another approach initializes the variable the first time it is read. The getter checks whether the variable is still `nil` and fills it if it is, and the other methods of the class go through the getter instead of touching the variable.

```
activeSegments
	^ activeSegments ifNil: [ self initializeActiveSegments ]
```

Lazy initialization is useful in a live environment where instance variables are added to objects that already exist: their `initialize` has already run once and running it again would be awkward. It also helps when initializing everything at creation time costs too much, by paying for each variable only when it is really needed, at the price of one `ifNil:` check per access. Which approach wins depends on the application, and that is a question for a profiler.

> **Note.** This game uses both. The cells initialize eagerly, as above. the game window's `grid` method, written much later in *A default board worth playing on*, is lazy, so that a game built with no board deals itself the standard one the first time it is asked for it.

## Getting the test green

Now we can write `isOn` for real. `activeSegments` answers a dictionary whose values say which segments are lit; as soon as one of them is true the cell is on.

```
isOn
	^ self activeSegments values anySatisfy: [ :each | each = true ]
```

Since the values are booleans you could equivalently write `anySatisfy: [ :each | each ]`. Once `isOn` is defined, `isOff` follows naturally.

```
isOff
	^ self isOn not
```

Rerun the test. It passes.

> **Note.** Both methods are quoted from the image in *Enhancing MirrorCell*, where they live on `Cell`.

## Adding a class comment

It is not good practice to leave classes undocumented, and the browser says so with a mark against the class name until you write a comment. Select `BlankCell`, press the *Comment* button and write what the class is for.

```
I am a `Cell` the beam crosses in a straight line. A beam entering from the west leaves by the east, one entering from the south leaves by the north, and the same in reverse.

I add no state to `Cell`. All I do is fill `exitSides` in `initializeExitSides`, which is what makes a cell blank. Every empty square of the board holds one of me.
```

Accept it and the mark is gone.

# Saving Your Work

Your code lives in the image, and an image is an easy thing to lose. Saving means putting your packages somewhere outside it, so that you can load them into a fresh image or go back to an earlier state of the project. This is a good moment to set that up, because the tests are green.

Pharo does it with **Iceberg**, which is part of the standard image and commits your packages to a Git repository. It writes each package out as a directory of readable text files, one per class, so the game can be read, diffed and merged with the usual Git tools.

We will not explain Iceberg here, because a book already does it well and is kept up to date with the image: the booklet *Managing Your Code with Iceberg*, from <https://books.pharo.org>. It covers cloning a repository, putting a package into it, committing, branching, and the traps you can fall into.

One habit matters more than the tool, and this book follows it from here on:

**Commit when the tests are green.** Then every state you can go back to is a state in which the game worked.

# Coding in the Debugger

Some developers write the test first, let it fail, and then define the methods it needs from inside the debugger. Why? Because in the debugger you work against live objects, in the context of the running program. You write code, execute it against those objects, save it and carry on from where you stopped. Let us see how that is done.

## Setting up the context

Temporarily redefine `isOn` and `isOff` on `BlankCell` so that they stop instead of answering.

```
isOff
	"dummy definition"
	^ self halt
```

```
isOn
	"dummy definition"
	^ self halt
```

`self halt` is the normal way to set a breakpoint: when it runs, a debugger opens. Here we are only using it to produce something to fix on the fly.

## Coding in the debugger

Run `testCellOnState`. The debugger opens on the halt. Navigate the stack and find the method that raised it, usually near the top of the list; here it is `isOff`, with the `halt` highlighted.

Now, in the debugger itself, restore `isOff` to what it should be and accept it.

```
isOff
	^ self isOn not
```

The moment you accept, the method is recompiled and the debugger re-enters it: the highlight moves to the `isOn` send, which is where execution resumes from. Press *Proceed* and the `halt` in `isOn` is reached in its turn. Restore that one too.

```
isOn
	^ self activeSegments values anySatisfy: [ :each | each = true ]
```

Press *Proceed* and the test finishes green.

> **Note.** The debugger does more than edit existing methods. When execution reaches a message no object understands, the debugger offers to create the method for you: it asks which class it belongs to and which protocol to file it under, then steps into the new method with a `shouldBeImplemented` body waiting to be replaced. We use that in the next chapter.

## Conclusion

We do not repeat this process in the rest of the tutorial, but we use it daily. It is one of the things Pharo does that is hard to explain and hard to give up, and we can only encourage you to try it.

# Improving Our Model

Now that the first test is green we can add behavior, and we do it test first.

## Asking whether one segment is on

We want to ask a cell whether the segment of a given side is lit. A new cell has all of them off, so the test is simple.

```smalltalk
BlankCellTestCase >> testCellSegmentState

	| cell |
	cell := BlankCell new.
	self shouldnt: [ cell isSegmentOnFor: #north ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
```

When you accept this, the compiler does not know `isSegmentOnFor:` and asks you to confirm, correct or cancel the unknown selector. Confirm: we mean it, the method does not exist yet.

Run the test. The debugger opens with a message-not-understood: the receiver is the `BlankCell` held by `cell` and it does not understand `isSegmentOnFor:`. Press *Create*, choose `BlankCell` as the class and `testing` as the protocol. The debugger steps into the method it just created for you, whose body is `self shouldBeImplemented` — a placeholder that opens the debugger again if you walk away and leave it there. Replace it and accept.

```
isSegmentOnFor: aSymbol
	^ self activeSegments at: aSymbol
```

> **Note.** This method ends up on `Cell`, where it is quoted from the image in the next chapter. The test above, on the other hand, is quoted from the image as it stands.

## Where the beam leaves

We know how to look at one segment. Now we need to know which side a beam leaves by, given the side it came in from.

```smalltalk
BlankCellTestCase >> testCellExitSides

	| cell exit |
	cell := BlankCell new.
	exit := cell exitSideFor: #north.
	self assert: exit equals: #south.

	exit := cell exitSideFor: #east.
	self assert: exit equals: #west.

	exit := cell exitSideFor: #south.
	self assert: exit equals: #north.

	exit := cell exitSideFor: #west.
	self assert: exit equals: #east
```

> **Note.** The message is `exitSideFor:`, not `exitFor:`, because it answers a *side*. Saying so in the name saves the reader a trip into the method body. And the distinction the name draws is the one this test makes: a beam entering by the north side of a blank cell leaves by the south side. This is about sides, not about directions.

The cell needs somewhere to keep that mapping, so `BlankCell` gains a second instance variable, `exitSides`, holding a dictionary from the side a beam enters by to the side it leaves by. Add the slot to the class definition and create its accessors the way you did for `activeSegments`.

```
Object << #BlankCell
	slots: { #activeSegments . #exitSides };
	tag: 'Model';
	package: 'Laser-Game'
```

Then fill the dictionary. This is the method that makes a cell blank: north to south, east to west, and the same in reverse.

```smalltalk
BlankCell >> initializeExitSides
	self exitSides: Dictionary new.
	self exitSides at: #north put: #south.
	self exitSides at: #east put: #west.
	self exitSides at: #south put: #north.
	self exitSides at: #west put: #east.
```

And call it from `initialize`.

```smalltalk
BlankCell >> initialize
	super initialize.
	self initializeExitSides.
```

Finally the lookup itself.

```
exitSideFor: aSymbol
	^ self exitSides at: aSymbol
```

> **Note.** `initializeExitSides` and `initialize` are quoted from the image and stay on `BlankCell` for good: filling `exitSides` is exactly what a subclass of `Cell` is for. `exitSideFor:` moves up to `Cell` in the next chapter.

## Telling the cell the beam entered

The last piece of behavior for now is to tell a cell that the laser beam has entered it from a given side. The cell should light the side the beam arrived by and the side it leaves by.

```smalltalk
BlankCellTestCase >> testCellLaserActivity

	| cell |
	cell := BlankCell new.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self assert: (cell isSegmentOnFor: #south).
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
```

Run it, and create the method from the debugger as before.

```
laserEntersFrom: aSymbol
	| exit |
	self activeSegments at: aSymbol put: true.
	exit := self exitSideFor: aSymbol.
	self activeSegments at: exit put: true.
```

> **Note.** You could go one step further and hide the two dictionary writes behind methods named `setSegmentOnFor:` and `setSegmentOffFor:`, then write `laserEntersFrom:` in terms of those. Nothing else in the game ever needs to light one segment on its own, so this book stops here — but the idea is worth keeping: a method reads better when it says *what* it does than when it shows *how* it stores things.

## A word about directions

The design we have proposed uses symbols to represent the sides. That is fine, but it has a weakness worth naming: symbols are carried around everywhere and nothing checks them. Mistype `#west` as `#vest` and the system quietly stops working.

One cheap improvement is to define the four symbols in one place, as class methods answering `#north`, `#south`, `#east` and `#west`, and use those everywhere instead of the literals. A good acid test of that design is that you could replace the symbol in each method by a number and the system would carry on working.

A stronger answer is to make the directions real objects. That is where this game ends up: *Push A Cell* introduces a `GridDirection` hierarchy with one subclass per direction, each knowing its own vector and the side of a cell a beam travelling that way enters by. It removes the last case statement from the beam path, and it is a good example of what you get for making a value into an object.

# Enhancing MirrorCell

A `MirrorCell` differs from a `BlankCell` in that it carries a mirror, and the mirror can be oriented to send the laser beam in different directions. Let us start with the class comment.

```
I am a `Cell` with a mirror on one of its diagonals. `leansLeft` says which one. When I lean left the mirror runs from my top left corner to my bottom right one, and a beam entering from the north leaves by the east. When I lean right it runs from my top right corner to my bottom left one, and the same beam leaves by the west.

`leanLeft` and `leanRight` set the lean and all four exit sides together, which is why `rotate` uses them instead of flipping `leansLeft` on its own. A lean changed without its exit sides is a bug that is hard to see: the mirror is drawn on the new diagonal while the beam still leaves by the old side.

`rotateClockwise` and `rotateCounterClockwise` are both `rotate`. A diagonal has only two positions, so either direction lands on the other one.
```

> **Note.** That is the comment the class ends up with. `rotate` and the two rotate messages do not exist yet — they arrive later in this chapter — so write the first paragraph now and come back for the rest.

## Capturing the orientation

We need a way to hold the orientation of the mirror. The default is that the mirror leans left unless something says otherwise, and we need to be able to ask which way it leans.

Add the instance variable `leansLeft` to the class definition and create its accessors.

```
Object << #MirrorCell
	slots: { #leansLeft };
	tag: 'Model';
	package: 'Laser-Game'
```

Then add a `testing` protocol with the two questions.

```smalltalk
MirrorCell >> isLeft
	^self leansLeft
```

```smalltalk
MirrorCell >> isRight
	^self isLeft not
```

## Introducing a common ancestor

That much was straightforward. But what about the behavior a mirror shares with a blank cell? It needs `laserEntersFrom:`, `exitSideFor:` and `isSegmentOnFor:` just as much, and therefore the instance variables `activeSegments` and `exitSides` too. Only the way the exit sides are filled differs.

We want to reuse that code, not copy it. Nearly the same state and nearly the same behavior in two classes is a sign that we can do better, and this is exactly the case an abstract superclass is for.

First create the class `Cell`.

```
Object << #Cell
	slots: {};
	tag: 'Model';
	package: 'Laser-Game'
```

And give it a comment.

```
I am the model of one square of the laser game board. I know where I sit (`gridLocation`, a `column @ row` point), which side a beam leaves by when it enters from a given side (`exitSides`, a dictionary keyed by `#north`, `#east`, `#south` and `#west`), and which of those sides carry light right now (`activeSegments`).

I am abstract: a subclass fills `exitSides` in `initializeExitSides`. `BlankCell` lets a beam straight through, `MirrorCell` turns it a quarter turn, `TargetCell` swallows it and lights up.

`rotateClockwise` and `rotateCounterClockwise` do nothing here, so a click on a cell that cannot turn is harmless. `MirrorCell` overrides both.

`printOn:` prints where I am and whether I am on; a subclass adds its own detail by overriding `printDetailsOn:`. Inspect me and the Sides tab lists my four sides with the side a beam leaves by and whether that side is lit.
```

> **Note.** Again, that is the comment the class ends up with. The last two paragraphs describe `printOn:` and the inspector tab, which we write later, and `gridLocation` is the instance variable `Cell` gains in the chapter *Grid*. At this point it has neither, so write what is true now and come back.

Pharo comes with a powerful tool for restructuring code: the refactoring engine, reachable from the *Refactoring* item of the class list context menu in the System Browser. A refactoring is a behavior preserving transformation, which is to say that the program does the same thing after it as it did before. Smalltalk had the first working refactoring engine of any language, and moving code around a hierarchy is what it is best at.

### Inheriting from Cell

Change the definitions of `BlankCell` and `MirrorCell` so that both subclass `Cell`. The browser then indents them under it. Rerun your tests; they still pass.

```smalltalk
Cell << #MirrorCell
	slots: { #leansLeft };
	tag: 'Model';
	package: 'Laser-Game'
```

```smalltalk
Cell << #BlankCell
	slots: {};
	tag: 'Model';
	package: 'Laser-Game'
```

### Moving the instance variables up

Both cells manage which segments are on and how a beam crosses them, so `activeSegments` and `exitSides` belong to the superclass. Bring up the context menu on `BlankCell`, choose *Refactoring > Instance variables > Pull up* and pick `activeSegments`, then do the same for `exitSides`.

Both variables move to `Cell` and `BlankCell` is left with none of its own, which is what the definition above already shows.

```
Object << #Cell
	slots: { #activeSegments . #exitSides };
	tag: 'Model';
	package: 'Laser-Game'
```

What is nice about using the refactorings rather than editing by hand is that they eliminate a class of mistakes. A subclass could already have an instance variable of that name, for instance, and the tool notices.

### Moving the methods up

The accessors and the behavior follow the instance variables. Select, in `BlankCell`, the accessors `activeSegments`, `activeSegments:`, `exitSides` and `exitSides:`, the testing methods `isOn`, `isOff` and `isSegmentOnFor:`, and the operations `laserEntersFrom:` and `exitSideFor:`, then choose *Refactoring > Push up* from the selection. All of them move to `Cell` at once, and here is where they end up.

```smalltalk
Cell >> activeSegments
	"Answer the value of activeSegments"

	^ activeSegments
```

```smalltalk
Cell >> activeSegments: aDictionary
	"Set the value of activeSegments"

	activeSegments := aDictionary
```

```smalltalk
Cell >> exitSides
	"Answer the value of exitSides"

	^ exitSides
```

```smalltalk
Cell >> exitSides: aDictionary
	"Set the value of exitSides"

	exitSides := aDictionary
```

```smalltalk
Cell >> isOn
	^self activeSegments values anySatisfy: [:each | each = true]
```

```smalltalk
Cell >> isOff
	^self isOn not
```

```smalltalk
Cell >> isSegmentOnFor: aSymbol
	^self activeSegments at: aSymbol
```

```smalltalk
Cell >> exitSideFor: aSymbol
	^self exitSides at: aSymbol
```

```smalltalk
Cell >> laserEntersFrom: aSymbol
	| exit |
	self activeSegments at: aSymbol put: true.
	exit := self exitSideFor: aSymbol.
	self activeSegments at: exit put: true.
```

Your tests should still pass.

### Splitting the initialization

That leaves the initialization methods. `initializeActiveSegments` works for any cell, since every cell has four segments that all start off, so it belongs on the superclass. `initializeExitSides` does not: it is precisely what makes a blank cell blank.

Push up `initializeActiveSegments` and edit the two `initialize` methods by hand.

```smalltalk
Cell >> initializeActiveSegments
	self activeSegments: Dictionary new.
	self activeSegments at: #north put: false.
	self activeSegments at: #east put: false.
	self activeSegments at: #south put: false.
	self activeSegments at: #west put: false.
```

```smalltalk
Cell >> initialize
	super initialize.
	self initializeActiveSegments.
```

```smalltalk
BlankCell >> initialize
	super initialize.
	self initializeExitSides.
```

`Cell` then says that filling the exit sides is a subclass's job, and says it in a way that fails loudly rather than quietly if a new kind of cell forgets.

```smalltalk
Cell >> initializeExitSides
	"Fill exitSides with the side a beam leaves by for each side it can enter from. Every
	subclass answers this differently, which is what makes a cell blank, a mirror or a target,
	so I am abstract here."

	^ self subclassResponsibility
```

> **Note.** `self subclassResponsibility` means *a subclass has to implement this*. It is how an abstract method is written in Pharo: if the method is ever reached, it raises an error naming the class and the method, so a cell that forgot to fill in its exit sides fails loudly and immediately instead of quietly misbehaving three steps later. Leaving the method body empty would have hidden the same mistake.

Run the tests. They pass.

## Tests for MirrorCell

Now we can write the tests for the mirror. By convention they go in their own class.

```smalltalk
TestCase << #MirrorCellTestCase
	slots: {};
	package: 'Laser-Game-Tests'
```

Start with the state of a newly created mirror, which is the same as for a blank cell: off, with all four segments off.

```smalltalk
MirrorCellTestCase >> testCellOnState

	| cell |
	cell := MirrorCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
```

```smalltalk
MirrorCellTestCase >> testCellSegmentState

	| cell |
	cell := MirrorCell  new.
	self shouldnt: [ cell isSegmentOnFor: #north ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
```

### Handling the orientation

We have to set the orientation when the cell is created, and again when the player rotates it. Before writing the methods, let us write the tests that say what we expect. The exit sides depend on the orientation, so there is one test per lean.

```smalltalk
MirrorCellTestCase >> testCellExitSidesMirrorLeft

	| cell exit |
	cell := MirrorCell new.
	cell leanLeft.

	exit := cell exitSideFor: #north.
	self assert: exit equals: #east.

	exit := cell exitSideFor: #east.
	self assert: exit equals: #north.

	exit := cell exitSideFor: #south.
	self assert: exit equals: #west.

	exit := cell exitSideFor: #west.
	self assert: exit equals: #south
```

```smalltalk
MirrorCellTestCase >> testCellExitSidesMirrorRight

	| cell exit |
	cell := MirrorCell new.
	cell leanRight.

	exit := cell exitSideFor: #north.
	self assert: exit equals: #west.

	exit := cell exitSideFor: #east.
	self assert: exit equals: #south.

	exit := cell exitSideFor: #south.
	self assert: exit equals: #east.

	exit := cell exitSideFor: #west.
	self assert: exit equals: #north
```

And two more for which segments light up when a beam crosses the cell in each orientation.

```smalltalk
MirrorCellTestCase >> testCellLaserActivityMirrorLeft

	| cell |
	cell := MirrorCell leanLeft.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self assert: (cell isSegmentOnFor: #east).
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
```

```smalltalk
MirrorCellTestCase >> testCellLaserActivityMirrorRight

	| cell |
	cell := MirrorCell leanRight.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self assert: (cell isSegmentOnFor: #west).
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #east ]
```

The last four fail, of course, since we have not written the methods yet. Now we can. Each lean sets the flag and all four exit sides together.

```smalltalk
MirrorCell >> leanLeft
	self leansLeft: true.
	self exitSides at: #north put: #east.
	self exitSides at: #east put: #north.
	self exitSides at: #south put: #west.
	self exitSides at: #west put: #south.
```

```smalltalk
MirrorCell >> leanRight
	self leansLeft: false.
	self exitSides at: #north put: #west.
	self exitSides at: #east put: #south.
	self exitSides at: #south put: #east.
	self exitSides at: #west put: #north.
```

> **Note.** Setting the lean and the four sides in one method is not a matter of taste. Changing one without the other is the bug the chapter *Rotate A Mirror Cell* spends its length hunting, and the fix is to route every change of orientation through these two methods. `MirrorCell >> rotate` does exactly that.

A mirror fills its exit sides from whichever lean it is given, so its own `initializeExitSides` only has to create the dictionary, and `initialize` leans left by default.

```smalltalk
MirrorCell >> initializeExitSides
	self exitSides: Dictionary new.
```

```smalltalk
MirrorCell >> initialize
	super initialize.
	self initializeExitSides.
	self leanLeft
```

Run your tests and they should pass. This is a good moment to save your work.

## Instance creation methods

As a practical matter a mirror always has an orientation, so every time we make one we have to take the extra step of orienting it. You have seen how that reads in the tests above:

```
cell := MirrorCell new.
cell leanRight.
```

It would be nicer to say it in one step:

```
cell := MirrorCell leanRight
```

and we can, by defining two *class* methods. A class method runs when a message is sent to the class itself, as in `MirrorCell leanRight`, whereas an instance method runs when the message is sent to an instance, as in `cell leanRight`. In the System Browser you write them with the *Class side* button pressed, under the class list. The `MirrorCell class >>` prefix used in this book means exactly that.

```smalltalk
MirrorCell class >> leanLeft
	"Answer a mirror on the diagonal from my top left corner to my bottom right one."

	^ self new leanLeft
```

```smalltalk
MirrorCell class >> leanRight
	"Answer a mirror on the diagonal from my top right corner to my bottom left one."

	^ self new leanRight
```

> **Note.** Make sure the *Class side* button is pressed before you accept these two, and remember to release it afterwards. Defining them on the instance side is the single most common mistake students make in this tutorial, and it shows up as a message-not-understood the first time you write `MirrorCell leanRight`. If it happens, delete the instance method and write the class method instead.

> **Note.** Watch the receiver of the cascade if you are tempted to write `^ self new; leanLeft`. That sends `leanLeft` to the class, not to the new instance, and answers the class. `^ self new leanLeft` is what you want, and it works because `leanLeft` answers the cell.

Check it from a Playground with `MirrorCell leanRight inspect`. The two tests `testCellLaserActivityMirrorLeft` and `testCellLaserActivityMirrorRight` above already use the new API.

## About the design of MirrorCell

Instead of testing the state all the time with `isLeft` and `isRight`, a cleaner design defines two subclasses of `MirrorCell`, one per orientation, and puts the specific methods in each. What is important to see is that sending a message already selects the right method for the receiver: message sending *is* a systematic conditional, and every explicit test we write by hand is a place where we are not using the mechanism at the center of object-oriented programming.

This game keeps the flag. A mirror has exactly two states and it flips between them on every click, so two classes would mean replacing the cell in the grid on every rotation rather than telling it to turn. It is worth knowing which trade you are making.

# Enhancing TargetCell

The `TargetCell` is the last of our cells. It is unique in that it has no exit: once the laser beam enters a target cell it does not leave and does not propagate any further. The design choice we make here is to answer `nil` for every exit side. Let us start with tests that say what we mean, and with a comment.

```
I am the `Cell` the beam is aimed at. Every side of me leaves by nothing, so a beam that enters lights the side it arrived by and stops there. Reaching me is how the game is won.

Like `BlankCell` I add no state to `Cell`; `initializeExitSides` fills `exitSides` with nil for all four sides. `Grid` puts exactly one of me on the board.
```

## Some tests

A new test class, as before.

```smalltalk
TestCase << #TargetCellTestCase
	slots: {};
	package: 'Laser-Game-Tests'
```

At creation the cell is off, and so are all of its segments.

```smalltalk
TargetCellTestCase >> testCellOnState

	| cell |
	cell := TargetCell new.
	self assert: cell isOff.
	self shouldnt: [ cell isOn ]
```

```smalltalk
TargetCellTestCase >> testCellSegmentState
|cell|
cell := TargetCell new.
self shouldnt: [ cell isSegmentOnFor: #north ].
self shouldnt: [ cell isSegmentOnFor: #east ].
self shouldnt: [ cell isSegmentOnFor: #south ].
self shouldnt: [ cell isSegmentOnFor: #west ].
```

When the beam enters, exactly one segment lights up: the side it came in by. Nothing leaves.

```smalltalk
TargetCellTestCase >> testCellLaserActivity

	| cell |
	cell := TargetCell new.
	cell laserEntersFrom: #north.
	self assert: cell isOn.
	self assert: (cell isSegmentOnFor: #north).
	self shouldnt: [ cell isSegmentOnFor: #south ].
	self shouldnt: [ cell isSegmentOnFor: #east ].
	self shouldnt: [ cell isSegmentOnFor: #west ]
```

And every exit side is nil.

```smalltalk
TargetCellTestCase >> testCellExitSides

	| cell inputSides |
	cell := TargetCell new.
	inputSides := #( #north #east #south #west ).
	inputSides do: [ :inputSide |
		| exit |
		exit := cell exitSideFor: inputSide.
		self assert: exit isNil ]
```

## The behavior

### TargetCell is a Cell

First make `TargetCell` inherit from `Cell`, the way the other two cells already do.

```smalltalk
Cell << #TargetCell
	slots: {};
	tag: 'Model';
	package: 'Laser-Game'
```

Run the tests. The two that are not about exit sides already pass, because everything they exercise now comes from `Cell`.

### Handling the exits

Now the exit sides. A target answers nothing for every side it can be entered from.

```smalltalk
TargetCell >> initializeExitSides
	self exitSides: Dictionary new.
	self exitSides at: #north put: nil.
	self exitSides at: #east put: nil.
	self exitSides at: #south put: nil.
	self exitSides at: #west put: nil.
```

```smalltalk
TargetCell >> initialize
	super initialize.
	self initializeExitSides.
```

Run the tests again and the three cell test classes are green. This is a good moment to save your code.

## About the design

### About our initialize methods

We have now written initialization methods three times, once per cell, and parts of them are identical. That duplication is a smell, and it is worth asking what to do about it before reading on.

One answer is to push the line that every cell repeats, `self exitSides: Dictionary new`, up into `Cell >> initialize`, make `Cell >> initializeExitSides` do nothing, and let each subclass fill the dictionary its superclass made. `BlankCell` and `TargetCell` then lose their `initialize` methods entirely, and `MirrorCell` keeps only the `leanLeft` line.

This port does not take that road, for one reason: an abstract superclass that silently supplies an empty dictionary makes a cell with no exit sides a legal object. Here, `Cell >> initializeExitSides` is `self subclassResponsibility` instead, so the third kind of cell someone adds to this game cannot forget to say how a beam crosses it. The cost is one line of dictionary creation repeated in three subclasses; the benefit is that the mistake is impossible.

### About the target design

Using `nil` to say that there is no exit is not ideal, because it makes every client check whether it got a side or nothing. A good object-oriented answer is an object that accepts the same messages and does nothing, which is the *null object* pattern. It removes the `ifNil:` tests and follows the tell-do-not-ask style of really thinking in objects.

We stay with `nil` here, and it turns out to be cheap: the beam path asks a cell for its exit side once and stops when there is none, so there is a single place in the whole game where the check happens. Keep the pattern in mind as a refactoring exercise all the same.

# Grid

The cells know how a beam crosses them. What is still missing is the thing that holds them. From what we have seen so far, the `Grid` is responsible for keeping the cells in a matrix. It must let us put a particular cell at a particular place, it must let us ask which cell sits at a place, and it is the object that will fire the laser beam.

## A class comment

As with the cells, we say what the class is for before we say how it works.

```
I am the model of the whole board: a dictionary of `Cell`s keyed by `column @ row` points, `numberOfColumns` of them across and `numberOfRows` down, plus the state of the laser. Every location holds a cell; `BlankCell` fills the empty ones.

`fireLaser` lights the cells the beam crosses and `stopLaser` clears them again. The beam is `laserBeamPath`, an ordered collection of `LaserPathElement`s built by `calculatePath`, which walks from `startingCell` until the beam stops. `movesStack` records the player's moves so `undo` can take them back.

Cells are moved with the `pushCell...FromLocation:` methods, each guarded by its `canPushCell...FromLocation:`, and mirrors are turned with `rotateCellClockwiseAt:` and `rotateCellCounterClockwiseAt:`. Inspect me for a picture of the board and a list of the beam path.
```

> **Note.** That is the comment the class ends up with. Everything after the first paragraph is about work still ahead of us: the beam path, the mouse pushes, the undo stack. For now a single line says all there is to say — a grid holds a matrix of cells, gives access to them, and fires the laser.

## The first test

As usual we start with a test for the initial state. A new grid should have an inactive laser, and every location should hold a blank cell.

```smalltalk
TestCase << #GridTestCase
	slots: {};
	package: 'Laser-Game-Tests'
```

```smalltalk
GridTestCase >> testInitialConditions

	| grid cell |
	grid := Grid new.
	self shouldnt: [ grid laserIsActive ].
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell
```

> **Note.** `assert:equals:` is worth preferring to `assert:` whenever you are comparing two values. When it fails it reports both of them — *expected 3, got 4* — where `assert: a = b` can only report that something was `false`.

## The instance variables

The test needs four things from a grid. `cells` holds a dictionary whose keys are locations inside the grid and whose values are the cells at those locations. `laserIsActive` is a boolean saying whether the beam is on. `numberOfColumns` and `numberOfRows` give the shape of the matrix.

```
Object << #Grid
	slots: { #cells . #laserIsActive . #numberOfColumns . #numberOfRows };
	tag: 'Model';
	package: 'Laser-Game'
```

Then create the accessors for the four of them, the same way we created the accessors on `Cell`: select the class, *Refactoring > Instance variables > Accessors*, and accept. Eight methods appear in the `accessing` protocol, `cells` and `cells:` among them.

```smalltalk
Grid >> cells
	"Answer the value of cells"

	^ cells
```

```smalltalk
Grid >> cells: anObject
	"Set the value of cells"

	cells := anObject
```

`laserIsActive`, `laserIsActive:`, `numberOfColumns:` and `numberOfRows:` are the same three lines each. The two getters `numberOfColumns` and `numberOfRows` are rewritten in a moment, so leave them as the refactoring wrote them for now.

> **Note.** The finished class has two more instance variables, `laserBeamPath` and `movesStack`, which arrive with the beam path in the next section and with *Undo* near the end of the book. The definition in the image is therefore:

```smalltalk
Object << #Grid
	slots: { #cells . #laserIsActive . #numberOfColumns . #numberOfRows . #laserBeamPath . #movesStack };
	tag: 'Model';
	package: 'Laser-Game'
```

## Encapsulating access to the cells

We want to address cells inside the grid. Rather than hand out the dictionary and let every client know how cells are stored, we give the grid two accessors of its own, `at:` and `at:put:`.

```smalltalk
Grid >> at: aPoint
	"Answer the cell at aPoint, a column @ row location, or nil when I hold no cell there."

	^self cells at: aPoint ifAbsent: []
```

```smalltalk
Grid >> at: aPoint put: aCell
	"Put aCell at aPoint, a column @ row location, and tell the cell where it now sits."

	aCell gridLocation: aPoint.
	self cells at: aPoint put: aCell
```

The `cells` and `cells:` accessors still expose the dictionary, so move them to a protocol named `private`, which says they are the grid's own business. A protocol has no effect on execution. It only helps a human read the class.

By convention a method parameter is named after the class it expects. Pharo has a built-in class `Point`, written `x@y`, and you get the parts of a point by sending it `x` and `y`: inspect `(2@3) x` and you get `2`.

Note that storing cells in a dictionary keyed by their `Point` location is the quick way, not the proper one. An array or a matrix indexed by a small calculation — something in the spirit of `x + (y * numberOfColumns)` — would be the real answer. It is a fine first pass all the same, and that is exactly the point of `at:` and `at:put:`: because the dictionary is hidden behind them, we can change our minds later without touching the rest of the program.

> **Note.** Two details here point forward. `at:` answers `nil` for a location the grid does not hold, because of the `ifAbsent: []` — we come back below to why that matters. And `at:put:` tells the cell where it has been put, which needs the `gridLocation` instance variable that `Cell` gains with the beam path work of the next section.

## Initializing a grid

Now we can fill a new grid with blank cells.

```smalltalk
Grid >> initialize
	super initialize.
	self laserIsActive: false.
	self initializeCells.
	
```

The first attempt at `initializeCells` reads like this.

```
initializeCells
	self cells: Dictionary new.
	1 to: self numberOfColumns do: [:x |
		1 to: numberOfRows do: [:y |
			| pt cell |
			pt := x@y.
			cell := BlankCell new.
			self at: pt put: cell]]
```

But wait. We wrote accessors for `numberOfColumns` and `numberOfRows`, and we never initialized either of them. There are two general answers. One is to set them in `initialize`:

```
initialize
	super initialize.
	self laserIsActive: false.
	self numberOfColumns: 10.
	self numberOfRows: 10.
	self initializeCells
```

The other is *lazy initialization*: the getter itself supplies a value the first time it is asked.

```smalltalk
Grid >> numberOfColumns
	numberOfColumns isNil ifTrue: [self numberOfColumns: 1].
	^ numberOfColumns
```

```smalltalk
Grid >> numberOfRows
	numberOfRows isNil ifTrue: [self numberOfRows: 1].
	^ numberOfRows
```

In a live programming environment like Pharo lazy initialization is used a great deal, so that is the road we take. Pay attention, though: it only works if the code consistently goes through the getter. Read the instance variable directly and you get whatever it holds, which before the first send is `nil`.

> **Note.** A grid nobody has sized is as small as a grid can be, 1 by 1. Nothing ever plays on a default grid, so the value hardly matters, but it does make the point of a lazy getter sharply: the grid has a usable size from the moment it exists, without anyone having to remember to set one.

## The bug the debugger finds

Run the tests. We expected green and we do not get it. Click the failing test, press *Debug*, and walk down the call stack until you reach one of your own objects, which is `Grid >> initializeCells`.

Look at the instance variables in the bottom left pane of the debugger. `numberOfColumns` holds a number, because the lazy getter was sent. `numberOfRows` holds `nil`. Look at the method again and the reason is in plain sight: the inner loop reads the instance variable `numberOfRows` directly instead of sending `self numberOfRows`, so it never gives the getter the chance to fill it in. That is exactly the mistake the note above warns about, and it is easy to make.

You can fix it in the debugger. Edit the method in the code pane, accept, then press *Proceed* and the test carries on with the new code.

```smalltalk
Grid >> initializeCells
	self cells: Dictionary new.
	1 to: self numberOfColumns do: [:x |
		1 to: self numberOfRows do: [:y |
			| pt cell |
			pt := x@y.
			cell := BlankCell new.
			self at: pt put: cell]]
```

Run the tests again and they pass. This is a good moment to save your work.

## A word about the order in which we define methods

The order in which methods are defined does not matter to the running program. It matters to us. Sometimes we prefer to be able to test a method as soon as it is written, and then we start with the elementary methods, the ones others use, and build upward. That is a bottom-up strategy, it works well when we already know what the low-level operations and the object's representation are, and it lets a test follow each method as it lands.

The other strategy is to write the complex method first, in terms of methods that do not exist yet. Running a test over it opens a debugger in the exact context where the missing method is needed, which is a good place to write it — as we did in *Coding in the Debugger*.

Both have their uses. Be aware that you have the choice, and pick the one that suits what you are doing.

## More tests, and a grid that grows

So far so good. Now let us think about a problem we might have. When `Grid` receives `new`, `initialize` runs and the cells are created — for the default number of rows and columns. What happens if we change the size afterwards? The answer was not obvious when the question came up, and a test is the way to find out.

```
testNonDefaultGridSizeInitialConditions
	| grid |
	grid := Grid new.
	grid numberOfColumns: 4.
	grid numberOfRows: 4.
	self deny: grid laserIsActive.
	self assert: (grid at: 1@1) class = BlankCell.
	self assert: (grid at: 4@4) class = BlankCell
```

It fails, and it fails at `grid at: 4@4`. Making the numbers bigger does not create the missing locations; the dictionary holds only what `initializeCells` put there, which is the default board. Inspect the grid in the debugger and you can see it: the keys stop where the default stopped.

> **Note.** Because our `at:` answers `nil` for a location the grid does not hold, this mistake arrives as an ordinary assertion failure on `nil class = BlankCell`. Had `at:` sent `Dictionary >> at:` bare, the same mistake would have opened a debugger on *KeyNotFound: key 4@4 not found in Dictionary* instead — the same lesson, through a noisier door.

## A better way to make a grid

We have been making grids by sending `new` to the class. `new` is a *class message*, a message sent to the class rather than to one of its instances, and what we want is a smarter one that takes the size at the same time.

```smalltalk
GridTestCase >> testNonDefaultGridSizeInitialConditions

	| grid cell |
	grid := Grid newOfSize: 4 @ 4.
	self shouldnt: [ grid laserIsActive ].
	cell := grid at: 1 @ 1.
	self assert: cell class equals: BlankCell.
	cell := grid at: 2 @ 3.
	self assert: cell class equals: BlankCell.
	self assert: cell isOff
```

The method it calls goes on the *class side*. In the browser, tick the *Class side* checkbox before writing it, and untick it afterwards; if you ever wonder where all your methods went, that checkbox is the first thing to look at.

A first attempt does the obvious thing.

```
newOfSize: aPoint
	| model |
	model := self new.
	model
		numberOfRows: aPoint y;
		numberOfColumns: aPoint x.
	^model
```

Run the tests and we are still not there, and for the same reason as before: `new` sends `initialize`, so the cells were built for the default size before we ever set the real one. The answer is `basicNew`, which does not, so we can set the size first and call `initialize` ourselves afterwards.

What is the difference between the two?

* `new` creates the instance and sends it `initialize`. A class is free to override it and do more.
* `basicNew` only creates the instance and answers it. It is a primitive creation message and should never be redefined — if it were, the trick we are about to use would stop working. `new` is itself written in terms of `basicNew`.

```smalltalk
Grid class >> newOfSize: aPoint
	| model |
	model := self basicNew.
	model
		numberOfRows: aPoint y;
		numberOfColumns: aPoint x.
	model initialize.
	^model
```

Run the tests and this time they are green.

> **Note.** `newOfSize:` takes one `Point` — `newOfSize: 4@4` — rather than two separate integers. A point is the shape the rest of the game already uses for a size and for a location, so one argument is both shorter to write and harder to get the wrong way round.

### Understanding `yourself`

The method works, but repeating `model` on every line is not the nicest thing to read. The alternative is a *cascade*, written with `;`, which sends several messages to the same object. The cascade in `newOfSize:` above already does that for the two sizes. We could go further and let the cascade answer the result:

```
newOfSize: aPoint
	^ self basicNew
		numberOfRows: aPoint y;
		numberOfColumns: aPoint x;
		initialize
```

That works, because a method that returns nothing in particular returns its receiver, and `initialize` is such a method. But it is fragile. What if `initialize` one day ended with `^ 42`? Then `newOfSize:` would answer `42` instead of a grid.

To be sure the object made by `self basicNew` is the one that comes back, end the cascade with `yourself`, a message that answers its receiver.

```
newOfSize: aPoint
	^ self basicNew
		numberOfRows: aPoint y;
		numberOfColumns: aPoint x;
		initialize;
		yourself
```

> **Note.** The image keeps the temporary variable and the explicit `^ model`, which is the same guarantee written the long way: whatever `initialize` answers is thrown away and the grid is returned. `yourself` is worth knowing all the same — you will meet it constantly in Pharo code, and it is why `OrderedCollection new add: 1; add: 2; yourself` answers the collection rather than `2`.

## A better context for the tests

With the cells working and a minimal test for `Grid`, we can write a much deeper test, one that uses broader parts of the design. Remember the diagram we used to introduce the game? That board is a good context to test against, so let us build it once and reuse it.

```
generateDemoGrid
	| grid |
	grid := Grid newOfSize: 5@5.
	grid at: 5@1 put: TargetCell new.

	grid at: 4@1 put: MirrorCell leanRight.
	grid at: 1@2 put: MirrorCell leanRight.
	grid at: 3@3 put: MirrorCell leanRight.
	grid at: 1@5 put: MirrorCell leanRight.
	grid at: 4@5 put: MirrorCell leanRight.

	grid at: 5@2 put: MirrorCell leanLeft.
	grid at: 2@3 put: MirrorCell leanLeft.
	grid at: 5@3 put: MirrorCell leanLeft.
	grid at: 2@4 put: MirrorCell leanLeft.
	grid at: 3@4 put: MirrorCell leanLeft.
	^ grid
```

Put it in a protocol of its own — `private`, or `grids` — since it is not a test.

And a test that uses it. Checking that the target cell is off will do for now.

```
testCellInteractions
	| grid cell |
	grid := self generateDemoGrid.
	cell := grid at: 5@1.
	self assert: cell isOff
```

> **Note.** A hand-made board is useful well beyond this one test, so it does not stay in the test class for long. The chapter *Drawing The Mirror* moves it to `GridFactory class >> demoGrid`, where the examples can reach it too, and `generateDemoGrid` becomes one line:

```smalltalk
GridTestCase >> generateDemoGrid

	^ GridFactory demoGrid
```

Writing the generator, it was easy to get confused about which half of `x@y` was the row and which the column. That is a tip-off: the names `at:` and `at:put:` are not saying enough, and we should go back and make them more intention-revealing. Perhaps we should have written this test *before* writing them — which is a clear advantage of writing tests first, since a test is the first client of the code and passes judgement on it.

A way to print a grid as text, and to build one from a text drawing of it, would make all of this easier to debug. That is the first thing the next section does.

## Conclusion

All the structural pieces of the game are now in place and tested: three kinds of cell under a common superclass, and a grid that holds them and can be asked for any of them. What is left of the model is the interesting part — working out the path the beam takes through the board — and that is where the next section begins.
