module.exports = (grunt) ->

  grunt.initConfig {
    pkg: grunt.file.readJSON('package.json')
    # monitoring
    watch: {
      scripts: {
        files: 'js/*.coffee'
        tasks: ['coffeelint', 'coffee']
      }
      styles: {
        files: ['*.scss']
        tasks: ['sass']
      }
      templates: {
        files: ['*.jade']
        tasks: ['jade']
      }
    }
    # processing
    coffeelint: {
      app: {
        files: {
          src: ['js/*.coffee']
        }
        options: {
          max_line_length: {
            level: 'ignore'
          }
        }
      }
    }
    autoprefixer: {
      styles: {
        src: 'style.css'
        dest: 'style.css'
      }
    }
    csso: {
      compress: {
        options: {
          report: 'gzip'
        }
        files: {
          'style.css': ['style.css']
        }
      }
    }
    uglify: {
      script: {
        files: {
          'neuralnet.js': ['neuralnet.js']
        }
        sourceMapIn: 'neuralnet.js.map'
      }
    }
    # compilation
    sass: {
      dist: {
        options: {
          style: 'expanded'
          sourcemap: true
        },
        files: {
          'style.css': 'style.scss'
        }
      }
    }
    coffee: {
      compile: {
        options: {
          sourceMap: true
        }
        files: {
          'neuralnet.js': ['js/utils.coffee', 'js/network.coffee', 'js/visualization.coffee', 'js/app.coffee']
        }
      }
    }
    jade: {
      dist: {
        options: {
          pretty: true,
          doctype: 'html'
        }
        files: [{
            expand: true
            cwd: './'
            src: ['*.jade']
            dest: './'
            ext: '.html'
        }]
      }
    }
  }

  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-sass')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-autoprefixer')
  grunt.loadNpmTasks('grunt-csso')

  grunt.registerTask('compile', (args...) ->
    tasks = []
    prod = 'production' in args
    msg = "BUILDING FOR #{if prod then 'PRODUCTION' else 'DEVELOPMENT'}"
    spaces = (" " for i in [0..7]).join('')
    equals = ("=" for i in [1..(msg.length + 2 * spaces.length)]).join('')
    console.log "#{equals}\n#{spaces}#{msg}#{spaces}\n#{equals}"
    # additional ones remove from compilation
    if 'coffee' not in args
      tasks = tasks.concat ['coffeelint', 'coffee']
      if prod then tasks = tasks.concat ['uglify']
    if 'sass' not in args
      tasks = tasks.concat ['sass', 'autoprefixer']
      if prod then tasks.push 'csso'
    if 'jade' not in args
      tasks.push 'jade'
    grunt.task.run tasks
  )

  grunt.registerTask('default', ['compile', 'watch'])
  grunt.registerTask('build', ['compile'])
  grunt.registerTask('production', ['compile:production'])