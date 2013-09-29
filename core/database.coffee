mongoose = require 'mongoose';
util = require 'util';

schemas = require "./schemas";


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
            if next?
              next();

module.exports = Database;