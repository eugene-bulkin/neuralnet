# Utility functions

sum = (l) -> l.reduce (a, b) -> a + b
zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.min(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments

# Neural network stuff

class @NeuralNetworkError extends Error
  constructor: (msg) ->
    @name = 'NeuralNetworkError'
    @message = msg

class @Neuron
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

class @NeuralNetwork
  constructor: (@numInputs = 2) ->
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
# Drawing stuff

refreshSVG = () ->
  $('#wrap').html $('#wrap').html()

options = {
  padding: 10
  layerPad: 125
  lineWidth: 2
  sizes: {
    inputNeuron: 40
    neuron: 60
  }
}

neuronCounter = 0

createNeuron = (x, y, r) ->
  $('<circle>').addClass('neuron').attr {
    cx: x
    cy: y
    r: r
    'stroke-width': 2,
    'data-id': neuronCounter++
  }

highlightNeuron = (e) ->
  curId = ($ @).attr('data-id')
  opacity = ~~(e.type is 'mouseover')
  $(".midLine[data-start=#{curId}], .midLine[data-end=#{curId}]").each ->
    ($ @).css('opacity', opacity)

drawNetwork = (inputs, layers) ->
  ctx = $('#canvas')
  canvas = $('#canvas g')
  canvas.empty()

  dims = {
    width: ctx.width()
    height: ctx.height()
  }
  neurons = []

  # input layer
  inputHeight = dims.height / inputs
  inputWidth = options.sizes.inputNeuron + 2 * options.padding
  curLayer = []
  for i in [0...inputs]
    neuron = createNeuron(options.layerPad + inputWidth / 2, (i + 1 / 2) * inputHeight, options.sizes.inputNeuron / 2).addClass('inputNeuron')
    curLayer.push neuron
    canvas.append neuron
  neurons.push curLayer

  # neuron layers
  startWidth = options.sizes.inputNeuron + 2 * options.padding + options.layerPad
  neuronWidth = options.sizes.neuron + 2 * options.padding
  for numNeurons, layer in layers
    neuronHeight = dims.height / numNeurons
    curLayer = []
    for i in [0...numNeurons]
      x = startWidth + layer * (options.sizes.neuron + 2 * options.padding) +
            (layer + 1) * options.layerPad
      neuron = createNeuron(x + neuronWidth / 2, (i + 1 / 2) * neuronHeight, options.sizes.neuron / 2).addClass('regularNeuron')
      curLayer.push neuron
      canvas.append neuron
    neurons.push curLayer

  # lines
  for layer, i in neurons
    inputLayer = i is 0
    outputLayer = i is (neurons.length - 1)
    if inputLayer
      for neuron in layer
        curX = 1 * neuron.attr 'cx'
        curR = 1 * neuron.attr 'r'
        curY = 1 * neuron.attr 'cy'
        curId = neuron.attr 'data-id'
        line = $('<line>').addClass('inLine').attr {
          x1: options.padding
          x2: curX - curR - options.padding
          y1: curY
          y2: curY
          'marker-end': 'url(#arrowEnd)'
          'stroke-width': options.lineWidth
          'data-start': curId
        }
        canvas.append line
        inText = $('<text>').addClass('inLine').text('input').attr {
          x: (curX - curR) / 2
          y: curY
          dy: -2 * options.lineWidth - 4
          'data-start': curId
        }
        canvas.append inText
    if outputLayer
      for neuron in layer
        curX = 1 * neuron.attr 'cx'
        curR = 1 * neuron.attr 'r'
        curY = 1 * neuron.attr 'cy'
        curId = neuron.attr 'data-id'
        line = $('<line>').addClass('outLine').attr {
          x1: curX + curR + options.padding
          x2: dims.width - options.padding
          y1: curY
          y2: curY
          'marker-end': 'url(#arrowEnd)'
          'stroke-width': options.lineWidth
          'data-start': curId
        }
        canvas.append line
        outText = $('<text>').addClass('outLine').text('output').attr {
          x: (dims.width + curX + curR) / 2
          y: curY
          dy: -2 * options.lineWidth - 4
          'data-start': curId
        }
        canvas.append outText
    else
      # arrow to right
      for neuron in layer
        curX = 1 * neuron.attr('cx')
        curR = 1 * neuron.attr 'r'
        startX = curX + curR + options.padding
        startY = 1 * neuron.attr 'cy'
        startId = neuron.attr 'data-id'

        for endNeuron in neurons[i + 1]
          endCurX = 1 * endNeuron.attr('cx')
          endR = 1 * endNeuron.attr 'r'
          endY = 1 * endNeuron.attr 'cy'
          endX = endCurX - endR - options.padding
          endId = endNeuron.attr 'data-id'

          w = endX - startX
          h = endY - startY
          scale = if endY isnt startY then options.padding * h / w else 0

          line = $('<line>').addClass('midLine').attr {
            x1: startX
            x2: endX
            y1: startY + scale
            y2: endY - scale
            'marker-end': 'url(#arrowEnd)'
            'stroke-width': options.lineWidth
            'data-start': startId
            'data-end': endId
          }
          canvas.append line

          textX = startX + w / 2
          textY = startY + h / 2
          angle = Math.atan(h / w) * 180 / Math.PI
          outText = $('<text>').addClass('midLine').text('output').attr {
            x: textX
            y: textY
            transform: "rotate(#{angle} #{textX},#{textY})"
            dy: -2 * options.lineWidth - 4
            'data-start': startId
            'data-end': endId
          }
          wText = $('<text>').addClass('midLine').text('weight').attr {
            x: textX
            y: textY
            transform: "rotate(#{angle} #{textX},#{textY})"
            dy: 4 * options.lineWidth + 4
            'data-start': startId
            'data-end': endId
          }
          canvas.append outText
          canvas.append wText

  # put in global (TEMP)
  window.neurons = neurons

createNetwork = (inputs, layers) ->
  drawNetwork(inputs, layers)
  refreshSVG()
  $('.neuron').on('mouseover', highlightNeuron)
  $('.neuron').on('mouseout', highlightNeuron)

draw = () ->
  layers = []
  $('#layers li').each ->
    layers.push 1 * ($ @).find('input').val()
  layers.push 1 * $('#numOutputs').val()
  createNetwork $('#numInputs').val(), layers

hiddenLayers = () ->
  n = 1 * $('#numLayers').val()
  div = $('#layers')
  div.empty()
  if n > 0
    list = $('<ul>')
    div.append list

    for i in [1..n]
      li = $('<li>')
      label = $('<label>').text("Number of neurons in layer #{i}:")
      label.append $('<input>').attr {
        type: 'number'
        min: 1
        max: 6
        value: 2
        'data-id': i
      }
      li.append label
      list.append li

$ ->
  draw()

  $('#redraw').on('click', draw)
  $('#numLayers').on('change', hiddenLayers)