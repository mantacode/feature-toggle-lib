#global module:false

module.exports = (grunt) ->
  grunt.loadNpmTasks("grunt-jasmine-bundle")
  grunt.loadNpmTasks("grunt-contrib-coffee")
  grunt.loadNpmTasks("grunt-contrib-clean")
  grunt.loadNpmTasks("grunt-browserify")

  grunt.initConfig
    spec:
      unit: {}

    clean:
      dist: 'dist'

    coffee:
      compile:
        files:
          'dist/request-decoration.js': 'lib/request-decoration.coffee'

    browserify:
      dist:
        files:
          'dist/feature-toggle-lib.js': 'dist/request-decoration.js'
        options:
          browserifyOptions:
            standalone: 'FtoggleRequestDecoration'

  grunt.registerTask("default", ["spec:unit"])
  grunt.registerTask('build', ['clean:dist', 'coffee:compile', 'browserify:dist'])
