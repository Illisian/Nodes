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
    @data.model.site.findOne { host: uri.hostname }, (err, site) =>
      if site?
        filter = { site: site._id, path: uri.pathname }
        @data.model.page.find filter, (err, pages) =>
          if pages.length > 0
            renderer = new Renderer(@config, @data, site);
            renderer.processPage pages[0], (html) =>
              res.send html
          else
            next();
      else
        next();

module.exports = Router