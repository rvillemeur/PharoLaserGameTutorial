Class {
	#name : #BaselineOfLaserGame,
	#superclass : #BaselineOf,
	#category : #BaselineOfLaserGame
}

{ #category : #baselines }
BaselineOfLaserGame >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec package: 'Laser-Game' with: [
			spec
				baseline: 'Bloc'
				with: [
				spec repository: 'github://pharo-graphics/Bloc:dev/src' ] ] ]
]
