glob = require "glob"
fs = require "fs"

class Util
  constructor: (@config, @database) ->

  unlink: (path, next) ->
    fs.unlink path, (err) ->
      next()
  freeforall: (path, next) ->
    setTimeout () ->
      fs.chmod path, 0x777, () ->
        next();
    , 2000
  
  syncLayouts: (next) =>
    @sync @config.paths.layout, @database.layouts
    #@syncFromDirectory @config.paths.layout, @database.layouts
    #@cleanDatabase @config.paths.layout, @database.layouts
    
  syncSublayouts: (next) =>
    @sync @config.paths.sublayout, @database.sublayouts
    #@syncFromDirectory @config.paths.sublayout, @database.sublayouts
    #@cleanDatabase @config.paths.sublayout, @database.sublayouts
    
    
  sync: (path, data) =>
    @readDirectory(path,"*", (files) =>
      data.getAll {}, (docs) =>
        for file in files
          docsExists = []
          docsExists.push doc for doc in docs when doc.name is file
          if docsExists.length is 0
            data.create { name: file }, (obj) =>
              console.log "[sync] Created", obj
        for doc in docs
          filesExists = []
          filesExists.push file for file in files when file is doc.name
          console.log "[sync] Check fileExists", doc.name, filesExists
          if filesExists.length is 0
            console.log "[sync] Removed Entry", doc
            data.remove doc
    )

  readDirectory: (path,name, next) ->
    console.log "[readDir] #{name}";
    glob "#{name}.coffee", {cwd: path}, (err, files) ->
      if err
        throw err;
      list = for f in files then f.split(".")[0]
      next list



module.exports = Util;