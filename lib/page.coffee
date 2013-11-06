Promise = require 'bluebird';
Promises = require './Promises';
events = require './events';
#Promise.longStackTraces();
paths = require 'path'
extend = require 'extend'
cacheStore = require './cacheStore';
util = require 'util'
class Page
  constructor: (@core, @site, @pageData) ->
    {@db, @log, @debug} = @core;
    @fields = {};
    @cache = new cacheStore();
    @controls = [];
    @html = "";
    @controlEvents = [
      "onControlLoad",
      "onControlBeforeRender",
      "onControlDataBind",
      "onControlTemplateRender",
      "onControlRender",
      "onControlAfterRender",
    ]
  fireEvent: (name, req, res) =>
    return new Promise (resolve, reject) =>
      promises = new Promises();
      for control in @controls
        if @site.events.length(name) > 0
          promises.push @site.events.chain, @site.events, [name, req, res, control]
        if control[name]?
          promises.push control[name], control, [req, res, control]
      return promises.chain().then () =>
        return resolve();
      
  createFields:() =>
    return new Promise (resolve, reject) =>
      if @pageData.fields?
        @fields = extend(true, @fields, @pageData.fields)
      if @site.siteData.fields?
        @fields = extend(true, @fields, @site.siteData.fields)
      return resolve();
  
  process: (req, res) =>
    return new Promise (resolve, reject) =>
      return @createFields().then () =>
        @debug "Page - process - onPageRequestStart - start"
        return @site.events.chain("onPageRequestStart", req, res, this).then () =>
          @debug "Page - process - onPageRequestStart - finish"
          promises = new Promises();
          for event in @controlEvents
            promises.push @fireEvent, this, [event, req, res]
          return promises.chain(req, res).then () =>
            return @site.events.chain("onPageRequestFinish", req, res, this).then () =>
              return resolve(@html);
            , reject
          , reject
        , reject
      , reject
module.exports = Page;
