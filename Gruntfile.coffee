#global module:false

module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-jasmine-bundle")
  grunt.loadNpmTasks("grunt-contrib-jshint")

  grunt.initConfig
    spec:
      unit:
        helpers: "spec/helpers/**/*.{js,coffee}",
        specs: "spec/**/*.{js,coffee}"
      e2e:
        helpers: "spec-e2e/helpers/**/*.{js,coffee}",
        specs: "spec-e2e/**/*.{js,coffee}"

    coverage:
      options:
        ignorePaths: ["spec-e2e/**", "spec/**", "coverage/**"]

      unit:
        options:
          task: "spec:unit"
          reportPath: "coverage/unit"

      e2e:
        options:
          task: "spec:e2e"
          reportPath: "coverage/e2e"

    jshint:
      options:
        force: false
        curly: true
        eqeqeq: true
        newcap: true
        noarg: true
        sub: true
        undef: false
        boss: true
        eqnull: true
        node: true
        indent: 2

  grunt.registerTask("default", ["jshint", "spec:unit", "spec:e2e"])

