Promise = require "bluebird";

Module = require "../lib/module";
util = require "util"
fs = require "fs";
coffee = require "coffee-script"
paths = require "path";

class Compiler extends Module
  onSiteStart: (req, res) =>
    return new Promise (resolve, reject) =>
      #@log "Illisian - Compiler Module - onSiteBeforePage", arguments
      path = req._parsedUrl.pathname
      if path.match('.coffee$')
        file = paths.join @site.staticPath, req._parsedUrl.pathname;
        @log "Illisian - Compiler Module - found coffee file", file
        return @core.cache.get("compiled", file).then (compiledFile) =>
          @log "Illisian - Compiler Module - sent cached copy", file
          res.send compiledFile;
        , () => 
          @log "Illisian - Compiler Module - cached copy not found", file
          return @core.cache.getFile(file).then (fileData) =>
            @log "Illisian - Compiler Module - file cached - compile with coffee", file, fileData
            try
              compiledFile = coffee.compile fileData, {filename: file}
            catch err
              @log "Compiler", err;
            @log "Illisian - Compiler Module - file compiled", file, compiledFile
            return @core.cache.put("compiled", file, compiledFile).then () =>
              res.send compiledFile
          #rejected
      else
        resolve();


module.exports = Compiler;