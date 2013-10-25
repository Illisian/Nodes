Promise = require 'bluebird'
Promises = require './Promises'
express = require 'express';
paths = require 'path'
func = require './func';
page = require './page';

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
    }
    @sublayoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.layout}";
    @modulePath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.module}"; 
    @sysmodulePath = "#{@config.base_dir}/modules/"; 
    @staticPath = "#{@config.base_dir}#{@siteData.paths.base}#{@siteData.paths.content}";
    @static = Promise.promisify(express.static(@staticPath));
    @modules = []
    
    fieldModule = @loadModule("#{@sysmodulePath}fields");
    @modules.push fieldModule;
    
    for module in @siteData.modules
      @log "loadSite - Load Modules - #{@modulePath}#{module}";
      result = @loadModule("#{@modulePath}#{module}");
      @modules.push result;
  

  process: (req, res) =>
    return new Promise (resolve, reject) =>
      #check for static content;
      return @static(req,res).then(() =>
        return @events.onSiteStart.chain(req, res, this).then () =>
          return @loadPageData(req,res).then (pageData) =>
            @log "process - init new page"
            newpage = new page(@core, this, pageData);
            @log "process - process new page"
            return newpage.process(req, res).then () =>
              return @events.onSiteFinish.chain(req, res, @site, @page).then () =>
                @log "Site - onSiteFinish - sending html";
                resolve(newpage.html);
            , reject;
          , reject;
        , reject)

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
    @log "Loading Module ", mod;
    newmod = new mod({ core: @core, site: this });
    for event of @events
      if newmod[event]?
        @log "loadModule - event - #{event}";
        @events[event].add newmod[event]
        
module.exports = Site;