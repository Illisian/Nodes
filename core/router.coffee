util = require 'util'
path = require 'path'
url = require 'url'

Renderer = require './renderer'
class Router
  constructor:(@config, @data) ->
    
  processRequest: (req, res, next) =>
    if req.method.toUpperCase() isnt "GET" and "HEAD" isnt req.method.toUpperCase()
      return next();
    uri = url.parse "http://#{req.headers.host}#{req.originalUrl}"; # this is the only place i could find.. am using nginx and unix socks
    
    #arr = uri.pathname.split('/');
    #console.log uri.pathname;
    @data.sites.find { host: uri.hostname }, (sites) =>
      if sites.length > 0
        filter = { site: sites[0]._id, path: uri.pathname }
        @data.pages.find filter, (pages) =>
          #console.log "PAGES:", util.inspect(filter);
          if pages.length > 0
            renderer = new Renderer(@config, @data);
            renderer.processPage pages[0], (html) =>
              res.send html
          else
            next();
      else
        next();
    
    #console.log uri.hostname
    
    #console.log util.inspect(req.headers);
    # return next();
    ###
    @data.pages.getByUrl req.url, (page) =>
      if page?
        renderer = new Renderer(@config, @data);
        renderer.processPage page, (html) =>
          res.send html
      else 
        next();
    ###
module.exports = Router