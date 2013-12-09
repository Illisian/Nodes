module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
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
    forever:
      options:
        index: 'build/app.js'
        logDir: 'logs'
        command: 'node --debug=10002'

#    nodemon:
#      dev:
#        options:
#          args: ['dev']
#          file: 'build/app.js'
#          nodeArgs: ['--debug=10002']
#          watchedExtensions: ['js'],
#          watchedFolders: ['build'],
#          delay: 20
#        #env: 
#        #  PORT: '8282'
    'node-inspector':
      dev:
        options:
          'web-port': 1337,
          'web-host': 'localhost',
          'debug-port': 10002,
          'save-live-edit': true,
          'stack-trace-limit': 4
    concurrent:
      run:
        tasks: ['nodemon']
        options:
          logConcurrentOutput: true
      debug:
        tasks: ['watch', 'node-inspector']
        options:
          logConcurrentOutput: true
    shell: 
      codo: 
        options:
          stdout: true
        command: 'codo ./src'
      projectz: 
        options:
          stdout: true
        command: 'projectz compile'
      'forever-stop':
        options:
          stdout: true
        command: "forever stop build/app.js"
      'forever-start':
        options:
          stdout: true
        command: "forever start -c 'node --debug=10002' build/app.js"

  grunt.loadNpmTasks 'grunt-shell';
  grunt.loadNpmTasks 'grunt-contrib-copy';
  grunt.loadNpmTasks 'grunt-contrib-clean';
  grunt.loadNpmTasks 'grunt-contrib-coffee';
  grunt.loadNpmTasks 'grunt-contrib-watch';
  grunt.loadNpmTasks 'grunt-plato';
  grunt.loadNpmTasks 'grunt-install-dependencies';
  grunt.loadNpmTasks 'grunt-concurrent'
  grunt.loadNpmTasks 'grunt-node-inspector';
  grunt.loadNpmTasks 'grunt-forever'
  
  
  grunt.registerTask 'test', 'Runs build and test', [ 'default' ]
  grunt.registerTask 'default', 'Compiles all of the assets and copies the files to the build directory.', [ 'build' ]
  grunt.registerTask 'clear', 'Clears all files from the build directory.', [ 'clean' ]
  grunt.registerTask 'run', 'Clears all files from the build directory.', [ 'default', 'concurrent:run' ]
  grunt.registerTask 'debug', 'Clears all files from the build directory.', [ 'watchnbuild', 'concurrent:debug' ]
  
  grunt.registerTask 'watchnbuild', 'Watch and Build', [ 'shellforever:stop', 'build', 'doc', 'forever:start' ]

  grunt.registerTask 'build', 'Builds the application', [ 'install-dependencies', 'clean', 'copy', 'coffee' ]
  grunt.registerTask 'doc', 'Builds the application documentation', [ 'plato', 'shell:projectz', 'shell:codo' ]
 
  