class NeuralNetworkError extends Error
  constructor: (msg) ->
    @name = 'NeuralNetworkError'
    @message = msg

class Neuron
  @sigmoidFn: (shift = 0) ->
    (x) -> 1 / (1 + Math.exp(shift - x))
  @thresholdFn = (a = 0) ->
    (x) -> if x >= a then 1 else 0
  actWeight: (y) ->
    t = @activationData[0]
    if t is 'sigmoid' then y * (1 - y)
    else 1
  constructor: (@weights, activation) ->
    activation ?= {
      type: 'sigmoid'
      param: 0
    }
    @activationData = activation
    {type, param} = activation
    switch type
      when 'threshold' then @actFn = Neuron.thresholdFn param
      when 'sigmoid' then @actFn = Neuron.sigmoidFn param
  apply: (inputs) ->
    @actFn(sum (n * @weights[i] for n, i in inputs))

class NeuralNetwork extends Observable
  constructor: (@numInputs = 2) ->
    super
    @layers = []
    @finalized = false
  addLayer: (numNeurons, activation) ->
    if @finalized
      throw new NeuralNetworkError 'Cannot add new layer; output layer has already been added.'
    length = if @layers.length is 0 then @numInputs else @layers[@layers.length - 1].length
    layer = []
    for i in [1..numNeurons]
      layer.push new Neuron((Math.random() for j in [1..length]), activation)
    @layers.push layer
    return
  addOutputLayer: (numNeurons = 1, activation) ->
    @addLayer(numNeurons, activation)
    @finalized = true
    return
  forward: (inputs) ->
    outputs = [inputs]
    for input, i in inputs
      @fire('step', {
        type: 'input'
        id: i
        value: roundTo(input, 2)
      })
    @fire('step', { type: 'inputsDone' })
    j = inputs.length
    for layer, index in @layers
      output = []
      isOutputLayer = index is @layers.length - 1
      for n in layer
        v = n.apply(outputs[outputs.length - 1])
        output.push v
        @fire('step', {
          type: 'hidden'
          id: j
          value: roundTo(v, 2)
        })
        if isOutputLayer
          @fire('step', {
            type: 'output'
            id: j
            value: roundTo(v, 2)
          })
        j += 1
      outputs.push output
    @fire('step', { type: 'forwardDone' })
    outputs
  backward: (outputs, goal, rate) ->
    # calculate all the errors
    delta = []
    allNeurons = flatten @layers
    oid = (flatten outputs).length - outputs[outputs.length - 1].length
    for o, i in outputs[outputs.length - 1]
      delta.push goal[i] - o
      @fire('step', {
        type: 'outputDelta'
        id: oid
        value: roundTo(goal[i] - o, 2)
      })
      oid += 1
    deltas = ([] for i in [1..@layers.length])
    deltas[deltas.length - 1] = delta
    for i in [(@layers.length - 2)..0]
      [cur, next] = [@layers[i], @layers[i + 1]]
      d = []
      # Loop through current layer and calculate errors for this layer
      for j in [0...cur.length]
        error = sum (deltas[i + 1][k] * w for w, k in (next.map (n) -> n.weights[j]))
        @fire('step', {
          type: 'hiddenDelta'
          id: @numInputs + allNeurons.indexOf cur[j]
          value: roundTo(error, 2)
        })
        d.push error
      deltas[i] = d
    @fire('step', { type: 'deltaDone' })
    # change the weights
    paired = zip(@layers, deltas).map (p) -> zip(p...)
    for layer, i in paired
      for sublayer, j in layer
        [neuron, delta] = sublayer
        weightZip = zip(neuron.weights, outputs[i].map (x) -> x * neuron.actWeight(outputs[i + 1][j]) * rate * delta)
        neuron.weights = weightZip.map sum
        for weight, wi in neuron.weights
          prevLayer = @layers[i - 1]?.map((n) -> allNeurons.indexOf n) or [0...@numInputs]
          prevIndex = if @layers[i - 1] then @numInputs + prevLayer[wi] else prevLayer[wi]
          @fire('step', {
            type: 'changeWeight'
            id: @numInputs + allNeurons.indexOf neuron
            value: [roundTo(weight, 2), prevIndex]
          })
    @fire('step', { type: 'backwardDone' })
    return
  apply: (inputs) ->
    f = @forward(inputs)
    f[f.length - 1]
  run: (trainingData, runs = 1, learningRate = 0.5) ->
    for i in [1..runs]
      for [x, y] in trainingData
        y = if typeof y is typeof [] then y else [y]
        # feed forward
        outputs = @forward x
        # backpropagate
        @backward(outputs, y, learningRate)
    return
  # lists the neurons in order for use in view
  listNeurons: () ->
    @layers.reduce (p, l) -> p.concat l