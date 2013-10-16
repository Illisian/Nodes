
Promise = require 'bluebird'
Promise.longStackTraces();

extend = require 'extend'
u = require 'util'
func = require './func'
cheerio = require 'cheerio'
paths = require 'path'

controlProcessor = require './controlProcessor'

class Renderer
  constructor: (@core, @site, @page, @req, @res) ->
    {@config, @db, @log} = @core;
    @sublayoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.layout}"; 
    @$ = cheerio.load "<html></html>";
    @modules = {};
    @modules.instances = [];
    @processModule(modName) for modName in @config.renderModules

  processModule: (modname) =>
    mod = require("./renderModules/#{modname}");
    @modules.instances.push new mod(this);

  
  render: () =>
    return @createFields()
      .then(@fireRenderModuleEvent_onPageStart)
      .then(@processLayout)
      .then(@processSublayouts)
      .then(@processSublayoutTags)
      .then(@fireRenderModuleEvent_onPageFinish)
      .then(@finish).catch (err) =>
        @log "Render Error", err;
  
  fireRenderModuleEvent_onPageStart: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - fireRenderModuleEvent_onPageStart"
      promises = []
      for module in @modules.instances
        promises.push @fireRenderModuleEvent(module, "onPageStart");
      @log "Renderer - fireRenderModuleEvent_onPageStart - firing promises"
      Promise.all(promises).then () =>
        @log "Renderer - fireRenderModuleEvent_onPageStart - finish"
        resolve();
      .catch (err) =>
        @log err.stack
        
  fireRenderModuleEvent_onPageFinish: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - fireRenderModuleEvent_onPageFinish"
      promises = []
      for module in @modules.instances
        promises.push @fireRenderModuleEvent(module, "onPageFinish") 
      Promise.all(promises).then () =>
        @log "Renderer - fireRenderModuleEvent_onPageFinish - finish"
        resolve();
  
  fireRenderModuleEvent: (module, eventName) =>
    return new Promise (resolve, reject) =>
      if module[eventName]?
        module[eventName] () =>
          resolve();
      else
        resolve();

  finish: (next) =>
    return new Promise (resolve, reject) =>
      @log "Renderer - finish"
      #@$('[nodes-sublayout]').removeAttr("nodes-sublayout")
      #@$('[nodes-placeholder]').removeAttr("nodes-placeholder")
      html = @$.html();
      resolve(html);
  
  createFields:() =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processFields"
      if @page.fields?
        @fields = extend(true, @fields, @page.fields)
      if @site.fields?
        @fields = extend(true, @fields, @site.fields)
      resolve();
  
  processLayout: ()=>
    return new Promise (resolve, reject) =>
      @log "Renderer - processLayout"
      @db.logic.layout.findOne({ _id: @page.layout.id }).then (layout) =>
        if layout?
          attr = @page.layout.attributes || {};
          attr.target = null;
          @processControl(@layoutPath, attr, layout.name).then (control) =>
            @log "Renderer - processLayout - finish"
            resolve();
  
  processSublayoutTags: () =>
    return new Promise (resolve, reject) =>
      promises = []
      @log "Renderer - processSublayoutTags - start"
      tagCount = @$('[nodes-sublayout]').length;
      if tagCount > 0
        tags = @$('[nodes-sublayout]').toArray();
        @log "Renderer - processSublayoutTags - tags", tags.length
        for sublayoutTag in tags
          promises.push @sublayoutTagProcessor(sublayoutTag);
        @log "Renderer - processSublayoutTags - promises", promises
        Promise.all(promises).then () =>
          @log "Renderer - processSublayoutTags - finish"
          resolve();
      else
        @log "Renderer - processSublayoutTags - no tags found"
        resolve();
      
  
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
      attr.target = sublayoutTag
      @processControl(@sublayoutPath, attr, name).then (control) =>
        resolve();
  
  processSublayouts: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processSublayouts"
      promises = []
      for sublayout in @page.sublayouts
        promises.push @sublayoutProcessor(sublayout) 
      Promise.all(promises).then () =>
        @log "Renderer - processSublayouts - finish"
        resolve();

  
  sublayoutProcessor: (sublayoutData) =>
    return new Promise (resolve, reject) =>
      @db.logic.sublayout.findOne({ _id: sublayoutData.id }).then (sublayout) =>
        if sublayout?
          attr = sublayoutData.attributes || {};
          attr.target = '[nodes-placeholder="'+sublayoutData.placeholder+'"]'
          @processControl(@sublayoutPath, attr, sublayout.name).then () =>
            @log "Renderer - sublayoutProcessor - finished - #{sublayout.name}"
            resolve();

  processControl:(path, attributes, controlName) =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processControl - Start"
      #@path, @attributes, @controlName, @renderer
      conproc = new controlProcessor path, attributes, controlName, this
      conproc.process().then () =>
        @log "Renderer - processControl - End"
        resolve(conproc.jsfile);

module.exports = Renderer