cheerio = require 'cheerio'
consolidate = require 'consolidate'
Promise = require 'bluebird'

class Control
  onControlTemplateRender: (next) =>
    @log "onControlTemplateRender Start #{@viewPath}, #{@view.renderer}"
    consolidate[@view.renderer] @viewPath, this, (err, html) =>
      if err?
        @log "onControlTemplateRender Error", err
        throw err;
      @html = html;
      next()
      @log "onControlTemplateRender rendered #{@viewPath}"
        
  onControlRender: (next) =>
    @log "onControlRender start #{@viewPath}"
    if not @html?
      @log "Html is undefined"
      next();
      return;
      
    if not @attr.target?
      @log "Load Cheerio"
      @renderer.$ = cheerio.load @html;
    else 
      @log "Append Cheerio"
      @renderer.$(@attr.target).append(@html);
    
    @log "onControlRender rendered #{@viewPath}"
    next();

module.exports = Control