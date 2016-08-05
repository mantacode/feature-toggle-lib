#global module:false

module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-jasmine-bundle')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-only')

  grunt.initConfig
    spec:
      unit:
        options:
          helpers: ['spec/helpers/**/*.coffee']
          specs: ['spec/**/*.coffee']
      e2e:
        options:
          helpers: ['spec-e2e/helpers/**/*.coffee']
          specs: ['spec-e2e/**/*.coffee', '!spec-e2e/fixtures/**']
    only:
      dev:
        options:
          fail: false
      ci: {}

    clean:
      dist: 'dist'

    coffee:
      compile:
        files:
          'dist/request-decoration.js': 'lib/request-decoration.coffee'

    watch:
      unit:
        files: ['lib/**/*.coffee', 'spec/**/*.coffee']
        tasks: ['spec:unit']
        options:
          atBegin: true
      e2e:
        files: ['lib/**', 'spec-e2e/**']
        tasks: ['spec:e2e']
        options:
          atBegin: true

    browserify:
      dist:
        files:
          'dist/feature-toggle-lib.js': 'dist/request-decoration.js',
        options:
          browserifyOptions:
            standalone: 'FtoggleRequestDecoration'
      standalone:
        files:
          'dist/feature-toggle-lib-standalone.js': 'dist/request-decoration.js'
        options:
          exclude: ['lodash']
          browserifyOptions:
            standalone: 'FtoggleRequestDecoration'

  grunt.registerTask('default', ['only:dev', 'spec'])
  grunt.registerTask('build', ['clean:dist', 'coffee:compile', 'browserify'])
  grunt.registerTask('ci', ['only:ci', 'spec'])
