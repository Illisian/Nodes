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
        [ 'build', 'report' ]
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
        'Gruntfile.coffee',
        'src/**/*'
      ]
      tasks: ['default']
    plato:
      default:
        options: 
          exclude: new RegExp("^.*public/*.*.js$", "i")

        files:
          'report/': ['src/**/*.js']
        
        

  grunt.loadNpmTasks 'grunt-contrib-copy';
  grunt.loadNpmTasks 'grunt-contrib-clean';
  grunt.loadNpmTasks 'grunt-contrib-coffee';
  grunt.loadNpmTasks 'grunt-contrib-watch';
  grunt.loadNpmTasks 'grunt-plato';
  
  
  grunt.registerTask 'default', 'Compiles all of the assets and copies the files to the build directory.', [ 'clean', 'copy', 'coffee', 'plato' ]
  grunt.registerTask 'clear', 'Clears all files from the build directory.', [ 'clean' ]
 
  