
Promise = require 'bluebird'
Promises = require './Promises'
events = require './events'
#Promise.longStackTraces();

#util = require 'util';

class BaseControl
  constructor: (options) ->
    #console.log "base", util.inspect options
    {@core, @site, @page, @controlData, @workingDir, @filePath, @attr, @target} = options;
    {@log, @db} = @core;

  process: (req, res, isPostBack) =>
    return new Promise (resolve, reject) =>


  

module.exports = BaseControl;