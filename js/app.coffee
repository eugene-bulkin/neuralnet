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
    @anim.stop()
    [numInputs, hiddenLayers, numOutputs] = @view.layerData()
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

  setHandlers: () ->
    $(window).on('resize', @onResize)

    $('#reinit').on('click', @initialize)
    $('#numLayers').on('change', @view.hiddenLayers)
  onResize: (e) =>
    @view.draw()

$ ->
  window.app = new NNApp()
  app.loadFromStorage()
  app.initialize()
  app.setHandlers()