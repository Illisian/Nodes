Promise = require 'bluebird'
Promises = require './Promises'
express = require 'express';
paths = require 'path'
func = require './func';
page = require './page';
cache = require './cache';
#Promise.longStackTraces();

class Site
  constructor: (@core, @siteData, @uri) ->
    {@config, @log, @db} = @core;
    @events = {
      onSiteStart: new Promises()
      onSiteFinish: new Promises()
      
      
      onPageLoad: new Promises()
      onPageFinish: new Promises() 

      onControlLoad: new Promises()
      onControlBeforeRender: new Promises()
      onControlDataBind: new Promises()
      onControlTemplateRender: new Promises()
      onControlRender: new Promises()
      onControlAfterRender: new Promises()
      onControlPostBack: new Promises();
    }
    @cache = new cache(@core);
    @sublayoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.layout}";
    @modulePath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.module}"; 
    @sysmodulePath = "#{@config.base_dir}/modules/"; 
    @staticPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.content}";
    @static = Promise.promisify(express.static(@staticPath));

   # @connectAssets = Promise.promisify(require("connect-assets")({src: @staticPath}));
    @modules = [];
    for m in @config.modules
      @modules.push @loadModule("#{@sysmodulePath}#{m}")
    
    for module in @siteData.modules
      @log "loadSite - Load Modules - #{@modulePath}#{module}";
      result = @loadModule("#{@modulePath}#{module}");
      @modules.push result;
  

  process: (req, res) =>
    return new Promise (resolve, reject) =>
      #@log "check for static content";
      return @events.onSiteStart.chain(req, res, this).then () =>
        return @static(req,res).then () =>
          return @loadPage(req,res).then (page) =>
            @log "process - process page"
            return page.process(req, res).then () =>
              return @events.onSiteFinish.chain(req, res, @site, @page).then () =>
                @log "Site - onSiteFinish - sending html";
                resolve(page.html);
              , reject
            , reject
          , reject
        , reject
      , reject
  
  loadPage: (req, res) =>
    return new Promise (resolve, reject) =>
      return @cache.get(req.sessionID, req._parsedUrl.pathname).then (file) =>
        @log "loadPage - Page Loaded from cache"
        return resolve(file);
      , () =>
        filter = { site: @siteData._id, path: req._parsedUrl.pathname }
        return @db.logic.page.findOne(filter).then (pageData) =>
          if pageData?
            newpage = new page(@core, this, pageData);
            return @cache.put(req.sessionID, req._parsedUrl.pathname, newpage).then () =>
              @log "loadPage - Page Loaded into cache"
              return resolve(newpage);
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
    mod = @cache.getControl(path);
    @log "Loading Module ", mod;
    newmod = new mod({ core: @core, site: this });
    for event of @events
      if newmod[event]?
        @log "loadModule - event - #{event}";
        @events[event].add newmod[event]
        
module.exports = Site;