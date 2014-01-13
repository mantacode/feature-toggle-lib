global.FakeHttpRequest = class FakeHttpRequest
  constructor: ->
    @cookies = {}
    @params = {}
  param: (name) -> @params[name]
