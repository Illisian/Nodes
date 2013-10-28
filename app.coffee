config = require "./config"
database = require "./lib/database";
func = require "./lib/func";
cache = require "./lib/cache";
site = require "./lib/site";
Promises = require "./lib/Promises";
cacheStore = require "./lib/cacheStore";

#extend = require 'extend'
util = require 'util'
#paths = require 'path'

express = require "express";
http = require "http";
#fs = require "fs";

Promise = require "bluebird"
Promise.longStackTraces();

class MainApp
  constructor: () ->
    @config = new config;
    @sysmodulePath = "#{@config.base_dir}/modules/"; 
    @db = new database @config
    @log = func.log;
    @func = func;
    @cache = new cache(this);
    
    @modules = new cacheStore();
    @sites = new cacheStore();
    
    @sockets = {}
    @events = {
      onAppConfig: new Promises()
      onAppStart: new Promises()
    }
    @modules = []
    for m in @config.modules
      @modules.push @loadModule("#{@sysmodulePath}#{m}")
  init: () =>
    @unixSockUnlink()
      .then(@expressSetup)
      .then(@unixSockFree)
      .then(@setupData)
      .then(@loadApps)
      .then(@finished)
      .catch (err) =>
        @log "An Error has occurred while running init", err;

  finished: () =>
    console.log "nodes cms has started";

  expressSetup: () =>
    return new Promise (resolve, reject) =>
      @log "setting up express";
      @express = express();
      @express.set "port", @config.host.port 
      @log "setting up express - enable";
      for setting in @config.express.enable then @express.enable(setting)
      @log "setting up express - use";
      for setting in @config.express.use then @express.use(setting)
      @log "setting up express - onAppConfig.chain", @events.onAppConfig.length;
      return @events.onAppConfig.chain(@express).then () =>
        @express.use express.bodyParser()
        @express.use @processRequest
        @server = http.createServer(@express)
        @server.listen @express.get("port"), () =>
          @events.onAppStart.chain(@express, @server).then () =>
          @log "express is now listening on #{@config.host.port}";
          return resolve();
      , reject


  setupData: () =>
    return @db.init()
      .then(@db.clearDb)
      .then () ->
        func.log "database init has finished";
      
  
  loadApps: () =>
    return new Promise (resolve, reject) =>
      func.log "loading apps";
      promises = [];
      for app in @config.apps
        path = "#{@config.base_dir}/#{app}/app"
        @log "Loading app - #{app} @ #{path}";
        a = require path;
        @cache.apps[app] = new a(this);
        promises.push(@cache.apps[app].init());
      
      Promise.all(promises).then () =>
        resolve();
 
  processRequest: (req, res, next) =>
   # if req.method.toUpperCase() isnt "GET" and "HEAD" isnt req.method.toUpperCase()
   #   return next();
    #req.viewstate = {};
    #cookie = func.findCookie(req);
    #req.session.cookie = 
    #@log "COOKIES", func.findCookieKey(req);
    @loadSite(req, res).then (site) =>
      @log "start site processing"
      site.process(req,res).then (html) =>
        if html?
          @log "sending html";
          res.send html
          return;
        else 
          @log "html not provided";
          next();
      , () =>
        @log "processRequest - not handled", arguments
        next();
    .catch (err) =>
      if err?
        @log "processRequest - catch -#{err}", err.stack
  
  loadSite: (req, res) =>
    return new Promise (resolve, reject) =>
      uri = func.getUriFromReq(req);
      key = func.findCookieKey(req);
      @sites.get(key, uri.hostname).then (site) =>
        resolve(site);
      , () =>
        return @db.logic.site.findOne({ hosts: uri.hostname }).then (siteData) =>
          @log "Starting Site"
          newsite = new site this, siteData;
          @log "Storing Site"
          return @sites.put(key, uri.hostname, newsite).then () =>
            @log "fireing the onSiteLoad Events"
            return newsite.events.onSiteLoad.chain(req,res,newsite).then () =>
              resolve(newsite);
        , reject
  loadModule: (path) =>
    @log "Loading Module #{path}"
    mod = @cache.getControl(path);
    newmod = new mod({ core: this });
    for event of @events
      if newmod[event]?
        @log "loadModule - event - #{event}";
        @events[event].add newmod[event]
  
  unixSockUnlink: () =>
    return new Promise (resolve, reject) =>
      if @config.host.is_sock
        @log "unlinking unix sock - #{@config.host.port}";
        func.unlink(@config.host.port).then () =>
          @log "unlinking unix sock - complete";
          resolve();
      else
        resolve();
  
  unixSockFree: () =>
    return new Promise (resolve, reject) =>
      if @config.host.is_sock
        @log "setting chmod 777 on unix sock - #{@config.host.port}";
        func.freeforall(@config.host.port).then () =>
          @log "setting chmod 777 on unix sock - complete";
          resolve();
      else
        resolve();
  

new MainApp().init();