"
`RSKernelDensity` is a class that performs calculations related to density distribution plots (`RSDensityPlot`,`RSViolinPlot`) using the **kernel density estimation (KDE) function**.
Resources to understand the calculations and concepts related:
- https://youtu.be/qc9elACH8LA
- https://mathisonian.github.io/kde/

**Responsibility:** calculate density distribution of a dataset.

**Collaborators:** `RSKernelFunction` represents the Kernel function (by default a Gaussian function) evaluated in the KDE function.

**Public API and Key Messages**
- `data: aCollection` to create instances passing aCollection (dataset) as argument.
- `evaluateKernel: aNumber` to get the kernel function evaluation of aNumber K(x). 
- `kde: aNumber` to get the corresponding density (probability)  of an x value. (it sum all the kernels applied over the dataset values).  
- `densityCurve`: to apply the `kde` function over a ""continuos"" set of x values and get the y values, for the domain of the dataset passed.

**Instance Variables:**
  
- `data`: aCollection, the dataset for wich the probability density is estimated.
- `bandwidth`: a Float that stores the bandwidth used for the kernel function.
- `kernel`: a `RSKernelFunction` that calculates the corresponding kernel (a `RSKernelGaussianFunction` by default) and has an `evaluate: aNumber` message.

**Example:**
```Smalltalk
| kernelDensity anXValue data |
data := #(14 15 28 27 32 35).
kernelDensity := RSKernelDensity data: data.
kernelDensity bandwidth: 4.
anXValue := 30.
self assert: (kernelDensity kde: anXValue) closeTo: 0.0495.
```
"
Class {
	#name : #RSKernelDensity,
	#superclass : #RSObject,
	#instVars : [
		'data',
		'bandwidth',
		'kernel'
	],
	#category : #'Roassal3-Chart-Statistics'
}

{ #category : #'instance creation' }
RSKernelDensity class >> bandwidth: aNumber [
	^ self gaussian bandwidth: aNumber.
]

{ #category : #'instance creation' }
RSKernelDensity class >> data: aCollection [
	| kernelDensity |
	kernelDensity := self gaussian.
	kernelDensity data: aCollection.
	^ kernelDensity
]

{ #category : #'instance creation' }
RSKernelDensity class >> gaussian [
	| kernelDensity |
	kernelDensity := self new.
	kernelDensity kernel: RSKernelGaussianFunction new.
	^ kernelDensity
]

{ #category : #'instance creation' }
RSKernelDensity class >> kernel: anRSKernelFunction [
	| kernelDensity |
	kernelDensity := self new.
	kernelDensity kernel: anRSKernelFunction. 
	^ kernelDensity
]

{ #category : #'instance creation' }
RSKernelDensity class >> kernel: anRSKernelFunction data: aCollection [
	| kernelDensity |
	kernelDensity := self new.
	kernelDensity kernel: anRSKernelFunction.
	kernelDensity data: aCollection.
	^ kernelDensity
]

{ #category : #accessing }
RSKernelDensity >> bandwidth [
	^ bandwidth
]

{ #category : #accessing }
RSKernelDensity >> bandwidth: aNumber [
	bandwidth := aNumber
]

{ #category : #accessing }
RSKernelDensity >> data [
	^ data.
]

{ #category : #accessing }
RSKernelDensity >> data: aCollection [
	self assert: (aCollection allSatisfy: [ :each | each isNumber ]) 
		description: 'data: should receive only a collection of numbers'.
	data := aCollection
]

{ #category : #accessing }
RSKernelDensity >> defaultBandwidth [
	^ 1.0.
]

{ #category : #accessing }
RSKernelDensity >> defaultKernel [
	^ RSKernelGaussianFunction new.
]

{ #category : #rendering }
RSKernelDensity >> densityCurve [
	| curvePoints xi yi maxData minData epsilon step minXDomain maxXDomain maxY |
	maxData := data max.
	minData := data min.
	curvePoints := OrderedCollection new.
	epsilon := 0.0001.
	step := 0.05.
	maxY := 0.
	
	"Calculate left side"
	xi := minData.
	yi := self kde: xi.
	curvePoints add: xi@yi.
	maxY := yi max: maxY.
	[ yi > epsilon ] whileTrue: [
		xi := xi - step.
		yi := self kde: xi. 
		curvePoints addFirst: xi@yi.
		maxY := yi max: maxY.
	].
	minXDomain := xi.

	"Calculate middle"
	xi := minData + step.
	yi := self kde: xi.
	maxY := yi max: maxY.
	curvePoints add: xi@yi.
	[ xi < maxData ] whileTrue: [
		xi := xi + step.
		yi := self kde: xi. 
		curvePoints add: xi@yi.
		maxY := yi max: maxY.
	].
		
	"Calculate right side"
	[ yi > epsilon ] whileTrue: [
		xi := xi + step.
		yi := self kde: xi. 
		curvePoints add: xi@yi.
		maxY := yi max: maxY.
	].
	maxXDomain := xi.
	maxY := yi max: maxY.

	^ curvePoints.
]

{ #category : #accessing }
RSKernelDensity >> densityCurveSample: aCollection [
	^ aCollection collect: [ :value | (self kde: value) ]
]

{ #category : #accessing }
RSKernelDensity >> evaluateKernel: aNumber [
	^ kernel evaluate: aNumber.
]

{ #category : #initialization }
RSKernelDensity >> initialize [
	super initialize.
	self bandwidth: self defaultBandwidth.
	self kernel: self defaultKernel.
]

{ #category : #accessing }
RSKernelDensity >> kde: aNumber [
	| sum h |
	sum := 0.
	h := bandwidth.
	data 
		do: [ :xi |
			sum := sum + (self evaluateKernel: ((aNumber - xi)/h))
		 ].
	^ sum / ((data size) * h)
]

{ #category : #accessing }
RSKernelDensity >> kernel [
	^ kernel
]

{ #category : #accessing }
RSKernelDensity >> kernel: anRSKernelFunction [
	self assert: (anRSKernelFunction isKindOf: RSKernelFunction) 
		description: 'Error: The argument passed to kernel is not an RSKernelFunction.'.
	kernel := anRSKernelFunction
]
