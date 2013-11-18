Promise = require "bluebird";
Promises = require "../lib/Promises";
Module = require "../lib/module";
util = require "util"

fs = require "fs";
coffee = require "coffee-script"
paths = require "path";
cacheStore = require "../lib/cacheStore";

exists = Promise.promisify(require("fs").exists);

class Compiler extends Module
  donotcache: true
  onSiteLoad: (req, res, site) =>
    return new Promise (resolve, reject) =>
      site.mod_compiler = new cacheStore();
      resolve();

  onSiteRequestStart: (req, res, site) =>
    return new Promise (resolve, reject) =>
      path = req._parsedUrl.pathname
      if path.match('.coffee$')
        loadFiles = new Promises
        for path in @site.staticPath
          @log "Adding promises for path #{path}"
          filePath = paths.join path, req._parsedUrl.pathname;
          loadFiles.push @loadFile, this, [req, res, site, filePath]
        return loadFiles.chain().then () =>
          return resolve();
          #rejected
      else
        return resolve();
  loadFile: (req, res, filePath) =>
    return new Promise (resolve, reject) =>
      
      if @donotcache
        return site.mod_compiler.getFile(filePath, @donotcache).then (fileData) =>
          #success
          @log "Success"
        , () =>
          @log "Reject"
          #reject
      else
        
  compileFile: (filePath, fileData) =>
    return new Promise (resolve, reject) =>
      if @donotcache
      
      else
        return @site.mod_compiler.get("compiled", file).then (compiledFile) =>
          @log "Illisian - Compiler Module - sent cached copy", file
          res.send compiledFile;
        , () => 
          @log "Illisian - Compiler Module - cached copy not found", file
      
      
      return fs.exists file, (result) =>
        if not result
          return resolve();
        @log "Illisian - Compiler Module - found coffee file", file
        return @site.mod_compiler.get("compiled", file).then (compiledFile) =>
          @log "Illisian - Compiler Module - sent cached copy", file
          res.send compiledFile;
        , () => 
          @log "Illisian - Compiler Module - cached copy not found", file
          return @site.mod_compiler.getFile(file).then (fileData) =>
            @log "Illisian - Compiler Module - file cached - compile with coffee", file
            try
              compiledFile = coffee.compile fileData, {filename: file}
            catch err
              @log "Compiler", err;
            @log "Illisian - Compiler Module - file compiled", file
            return @site.mod_compiler.put("compiled", file, compiledFile).then () =>
              res.send compiledFile

module.exports = Compiler;