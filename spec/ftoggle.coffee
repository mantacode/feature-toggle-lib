sampleConfig1 =
  version: 1
  features:
    feat1:
      traffic: 1
      features:
        subfeat1:
          traffic: 1 
        subfeat2:
          traffic: 0 
    feat2:
      traffic: .5
    feat3:
      traffic: 0
    feat4:
      traffic: 1
      

describe 'can instantiate middleware function', ->
  Given -> @ftoggleLib = requireSubject 'lib/ftoggle'
  When  -> @ftoggle = @ftoggleLib.makeFtoggle().newMiddleware()
  Then  -> expect(typeof @ftoggle).toBe 'function'

describe 'adds a formally correct ftoggle bundle to the request', ->
  Given ->
    @ftoggleLib = requireSubject 'lib/ftoggle'
    @ftoggleParent = @ftoggleLib.makeFtoggle();
    @ftoggle = @ftoggleParent.newMiddleware()
  When ->
    @req = {}
    @res = {}
    @next = -> # will need to do this async at some point...
    @ftoggle(@req, @res, @next)
  Then -> expect(typeof @req.ftoggle).toBe 'object'
  And  -> expect(typeof @req.ftoggle.isFeatureEnabled).toBe 'function'
  And  -> expect(typeof @ftoggleParent.getConfig).toBe 'function'
  And  -> expect(typeof @ftoggleParent.setConfig).toBe 'function'

describe 'achieves correct traffic allocation', ->
  Given ->
    @ftoggleLib = requireSubject 'lib/ftoggle'
    @ftoggleParent = @ftoggleLib.makeFtoggle();
    @ftoggleParent.setConfig(sampleConfig1)
    @ftoggle = @ftoggleParent.newMiddleware()
    @res = {}
    @next = -> # will need to do this async at some point...
  When ->
    @req = {}
    @ftoggle(@req, @res, @next)
  Then -> @req.ftoggle.isFeatureEnabled('feat4') == true
  And  -> @req.ftoggle.isFeatureEnabled('feat3') == false
  And  -> @req.ftoggle.isFeatureEnabled('feat1.subfeat1') == true
  And  -> @req.ftoggle.isFeatureEnabled('feat1.subfeat2') == false

describe 'percentage traffic works', ->
  Given ->
    @ftoggleParent = requireSubject('lib/ftoggle').makeFtoggle()
    @ftoggleParent.setConfig(sampleConfig1)
    @ftoggle = @ftoggleParent.newMiddleware()
  When ->
    @req = {}
    @ftoggleParent.roll = ->  0.4 ;
    @ftoggle(@req, {}, -> )
  Then ->
    @req.ftoggle.isFeatureEnabled('feat2') == true

describe 'percentage traffic works (2)', ->
  Given ->
    @ftoggleParent = requireSubject('lib/ftoggle').makeFtoggle()
    @ftoggleParent.setConfig(sampleConfig1)
    @ftoggle = @ftoggleParent.newMiddleware()
  When ->
    @req = {}
    @ftoggleParent.roll = -> 0.6 ;
    @ftoggle(@req, {}, -> )
  Then ->
    @req.ftoggle.isFeatureEnabled('feat2') == false

