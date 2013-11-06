Promise = require "bluebird";
Promises = require "../lib/Promises";
Module = require "../lib/module";
cheerio = require "cheerio";
paths = require "path";

class Magician extends Module
  constructor: (@options) ->
    super
    
  onPageRequestStart: (req, res, page) =>
    return new Promise (resolve, reject) =>
      @log "Magician - onPageRequestStart";
      return @loadControls(page).then () =>
        @log "Magician - onPageRequestStart - finish";
        return resolve();
      , reject
    
    
  processSublayoutTags: (req, res, page) =>
    return new Promise (resolve, reject) =>
      @log "Magician - onControlAfterRender - start";
      tagCount = page.$('[nodes-sublayout]').length
      if tagCount > 0
        tags = page.$('[nodes-sublayout]').toArray();
        @log "Magician - onControlAfterRender - tags", tags.length
        
        tagPromises = new Promises();
        for sublayoutTag in tags
          sltdetail = @getTagDetails(sublayoutTag, page);
          tagPromises.push @sublayoutTagProcessor, this, [req, res, sltdetail, sltdetail.id, sublayoutTag, page];
        return tagPromises.chain().then () =>
          return resolve();
        , reject
      else
        return resolve();

  sublayoutTagProcessor: (req, res, ref, id, sublayoutTag, page) =>
    return new Promise (resolve, reject) =>
      return @loadControl(ref.controlname, page.site.sublayoutPath, ref, page).then (sublayout) =>
        sublayout.ref = ref;
        sublayout.ref.tag = sublayoutTag;
        sublayout.attr = ref.attributes || {}
        promises = new Promises();
        for event in page.controlEvents
          if sublayout[event]?
            promises.push sublayout[event], sublayout, [req, res, sublayout];
          #if page.site.events.length(event) > 0
          #  promises.push page.site.events.chain, page.site.events, [event, req, res, sublayout]
        return promises.chain().then () =>
          page.$(sublayoutTag).append(sublayout.html);
          #page.controls.push sublayout;
          return resolve();
        ,reject
      , reject

  getTagDetails: (sublayoutTag, page) =>
    id = page.$(sublayoutTag).attr('nodes-id')
    controlname = page.$(sublayoutTag).attr('nodes-sublayout');
    attributes = page.$(sublayoutTag).attr();
    field_regex = /^nodes-sublayout-attr-.*$/
    replace_regex = /^nodes-sublayout-attr-/
    attr = {};
    for key of attributes
      result = key.match(field_regex);
      if result?
        fieldname = key.replace(replace_regex, "");
        fielddata = page.$(sublayoutTag).attr(key);
        attr[fieldname] = fielddata;
    return {
      id: id
      tag: sublayoutTag
      controlname: controlname
      attributes: attributes
    };
    
  onPageRequestFinish: (req, res, page) =>
    return new Promise (resolve, reject) =>
      controls = []
      for control in page.controls
        if control.isLayout
          page.html = control.html;
          page.$ = cheerio.load page.html
        else 
          controls.push control
      if page.$?
        for c in controls
          if c.ref?
            if c.ref.placeholder?
              target = "[nodes-placeholder='#{c.ref.placeholder}']";
              @log "appending control to #{c.ref.placeholder}";
              page.$(target).append(c.html);
              
        return @processSublayoutTags(req, res, page).then () =>
          page.isLoaded = true;
          page.html = page.$.html();
          return resolve();
        , reject
      else 
        return reject();
      
      
      
      
  loadPageLayout: (page) =>
    return new Promise (resolve, reject) =>
      @log "Magician - loadPageLayout - start", page.pageData;
      return @db.logic.layout.findOne({ _id: page.pageData.layout.id }).then (layoutData) =>
        if layoutData?
          return @loadControl(layoutData.name, page.site.layoutPath, layoutData, page).then (layout) =>
            page.controls.push layout;
            return resolve();
          , reject
        @log "Magician - loadPageLayout - reject";
        return reject();
      , reject
  
  loadPageSublayouts: (page) =>
    return new Promise (resolve, reject) =>
      loadSublayoutPromises = new Promises();
      for sublayoutRef in page.pageData.sublayouts
        loadSublayoutPromises.push @loadSublayout, this, [sublayoutRef, page];
      return loadSublayoutPromises.chain().then(resolve, reject);
  
  loadSublayout: (sublayoutRef, page) =>
    return new Promise (resolve, reject) =>
      return @db.logic.sublayout.findOne({ _id: sublayoutRef.id }).then (sublayoutData) =>
        if sublayoutData?
          return @loadControl(sublayoutData.name, page.site.sublayoutPath, sublayoutData, page).then (sublayout) =>
            sublayout.ref = sublayoutRef;
            sublayout.attr = sublayoutRef.attributes || {}
            page.controls.push sublayout;
            return resolve();
          , reject 
      ,reject

  loadControls: (page) =>
    return new Promise (resolve, reject) =>
      if page.isLoaded
        return resolve();
      else
        return @loadPageLayout(page).then () =>
          return @loadPageSublayouts(page).then () =>
            return resolve();
          , reject
        , reject
  
  loadControl: (name, baseDir, controlData, page) =>
    return new Promise (resolve, reject) =>
      path = baseDir + name;
      dir = paths.dirname(path);
      return @core.cache.getControlAsync(path).then (control) =>
        context = new control({ 
          core: @core, 
          site: page.site, 
          page: page, 
          controlData: controlData, 
          filePath: path,
          workingDir: dir
        });
        return resolve(context);
      , reject
    .catch (err) =>
      @log "Page - loadControl - error", err, err.stack
    
  
module.exports = Magician;