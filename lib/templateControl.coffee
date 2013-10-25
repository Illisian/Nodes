cheerio = require 'cheerio'
consolidate = require 'consolidate'
Promise = require 'bluebird'
extend = require 'extend';
Control = require './control'

class templateControl extends Control
  constructor: () ->
    super; #mmm if this is first everything gets set right :D
    @viewPath = "#{@workingDir}/views/#{@view.file}";

  onControlTemplateRender: (req, res) =>
    return new Promise (resolve, reject) =>
      @log "onControlTemplateRender Start #{@viewPath}, #{@view.renderer}"
      context = extend(true, this, { req: req, res: res});
      consolidate[@view.renderer] @viewPath, context, (err, html) =>
        if err?
          @log "onControlTemplateRender Error", err
          return reject(err);
        @html = html;
        @log "onControlTemplateRender rendered #{@viewPath}"
        resolve()
  
#  onControlRender: (next) =>
#    next();
module.exports = templateControl