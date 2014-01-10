sampleConfig1 =
  version: 1
  features:
    feat1:
      traffic:
        public: 1
      features:
        subfeat1:
          traffic: .5
        subfeat2:
          traffic: .5
    feat2:
      public: .5
    feat3:
      public: 0
    feat4:
      public: 1
      

describe 'can instantiate middleware function', ->
  Given -> @ftoggleLib = requireSubject 'lib/ftoggle'
  When  -> @ftoggle = @ftoggleLib.newMiddleware()
  Then  -> expect(typeof @ftoggle).toBe 'function'

describe 'adds a formally correct ftoggle bundle to the request', ->
  Given ->
    @ftoggleLib = requireSubject 'lib/ftoggle'
    @ftoggle = @ftoggleLib.newMiddleware()
  When ->
    @req = {}
    @res = {}
    @next = -> # will need to do this async at some point...
    @ftoggle(@req, @res, @next)
  Then -> expect(typeof @req.ftoggle).toBe 'object'
  And  -> expect(typeof @req.ftoggle.isFeatureEnabled).toBe 'function'
  And  -> expect(typeof @req.ftoggle.getConfig).toBe 'function'
  And  -> expect(typeof @req.ftoggle.setConfig).toBe 'function'
