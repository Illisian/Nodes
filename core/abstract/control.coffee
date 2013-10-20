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

    next();

module.exports = Control