_ = require 'lodash'

beforeEach ->
  @addMatchers
    toHaveOneEnabled: (keys...) ->
      actualKeys = _.without(_.keys(@actual), 'e')
      @message = ->
        return [
          "Expected #{actualKeys} to have only one of #{keys} enabled",
          "Expected #{actualKeys} not to have one of #{keys} enabled"
        ]
      return _.intersection(actualKeys, keys).length == 1

    toContainOneOf: (vals...) ->
      @message = =>
        return [
          "Expected #{@actual} to contain only one of #{vals}",
          "Expected #{@actual} not to contain only one of #{vals}"
        ]
      return _.intersection(@actual, vals).length == 1
