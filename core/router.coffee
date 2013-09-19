util = require 'util'
path = require 'path'
Renderer = require './renderer'
Data = require './data'
class Router
  constructor:(@data = new Data) ->
    
  process: (req, res, next) =>
    if req.method.toUpperCase() isnt "GET" and "HEAD" isnt req.method.toUpperCase()
      return next();
      
    #console.log util.inspect(req)
    #return next();
      
    @data.getPage req.url, (page) ->
      if page?
        renderer = new Renderer();
        renderer.processPage page, (html) ->
          res.send html
      else 
        next();

module.exports = new Router().process