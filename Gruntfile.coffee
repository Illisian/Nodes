module.exports = (grunt) ->
  grunt.initConfig
    pkg: '<json:package.json>'
    copy:
      build:
        cwd: 'src'
        src: [ '**', '!**/*.coffee' ]
        dest: 'build'
        expand: true
    clean:
      build:
        [ 'build' ]
    coffee:
      lib:
        files:[
          expand: true
          cwd: 'src'
          src: ['**/*.coffee']
          dest: 'build'
          ext: '.js'
        ]
    watch:
      files: [
        'Gruntfile.coffee'
        'src/**/*'
        'package.json'
      ]
      tasks: ['default']
    plato:
      default:
        options: 
          exclude: new RegExp("^.*public/*.*.js$", "i")
        files:
          'report/': ['build/**/*.js']

  grunt.loadNpmTasks 'grunt-contrib-copy';
  grunt.loadNpmTasks 'grunt-contrib-clean';
  grunt.loadNpmTasks 'grunt-contrib-coffee';
  grunt.loadNpmTasks 'grunt-contrib-watch';
  grunt.loadNpmTasks 'grunt-plato';
  grunt.loadNpmTasks 'grunt-install-dependencies';
  
  
  grunt.registerTask 'default', 'Compiles all of the assets and copies the files to the build directory.', [ 'install-dependencies', 'clean', 'copy', 'coffee', 'plato' ]
  grunt.registerTask 'clear', 'Clears all files from the build directory.', [ 'clean' ]
 
  