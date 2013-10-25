Promise = require 'bluebird';
Promises = require './Promises';
#Promise.longStackTraces();
paths = require 'path'
cheerio = require 'cheerio';
extend = require 'extend'

class Page
  constructor: (@core, @site, @pageData) ->
    {@db, @log} = @core;
    @events = {
      onPageLoad: new Promises()
      onPageFinish: new Promises() 
    }
    @sublayouts = [];
    @sublayoutPromises = new Promises();
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
                @log "Page - processSublayoutTags";
                return @processSublayoutTags(req,res)
                  .then(@assembleSublayouts).then () =>
                    @log "Page - onPageFinish";
                    return @site.events.onPageFinish.chain(req,res, this).then () =>
                      return @events.onPageFinish.chain(req,res).then () =>
                        @log "Page - onPageFinish - Finished", @$?;
                        #@$('[nodes-sublayout]').removeAttr("nodes-sublayout")
                        #@$('[nodes-placeholder]').removeAttr("nodes-placeholder")
                        @html = @$.html();
                        resolve();
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
      @db.logic.layout.findOne({ _id: @pageData.layout.id }).then (layoutData) =>
        if layoutData?
          @log "init processControl"
          return @processControl(req, res, layoutData.name, @site.layoutPath, layoutData)
            .then (@layout) =>
              @log "Page - processLayout - Loading Layout Complete"
              @$ = cheerio.load @layout.html;
              return resolve();
        return reject();
      , reject

  
  processSublayouts: (req, res) =>
    return new Promise (resolve, reject) =>
      @log "Page - processSublayouts"
      promises = new Promises();
      for sublayout in @pageData.sublayouts
        promises.push @sublayoutProcessor, this, [req, res, sublayout];
      @log "Page - processSublayouts - Found Sublayouts - #{promises.length}"
      return promises.chain().then resolve, reject;

  sublayoutProcessor: (req, res, sublayoutRef) =>
    return new Promise (resolve, reject) =>
      @log "Renderer - sublayoutProcessor - Searching for Sublayout - #{sublayoutRef.id}"
      @db.logic.sublayout.findOne({ _id: sublayoutRef.id }).then (sublayoutData) =>
        if sublayoutData?
          attr = sublayoutRef.attributes || {};
          target = '[nodes-placeholder="'+sublayoutRef.placeholder+'"]'
          return @processControl(req, res, sublayoutData.name, @site.sublayoutPath, sublayoutData, attr, target)
            .then (sublayout) =>
              @sublayouts.push sublayout;
              @log "Page - sublayoutProcessor - finished - #{sublayoutRef.name}"
              resolve();

  processSublayoutTags: (req, res) =>
    return new Promise (resolve, reject) =>
      promises = new Promises();
      @log "Renderer - processSublayoutTags - start"
      tagCount = @$('[nodes-sublayout]').length;
      if tagCount > 0
        tags = @$('[nodes-sublayout]').toArray();
        @log "Renderer - processSublayoutTags - tags", tags.length
        for sublayoutTag in tags
          promises.push @sublayoutTagProcessor, this, [req, res, sublayoutTag];
        @log "Renderer - processSublayoutTags - promises", promises
        return promises.chain().then resolve, reject;
      else
        @log "Renderer - processSublayoutTags - no tags found"
        resolve();
  
  sublayoutTagProcessor: (req, res, sublayoutTag) =>
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
          fielddata = @$(sublayoutTag).attr(key);
          attr[fieldname] = fielddata;
      return @processControl(req, res, name, @site.sublayoutPath, {}, attr, sublayoutTag).then (sublayout) =>
        @sublayouts.push sublayout
        resolve();
  
  assembleSublayouts: () =>
    return new Promise (resolve, reject) =>
      @log "Page - assembleSublayouts - Starting Sublayouts"
      for s in @sublayouts
        @log "Page - assembleSublayouts - Appending Sublayouts #{s.viewPath}", s.html? , s.target?;
        if s.html? and s.target?
          @$(s.target).append(s.html);
      @log "Renderer - assembleSublayouts - End"
      resolve();

        
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
