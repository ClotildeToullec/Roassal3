Extension { #name : #RSCanvas }

{ #category : #'*Roassal3-Examples' }
RSCanvas class >> exampleSimple [
	| canvas |
	canvas := self new.
	canvas color: Color black.
	"add some shapes here"
	^ canvas open
]

{ #category : #'*Roassal3-Examples' }
RSCanvas class >> exampleSpec [
	| canvas spec |
	canvas := self new.
	canvas color: Color black.
	spec := SpMorphPresenter new.
	spec morph: canvas createMorph.
	^ spec open
]
