sum = (l) -> l.reduce (a, b) -> a + b
flatten = (l) -> l.reduce (a, b) -> a.concat b
zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.min(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments
roundTo = (number, to) ->
  Math.round(number * Math.pow(10, to)) / Math.pow(10, to)

guid = () ->
  s4 = () -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
  s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()

class Observable
  constructor: () ->
    @subscribers = []
    @id = guid()
  fire: (eventType, data = null) ->
    @subscribers.forEach (s) => s.notify(@id, eventType, data)
    return
  # precondition: observer not already subscribed
  subscribe: (observer) ->
    @subscribers.push observer
    return
  unsubscribe: (observer) ->
    for s, i in @subscribers
      if s is observer
        @subscribers.splice(i, 1)
        break
    return
  destroy: () ->
    @subscribers.forEach (s) => s.remove @
    return

class Observer
  constructor: () ->
    @subjects = []
    @listeners = {}
  listen: (obj, evt, cb) ->
    if obj not in @subjects
      obj.subscribe @
      @subjects.push obj.id
      @listeners[obj.id] = {}
    @listeners[obj.id][evt] = cb
    return
  notify: (objId, eventType, data) ->
    if eventType of @listeners[objId]
      @listeners[objId][eventType] {
        eventType: eventType
        data: data
      }
    return
  remove: (subject) ->
    for s, i in @subjects
      if s is subject.id
        delete @listeners[s.id]
        @subjects.splice(i, 1)
        break
    return
