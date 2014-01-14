class NNAnim extends Observer
  constructor: (@view) ->
    super

    @queue = []
    @interval = null
    @delay = 500
  init: () ->
    @listen(@view.network, 'step', @step)
  step: (e) =>
    {type, id, value} = e.data
    neuron = $(".neuron[data-id='#{id}']")
    # Forward
    if type is 'input'
      @queue.push () ->
        $("text.inLine[data-start='#{id}']").text(value)
        $("text.midLine.output[data-start='#{id}']").text(value)
        $("line.inLine").css('stroke', '#000').attr('marker-end', 'url(#arrowEnd)')
        $("line.inLine[data-start='#{id}']").css('stroke', '#f00').attr('marker-end', 'url(#arrowEndRed)')
    else if type is 'inputsDone'
      @queue.push () ->
        $("line.inLine").css('stroke', '#000').attr('marker-end', 'url(#arrowEnd)')
    else if type is 'hidden'
      @queue.push () ->
        $(".midLine").each ->
          ($ @).css('opacity', 0)
        $("text.midLine.output[data-start='#{id}']").text(value)
        $(".midLine[data-end=#{id}]").each ->
          ($ @).css('opacity', 1)
    else if type is 'output'
      @queue.push () ->
        $("text.outLine[data-start='#{id}']").text(value)
    else if type is 'forwardDone' or type is 'deltaDone'
      @queue.push () ->
        $(".midLine").each ->
          ($ @).css('opacity', 0)
    # Backward
    else if type is 'outputDelta'
      @queue.push () ->
        out = $("text.outLine[data-start='#{id}']").text()
        $("text.outLine[data-start='#{id}']").text(out + " (#{value})")
    else if type is 'hiddenDelta'
      @queue.push () ->
        $(".midLine").each ->
          ($ @).css('opacity', 0)
        # we use first because otherwise jQuery takes all of them and concatenates
        out = $("text.midLine.output[data-start='#{id}']").first().text()
        $("text.midLine.output[data-start='#{id}']").text(out + " (#{value})")
        $(".midLine[data-start=#{id}]").each ->
          ($ @).css('opacity', 1)
  start: () ->
    @interval = setInterval(@animate, @delay)
  stop: () ->
    clearInterval @interval
  setDelay: (@delay) ->
    @stop()
    @start()
  animate: () =>
    if @queue.length > 0
      @queue.shift()()
      @view.refreshSVG()
    return

class NNView
  constructor: () ->
    @options = {
      padding: 10
      layerPad: 125
      lineWidth: 2
      sizes: {
        inputNeuron: 40
        neuron: 60
      }
    }
    @neuronCounter = 0
    @network = null

  refreshSVG: () ->
    $('.neuron').off('mouseover', @highlightNeuron)
    $('.neuron').off('mouseout', @highlightNeuron)
    $('#wrap').html $('#wrap').html()
    $('.neuron').on('mouseover', @highlightNeuron)
    $('.neuron').on('mouseout', @highlightNeuron)

  createNeuron: (x, y, r) ->
    $('<circle>').addClass('neuron').attr {
      cx: x
      cy: y
      r: r
      'stroke-width': 2,
      'data-id': @neuronCounter++
    }

  highlightNeuron: (e) ->
    curId = ($ @).attr('data-id')
    opacity = ~~(e.type is 'mouseover')
    $(".midLine[data-start=#{curId}], .midLine[data-end=#{curId}]").each ->
      ($ @).css('opacity', opacity)

  drawNetwork: (inputs, layers) ->
    ctx = $('#canvas')
    canvas = $('#canvas g')
    canvas.empty()

    dims = {
      width: ctx.width()
      height: ctx.height()
    }
    neurons = []
    networkNeurons = @network?.listNeurons()

    # input layer
    inputHeight = dims.height / inputs
    inputWidth = @options.sizes.inputNeuron + 2 * @options.padding
    curLayer = []
    for i in [0...inputs]
      neuron = @createNeuron(@options.layerPad + inputWidth / 2, (i + 1 / 2) * inputHeight, @options.sizes.inputNeuron / 2).addClass('inputNeuron')
      curLayer.push neuron
      canvas.append neuron
    neurons.push curLayer

    # neuron layers
    startWidth = @options.sizes.inputNeuron + 2 * @options.padding + @options.layerPad
    neuronWidth = @options.sizes.neuron + 2 * @options.padding
    for numNeurons, layer in layers
      neuronHeight = dims.height / numNeurons
      curLayer = []
      for i in [0...numNeurons]
        x = startWidth + layer * (@options.sizes.neuron + 2 * @options.padding) +
              (layer + 1) * @options.layerPad
        neuron = @createNeuron(x + neuronWidth / 2, (i + 1 / 2) * neuronHeight, @options.sizes.neuron / 2).addClass('regularNeuron')
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
            x1: @options.padding
            x2: curX - curR - @options.padding
            y1: curY
            y2: curY
            'marker-end': 'url(#arrowEnd)'
            'stroke-width': @options.lineWidth
            'data-start': curId
          }
          canvas.append line
          inText = $('<text>').addClass('inLine').text('input').attr {
            x: (curX - curR) / 2
            y: curY
            dy: -2 * @options.lineWidth - 4
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
            x1: curX + curR + @options.padding
            x2: dims.width - @options.padding
            y1: curY
            y2: curY
            'marker-end': 'url(#arrowEnd)'
            'stroke-width': @options.lineWidth
            'data-start': curId
          }
          canvas.append line
          outText = $('<text>').addClass('outLine').text('output').attr {
            x: (dims.width + curX + curR) / 2
            y: curY
            dy: -2 * @options.lineWidth - 4
            'data-start': curId
          }
          canvas.append outText
      else
        # arrow to right
        for neuron, neuronIndex in layer
          curX = 1 * neuron.attr('cx')
          curR = 1 * neuron.attr 'r'
          startX = curX + curR + @options.padding
          startY = 1 * neuron.attr 'cy'
          startId = neuron.attr 'data-id'

          for endNeuron in neurons[i + 1]
            endCurX = 1 * endNeuron.attr('cx')
            endR = 1 * endNeuron.attr 'r'
            endY = 1 * endNeuron.attr 'cy'
            endX = endCurX - endR - @options.padding
            endId = endNeuron.attr 'data-id'

            w = endX - startX
            h = endY - startY
            scale = if endY isnt startY then @options.padding * h / w else 0

            line = $('<line>').addClass('midLine').attr {
              x1: startX
              x2: endX
              y1: startY + scale
              y2: endY - scale
              'marker-end': 'url(#arrowEnd)'
              'stroke-width': @options.lineWidth
              'data-start': startId
              'data-end': endId
            }
            canvas.append line

            textX = startX + w / 2
            textY = startY + h / 2
            angle = Math.atan(h / w) * 180 / Math.PI
            outText = $('<text>').addClass('midLine').addClass('output').text('output').attr {
              x: textX
              y: textY
              transform: "rotate(#{angle} #{textX},#{textY})"
              dy: -2 * @options.lineWidth - 4
              'data-start': startId
              'data-end': endId
            }
            weight = networkNeurons[endId - inputs].weights[neuronIndex]
            weight = roundTo(weight, 2)
            wText = $('<text>').addClass('midLine').addClass('weight').text(weight).attr {
              x: textX
              y: textY
              transform: "rotate(#{angle} #{textX},#{textY})"
              dy: 4 * @options.lineWidth + 4
              'data-start': startId
              'data-end': endId
            }
            canvas.append outText
            canvas.append wText

    # put in global (TEMP)
    window.neurons = neurons

  createNetwork: (inputs, layers) ->
    @drawNetwork(inputs, layers)
    @refreshSVG()

  hiddenLayers: () ->
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

  setNetwork: (network) ->
    @network = network

  layerData: () ->
    numInputs = 1 * $('#numInputs').val()
    hiddenLayers = []
    $('#layers li').each ->
      hiddenLayers.push 1 * ($ @).find('input').val()
    numOutputs = 1 * $('#numOutputs').val()
    [numInputs, hiddenLayers, numOutputs]

  draw: () =>
    @neuronCounter = 0
    [numInputs, hiddenLayers, numOutputs] = @layerData()
    layers = hiddenLayers.concat numOutputs
    @createNetwork numInputs, layers