describe 'can instantiate middleware function', ->
  Given -> @ftoggleLib = requireSubject 'lib/ftoggle'
  When  -> @ftoggle = @ftoggleLib.newMiddleware()
  Then  -> expect(typeof @ftoggle).toBe 'function'
