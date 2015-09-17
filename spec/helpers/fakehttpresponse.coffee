global.FakeHttpResponse = class FakeHttpResponse
  constructor: ->
    @cookies = {}
  cookie: (key, val, options) ->
    @cookies[key] = val
    @cookies["#{key}--options"] = options
  clearCookie: jasmine.createSpy 'clearCookie'
