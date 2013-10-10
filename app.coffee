config = require "./config"
renderer = require "./core/renderer";
database = require "./core/database";
util = require "./core/util";

express = require "express";
http = require "http";
fs = require "fs";
url = require 'url'

Promise = require "bluebird"
Promise.longStackTraces();
class MainApp
  constructor: () ->
    @config = new config @express;
    @db = new database @config
    #@router = new router @config, @db
    
    @static = [];
    @apps = [];
    

  init: () =>
    @unixSockUnlink()
      .then(@expressSetup)
      .then(@unixSockFree)
      .then(@setupData)
      .then(@loadApps)
      .then(@finished)
      .catch (err) ->
        util.log "An Error has occurred while running init", err;

  finished: () =>
    util.log "nodes cms has started";

  expressSetup: () =>
    return new Promise (resolve, reject) =>
      util.log "setting up express";
      @express = express();
      @express.set "port", @config.host.port 
      for setting in @config.express.enable then @express.enable(setting)
      for setting in @config.express.use then @express.use(setting)
      @express.use @processRequest
      http.createServer(@express).listen @express.get("port"), =>
        util.log "express is now listening on #{@config.host.port}";
        resolve();


  setupData: () =>
    return @db.init()
        .then(@db.clearDb)
        .then(() ->
          util.log "database init has finished";
        )
  
  loadApps: () =>
    return new Promise (resolve, reject) =>
      util.log "loading apps";
      promises = [];
      for app in @config.apps
        path = "#{@config.base_dir}/#{app}/app"
        util.log "Loading app - #{app} @ #{path}";
        a = require path;
        @apps[app] = new a(this);
        promises.push(@apps[app].init());
      Promise.all(promises).then () ->
        resolve();
      
      
  processRequest: (req, res, next) =>
    if req.method.toUpperCase() isnt "GET" and "HEAD" isnt req.method.toUpperCase()
      return next();
    uri = url.parse "http://#{req.headers.host}#{req.originalUrl}"; # this is the only place i could find.. am using nginx and unix socks
    #console.log "Request for #{uri.hostname}";
    @db.logic.site.findOne({ hosts: uri.hostname }).then (site) =>
      if site?
        #console.log "Site found";
        filter = { site: site._id, path: uri.pathname }
        @db.logic.page.findOne(filter).then((page) =>
          if page?
            util.log "page found";
            
            renderer = new renderer(this, site);
            renderer.processPage(page).then((html) =>
              res.send html
            ).catch (err) ->
              util.log err
          else
            @getStatic site, req, res, next
        ).catch (err) ->
          util.log err
      else
        next();
        
  getStatic: (site, req, res, next) => 
    #if not site.hostname of @static
    path = "#{@config.base_dir}#{site.paths.base}#{site.paths.content}";
    #console.log "getStatic path #{path}";
    if not @static[site._id]?
      @static[site._id] = express.static(path)
    @static[site._id](req, res, next);
    
  unixSockUnlink: () =>
    return new Promise (resolve, reject) =>
      if @config.host.is_sock
        util.log "unlinking unix sock - #{@config.host.port}";
        util.unlink(@config.host.port).then () ->
          util.log "unlinking unix sock - complete";
          resolve();
      else
        resolve();
  
  unixSockFree: () =>
    return new Promise (resolve, reject) =>
      if @config.host.is_sock
        util.log "setting chmod 777 on unix sock - #{@config.host.port}";
        util.freeforall(@config.host.port).then () ->
          util.log "setting chmod 777 on unix sock - complete";
          resolve();
      else
        resolve();
  

new MainApp().init();