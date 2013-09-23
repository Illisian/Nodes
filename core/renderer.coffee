extend = require 'extend'
util = require 'util'
cheerio = require 'cheerio'
consolidate = require 'consolidate'
class Renderer
  constructor: (@config, @data) ->
    @sublayoutPath = @config.paths.sublayout;
    @layoutPath = @config.paths.layout;
  processPage: (page, next) =>
    @context = { page: page };
    @data.layouts.find { _id: page.layout }, (layouts) =>
      if layouts.length > 0
        layout = layouts[0];
        @processControl(@layoutPath, layout.name, (control) =>
          @context.html = control.html;
          @context.$ = cheerio.load @context.html
          @processSublayouts([].concat(@context.page.sublayouts), () =>
            @processFields( () =>
              @context.$('[nodes-field]').removeAttr("nodes-field")
              @context.$('[nodes-placeholder]').removeAttr("nodes-placeholder")
              @context.html = @context.$.html();
              next @context.html;
            )
          )
        )
  processSublayouts: (remaining, finish) =>
    if remaining.length <= 0
      return finish()
    refsl = remaining.shift();
    @data.sublayouts.find { _id: refsl.id }, (sublayouts) =>
      if sublayouts.length > 0
        sublayout = sublayouts[0]
        @processControl(@sublayoutPath, sublayout.name, (control) =>
          @context.$('[nodes-placeholder="'+refsl.placeholder+'"]').append(control.html);
          @processSublayouts(remaining, finish);
        )
  processFields: (next) =>
    arr = @context.$('[nodes-field]');
    for i in arr
      fieldName = @context.$(i).attr("nodes-field")
      fieldContents = @context.page.fields[fieldName]
      @context.$(i).html(fieldContents)
    next();
  processControl:(path, controlName, next) =>
    controlPath = path + controlName;
    control = require controlPath
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
