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
          'dist/feature-toggle-lib.js': 'dist/request-decoration.js',
        options:
          browserifyOptions:
            standalone: 'FtoggleRequestDecoration'

      # This task is currently not working. For whatever reason, lodash is not excluded no matter what I do.
      # I've opened an issue here: https://github.com/jmreidy/grunt-browserify/issues/348. For now, you can build
      # a standalone script manually by installing browserify globally (npm i -g browserify) and then running:
      # browserify dist/request-decoration.js --exclude lodash --standalone FtoggleRequestDecoration > dist/feature-toggle-lib-standalone.js
      
      #standalone:
        #files:
          #'dist/feature-toggle-lib-standalone.js': 'dist/request-decoration.js'
        #options:
          #exclude: 'lodash'
          #browserifyOptions:
            #standalone: 'FtoggleRequestDecoration'

  grunt.registerTask("default", ["spec:unit"])
  grunt.registerTask('build', ['clean:dist', 'coffee:compile', 'browserify'])
