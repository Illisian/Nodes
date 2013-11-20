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
      tasks: ['build']
    plato:
      default:
        options: 
          exclude: new RegExp("^.*public/*.*.js$", "i")
        files:
          'report/': ['build/**/*.js']
    nodemon:
      dev:
        options:
          args: ['dev']
          file: 'build/app.js'
          nodeArgs: ['--debug']
          watchedExtensions: ['js'],
          watchedFolders: ['build']
        #env: 
        #  PORT: '8282'
    'node-inspector':
      dev:
        options:
          'web-port': 1337,
          'web-host': 'localhost',
          'debug-port': 5858,
          'save-live-edit': true,
          'stack-trace-limit': 4
    concurrent:
      devtasks:
        tasks: ['nodemon', 'watch', 'node-inspector']
        options:
          logConcurrentOutput: true

  grunt.loadNpmTasks 'grunt-contrib-copy';
  grunt.loadNpmTasks 'grunt-contrib-clean';
  grunt.loadNpmTasks 'grunt-contrib-coffee';
  grunt.loadNpmTasks 'grunt-contrib-watch';
  grunt.loadNpmTasks 'grunt-plato';
  grunt.loadNpmTasks 'grunt-install-dependencies';
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-nodemon';
  grunt.loadNpmTasks 'grunt-node-inspector';
  
  
  grunt.registerTask 'test', 'Runs build and test', [ 'install-dependencies', 'clean', 'copy', 'coffee' ]
  grunt.registerTask 'default', 'Compiles all of the assets and copies the files to the build directory.', [ 'install-dependencies', 'clean', 'copy', 'coffee', 'plato', 'concurrent:devtasks' ]
  grunt.registerTask 'build', 'Compiles all of the assets and copies the files to the build directory.', [ 'install-dependencies', 'clean', 'copy', 'coffee', 'plato' ]
  grunt.registerTask 'clear', 'Clears all files from the build directory.', [ 'clean' ]
 
  