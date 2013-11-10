Promise = require "bluebird";
Promises = require "../lib/Promises";
Module = require "../lib/module";
cheerio = require "cheerio";
paths = require "path";
uuid = require 'node-uuid';

class Magician extends Module
  constructor: (@options) ->
    super
    
  onPageRequestStart: (req, res, page) =>
    return new Promise (resolve, reject) =>
      @log "Magician - onPageRequestStart";
      if page.isLoaded
        return resolve();
      return @loadControls(page).then () =>
        @log "Magician - onPageRequestStart - finish";
        return resolve();
      , reject
    
  onControlRender: (req, res, control) =>
    return new Promise (resolve, reject) =>
      @log "Magician - onControlRender - start", control.$.length;
      return resolve();

  onPageRequestFinish: (req, res, page) =>
    return new Promise (resolve, reject) =>
      if not page.isLoaded
        for control in page.controls
          if control.isLayout
            page.html = control.html;
            page.$ = cheerio.load page.html
      if page.$?
        for c in page.controls
          if not c.element?
            if c.ref? and not page.isLayout
              if c.ref.placeholder?
                tagName = "div";
                if c.tagName?
                  tagName = c.tagName;
                c.element = page.$("<#{tagName}></#{tagName}>").attr("id", c.id).attr("nodes-control","").append(c.html);
                if c.tagAttributes?
                  for attrib of c.tagAttributes
                    page.$(c.element).attr(attrib, c.tagAttributes[attrib]);
                target = "[nodes-placeholder='#{c.ref.placeholder}']";
                @log "appending control to #{c.ref.placeholder}";
                page.$(target).append(c.element);
          else
            if page.$(c.element).length > 0
              page.$(c.element).html(c.html);
            else 
              target = "[nodes-placeholder='#{c.ref.placeholder}']";
              page.$(target).append(c.element);
              
        return @processSublayoutTags(req, res, page).then () =>
          page.isLoaded = true;
          page.html = page.$.html();
          return resolve();
        , reject
      else 
        return reject();
      
  processSublayoutTags: (req, res, page) =>
    return new Promise (resolve, reject) =>
      @log "Magician - processSublayoutTags - start";
      tagCount = page.$('[nodes-sublayout]').length
      if tagCount > 0
        tags = page.$('[nodes-sublayout]').toArray();
        @log "Magician - processSublayoutTags - tags", tags.length
        
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
        context.id = uuid.v4();
        return resolve(context);
      , reject
    .catch (err) =>
      @log "Page - loadControl - error", err, err.stack
    
  
module.exports = Magician;