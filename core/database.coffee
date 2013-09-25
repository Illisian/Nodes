
#Layouts = require "./data/layouts"
#Sublayouts = require "./data/sublayouts"
#Pages = require "./data/pages"

mongoose = require 'mongoose';
util = require 'util';

schemas = require "./schemas";

###
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
###

class Pages
  constructor: (@data) ->
    
  getChildren: (page, callback) =>
    @data.model.page.find({ parent: page._id }, callback);

class Sites
  constructor: (@data) ->
    
  getRootPage: (site, cb) =>
    @data.model.page.find({ _id: site.root }, cb);
    

class Database
  constructor: (@config) ->

  init: (next) =>
    console.log "db init"
    
    @logic = {
      sites: new Sites(this)
      pages: new Pages(this)
    }
    
    @model = {
      site: mongoose.model "site", schemas.Site
      page: mongoose.model "page", schemas.Page
      layout: mongoose.model "layout", schemas.Layout
      sublayout: mongoose.model "sublayout", schemas.Sublayout
    }
    mongoose.connect("#{@config.database.ip}/#{@config.database.name}");
    @db = mongoose.connection;
    @db.on('error', console.error.bind(console, 'connection error:'));
    @db.once 'open', () =>
      @createDemo();
      if next?
        next();
        
  clearDb: (next) =>
    @model.site.remove (err) =>
      if err?
        throw err;
      @model.page.remove (err) =>
        if err?
          throw err;
        @model.layout.remove (err) =>
        if err?
          throw err;
        @model.sublayout.remove (err) =>
          if err?
            throw err;
          next();
        
  createDemo:() =>
    @clearDb( () =>
      main = new @model.layout;
      main.name = "main";
    
      content = new @model.sublayout;
      content.name = "content";

      page = new @model.page;
      page.name = "Home";
      page.fields = {  }
      page.path = "/";
      page.isRoot = true;
      page.hasChildren = true;
    
      service = new @model.page;
      service.name = "Services";
      service.fields = {  }
      service.path = "/services/";
      service.isRoot = false;
      service.hasChildren = false;

      projects = new @model.page;
      projects.name = "Projects";
      projects.fields = {  }
      projects.path = "/projects/";
      projects.isRoot = false;
      projects.hasChildren = true;
    
      projects_nodes = new @model.page;
      projects_nodes.name = "Nodes";
      projects_nodes.fields = {  }
      projects_nodes.path = "https://github.com/Illisian/Nodes";
      projects_nodes.isRoot = false;
      projects_nodes.hasChildren = false;
    
    
      site = new @model.site;
      site.name = "demo";
      site.host = "clive.illisian.com.au";
      site.fields = { sitename: "SiteDemo" }
    
      main.save () =>
        page.layout = main._id
        service.layout = main._id;
        projects.layout = main._id;
        projects_nodes.layout = main._id;
        content.save () =>
          page.sublayouts = [{placeholder: "content", id: content._id}]
          page.save () =>
            site.root = page._id;
            site.save () =>
              page.site = site._id
              page.save () =>
                
                service.parent = page._id;
                service.site = site._id
                
                projects.parent = page._id;
                projects.site = site._id;
                
                service.save () =>
                  projects.save () =>
                    projects_nodes.parent = projects._id;
    )
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