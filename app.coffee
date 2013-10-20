config = require "./config"
renderer = require "./core/renderer";
database = require "./core/database";
func = require "./core/func";
siteManager = require "./core/managers/siteManager";
cacheManager = require "./core/managers/cacheManager";

extend = require 'extend'
util = require 'util'
cheerio = require 'cheerio'
consolidate = require 'consolidate'
paths = require 'path'

express = require "express";
http = require "http";
fs = require "fs";
url = require 'url'

Promise = require "bluebird"
Promise.longStackTraces();

class MainApp
  constructor: () ->
    @managers = {};
    
    @config = new config;
    @db = new database @config
    #@router = new router @config, @db
    @log = func.log;
    @func = func;
    @static = [];
    @cache = {};
    @cache.controls = {}
    @apps = [];
    @sites = [];
    
    @managers.sites = new siteManager(this);
    @managers.cache = new cacheManager(this);
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
      for setting in @config.express.enable then @express.enable(setting)
      for setting in @config.express.use then @express.use(setting)
      @express.use express.bodyParser()
      @express.use @processRequest
      http.createServer(@express).listen @express.get("port"), =>
        @log "express is now listening on #{@config.host.port}";
        resolve();


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
        @apps[app] = new a(this);
        promises.push(@apps[app].init());
      
      Promise.all(promises).then () =>
        resolve();
 
  processRequest: (req, res, next) =>
   # if req.method.toUpperCase() isnt "GET" and "HEAD" isnt req.method.toUpperCase()
   #   return next();
    @managers.sites.processRequest(req, res).then (html) =>
      #success
      @log "processRequest", html?;
      if html?
        @log "sending html";
        res.send html
        return;
      next();
    , () =>
      @log "processRequest - not handled", arguments;
      #next();
    .catch (err) =>
      @log "processRequest - catch - #{err.stack}"
  
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