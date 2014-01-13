global.FakeHttpResponse = class FakeHttpResponse
  constructor: ->
    @cookies = {}
  cookie: (key, val) ->
    @cookies[key] = val
