$ ->
  draw()

  $('#redraw').on('click', draw)
  $('#numLayers').on('change', hiddenLayers)