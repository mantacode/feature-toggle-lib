#global module:false

module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-jasmine-bundle")

  grunt.initConfig
    spec:
      unit: {}

  grunt.registerTask("default", ["spec:unit"])

