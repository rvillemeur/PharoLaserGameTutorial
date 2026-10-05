"
I check the examples of the package Laser-Game-Examples.

Every example is a class-side method marked `<sampleInstance>`, which the browser offers as one click: it answers an object and opens an inspector on it.
I hold that promise to three rules.
Every method of the package is such an example.
Every example that answers an object answers one the inspector has a tab of our own for, and between them the examples reach every tab the game defines.
Only an example whose selector begins with `open` opens a window, so running the others costs nothing.
"
Class {
	#name : 'LaserGameExamplesTestCase',
	#superclass : 'TestCase',
	#category : 'Laser-Game-Tests',
	#package : 'Laser-Game-Tests'
}

{ #category : 'support' }
LaserGameExamplesTestCase >> allTabNames [
	"Answer the name of every inspector tab the game defines, on either side of every class."

	| package |
	package := (self class environment at: #PackageOrganizer) default
		           packageNamed: 'Laser-Game'.
	^ ((self tabMethodsDefinedBy: package) collect: [ :each |
		   each methodClass name , ' >> ' , each selector ]) asSet
]

{ #category : 'support' }
LaserGameExamplesTestCase >> exampleMethods [
	"Answer every example, sorted, so a failure always names the same one first."

	^ (self examplePackage methods select: [ :each |
		   each pragmas anySatisfy: [ :pragma | pragma selector = #sampleInstance ] ])
		  asSortedCollection: [ :one :other |
		  one methodClass name , one selector
		  <= (other methodClass name , other selector) ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> examplePackage [
	"Answer the package the examples live in."

	^ (self class environment at: #PackageOrganizer) default packageNamed: 'Laser-Game-Examples'
]

{ #category : 'support' }
LaserGameExamplesTestCase >> quietExampleMethods [
	"Answer the examples that answer an object without opening a window: everything but the openers."

	^ self exampleMethods reject: [ :each | each selector beginsWith: 'open' ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> runExample: aCompiledMethod [
	"Answer what the example answers. An example is a class-side method, so it is the class itself that is asked."

	^ aCompiledMethod methodClass instanceSide perform: aCompiledMethod selector
]

{ #category : 'support' }
LaserGameExamplesTestCase >> tabMethodsDefinedBy: aClassOrPackage [
	"Answer the inspector tabs of our own packages among the methods of aClassOrPackage."

	^ aClassOrPackage methods select: [ :each |
		  (each pragmas anySatisfy: [ :pragma |
			   pragma selector = #inspectorPresentationOrder:title: ]) and: [
			  each package notNil and: [
				  each package name beginsWith: 'Laser-Game' ] ] ]
]

{ #category : 'support' }
LaserGameExamplesTestCase >> tabsShownFor: anObject [
	"Answer the names of the tabs of our own that the inspector shows for anObject.
	Asking the class of anObject covers both sides: a cell answers the tabs its class and its superclasses define, and a class answers the ones defined on its metaclass."

	^ (anObject class withAllSuperclasses flatCollect: [ :each |
		   self tabMethodsDefinedBy: each ]) collect: [ :each |
		  each methodClass name , ' >> ' , each selector ]
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testEveryMethodOfThePackageIsAnExample [
	"The package holds examples and nothing else, so everything in it is one click the browser offers."

	| strays |
	strays := self examplePackage methods reject: [ :each |
		          each pragmas anySatisfy: [ :pragma |
			          pragma selector = #sampleInstance ] ].
	self assertEmpty: (strays collect: [ :each |
			 each methodClass name , ' >> ' , each selector ]) asArray.
	self denyEmpty: self exampleMethods
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testEveryQuietExampleAnswersAnObjectWithATabOfOurOwn [
	"An example that answers an object is worth one click because the inspector it opens has something of ours to show."

	self denyEmpty: self quietExampleMethods.
	self quietExampleMethods do: [ :each |
		| subject |
		subject := self runExample: each.
		self
			deny: subject isNil
			description: each selector , ' answers nil'.
		self
			deny: (self tabsShownFor: subject) isEmpty
			description: each selector , ' answers an object with no tab of ours' ]
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testOnlyAnExampleNamedOpenOpensAWindow [
	"Reading the selector tells you what the click costs: an opener puts a window on screen, anything else only answers an object.
	Read off the source, so that running me puts up no window."

	self quietExampleMethods do: [ :each |
		self
			deny: (each sourceCode includesSubstring: 'openOn:')
			description: each selector , ' opens a window but is not named open...' ].
	(self exampleMethods select: [ :each | each selector beginsWith: 'open' ])
		do: [ :each |
			self
				assert: (each sourceCode includesSubstring: 'openOn:')
				description: each selector , ' is named open... but opens no window' ]
]

{ #category : 'tests' }
LaserGameExamplesTestCase >> testTheExamplesReachEveryTabTheGameDefines [
	"Whatever tab the game grows, one click of the examples opens an inspector that shows it."

	| reached |
	reached := Set new.
	self quietExampleMethods do: [ :each |
		reached addAll: (self tabsShownFor: (self runExample: each)) ].
	self assertEmpty: (self allTabNames difference: reached) asSortedCollection asArray
]
