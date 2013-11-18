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

  grunt.loadNpmTasks 'grunt-contrib-copy';
  grunt.loadNpmTasks 'grunt-contrib-clean';
  grunt.loadNpmTasks 'grunt-contrib-coffee';
  grunt.registerTask 'build', 'Compiles all of the assets and copies the files to the build directory.', [ 'clean', 'copy', 'coffee' ]
  grunt.registerTask 'clear', 'Clears all files from the build directory.', [ 'clean' ]
 
  