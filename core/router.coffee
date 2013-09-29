util = require 'util'
path = require 'path'
url = require 'url'
express = require 'express'

Renderer = require './renderer'
class Router
  constructor:(@config, @data) ->
    @static = [];
  processRequest: (req, res, next) =>
    if req.method.toUpperCase() isnt "GET" and "HEAD" isnt req.method.toUpperCase()
      return next();
    uri = url.parse "http://#{req.headers.host}#{req.originalUrl}"; # this is the only place i could find.. am using nginx and unix socks
    console.log "Request for #{uri.hostname}";
    @data.model.site.findOne { hosts: uri.hostname }, (err, site) =>
      if site?
        console.log "Site found";
        filter = { site: site._id, path: uri.pathname }
        @data.model.page.find filter, (err, pages) =>
          if pages.length > 0
            renderer = new Renderer(@config, @data, site);
            renderer.processPage pages[0], (html) =>
              res.send html
          else
            @getStatic site, req, res, next
      else
        next();
  getStatic: (site, req, res, next) => 
    #if not site.hostname of @static
    path = "#{@config.base_dir}#{site.paths.base}#{site.paths.content}";
    #console.log "getStatic path #{path}";
    if not @static[site._id]?
      @static[site._id] = express.static(path)
    @static[site._id](req, res, next);
    
module.exports = Router