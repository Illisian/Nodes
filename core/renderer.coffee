Data = require './data'
extend = require 'extend'
util = require 'util'
cheerio = require 'cheerio'
consolidate = require 'consolidate'
class Renderer
  constructor: ->
    @data = new Data
    @sublayoutPath = @data.paths.sublayout;
    @layoutPath = @data.paths.layout;
  processPage: (page, next) =>
    @context = { page: page };
    console.log page.layout
    @data.getLayout page.layout, (layout) =>
#      if not layout?
#        throw "Layout not found, id is #{page.layout}"
      @processControl(@layoutPath, layout.name, (control) =>
        @context.html = control.html;
        @context.$ = cheerio.load @context.html
        @processSublayouts([].concat(@context.page.sublayouts), () =>
          @context.$('[nodes-placeholder]').removeAttr("nodes-placeholder")
          @context.html = @context.$.html();
          next @context.html;
        )
      )
  processSublayouts: (remaining, finish) =>
    #console.log "processSublayouts", remaining.length
    if remaining.length <= 0
      #console.log "fire finish"
      return finish()
    refsl = remaining.shift();
    @data.getSublayout refsl.id, (sublayout) =>
      @processControl(@sublayoutPath, sublayout.name, (control) =>
        @context.$('[nodes-placeholder="'+refsl.placeholder+'"]').append(control.html);
        @processSublayouts(remaining, finish);
      )
  processControl:(path, controlName, next) =>
    controlPath = path + controlName;
    console.log controlPath
    control =  require controlPath
    jsfile = new control
    jsfile.context = @context # this sets page and fields
    viewPath = path + "views/" + jsfile.view.file;
    jsfile.onData () =>
      if jsfile.fields?
        fields = extend(true, @context.page.fields, jsfile.fields)
      else 
        fields = @context.page.fields
      @renderFile(viewPath, jsfile.view.renderer, fields, (html) =>
        jsfile.html = html;
        jsfile.onHtml () =>
          next(jsfile);
      )
  renderFile: (path, renderer, fields, next) ->
    consolidate[renderer](path, fields, (err, html) ->
      if err?
        throw err;
      next(html)
    )
module.exports = Renderer
