Class {
	#name : 'BaselineOfLaserGame',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfLaserGame',
	#package : 'BaselineOfLaserGame'
}

{ #category : 'as yet unclassified' }
BaselineOfLaserGame >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			baseline: 'Bloc'
			with: [ spec repository: 'github://pharo-graphics/Bloc:dev/src' ].
		spec
			baseline: 'Toplo'
			with: [ spec repository: 'github://pharo-graphics/Toplo:dev/src' ].
		spec package: 'Laser-Game' with: [ spec requires: #( 'Bloc' 'Toplo' ) ].
		spec
			package: 'Laser-Game-Tests'
			with: [ spec requires: #( 'Laser-Game' ) ].
		spec group: 'core' with: #( 'Laser-Game' ).
		spec group: 'tests' with: #( 'Laser-Game-Tests' ).
		spec group: 'default' with: #( 'core' 'tests' ) ]
]
