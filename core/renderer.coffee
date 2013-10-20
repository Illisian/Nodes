
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
    @modules = [];
    @processModule(modName) for modName in @config.renderModules
    @layout = {}
    @sublayouts = []
  
  render: () =>
    return @createFields()
      .then(@fireRenderModuleEvent_onPageStart)
      .then(@processLayout)
      .then(@processSublayouts)
      .then(@processSublayoutTags)
      .then(@processLoadedControls)
      .then(@fireRenderModuleEvent_onPageFinish)
      .then(@finish).catch (err) =>
        @log "Render Error - #{err.stack}";
  
  createFields:() =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processFields"
      if @page.fields?
        @fields = extend(true, @fields, @page.fields)
      if @site.fields?
        @fields = extend(true, @fields, @site.fields)
      resolve();
  
  
  fireRenderModuleEvent_onPageStart: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - fireRenderModuleEvent_onPageStart"
      promises = []
      for module in @modules
        promises.push @fireRenderModuleEvent(module, "onPageStart");
      @log "Renderer - fireRenderModuleEvent_onPageStart - firing promises"
      Promise.all(promises)
        .then () =>
          resolve();
        .catch (err) =>
          @log err.stack
          
  processLayout: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processLayout"
      @db.logic.layout.findOne({ _id: @page.layout.id }).then (layout) =>
        if layout?
          attr = @page.layout.attributes || {};
          attr.target = null;
          @layout = new controlProcessor @layoutPath, attr, layout.name, this
          @log "Renderer - processLayout - finish"  
          @layout.process().then () =>
            @log "Renderer - processLayout - Loading Layout Complete", @layout
            @$ = cheerio.load @layout.jsfile.html;
          resolve();

  processSublayouts: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processSublayouts"
      promises = []
      for sublayout in @page.sublayouts
        promises.push @sublayoutProcessor(sublayout) 
      @log "Renderer - sublayoutProcessor - Found Sublayouts - #{promises.length}"
      Promise.all(promises).then () =>
        @log "Renderer - processSublayouts - finish"
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
  processLoadedControls:() =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processLoadedControls - Starting Sublayouts"
      promises = [];
      promises.push s.process() for s in @sublayouts;
      Promise.all(promises).then (results) =>
        for s in results
          @log "Renderer - processLoadedControls - Appending Sublayouts #{s.controlPath}", s.html? , s.target?;
          if s.html?
            @$(s.target).append(s.html);
        @log "Renderer - processLoadedControls - End"
        resolve();
            
          
  fireRenderModuleEvent_onPageFinish: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - fireRenderModuleEvent_onPageFinish"
      promises = []
      for module in @modules
        promises.push @fireRenderModuleEvent(module, "onPageFinish") 
      Promise.all(promises).then () =>
        @log "Renderer - fireRenderModuleEvent_onPageFinish - finish"
        resolve();
  
  fireRenderModuleEvent: (module, eventName) =>
    return new Promise (resolve, reject) =>
      @log "Renderer - fireRenderModuleEvent_onPageStart - firing promises - #{eventName}"
      if module[eventName]?
        module[eventName](resolve);
      else
        resolve();

  finish: (next) =>
    return new Promise (resolve, reject) =>
      @log "Renderer - finish"
      #@$('[nodes-sublayout]').removeAttr("nodes-sublayout")
      #@$('[nodes-placeholder]').removeAttr("nodes-placeholder")
      html = @$.html();
      resolve(html);
  
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
      @addSublayoutToRenderPipeline(@sublayoutPath, attr, name);
      resolve();
  
  sublayoutProcessor: (sublayoutData) =>
    return new Promise (resolve, reject) =>
      @log "Renderer - sublayoutProcessor - Searching for Sublayout - #{sublayoutData.id}"
      @db.logic.sublayout.findOne({ _id: sublayoutData.id }).then (sublayout) =>
        if sublayout?
          attr = sublayoutData.attributes || {};
          attr.target = '[nodes-placeholder="'+sublayoutData.placeholder+'"]'
          @addSublayoutToRenderPipeline(@sublayoutPath, attr, sublayout.name);
          @log "Renderer - sublayoutProcessor - finished - #{sublayout.name}"
          resolve();


  addSublayoutToRenderPipeline:(path, attributes, controlName) =>
    @log "Renderer - addControlToRenderPipeline - Start #{controlName}"
    conproc = new controlProcessor path, attributes, controlName, this
    @sublayouts.push(conproc);

  processModule: (modname) =>
    @log "Loading Module #{modname}"
    mod = @getControl("./renderModules/#{modname}");
    @modules.push new mod(this);
  
  getControl: (path) =>
    if @core.cache.controls[path]?
      return @core.cache.controls[path];
    mod = require(path)
    @core.cache.controls[path] = mod;
    return mod;


###
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
  processControl:(path, attributes, controlName) =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processControl - Start #{controlName}"
      #@path, @attributes, @controlName, @renderer
      conproc = new controlProcessor path, attributes, controlName, this
      conproc.process().then () =>
        @log "Renderer - processControl - End #{controlName}"
        @controls.push
        resolve(conproc);
###
module.exports = Renderer