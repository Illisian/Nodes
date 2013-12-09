database = require "./database";
func = require "./func";
cache = require "./cache";
site = require "./site";
Promises = require "./Promises";
cacheStore = require "./cacheStore";

#extend = require 'extend'
util = require 'util'
#paths = require 'path'
connect = require "connect";
express = require "express";
http = require "http";
#fs = require "fs";

Promise = require "bluebird"
Promise.longStackTraces();
###*
* This is the bootstrap class for the application, and the main handler for express requests
*
* @class MainApp
* @constructor
###

###*
* This is init method called on startup
*
* @method init
* @return {Void} Returns nothing
###


class MainApp
  constructor: (@config) ->
    @db = new database @config
    @log = func.log;
    @debug = func.log;
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
      @modules.push @loadModule(m);

  init: () =>
    return new Promise (resolve, reject) =>
      return @unixSockUnlink()
        .then(@expressSetup)
        .then(@unixSockFree)
        .then(@setupData)
        .then () =>
          console.log "nodes cms has started";
          return resolve();
        .catch (err) =>
          @log "An Error has occurred while running init", err;


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
    return new Promise (resolve, reject) =>
      return @db.init()
        .then () ->
          func.log "database init has finished";
          return resolve();
      
  
  #loadApps: () =>
  #  return new Promise (resolve, reject) =>
  #    if not @config.apps?
  #      return resolve();
  #    func.log "loading apps";
  #    promises = [];
  #    for app in @config.apps
  #      path = "#{@config.base_dir}/#{app}/app"
  #      @log "Loading app - #{app} @ #{path}";
  #      a = require path;
  #      @cache.apps[app] = new a(this);
  #      promises.push(@cache.apps[app].init());
  #    
  #    Promise.all(promises).then () =>
  #      resolve();
 
  processRequest: (req, res, next) =>
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
            return newsite.events.chain("onSiteLoad",req,res,newsite).then () =>
              resolve(newsite);
        , reject
        
  loadModule: (mod) =>
    @log "Loading Module", mod
    newmod = new mod({ core: this });
    for event of @events
      if newmod[event]?
        @log "loadModule - event - #{event}";
        @events[event].add newmod[event]
    return newmod;
    
  #loadModuleByPath: (path) =>
  #  @log "Loading Module #{path}"
  #  mod = @cache.getControl(path);
  #  newmod = new mod({ core: this });
  #  for event of @events
  #    if newmod[event]?
  #      @log "loadModuleByPath - event - #{event}";
  #      @events[event].add newmod[event]
  
  unixSockUnlink: () =>
    return new Promise (resolve, reject) =>
      if @config.host.is_sock
        @log "unlinking unix sock - #{@config.host.port}";
        func.unlink(@config.host.port).then () =>
          @log "unlinking unix sock - complete";
          resolve();
      else
        resolve();
  
  unixSockUnlink: () =>
    return new Promise (resolve, reject) =>
      if @config.host.is_sock
        @log "setting chmod 777 on unix sock - #{@config.host.port}";
        func.freeforall(@config.host.port).then () =>
          @log "setting chmod 777 on unix sock - complete";
          resolve();
      else
        resolve();
  

module.exports = MainApp;