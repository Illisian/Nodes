extend = require 'extend'
util = require 'util'
cheerio = require 'cheerio'
consolidate = require 'consolidate'
paths = require 'path'
class Renderer
  constructor: (@config, @data, @site) ->
    @sublayoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.layout}";;    
    
    #@sublayoutPath = @config.paths.sublayout;
    #@layoutPath = @config.paths.layout;
  processPage: (page, next) =>
    @context = { page: page, site: @site, data: @data };
    if @context.page.fields?
      @context.fields = extend(true, @context.fields, @context.page.fields)
    if @context.site.fields?
      @context.fields = extend(true, @context.fields, @context.site.fields)
    
    @data.model.layout.find { _id: page.layout }, (err, layouts) =>
      if layouts.length > 0
        layout = layouts[0];
        @processControl(@layoutPath, layout.name, (control) =>
          #console.log "start layout processing";
          @context.html = control.html;
          @context.$ = cheerio.load @context.html
          @processSublayouts([].concat(@context.page.sublayouts), () =>
            @processFields( () =>
              @context.$('[nodes-control]').removeAttr("nodes-control")
              @context.$('[nodes-field]').removeAttr("nodes-field")
              @context.$('[nodes-placeholder]').removeAttr("nodes-placeholder")
              @context.html = @context.$.html();
              next @context.html;
            )
          )
        )
  
  processSublayoutAttributes: (remaining, finish) =>
    if remaining.length <= 0
      #console.log "processSublayoutAttributes finished";
      return finish()
    refsl = remaining.shift();
    if not refsl? 
      #console.log "processSublayoutAttributes refsl invalid"
      return @processSublayoutAttributes(remaining, finish);
    name = @context.$(refsl).attr('nodes-sublayout');
    #console.log "processSublayoutAttributes processControl";
    @processControl(@sublayoutPath, name, (control) =>
      #console.log "processSublayoutAttributes processControl append";
      @context.$(refsl).append(control.html);
      @processSublayoutAttributes(remaining, finish);
    )
  
  checkForSublayoutAttributes: (finish) =>
    #console.log "checkForSublayoutAttributes";
    controlrefs = @context.$('[nodes-sublayout]').toArray();
    if controlrefs.length > 0
      #console.log "processing attribute";
      @processSublayoutAttributes(controlrefs, finish);
    else  
      return finish()



  processSublayouts: (remaining, finish) =>
    if remaining.length <= 0
      #console.log "processSublayouts finished", util.inspect(remaining), util.inspect(finish);
      return @checkForSublayoutAttributes(finish);
    refsl = remaining.shift();
    if not refsl?
      #console.log "processSublayouts refsl invalid"
      return @processSublayouts(remaining, finish);
    @data.model.sublayout.findOne { _id: refsl.id }, (err, sublayout) =>
      #console.log "processSublayouts findOne callback";
      if not sublayout?
        return @processSublayouts(remaining, finish);
      else
        @processControl(@sublayoutPath, sublayout.name, (control) =>
          #console.log "processSublayouts processControl append";
          @context.$('[nodes-placeholder="'+refsl.placeholder+'"]').append(control.html);
          @processSublayouts(remaining, finish);
        )

  processFields: (next) =>
    if @context.fields?
      arr = @context.$('[nodes-field]');
      for i in arr
        fieldName = @context.$(i).attr("nodes-field")
        if fieldName of @context.fields
          fieldContents = @context.fields[fieldName]
          @context.$(i).prepend(fieldContents)
    next();
    
  processControl:(path, controlName, next) =>
    controlPath = path + controlName;
    control = require controlPath
    jsfile = new control
    jsfile.context = @context # this sets page and fields
    dir = paths.dirname(path + controlName);
    viewPath = "#{dir}/views/#{jsfile.view.file}";
    #console.log "processControl onData start";
    jsfile.onData(() =>
      #console.log "processControl onData callback";
      if jsfile.fields?
        @context.fields = extend(true, @context.fields, jsfile.fields)
      #console.log "processControl renderFile #{viewPath}", util.inspect(@context.fields);
      @renderFile(viewPath, jsfile.view.renderer, @context.fields, (html) =>
        jsfile.html = html;
        #console.log "processControl renderFile";
        jsfile.onHtml () =>
          #console.log "processControl onHtml";
          next(jsfile);
      )
    )
  renderFile: (path, renderer, fields, next) =>
    consolidate[renderer](path, fields, (err, html) =>
      if err?
        throw err;
      next(html)
    )

module.exports = Renderer
