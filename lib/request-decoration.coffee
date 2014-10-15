module.exports = class RequestDecoration
  constructor: (@config, @featureVals = {}) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    #featureNodes = @lookupFeature(feature.split("."), @objClone(@config))
    
    #if enabled = (featureNodes? && featureNodes.enabled)
    enabled = Boolean(@safe(@config, feature + '.enabled'))
    if enabled
      trueCallback?(feature)
    else
      falseCallback?(feature)
    enabled

  findEnabledChildren: (prefix) ->
    p = []
    p = prefix.split(".") if prefix?
    feature = @lookupFeature(p, @config)
    return [] unless feature
    children = @filter Object.keys(feature), (k) ->
      feature[k].enabled == true
    if children? then children else []

  doesFeatureExist: (feature) ->
    nodes = @lookupFeature(feature.split("."), @config)
    return nodes?

  getFeatures: () ->
    @config


  featureVal: (key) ->
    if @featureVals[key]? then @featureVals[key] else null

  getFeatureVals: () ->
    @featureVals

  #private

  lookupFeature: (path, nodes, over = null) ->
    current = path.shift()
    nodes.enabled = over if nodes? and over?
    if current? && nodes?
      over = false if nodes.enabled? && nodes.enabled == false
      @lookupFeature(path, nodes[current], over)
    else
      nodes

  # not using underscore here, for front-end reasons
  filter: (list, f) ->
    out = []
    list.forEach (e) ->
      if f(e)
        out.push e
    return out

  # same story; limiting dependencies
  objClone: (o) ->
    if typeof o == 'object'
      out = {}
      out[k] = @objClone(v) for k, v of o
      return out
    else
      return o
  
  isObject: (obj) ->
    # Implementation lifted from underscore
    typeof obj is "function" or typeof obj is "object" and !!obj
  
  safe: (obj, path, otherwise) ->
    return otherwise unless path
    obj = (if @isObject(obj) then obj else {})
    props = path.split(".")
    if props.length is 1
      if typeof obj[props[0]] is "undefined"
        otherwise
      else if obj[props[0]] is null
        (if typeof otherwise is "undefined" then null else otherwise)
      else
        obj[props.shift()]
    else
      prop = props.shift()
      (if @isObject(obj[prop]) then @safe(obj[prop], props.join("."), otherwise) else otherwise)
