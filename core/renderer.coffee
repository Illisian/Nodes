
Promise = require 'bluebird'
Promise.longStackTraces();

extend = require 'extend'
u = require 'util'
util = require './util'
cheerio = require 'cheerio'
consolidate = require 'consolidate'
paths = require 'path'



class Renderer
  constructor: (@core, @site, @page, @req, @res) ->
    {@config, @db, @log} = @core;
    @sublayoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.layout}"; 
    @$ = cheerio.load "";
    @modules = {};
    @modules.instances = [];
    @processModule(modName) for modName in @config.renderModules

  processModule: (modname) =>
    mod = require("./renderModules/#{modname}");
    @modules.instances.push new mod(this);

  onControlProcessedPromises: (control) =>
    promises = [];
    for mod in @modules.instances
      if mod["onControlProcessed"]?
        promises.push mod.onControlProcessed(control);
    return Promise.all(promises);
  
  onStartPromises: () =>
    promises = [];
    for mod in @modules.instances
      if mod["onStart"]?
        promises.push mod.onStart(this);
    return Promise.all(promises);
  
  onFinishPromises: () =>
    promises = [];
    for mod in @modules.instances
      if mod["onFinish"]?
        promises.push mod.onFinish(this);
    return Promise.all(promises);
  
  render: () =>
    return @processFields()
      .then(@onStartPromises)
      .then(@processLayout)
      .then(@processSublayouts)
      .then(@processSublayoutTags)
      .then(@onFinishPromises)
      .then(@finish).catch (err) =>
        @log err;
      
  finish: () =>
    return new Promise (resolve, reject) =>
      @$('[nodes-sublayout]').removeAttr("nodes-sublayout")
      @$('[nodes-placeholder]').removeAttr("nodes-placeholder")
      html = @$.html();
      resolve(html);
  
  processFields:() =>
    return new Promise (resolve, reject) =>
      if @page.fields?
        @fields = extend(true, @fields, @page.fields)
      if @site.fields?
        @fields = extend(true, @fields, @site.fields)
      resolve();
  
  processLayout: ()=>
    return new Promise (resolve, reject) =>
      @db.logic.layout.findOne({ _id: @page.layout.id }).then (layout) =>
        if layout?
          @processControl(null, @layoutPath,  @page.layout.attributes || {} , layout.name).then (control) =>
            resolve();
        else
          reject();
  
  processSublayoutTags: () =>
    return Promise.all(@sublayoutTagProcessor(sublayoutTag) for sublayoutTag in @$('[nodes-sublayout]').toArray());
  
  sublayoutTagProcessor: (sublayoutTag) =>
    return new Promise (resolve, reject) =>
      name = @$(sublayoutTag).attr('nodes-sublayout');
      attributes = @$(sublayoutTag).attr();
      field_regex = /^nodes-sublayout-attr-.*$/
      replace_regex = /^nodes-sublayout-attr-/
      attr = {};
      for key of attributes
        result = key.match(field_regex);
        if result?
          fieldname = key.replace(replace_regex, "");
          fielddata = @$(refsl).attr(key);
          attr[fieldname] = fielddata;
          
      @log "sublayoutTagProcessor", @sublayoutPath, attr, name
      @processControl(sublayoutTag, @sublayoutPath, attr, name).then (control) =>
        resolve();
  
  processSublayouts: () =>
    return Promise.all(@sublayoutProcessor(sublayout) for sublayout in @page.sublayouts)

  
  sublayoutProcessor: (sublayoutData) =>
    return new Promise (resolve, reject) =>
      @db.logic.sublayout.findOne({ _id: sublayoutData.id }).then (sublayout) =>
        if sublayout?
          return @processControl('[nodes-placeholder="'+sublayoutData.placeholder+'"]', @sublayoutPath, sublayoutData.attributes || {}, sublayout.name).then (control) =>
            resolve();
        else
          reject();

  
  processControl:(target, path, attributes, controlName) =>
    return new Promise (resolve, reject) =>
      controlPath = path + controlName;
      control = require controlPath
      jsfile = new control
      extend(true, jsfile, this);
      jsfile.attr = attributes;
      jsfile.renderer = this # this sets page and fields
      dir = paths.dirname(path + controlName);
      viewPath = "#{dir}/views/#{jsfile.view.file}";

      jsfile.onData () =>
        @renderFile(viewPath, jsfile.view.renderer, jsfile).then (html) =>
          
          if target == null
            @log "Load Cheerio"
            @$ = cheerio.load html;
          else 
            @log "Append Cheerio"
            @$(target).append(html);
          jsfile.html = html;
          #console.log "processControl renderFile";
          jsfile.onHtml () =>
            @onControlProcessedPromises(jsfile).then () =>
              #console.log "processControl onHtml";
              resolve(jsfile);
            
  renderFile: (path, renderer, fields, next) =>
    return new Promise (resolve, reject) =>
      consolidate[renderer] path, fields, (err, html) =>
        if err?
          throw err;
        resolve(html)
      

module.exports = Renderer