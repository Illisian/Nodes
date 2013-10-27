Promise = require 'bluebird';
Promises = require './Promises';
#Promise.longStackTraces();
paths = require 'path'
cheerio = require 'cheerio';
extend = require 'extend'
cache = require './cache';
util = require 'util'
class Page
  constructor: (@core, @site, @pageData) ->
    {@db, @log} = @core;
    @events = {
      onPageLoad: new Promises()
      onPageFinish: new Promises() 
    }
    @fields = {};
    @cache = new cache(@core);
    
    @html = "";
    #@$ = cheerio.load @html;
    
    @cache.put("sublayouts");
   
    @sublayoutPromises = new Promises();
    @isRendered = false;
  process: (req, res) =>
    return new Promise (resolve, reject) =>
      return @createFields().then () =>
        @log "Page - onPageStart";
        return @site.events.onPageLoad.chain(req, res, this).then () =>
          return @events.onPageLoad.chain(req, res).then () =>
            @log "Page - onPageStart - Finished";
            @log "Page - processLayout";
            return @processLayout(req,res).then () =>
              @log "Page - processLayout - Finished";
              @log "Page - processSublayouts";
              return @processSublayouts(req,res).then () =>
                @log "Page - processSublayouts - Finished";
                return @assembleSublayouts(req,res).then () =>
                  @log "Page - onPageFinish";
                  return @site.events.onPageFinish.chain(req,res, this).then () =>
                    return @events.onPageFinish.chain(req,res).then () =>
                      @log "Page - onPageFinish - Finished", @$?;
                      #@$('[nodes-sublayout]').removeAttr("nodes-sublayout")
                      #@$('[nodes-placeholder]').removeAttr("nodes-placeholder")
                      @html = @$.html();
                      return resolve();
                    ,reject
                  ,reject
                ,reject
              ,reject
            ,reject
          ,reject
        ,reject

  
  finish: () =>
    return new Promise (resolve, reject) =>
      @log "Page - finish"
      #@$('[nodes-sublayout]').removeAttr("nodes-sublayout")
      #@$('[nodes-placeholder]').removeAttr("nodes-placeholder")
      html = @$.html();
      resolve(html);
      
  createFields:() =>
    return new Promise (resolve, reject) =>
      @log "Page - processFields"
      if @pageData.fields?
        @fields = extend(true, @fields, @pageData.fields)
      if @site.siteData.fields?
        @fields = extend(true, @fields, @site.siteData.fields)
      @log "Page - processFields - Finished"
      resolve();
  
  processLayout: (req, res) =>
    return new Promise (resolve, reject) =>
      if @layout?
        return @layout.process(req,res, true).then () =>
          @html = @layout.html
          @$ = cheerio.load @html
          return resolve();
        ,reject
      else 
        return @db.logic.layout.findOne({ _id: @pageData.layout.id }).then (layoutData) =>
          if layoutData?
            @log "init processControl"
            return @processControl(req, res, layoutData.name, @site.layoutPath, layoutData)
              .then (@layout) =>
                @log "Page - processLayout - Loading Layout Complete"
                @html = @layout.html
                @$ = cheerio.load @html;
                return resolve();
          return reject();
        , reject

  
  processSublayouts: (req, res) =>
    return new Promise (resolve, reject) =>
      @sublayoutPromises = new Promises();
      @log "Page - loadSublayouts - start";
      for sublayoutRef in @pageData.sublayouts
        target = "[nodes-placeholder='#{sublayoutRef.placeholder}']";
        sublayoutid = "#{sublayoutRef.id}-#{sublayoutRef.placeholder}-#{sublayoutRef.index}"
        @sublayoutPromises.push @sublayoutProcessor, this, [req, res, sublayoutRef, sublayoutid, target];
      @log "Page - loadSublayouts - load tags"
      tagCount = @$('[nodes-sublayout]').length;
      if tagCount > 0
        tags = @$('[nodes-sublayout]').toArray();
        @log "Page - processSublayouts - tags", tags.length
        for sublayoutTag in tags
          sltdetail = @getTagDetails(sublayoutTag);
          @sublayoutPromises.push @sublayoutProcessor, this, [req, res, sltdetail, sltdetail.id, sublayoutTag];
      return @sublayoutPromises.chain().then resolve, reject;
    

  sublayoutProcessor: (req, res, ref, id, target) =>
    return new Promise (resolve, reject) =>
      return @cache.get('sublayouts', id).then (sublayout) =>
        sublayout.target = target;
        return sublayout.process(req, res, true).then () =>
          return resolve();
        , reject
      , () =>
        #rejected
        @log "Page - sublayoutProcessor - Nothing in cache for #{id}";
        if ref.controlname?
          @log "Page - sublayoutProcessor - Processing Tag #{ref.controlname}";
          attr = ref.attributes || {};
          name = ref.controlname;
          
          return @processControl(req, res, name, @site.sublayoutPath, ref, attr, target).then (sublayout) =>
            @cache.put("sublayouts", id, sublayout).then () =>
              return resolve();
            , reject
        else
          @log "Page - sublayoutProcessor - Processing Sublayout - #{ref.id}"
          return @db.logic.sublayout.findOne({ _id: ref.id }).then (sublayoutData) =>
            if sublayoutData?
              attr = ref.attributes || {};
              ref.sublayoutData = sublayoutData;
              return @processControl(req, res, sublayoutData.name, @site.sublayoutPath, ref, attr, target).then (sublayout) =>
                sublayout.target = target;
                return @cache.put('sublayouts', id, sublayout).then () =>
                  @log "Page - sublayoutProcessor - finished - #{ref.id}", target
                  return resolve();
                , reject 
              , reject 
          ,reject

  getTagDetails: (sublayoutTag) =>
    id = @$(sublayoutTag).attr('nodes-id')
    controlname = @$(sublayoutTag).attr('nodes-sublayout');
    attributes = @$(sublayoutTag).attr();
    field_regex = /^nodes-sublayout-attr-.*$/
    replace_regex = /^nodes-sublayout-attr-/
    attr = {};
    for key of attributes
      result = key.match(field_regex);
      if result?
        fieldname = key.replace(replace_regex, "");
        fielddata = @$(sublayoutTag).attr(key);
        attr[fieldname] = fielddata;
    return {
      id: id
      tag: sublayoutTag
      controlname: controlname
      attributes: attributes
    };

  assembleSublayouts: () =>
    return new Promise (resolve, reject) =>
      if @isRendered
        resolve();
      else
        @log "Page - assembleSublayouts - Starting Sublayouts"
        return @cache.get('sublayouts').then((sublayouts) =>
          @log "Page - assembleSublayouts - got sublayouts", sublayouts?
          for s of sublayouts
            @log "Page - assembleSublayouts - Appending Sublayouts #{sublayouts[s].viewPath}", sublayouts[s].html? , sublayouts[s].target?;
            if sublayouts[s].html? and sublayouts[s].target?
              target = sublayouts[s].target;
              if @$(target).length == 0
                @log "target is missing ", sublayouts[s].controlData
              else
                @log "setting html", sublayouts[s].target
                @$(target).append(sublayouts[s].html);
              ###
                if sublayouts[s].controlData.placeholder?
                  @log "searching for - placeholder - #{sublayouts[s].controlData.placeholder}"
                  target = @$("[nodes-placeholder='#{sublayouts[s].controlData.placeholder}']");
                else if sublayouts[s].controlData.tag?
                  @log "searching for - id - #{sublayouts[s].controlData.id}"
                  target = @$("[nodes-id='#{sublayouts[s].controlData.id}']");
                sublayouts[s].target = target;
              ###
            #@isRendered = true;
          return resolve();
        , reject)
          .catch (err) => 
            @log err, err.stack
        return resolve();

        
  processControl: (req, res, name, baseDir, controlData, attr, target) =>
    return new Promise (resolve, reject) =>
      @log "Page - processControl - Start #{name}"
      path = baseDir + name;
      dir = paths.dirname(path);
      @log "Page - processControl - Path #{path}"      
      return @core.cache.getControlAsync(path).then (control) =>
        @log "Page - processControl - new context #{name}"
        context = new control({ 
          core: @core, 
          site: @site, 
          page: this, 
          controlData: controlData, 
          filePath: path,
          workingDir: dir,
          attr: attr,
          target: target
        });
        @log "Page - processControl - context #{name}"
        return context.process(req, res).then(() =>
          return resolve(context);
        , reject)
      , reject
    .catch (err) =>
      @log "Page - processControl - error", err, err.stack
module.exports = Page;
