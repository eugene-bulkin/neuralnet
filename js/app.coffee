class NNApp
  constructor: () ->
    @view = new NNView()
    @network = null
  saveToStorage: (numInputs, hiddenLayers, numOutputs) ->
    obj = {
      numInputs: numInputs
      hiddenLayers: hiddenLayers
      numOutputs: numOutputs
    }
    window.localStorage.setItem('neuralnet', JSON.stringify obj)
  loadFromStorage: () ->
    data = JSON.parse window.localStorage.getItem 'neuralnet'
    if not data then return
    {numInputs, hiddenLayers, numOutputs} = data
    $('#numLayers').val(hiddenLayers.length)
    $('#numInputs').val(numInputs)
    $('#numOutputs').val(numOutputs)
    @view.hiddenLayers()
    $('#layers li').each (i) ->
      ($ @).find('input').val(hiddenLayers[i])
  initialize: () =>
    [numInputs, hiddenLayers, numOutputs] = @view.layerData()
    @saveToStorage(numInputs, hiddenLayers, numOutputs)
    @network = new NeuralNetwork numInputs
    for layer in hiddenLayers
      @network.addLayer layer
    @network.addOutputLayer numOutputs
    @view.setNetwork @network
    @view.draw()

$ ->
  app = new NNApp()
  app.loadFromStorage()
  app.initialize()

  $('#reinit').on('click', app.initialize)
  $('#numLayers').on('change', app.view.hiddenLayers)