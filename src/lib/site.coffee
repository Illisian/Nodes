Promise = require 'bluebird'
Promises = require './Promises'
express = require 'express';
paths = require 'path'
func = require './func';
page = require './page';
cacheStore = require './cacheStore';
events = require './events';
#Promise.longStackTraces();

class Site
  constructor: (@core, @siteData, @uri) ->
    {@config, @log, @db, @debug} = @core;
    @events = new events(@log);
    @events.register "onSiteLoad";
    @events.register "onSiteRequestStart";
    @events.register "onSiteRequestFinish";
    @events.register "onPageLoad";
    @events.register "onPageRequestStart";
    @events.register "onPageRequestFinish";
    @events.register "onControlLoad";
    @events.register "onControlBeforeRender";
    @events.register "onControlDataBind";
    @events.register "onControlTemplateRender";
    @events.register "onControlRender";
    @events.register "onControlAfterRender";
    @events.register "onControlPostBack";
    @pages = new cacheStore();
    
    @sublayoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.layout}";
    @modulePath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.module}";
    @staticPath = []
    if func.isArray(@siteData.paths.content)
      for content in @siteData.paths.content
        @staticPath.push "#{@config.base_dir}#{@siteData.paths.base}#{content}";
    else
      @staticPath.push "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.content}";
    @static = new Promises()
    for path in @staticPath
      @log "Creating Static path: #{path}";
      @static.push Promise.promisify(express.static(path))

    @modules = [];
    
    for m in @config.modules #not sure about using the system event object to inherit the loaded modules. 
      @modules.push @loadModule("#{@core.sysmodulePath}#{m}")
    
    for module in @siteData.modules
      result = @loadModule("#{@modulePath}#{module}");
      @modules.push result;

  process: (req, res) =>
    return new Promise (resolve, reject) =>
      return @events.chain("onSiteRequestStart", req, res, this).then () =>
        return @static.chain(req,res).then () =>
          return @loadPage(req,res).then (page) =>
            @debug "Site - process - page.process - start";
            return page.process(req, res).then () =>
              return @events.chain("onSiteRequestFinish", req, res, @site, @page).then () =>
                resolve(page.html);
              , reject
            , reject
          , reject
        , reject
      , reject
  
  loadPage: (req, res) =>
    return new Promise (resolve, reject) =>
      key = func.findCookieKey(req);
      return @pages.get(key, req._parsedUrl.pathname).then (file) =>
        return resolve(file);
      , () =>
        filter = { site: @siteData._id, path: req._parsedUrl.pathname }
        return @db.logic.page.findOne(filter).then (pageData) =>
          if pageData?
            newpage = new page(@core, this, pageData);
            
            return @events.chain("onPageLoad", req,res, newpage).then () =>
              return @pages.put(key, req._parsedUrl.pathname, newpage).then () =>
                return resolve(newpage);
              ,reject
            ,reject
          else
            return reject();
      
      
      @log "session id?",req;
      #resolve();
  
  loadPageData: (req, res) =>
    return new Promise (resolve, reject) =>
      filter = { site: @siteData._id, path: req._parsedUrl.pathname }
      return @db.logic.page.findOne(filter).then (page) =>
        if page?
          return resolve(page);
        else
        return reject();
  
  loadModule: (path) =>
    mod = @core.cache.getControl(path);
    newmod = new mod({ core: @core, site: this });
    @events.add(newmod);
    
module.exports = Site;