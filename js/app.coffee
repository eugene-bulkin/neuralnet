class NNApp
  constructor: () ->
    @view = new NNView()
    @anim = new NNAnim(@view)
    @network = null
  saveToStorage: (numInputs, hiddenLayers, numOutputs) ->
    obj = {
      numInputs: numInputs
      hiddenLayers: hiddenLayers
      numOutputs: numOutputs
    }
    window.localStorage.setItem('neuralnet', JSON.stringify obj)
    return
  getFromStorage: () ->
    data = JSON.parse window.localStorage.getItem 'neuralnet'
    if not data then return null
    {numInputs, hiddenLayers, numOutputs} = data
    [numInputs, hiddenLayers, numOutputs]
  addHiddenLayer: () =>
    len = $('#layers li').length
    if len < 3
      li = $('<li>').append($('<label>').text("Layer #{len + 1}:")).append $('<input>').attr {
        type: 'number'
        min: 1
        max: 6
        value: 2
        'data-id': len + 1
      }
      closeBtn = $('<button>X</button>').attr('data-id', len + 1)
      closeBtn.on('click', @removeLayer)
      li.append closeBtn
      $('#layers ul').append li
    [numInputs, hiddenLayers, numOutputs] = @view.layerData()
    @saveToStorage(numInputs, hiddenLayers, numOutputs)
  removeLayer: () ->
    curId = ($ @).attr('data-id')
    # remove old list element
    $("#layers [data-id=#{curId}]").parent('li').remove()
    # renumber everything
    $('#layers li').each (i) ->
      ($ @).find('label').text("Layer #{i + 1}:")
      ($ @).find('input').attr('data-id', i + 1)
      ($ @).find('button').attr('data-id', i + 1)
  populateForm: () ->
    $('#form').empty()
    [numInputs, hiddenLayers, numOutputs] = @getFromStorage()
    $('#form').append $('<label>').text('Number of inputs:').append $('<input id="numInputs">').attr {
      type: 'number'
      min: 1
      max: 6
      value: numInputs
    }
    $('#form').append $('<label>').text('Number of outputs:').append $('<input id="numOutputs">').attr {
      type: 'number'
      min: 1
      max: 6
      value: numOutputs
    }
    $('#form').append $('<br>')
    $('#form').append $('<div id="layers">Hidden layers <button id="addLayer">+</button>: <ul></ul></div>')
    $('button#addLayer').on('click', @addHiddenLayer)
    for layer, i in hiddenLayers
      li = $('<li>').append($('<label>').text("Layer #{i + 1}:")).append $('<input>').attr {
        type: 'number'
        min: 1
        max: 6
        value: layer
        'data-id': i + 1
      }
      closeBtn = $('<button>X</button>').attr('data-id', i + 1)
      closeBtn.on('click', @removeLayer)
      li.append closeBtn
      $('#layers ul').append li
    $('#forward ul').empty()
    for i in [1..numInputs]
      $('#forward ul').append $('<li>').append $('<input>')
  initialize: () =>
    @anim.stop()
    [numInputs, hiddenLayers, numOutputs] = @getFromStorage()
    @populateForm()
    @saveToStorage(numInputs, hiddenLayers, numOutputs)
    @network?.destroy()
    @network = new NeuralNetwork numInputs
    for layer in hiddenLayers
      @network.addLayer layer
    @network.addOutputLayer numOutputs
    @view.setNetwork @network
    @anim.init()
    @anim.start()
    @view.draw()
    return
  forwardKeyPress: (e) =>
    if e.keyCode is 13
      @forward e
  forward: (e) =>
    inputs = []
    $('#forward li').each (i) ->
      inputs.push parseFloat ($ @).find('input').val()
    @network.forward inputs
  setHandlers: () ->
    $(window).on('resize', @onResize)

    $('#reinit').on('click', () =>
      [numInputs, hiddenLayers, numOutputs] = @view.layerData()
      @saveToStorage(numInputs, hiddenLayers, numOutputs)
      @initialize()
    )

    $('#forward button').on('click', @forward)
    $('#forward input').on('keypress', @forwardKeyPress)
    return
  onResize: (e) =>
    @view.draw()
    return

$ ->
  window.app = new NNApp()
  app.initialize()
  app.setHandlers()