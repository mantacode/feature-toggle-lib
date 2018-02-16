_ = require 'lodash'
listify = require 'listify'

beforeEach ->
  @addMatchers
    toHaveOneEnabled: (keys...) ->
      actualKeys = _.without(_.keys(@actual), 'e')
      @message = ->
        return [
          "Expected #{actualKeys} to have only one of #{listify(keys)} enabled",
          "Expected #{actualKeys} not to have one of #{listify(keys)} enabled"
        ]
      return _.intersection(actualKeys, keys).length == 1

    toContainOneOf: (vals...) ->
      @message = =>
        return [
          "Expected #{@actual} to contain only one of #{listify(vals)}",
          "Expected #{@actual} not to contain only one of #{listify(vals)}"
        ]
      return _.intersection(@actual, vals).length == 1

    toBeOneOf: (vals...) ->
      @message = =>
        return [
          "Expected #{@actual} to be one of #{listify(vals)}",
          "Expected #{@actual} not to be one of #{listify(vals)}"
        ]

      return vals.includes(@actual)
