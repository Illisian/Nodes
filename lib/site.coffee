Promise = require 'bluebird'
Promises = require './Promises'
express = require 'express';
paths = require 'path'
func = require './func';
page = require './page';
cacheStore = require './cacheStore';
#Promise.longStackTraces();

class Site
  constructor: (@core, @siteData, @uri) ->
    {@config, @log, @db} = @core;
    @events = {
      onSiteLoad: new Promises()
      onSiteRequestStart: new Promises()
      onSiteRequestFinish: new Promises()
      
      onPageLoad: new Promises()
      onPageRequestStart: new Promises()
      onPageRequestFinish: new Promises() 

      onControlLoad: new Promises()
      onControlBeforeRender: new Promises()
      onControlDataBind: new Promises()
      onControlTemplateRender: new Promises()
      onControlRender: new Promises()
      onControlAfterRender: new Promises()
      onControlPostBack: new Promises();
    }
    @pages = new cacheStore();
    
    @sublayoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.layout}";
    @modulePath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.module}"; 
    
    @staticPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.content}";
    @static = Promise.promisify(express.static(@staticPath));

   # @connectAssets = Promise.promisify(require("connect-assets")({src: @staticPath}));
    @log "loading system modules"
    @modules = [];
    
    for m in @config.modules #not sure about using the system event object to inherit the loaded modules. 
      @modules.push @loadModule("#{@core.sysmodulePath}#{m}")
    
    @log "loading site modules"
    for module in @siteData.modules
      @log "loadSite - Load Modules - #{@modulePath}#{module}";
      result = @loadModule("#{@modulePath}#{module}");
      @modules.push result;
    @events.refresh = (event) =>

  refreshEvents: (event) =>
    return new Promise (resolve, reject) =>
      @log "Refreshing #{event}"
      @events[event].clear();
      for m of @modules
        if m[event]?
          @log "loadModule - event - #{event}";
          @events[event].add m[event], m
      resolve();
    
  process: (req, res) =>
    return new Promise (resolve, reject) =>
      return @events.onSiteRequestStart.chain(req, res, this).then () =>
        return @static(req,res).then () =>
          return @loadPage(req,res).then (page) =>
            @log "process - process page"
            return page.process(req, res).then () =>
              return @events.onSiteRequestFinish.chain(req, res, @site, @page).then () =>
                @log "Site - onSiteFinish - sending html";
                resolve(page.html);
              , reject
            , reject
          , reject
        , reject
      , reject
  
  loadPage: (req, res) =>
    return new Promise (resolve, reject) =>
      key = func.findCookieKey(req);
      @log "loadPage - checking for existing page"
      return @pages.get(key, req._parsedUrl.pathname).then (file) =>
        @log "loadPage - Page Loaded from cache"
        return resolve(file);
      , () =>
        filter = { site: @siteData._id, path: req._parsedUrl.pathname }
        return @db.logic.page.findOne(filter).then (pageData) =>
          @log "loadPage - is page found?",pageData?
          if pageData?
            newpage = new page(@core, this, pageData);
            
            return @events.onPageLoad.chain(req,res, newpage).then () =>
              return @pages.put(key, req._parsedUrl.pathname, newpage).then () =>
                @log "loadPage - Page Loaded into cache"
                return resolve(newpage);
              ,reject
            ,reject
          else
            @log "loadPage - Page Not Found in system"
            return reject();
      
      
      @log "session id?",req;
      #resolve();
  
  loadPageData: (req, res) =>
    return new Promise (resolve, reject) =>
      filter = { site: @siteData._id, path: req._parsedUrl.pathname }
      return @db.logic.page.findOne(filter).then (page) =>
        if page?
          @log "loadPage - Page Found in system"
          return resolve(page);
        else
          @log "loadPage - Page Not Found in system"
        return reject();
  
  loadModule: (path) =>
    @log "Loading Module #{path}"
    mod = @core.cache.getControl(path);
    newmod = new mod({ core: @core, site: this });
    for event of @events
      if newmod[event]?
        @log "loadModule - event - #{event}";
        @events[event].add newmod[event], newmod
        
module.exports = Site;