
Promise = require 'bluebird'


extend = require 'extend'
u = require 'util'
cheerio = require 'cheerio'
consolidate = require 'consolidate'
paths = require 'path'



class Renderer
  constructor: (@core, @site) ->
    {@config, @db} = @core;
    @sublayoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.sublayout}";
    @layoutPath = "#{@config.base_dir}#{@site.paths.base}#{@site.paths.layout}"; 
  processPage: (page) =>
    return new Promise (resolve, reject) =>
      @page = page;
      if @page.fields?
        @fields = extend(true, @fields, @page.fields)
      if @site.fields?
        @fields = extend(true, @fields, @site.fields)
      @db.logic.layout.findOne({ _id: page.layout.id }).then (layout) =>
        if layout?
          return @processControl(@layoutPath,  page.layout.attributes || {} , layout.name).then (control) =>
            #console.log "start layout processing";
            @html = control.html;
            @$ = cheerio.load @html
            return @processSublayouts(@page.sublayouts).then () =>
              return @processSublayoutTags().then () =>
                return @processFields().then () =>
                  @$('[nodes-sublayout]').removeAttr("nodes-sublayout")
                  @$('[nodes-field]').removeAttr("nodes-field")
                  @$('[nodes-placeholder]').removeAttr("nodes-placeholder")
                  @html = @$.html();
                  resolve(@html);
        else
          reject();
  processFields: () =>
    return new Promise (resolve, reject) =>
      if @fields?
        arr = @$('[nodes-field]');
        for i in arr
          fieldName = @$(i).attr("nodes-field")
          if fieldName of @fields
            fieldContents = @fields[fieldName]
            @$(i).prepend(fieldContents)
      resolve();
  
  processSublayoutTags: () =>
    return new Promise (resolve, reject) =>
      sublayoutTags  = @$('[nodes-sublayout]').toArray();
      promises = @sublayoutTagProcessor(sublayoutTag) for sublayoutTag in sublayoutTags
      Promise.all(promises).then () =>
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
      @processControl(@sublayoutPath,attr, name).then (control) =>
        @$(sublayoutTag).append(control.html);
        resolve();
  
  processSublayouts: (sublayouts) =>
    return new Promise (resolve, reject) =>
      promises = @sublayoutProcessor(sublayout) for sublayout in sublayouts
      Promise.all(promises).then () =>
        resolve();
  
  sublayoutProcessor: (sublayoutData) =>
    return new Promise (resolve, reject) =>
      @db.logic.sublayout.findOne({ _id: sublayoutData.id }).then (sublayout) =>
        if sublayout?
          return @processControl(@sublayoutPath, sublayoutData.attributes || {}, sublayout.name).then (control) =>
            #console.log "processSublayouts processControl append";
            @$('[nodes-placeholder="'+sublayoutData.placeholder+'"]').append(control.html);
            resolve();
        else
          reject();

  
  processControl:(path, attributes, controlName) =>
    return new Promise (resolve, reject) =>
      controlPath = path + controlName;
      control = require controlPath
      jsfile = new control
      extend(true, jsfile, this);
      jsfile.attr = attributes;
      #jsfile.fields = @fields
      #jsfile.db = @db;
      jsfile.renderer = this # this sets page and fields
      dir = paths.dirname(path + controlName);
      viewPath = "#{dir}/views/#{jsfile.view.file}";
      #console.log "processControl onData start";
      jsfile.onData () =>
        @renderFile(viewPath, jsfile.view.renderer, jsfile).then (html) =>
          jsfile.html = html;
          #console.log "processControl renderFile";
          jsfile.onHtml () =>
            #console.log "processControl onHtml";
            resolve(jsfile);
            
  renderFile: (path, renderer, fields, next) =>
    return new Promise (resolve, reject) =>
      consolidate[renderer] path, fields, (err, html) =>
        if err?
          throw err;
        resolve(html)
      

module.exports = Renderer