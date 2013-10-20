Promise = require 'bluebird'
Promise.longStackTraces();
paths = require 'path'
func = require './func';

class ControlProcessor
  constructor: (@path, @attributes, @controlName, @renderer) ->
    @controlPath = @path + @controlName;
    @dir = paths.dirname(@path + @controlName);
    @log = @renderer.log;
  
  fireEvents: () =>
    return new Promise (resolve, reject) =>
      @log "ControlProcessor - fireEvents - start";
      @fireEvent("onControlLoad").then () =>
        @fireEvent("onControlBeforeRender").then () =>
          @fireEvent("onControlDataBind").then () =>
            @fireEvent("onControlTemplateRender").then () =>
              @fireEvent("onControlRender").then () =>
                @fireEvent("onControlAfterRender").then () =>
                  @log "ControlProcessor - fireEvents - end";
                  resolve();
                , reject
              , reject
            , reject
          , reject
        , reject
      , reject
  
  fireEvent: (name) =>
    return new Promise (resolve, reject) =>
      @log "ControlProcessor - fireEvent #{name} start";
      if @jsfile[name]?
        return @jsfile[name]().then () =>
          @log "ControlProcessor - fireEvent #{name} finished!";
          return @fireModuleEvent(name)
            .then(resolve, reject);
        , reject
      else
        return @fireModuleEvent(name)
          .then(resolve, reject);

  fireModuleEvent: (name) =>
    return new Promise (resolve, reject) =>
      func.firePromises(0,  @renderer.site.nodes.modules, name)
        .then(resolve, reject);
    

  

  process: () =>
    return new Promise (resolve, reject) =>
      @log "ControlProcessor - process - Loading #{@controlPath}";
      control = @renderer.core.managers.cache.getObject(@controlPath);
      #control = require @controlPath
      @jsfile = new control();
      #extend(true, jsfile, this); # probally shouldnt do this...
      @jsfile.attr = @attributes;
      @jsfile.renderer = @renderer # this sets page and fields
      @jsfile.fields = @renderer.fields;
      @jsfile.log = @renderer.log;
      @jsfile.viewPath = "#{@dir}/views/#{@jsfile.view.file}";
      @fireEvents().then () =>
        @html = @jsfile.html;
        @target = @jsfile.attr.target;
        @log "ControlProcessor - fireEvents Completed. #{@controlPath}";
        resolve(this);
      .catch (err) =>
        @log "ControlProcessor - fireEvents Error", err.stack
module.exports = ControlProcessor