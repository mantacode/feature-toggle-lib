global.FakeHttpRequest = class FakeHttpRequest
  constructor: ->
    @cookies = {}
    @query = {}
    @params = {}
    @headers = {}
  param: (name) -> @params[name]
  
