#global module:false

module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-jasmine-bundle")

  grunt.initConfig
    spec:
      unit:
        options:
          helpers: "spec/helpers/**/*.{js,coffee}"
          specs: "spec/**/*.{js,coffee}"
      e2e:
        options:
          helpers: "spec/helpers/**/*.{js,coffee}"
          specs: "spec-e2e/**/*.{js,coffee}"

  grunt.registerTask("default", ["spec:unit", "spec:e2e"])

