class NNApp
  constructor: () ->
    @view = new NNView()
    @network = null
  initialize: () =>
    [numInputs, hiddenLayers, numOutputs] = @view.layerData()
    @network = new NeuralNetwork numInputs
    for layer in hiddenLayers
      @network.addLayer layer
    @network.addOutputLayer numOutputs
    @view.setNetwork @network
    @view.draw()

$ ->
  app = new NNApp()
  app.initialize()

  $('#reinit').on('click', app.initialize)
  $('#numLayers').on('change', app.view.hiddenLayers)