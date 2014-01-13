$ ->
  view = new NNView()
  view.draw()

  $('#redraw').on('click', view.draw)
  $('#numLayers').on('change', view.hiddenLayers)