"
`RSSearchInCanvas` am an option for the canvas controller. 
You can use `RSSearchInCanvas` as follows (press the S key and the R key):

Examples
- `RSSearchInCanvasInteraction class >>#exampleCollection`
- `RSSearchInCanvasInteraction class >>#exampleCollection2`

### Variables
- canvas, the current canvas.
- useExactMach, a configuration flag, if true it will use a exact regular expression
- highlightesShapes, a collection of the group of shapes
- colorsToUse, a color palette to highlight each search group
- highlightableLabels, the current labels on the top left of the search.
Search In Canvas will highlight with a shadow a current shape. You have to click on the search result to jump between results of the list.

The selection of the elements is based on each shape model `asString`
"
Class {
	#name : #RSSearchInCanvasInteraction,
	#superclass : #RSAbstractControlCanvasInteraction,
	#instVars : [
		'canvas',
		'useExactMatch',
		'fixedLabels',
		'highlightesShapes',
		'colorsToUse',
		'highlightableLabels'
	],
	#category : #'Roassal3-Interaction-Controls'
}

{ #category : #public }
RSSearchInCanvasInteraction >> adjustRegExpIfNecessary: regExp [

	^ useExactMatch ifTrue: [ regExp ] ifFalse: [ '*', regExp, '*' ]
]

{ #category : #'private - events' }
RSSearchInCanvasInteraction >> animateShadowPosition: shadow [
	| rect correct camera newPosition |
	rect := shadow globalEncompassingRectangle.
	(canvas visibleRectangle containsRect: rect)
		ifTrue: [ ^ self ].
	camera := canvas camera.

	newPosition := camera positionFromSpace: rect floatCenter.
	correct := self correctCamera: camera matrixDo: [ :mat | mat translation: newPosition ].

	canvas newAnimation
		duration: 500 milliSeconds;
		from: canvas camera position;
		to: correct;
		on: camera set: #position:
]

{ #category : #util }
RSSearchInCanvasInteraction >> candidateShapes [
	"Return shapes for which the model has to be matched.
	 Only shapes that are not a line and having a model may be eligeable to be highligted"
	self assert: [ canvas notNil ] description: 'Canvas should be set first'.
	^ canvas allChildren select: [ :child | child model notNil and: [ child isNode ] ]
]

{ #category : #accessing }
RSSearchInCanvasInteraction >> canvas: aCanvas [
	"Set the canvas from which shapes should be searched in"
	canvas := aCanvas
]

{ #category : #public }
RSSearchInCanvasInteraction >> cleanAndResetFixedshapes [
	fixedLabels do: [ :s | s remove ].
	self resetFixedShapes
]

{ #category : #'private - events' }
RSSearchInCanvasInteraction >> clickOnLabel: evt [
	| shapes label index shadow nextShadow |
	label := evt shape.
	shapes := label propertyAt: #shapesToHighlight.
	(shapes isNil or: [shapes isEmpty]) ifTrue: [ ^ self ].
	index := label propertyAt: #index ifAbsent: [ 1 ].
	shadow := (shapes at: index) propertyAt: #shadow.
	shadow color: label color.

	index := evt class == RSMouseLeftClick
		ifTrue: [ index % shapes size + 1]
		ifFalse: [ index - 1 ].
	index = 0 ifTrue: [ index := shapes size ].
	label propertyAt: #index put: index.
	nextShadow := (shapes at: index) propertyAt: #shadow.
	self animateShadowPosition: nextShadow
]

{ #category : #'public - configuration' }
RSSearchInCanvasInteraction >> colorToHighlight: aColor [
	"Set the color to highlight shapes when searching"
	colorsToUse range at: 1 put: aColor
]

{ #category : #public }
RSSearchInCanvasInteraction >> colorToUseToHighlight [

	^ colorsToUse scale: self numberOfPerformedSearches
]

{ #category : #public }
RSSearchInCanvasInteraction >> colorsToUse: aNSOrdinalScale [
	colorsToUse := aNSOrdinalScale
]

{ #category : #public }
RSSearchInCanvasInteraction >> doHighlightShapes: shapesToHighlight [
	shapesToHighlight do: [ :s | self putShadowOn: s ].
	"We record the highlighted shapes"
	highlightesShapes addAll: shapesToHighlight
]

{ #category : #'public - configuration' }
RSSearchInCanvasInteraction >> doNotUseExactMatch [
	"Expect a regular expression as input, but a * is prepended and appended to the regexp"
	useExactMatch := false
]

{ #category : #public }
RSSearchInCanvasInteraction >> doUnhighlightShapes [

	highlightesShapes do: [ :s | self removeShadow: s ].
	highlightesShapes := RSGroup new
]

{ #category : #accessing }
RSSearchInCanvasInteraction >> fixedLabels [
	"Return the label that are created when a search is performed"
	^ fixedLabels
]

{ #category : #'private - events' }
RSSearchInCanvasInteraction >> hideCurrentShadow: evt [
	| shapes label index shadow anime |
	label := evt shape.
	shapes := label propertyAt: #shapesToHighlight.
	anime := label propertyAt: #animation.
	anime ifNotNil: [
		anime stop.
		label removeKey: #animation ].
	(shapes isNil or: [shapes isEmpty]) ifTrue: [ ^ self ].
	index := label propertyAt: #index ifAbsent: [ 1 ].

	shadow := (shapes at: index) propertyAt: #shadow.
	shadow color: label color
]

{ #category : #initialization }
RSSearchInCanvasInteraction >> initialize [

	super initialize.
	self resetFixedShapes.
	highlightesShapes := RSGroup new.

	colorsToUse := NSScale ordinalColored: 7.
	highlightableLabels := RSHighlightable new
		when: RSHighlightEvent send: #showCurrentShadow: to: self;
		when: RSUnHighlightEvent send: #hideCurrentShadow: to: self;
		yourself.

	"The variable highlightedShapes contains the shapes that have been searched and therefore highlighted"
	self useExactMatch
]

{ #category : #util }
RSSearchInCanvasInteraction >> isRegExpValid: regExp [
	"Is the regular expression relevant to be processed"
	^ regExp notNil and: [ regExp notEmpty ]
]

{ #category : #configuration }
RSSearchInCanvasInteraction >> keyForReset [
	^ 'R'
]

{ #category : #configuration }
RSSearchInCanvasInteraction >> keyForSearch [
	^ 'S'
]

{ #category : #util }
RSSearchInCanvasInteraction >> numberOfHighlightedShapes [
	"Return the number of shapes that have been highlited"
	^ highlightesShapes size
]

{ #category : #accessing }
RSSearchInCanvasInteraction >> numberOfPerformedSearches [
	"Return the number of searches that have been done since the last reset. This number is the same than the number of fixed labels that were already set."
	^ fixedLabels size
]

{ #category : #private }
RSSearchInCanvasInteraction >> obtainRegExpToHighlight [
	"Open a UI"
	^ UIManager default
		request: 'Enter a reg exp to search for an item'
		initialAnswer: '*value*'
]

{ #category : #hooks }
RSSearchInCanvasInteraction >> onShape: aCanvas [
	aCanvas
		when: RSKeyUp send: #processKeyUp: to: self;
		when: RSScaleChangedEvent send: #updateShadows: to: self
]

{ #category : #'private - events' }
RSSearchInCanvasInteraction >> processKeyUp: evt [
	| keyName |
	self canvas: evt canvas.
	keyName := evt keyName.
	evt anyModifierKeyPressed ifTrue: [ ^ self ].
	keyName = self keyForSearch ifTrue: [ self searchForShapes ].
	keyName = self keyForReset ifTrue: [ self resetAllHighlightedShapes ]
]

{ #category : #public }
RSSearchInCanvasInteraction >> putShadowOn: shape [
	| shadow key |
	key := #shadow.
	shadow := RSBox new
		paint: self colorToUseToHighlight;
		yourself.
	shape removeInteractionIfPresent: self class.
	shape
		when: RSPositionChangedEvent send: #updateShadow: to: self;
		when: RSExtentChangedEvent send: #updateShadow: to: self;
		when: RSShapeRemovedEvent send: #removeShadow: to: self.

	shape parent ifNotNil: [ shape parent addShape: shadow before: shape ].
	shape propertyAt: key
		ifPresent: [ :oldShadow | oldShadow remove ].

	shape propertyAt: key put: shadow.
	self updateShadow: shape
]

{ #category : #public }
RSSearchInCanvasInteraction >> removeShadow: evt [
	| shape |
	shape := evt shape.
	shape propertyAt: #shadow ifPresent: [ :shadow |
		shadow remove.
		shape removeKey: #shadow.
	]
]

{ #category : #rendering }
RSSearchInCanvasInteraction >> renderLegendOn: aLegendBuilder [
	aLegendBuilder
		text: self keyForSearch
		description: 'Search and highlight items'.
	aLegendBuilder
		text: self keyForReset
		description: 'Unhighlight all items'
]

{ #category : #public }
RSSearchInCanvasInteraction >> resetAllHighlightedShapes [

	"Restore the colors of all the highlighted shapes. This method is called whtn keyForReset is pressed"

	self cleanAndResetFixedshapes.
	self doUnhighlightShapes.
	canvas signalUpdate
]

{ #category : #initialization }
RSSearchInCanvasInteraction >> resetFixedShapes [
	fixedLabels := RSGroup new
]

{ #category : #private }
RSSearchInCanvasInteraction >> scaleFrom: s [
	"Return the scale used by the canvas of the shape"
	s canvas ifNil: [ ^ 1 ].
	^ s canvas camera scale
]

{ #category : #public }
RSSearchInCanvasInteraction >> searchForShapes [
	"callback called when some shapes have to be search"
	| regExp |
	regExp := self obtainRegExpToHighlight.
	(self isRegExpValid: regExp)
		ifFalse: [ ^ self ].
	self searchForShapes: regExp
]

{ #category : #public }
RSSearchInCanvasInteraction >> searchForShapes: regExp [
	"callback called when some shapes have to be search"

	| shapesToHighlight lbl |
	shapesToHighlight := self shapesToHighlightUsingRegExp:
		                     (self adjustRegExpIfNecessary: regExp).

	"No need to pursue if we have not found anything"
	shapesToHighlight ifEmpty: [ ^ self ].
	self doHighlightShapes: shapesToHighlight.

	lbl := RSLabel new text: regExp.
	lbl propertyAt: #shapesToHighlight put: shapesToHighlight.

	lbl fontSize: 14.
	lbl
		@ (RSPopup text:  shapesToHighlight size asString, ' elements');
		@ highlightableLabels.
	lbl when: RSMouseClick send: #clickOnLabel: to: self.
	lbl color: self colorToUseToHighlight.
	canvas addShape: lbl.
	lbl setAsFixed.
	fixedLabels add: lbl.
	RSHorizontalLineLayout on: fixedLabels.
	fixedLabels translateTo: fixedLabels extent / 2 + (5 @ 5).


	canvas signalUpdate
]

{ #category : #util }
RSSearchInCanvasInteraction >> shapesToHighlightUsingRegExp: regExp [
	"Return the shapes to be highlighted"

	| candidateShapes shapesToHighlight |
	candidateShapes := self candidateShapes.
	shapesToHighlight := candidateShapes
		select: [ :s | regExp match: s model asString ].

	^ shapesToHighlight
]

{ #category : #'private - events' }
RSSearchInCanvasInteraction >> showCurrentShadow: evt [
	| shapes label anime index shadow |
	label := evt shape.
	shapes := label propertyAt: #shapesToHighlight.
	anime := label propertyAt: #animation.
	anime ifNotNil: [ anime stop ].
	(shapes isNil or: [shapes isEmpty]) ifTrue: [ ^ self ].
	index := label propertyAt: #index ifAbsent: [ 1 ].
	shadow := (shapes at: index) propertyAt: #shadow.
	self animateShadowPosition: shadow.
	anime := label newAnimation
		repeat;
		duration: 1 second;
		scale: (NSScale linear
			domain: #(0 0.5 1);
			range: {label color. label color negated. label color});
		onStepDo: [:newColor |
			shadow ifNotNil: [
				index := label propertyAt: #index ifAbsent: [ 1 ].
				shadow := (shapes at: index) propertyAt: #shadow.
				shadow color: newColor.
				shadow signalUpdate.
			 ]
		].
	label propertyAt: #animation put: anime
]

{ #category : #util }
RSSearchInCanvasInteraction >> unhighlightShape: s [
	^ RSHighlightable new restore: s selector: #color
]

{ #category : #util }
RSSearchInCanvasInteraction >> unhighlightShapes: shapesToHighlight [
	shapesToHighlight do: [ :s | self unhighlightShape: s ]
]

{ #category : #public }
RSSearchInCanvasInteraction >> updateShadow: evt [
	| shadow shape pad |
	shape := evt shape.
	shadow := shape propertyAt: #shadow.
	shadow ifNil: [ ^ self ].
	pad := 5/ (self scaleFrom: shape).
	shadow
		fromRectangle: (shape encompassingRectangle expandBy: pad);
		cornerRadius: pad * 0.75
]

{ #category : #public }
RSSearchInCanvasInteraction >> updateShadows: evt [
	highlightesShapes do: [ :each | self updateShadow: each ]
]

{ #category : #'public - configuration' }
RSSearchInCanvasInteraction >> useExactMatch [
	"Expect a regular expression as input"
	useExactMatch := true
]
