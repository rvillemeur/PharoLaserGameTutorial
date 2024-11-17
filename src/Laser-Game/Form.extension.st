Extension { #name : #Form }

{ #category : #'*Laser-Game' }
Form >> anyOfColor: aColor inColumn: int [
	| color |
	1 to: self height do: [:row |
		color := self colorAt: int@row.
		color = aColor ifTrue: [^true]].
	^false
]

{ #category : #'*Laser-Game' }
Form >> anyOfColor: aColor inRow: int [
	| color |
	1 to: self width do: [:column |
		color := self colorAt: column@int.
		color = aColor ifTrue: [^true]].
	^false
]

{ #category : #'*Laser-Game' }
Form >> firstColumnOfColorFromLeft: aColor [
	| x |
	x := 1.
	[self anyOfColor: aColor inColumn: x] whileFalse: [
		x := x + 1.
		x >= self width ifTrue: [^nil]].
	^x
]

{ #category : #'*Laser-Game' }
Form >> firstColumnOfColorFromRight: aColor [
	| x |
	x := self width.
	[self anyOfColor: aColor inColumn: x] whileFalse: [
		x := x - 1.
		x <= 1 ifTrue: [^nil]].
	^x
]

{ #category : #'*Laser-Game' }
Form >> firstRowOfColorFromBottom: aColor [
	| y |
	y := height.
	[self anyOfColor: aColor inRow: y] whileFalse: [
		y := y - 1.
		y <= 1 ifTrue: [^nil]].
	^y
]

{ #category : #'*Laser-Game' }
Form >> firstRowOfColorFromTop: aColor [
	| y |
	y := 1.
	[self anyOfColor: aColor inRow: y] whileFalse: [
		y := y + 1.
		y >= self height ifTrue: [^nil]].
	^y
]

{ #category : #'*Laser-Game' }
Form >> tightRectangleAroundColor: aColor [
	| left right top bottom |
	left := self firstColumnOfColorFromLeft: aColor.
	right := self firstColumnOfColorFromRight: aColor.
	top := self firstRowOfColorFromTop: aColor.
	bottom := self firstRowOfColorFromBottom: aColor.
	^left@top corner: right@bottom
]
