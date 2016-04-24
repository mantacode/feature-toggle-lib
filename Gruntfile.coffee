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

    watch:
      unit:
        files: ['lib/**/*.js', 'spec/**/*.coffee']
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
          'dist/ftoggle.js': 'lib/ftoggle.js',
        options:
          browserifyOptions:
            standalone: 'Ftoggle'
      standalone:
        files:
          'dist/ftoggle-standalone.js': 'lib/ftoggle.js'
        options:
          exclude: ['lodash']
          browserifyOptions:
            standalone: 'Ftoggle'

  grunt.registerTask('default', ['only:dev', 'spec'])
  grunt.registerTask('build', ['clean:dist', 'browserify'])
  grunt.registerTask('ci', ['only:ci', 'spec'])
