global.FakeHttpRequest = class FakeHttpRequest
  constructor: ->
    @cookies = {}
    @params = {}
    @headers = {}
  param: (name) -> @params[name]
  
