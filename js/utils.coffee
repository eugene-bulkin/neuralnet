sum = (l) -> l.reduce (a, b) -> a + b
zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.min(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments
roundTo = (number, to) ->
  Math.round(number * Math.pow(10, to)) / Math.pow(10, to)