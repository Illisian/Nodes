Promise = require 'bluebird'
Promise.longStackTraces();
paths = require 'path'

class ControlProcessor
  constructor: (@path, @attributes, @controlName, @renderer) ->
    @controlPath = @path + @controlName;
    @dir = paths.dirname(@path + @controlName);
    @log = @renderer.log;
  
  fireEvents: () =>
    return new Promise (resolve, reject) =>
      @log "ControlProcessor - fireEvents - start";
      @fireEvent "onControlLoad", () =>
        @fireEvent "onControlBeforeRender", () =>
          @fireEvent "onControlDataBind", () =>
            @fireEvent "onControlTemplateRender", () =>
              @fireEvent "onControlRender", () =>
                @fireEvent "onControlAfterRender", () =>
                  @log "ControlProcessor - fireEvents - end";
                  resolve();
  
  fireEvent: (name, next) =>
    @log "ControlProcessor - fireEvent #{name} start";
    if @jsfile[name]?
      @jsfile[name] () =>
        @log "ControlProcessor - fireEvent #{name} finished!";
        next();
    else
      @log "ControlProcessor - #{name} nothing found!";
      next();

  process: () =>
    return new Promise (resolve, reject) =>
      @log "ControlProcessor - process - Loading #{@controlPath}";
      control = require @controlPath
      @jsfile = new control();
      #extend(true, jsfile, this); # probally shouldnt do this...
      @jsfile.attr = @attributes;
      @jsfile.renderer = @renderer # this sets page and fields
      @jsfile.fields = @renderer.fields;
      @jsfile.log = @renderer.log;
      @jsfile.viewPath = "#{@dir}/views/#{@jsfile.view.file}";
      @fireEvents().then () =>
        @log "ControlProcessor - fireEvents Completed. #{@controlPath}";
        resolve(@jsfile);
      .catch (err) =>
        @log "ControlProcessor - fireEvents Error", err.stack
module.exports = ControlProcessor