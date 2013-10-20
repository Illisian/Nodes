func = require "../func";

util = require 'util'
express = require "express";
http = require "http";
fs = require "fs";
url = require 'url'
renderer = require '../renderer'

Promise = require "bluebird"
Promise.longStackTraces();

class SiteManager
  
  constructor: (@core) ->
    {@config, @log, @db} = @core;
    @sites = []
    @static = [];
  
  fireEvent: (site, name) =>
    return new Promise (resolve, reject) =>
      @log "siteManager - fireEvent - #{name} - #{site.nodes.modules.length}";
      return func.firePromises(0, site.nodes.modules, name).then(resolve, reject);
      
  
  
  processRequest: (req, res) =>
    return new Promise (resolve, reject) =>
      uri = url.parse "http://#{req.headers.host}#{req.originalUrl}";
      @log "loadSite - Checking for site - #{uri.hostname}";
      return @loadSite(uri).then (site) =>
        @log "sending too static";
        #f = () =>
        site.nodes.static(req, res).then () =>
          @log "static fowarded the command chain";  
          @log "Firing Event - onSiteRequestStart - Start" 
          return @fireEvent(site, "onSiteRequestStart").then () =>
            @log "Firing Event - onSiteRequestStart - Finish"
            @loadPage(site).then (page) =>
              @log "Creating Renderer";
              rendered = new renderer(@core, site, page, req, res)
              @log "Processing Page";
              
              rendered.render()
                .then((html) =>
                  @log "onSiteRequestEnd";
                  return func.firePromises(0, site.nodes.modules, "onSiteRequestEnd").then () =>
                    @log "sending Site and HTML", html?;
                    return resolve(html);
                  , reject
                , reject)
                .catch (err) =>
                  @log "Render Error", err, err.stack
            , () =>
              @log "Site found, but page not - passing resolve";
              return resolve(site);
            .catch (err) =>
              @log "LoadPage - Render Error", err, err.stack
          , reject
        #f();
      , reject

  loadSite: (uri) =>
    return new Promise (resolve, reject) =>
      if @sites[uri.hostname]?
        return resolve(@sites[uri.hostname]);
      else      
        return @db.logic.site.findOne({ hosts: uri.hostname }).then (site) =>
          if site?
            @log "loadSite - Site Loaded - #{uri.hostname}";
            site.nodes = {}
            site.nodes.sublayoutPath = "#{@config.base_dir}#{site.paths.base}#{site.paths.sublayout}";
            site.nodes.layoutPath = "#{@config.base_dir}#{site.paths.base}#{site.paths.layout}"; 
            site.nodes.modulePath = "#{@config.base_dir}#{site.paths.base}#{site.paths.module}"; 
            site.nodes.modules = []
            @log "Creating Static Handlerer", uri.hostname
            path = "#{@config.base_dir}#{site.paths.base}#{site.paths.content}";
            staticFunc = express.static(path);
            site.nodes.static = Promise.promisify(staticFunc);
            for module in site.modules
              @log "loadSite - Load Modules - #{site.nodes.modulePath}#{module}";
              result = @loadModule("#{site.nodes.modulePath}#{module}", site);
              site.nodes.modules.push result;
            site.nodes.uri = uri;
            site.nodes.pages = [];
            @sites[uri.hostname] = site;
            @log "Loaded site - #{uri.hostname} - Modules: #{site.modules.length} - Loaded Modules: #{site.nodes.modules.length}"
            return resolve(@sites[uri.hostname]);
          else
            return reject("Site not found");
  loadPage: (site) =>
    return new Promise (resolve, reject) =>
      #if site.nodes.pages[site.nodes.uri.pathname]?
      #  resolve(site.nodes.pages[site.nodes.uri.pathname]);
      #else
      filter = { site: site._id, path: site.nodes.uri.pathname }
      return @db.logic.page.findOne(filter).then (page) =>
        if page?
          site.nodes.pages[site.nodes.uri.pathname] = page;
          return resolve(page);
        else
          @log "loadPage - Page Not Found in system"
        return reject();

  loadModule: (name, site) =>
    @log "Loading Module #{name}"
    mod = @core.managers.cache.loadNewObject(name);
    mod.site = site
    return mod;

module.exports = SiteManager