cheerio = require 'cheerio'
consolidate = require 'consolidate'
Promise = require 'bluebird'

class Control
  onControlTemplateRender: () =>
    return new Promise (resolve, reject) =>
      @log "onControlTemplateRender Start #{@viewPath}, #{@view.renderer}"
      consolidate[@view.renderer] @viewPath, this, (err, html) =>
        if err?
          @log "onControlTemplateRender Error", err
          return reject(err);
        @html = html;
        @log "onControlTemplateRender rendered #{@viewPath}"
        resolve()

#  onControlRender: (next) =>
#    next();

module.exports = Control