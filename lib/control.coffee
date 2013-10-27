Promise = require 'bluebird'
Promises = require './Promises'
#Promise.longStackTraces();

#util = require 'util';

class BaseControl
  constructor: (options) ->
    #console.log "base", util.inspect options
    {@core, @site, @page, @controlData, @workingDir, @filePath, @attr, @target} = options;
    @events = {
      onControlLoad: new Promises()
      onControlBeforeRender: new Promises()
      onControlDataBind: new Promises()
      onControlTemplateRender: new Promises()
      onControlRender: new Promises()
      onControlAfterRender: new Promises()
      onControlPostBack: new Promises();
    };
    
    {@log, @db} = @core;
    for event of @events
      if this[event]?
        @events[event].add this[event], this
  process: (req, res, isPostBack) =>
    return new Promise (resolve, reject) =>
      init = "onControlLoad"
      if isPostBack
        init = "onControlPostBack";
      return @fireEvent(req, res, init).then () =>
        return @fireEvent(req, res,"onControlBeforeRender").then () =>
          return @fireEvent(req, res,"onControlDataBind").then () =>
            return @fireEvent(req, res,"onControlTemplateRender").then () =>
              return @fireEvent(req, res,"onControlRender").then () =>
                return @fireEvent(req, res,"onControlAfterRender").then () =>
                  return resolve();
                , reject
              , reject
            , reject
          , reject
        , reject
      , reject
      
  fireEvent: (req, res, name) =>
    return new Promise (resolve, reject) =>
     @site.events[name].chain(req, res, this).then () =>
        @events[name].chain(req, res).then () =>
          return resolve();
        , reject
      ,reject
  

module.exports = BaseControl;