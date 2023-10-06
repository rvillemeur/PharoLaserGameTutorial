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
			spec requires:
				#( 'Laser-Game-Model' 'Laser-Game-Tests' 'Laser-Game-Graphics' ) ] ]
]
