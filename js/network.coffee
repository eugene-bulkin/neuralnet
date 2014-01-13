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
    sum (n * @weights[i] for n, i in inputs)

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
  addOutputLayer: (numNeurons = 1, activation) ->
    @addLayer(numNeurons, activation)
    @finalized = true
  forward: (inputs) ->
    outputs = [inputs]
    for input, i in inputs
      @fire('step', {
        type: 'input'
        id: i
        value: input
      })
    for layer in @layers
      outputs.push layer.map (n) -> n.apply(outputs[outputs.length - 1])
    outputs
  backward: (outputs, goal, rate) ->
    # calculate all the errors
    delta = (goal[i] - o for o, i in outputs[outputs.length - 1])
    deltas = ([] for i in [1..@layers.length])
    deltas[deltas.length - 1] = delta
    for i in [(@layers.length - 2)..0]
      [cur, next] = [@layers[i], @layers[i + 1]]
      d = []
      for j in [0...cur.length]
        d.push sum (deltas[i + 1][k] * w for w, k in (next.map (n) -> n.weights[j]))
      deltas[i] = d
    # change the weights
    paired = zip(@layers, deltas).map (p) -> zip(p...)
    for layer, i in paired
      for sublayer, j in layer
        [neuron, delta] = sublayer
        weightZip = zip(neuron.weights, outputs[i].map (x) -> x * neuron.actWeight(outputs[i + 1][j]) * rate * delta)
        neuron.weights = weightZip.map sum
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
  # lists the neurons in order for use in view
  listNeurons: () ->
    @layers.reduce (p, l) -> p.concat l