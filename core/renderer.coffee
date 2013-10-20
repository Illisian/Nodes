
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
    @sublayoutPath =  @site.nodes.sublayoutPath;
    @layoutPath =  @site.nodes.layoutPath;
    @modulePath =  @site.nodes.modulePath;
    @modules = [];
    @processModule("#{__dirname}/renderModules/#{modName}") for modName in @config.renderModules
    @layout = {}
    @sublayouts = []
    if @site.modules?
      @processModule("#{@site.nodes.modulePath}#{siteModName}") for siteModName in @site.modules
  
  render: () =>
    return @createFields()
      .then(@fireRenderModuleEvent_onPageStart)
      .then(@processLayout)
      .then(@processSublayouts)
      .then(@processSublayoutTags)
      .then(@processLoadedControls)
      .then(@fireRenderModuleEvent_onPageFinish)
      .then(@finish)
      .catch (err) =>
        @log "Render Error", err, err.stack;
  
  createFields:() =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processFields"
      if @page.fields?
        @fields = extend(true, @fields, @page.fields)
      if @site.fields?
        @fields = extend(true, @fields, @site.fields)
      @log "Renderer - processFields - Finished"
      resolve();
  
  
  fireRenderModuleEvent_onPageStart: () =>
    @log "fireing Promises - onPageStart";
    return func.firePromises(0,  @modules, "onPageStart")

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
            @log "Renderer - processLayout - Loading Layout Complete"
            @$ = cheerio.load @layout.jsfile.html;
            resolve();

  processSublayouts: () =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processSublayouts"
      promises = []
      for sublayout in @page.sublayouts
        promises.push @sublayoutProcessor(sublayout) 
      @log "Renderer - sublayoutProcessor - Found Sublayouts - #{promises.length}"
      
      return Promise.all(promises).then () =>
        @log "Renderer - processSublayouts - finish"
        resolve();
      , reject
        
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
        return Promise.all(promises).then () =>
          @log "Renderer - processSublayoutTags - finish"
          resolve();
        , reject
      else
        @log "Renderer - processSublayoutTags - no tags found"
        resolve();
  processLoadedControls:() =>
    return new Promise (resolve, reject) =>
      @log "Renderer - processLoadedControls - Starting Sublayouts"
      promises = [];
      promises.push s.process() for s in @sublayouts;
      return Promise.all(promises).then (results) =>
        for s in results
          @log "Renderer - processLoadedControls - Appending Sublayouts #{s.controlPath}", s.html? , s.target?;
          if s.html?
            @$(s.target).append(s.html);
        @log "Renderer - processLoadedControls - End"
        resolve();
      , (result) =>
        @log "Renderer - processLoadedControls - Appending Sublayouts failed #{s.controlPath}", s.html? , s.target?;
        resolve();
            
          
  fireRenderModuleEvent_onPageFinish: () =>
    return new Promise (resolve, reject) =>
      func.firePromises(0,  @modules, "onPageFinish", resolve, reject).then(resolve, reject);
  
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
    mod = @core.managers.cache.loadNewObject(modname);
    mod.renderer = this;
    @modules.push mod;
  
module.exports = Renderer