
#Layouts = require "./data/layouts"
#Sublayouts = require "./data/sublayouts"
#Pages = require "./data/pages"

mongoose = require 'mongoose';
util = require 'util';

schemas = require "./schemas";


class ModelHelper
  constructor: (@modelName, @schema) ->
    @model = mongoose.model @modelName, @schema
  find: (filter, next) =>
    @model.find filter, (err,doc) =>
      if err
        throw err;
      next doc;
  create: () =>
    return new @model;
  remove: (filter, next) =>
    @model.remove filter, (err) =>
      if err?
        throw err;
      if next?
        next();
class Database
  constructor: (@config) ->

  init: (next) =>
    console.log "db init"
    @sites = new ModelHelper "site", schemas.Site
    @pages = new ModelHelper "page", schemas.Page
    @layouts = new ModelHelper "layout", schemas.Layout
    @sublayouts = new ModelHelper "sublayout", schemas.Sublayout
    mongoose.connect("#{@config.database.ip}/#{@config.database.name}");
    @db = mongoose.connection;
    @db.on('error', console.error.bind(console, 'connection error:'));
    @db.once 'open', () =>
      @createDemo();
      if next?
        next();
  createDemo:() =>
    
    @sites.remove();
    @pages.remove();
    @layouts.remove();
    @sublayouts.remove();
    
    main = @layouts.create();
    main.name = "main";
    
    content = @sublayouts.create();
    content.name = "content";
    
    page = @pages.create()
    page.name = "Home";
    page.fields = { sitename: "SiteDemo" }
    page.path = "/";
    
    site = @sites.create()
    site.name = "demo";
    site.host = "clive.illisian.com.au";
    
    main.save () =>
      page.layout = main._id
      content.save () =>
        page.sublayouts = [{placeholder: "content", id: content._id}]
        page.save () =>
          site.root = page._id;
          site.save () =>
            page.site = site._id
            page.save();
        
###
Page = new Schema {
  site: { type: Schema.Types.ObjectId, index: true }
  name: { type: String, required: true, index: true }
  layout: { type: Schema.Types.ObjectId }
  sublayouts: [{
    placeholder: { type: String }
    id: { type: Schema.Types.ObjectId }
  }]
  fields: { type: Schema.Types.Mixed }
}
###
module.exports = Database;