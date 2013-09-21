util = require 'util'
path = require 'path'
Renderer = require './renderer'
class Router
  constructor:(@config, @data) ->
    
  processRequest: (req, res, next) =>
    if req.method.toUpperCase() isnt "GET" and "HEAD" isnt req.method.toUpperCase()
      return next();
    @data.getPage req.url, (page) =>
      if page?
        renderer = new Renderer(@config, @data);
        renderer.processPage page, (html) =>
          res.send html
      else 
        next();

module.exports = Router