mongoose = require 'mongoose';
Promise = require "bluebird"
#extend = require "extend";

schemas = require "./schemas";
func = require './func';
u = require 'util';


class ModelLogic
  constructor: (@db) ->
    if not @modelName?
      throw "Model Name is not defined";
    if not @schema?
      throw "Schema is not defined";
    func.log "Init model: #{@modelName}";
    @model = mongoose.model @modelName, @schema;
  remove: (filter) =>
    return new Promise (resolve, reject) =>
      @model.remove filter, (err) =>
        if err?
          reject(err);
        resolve();
  find: (filter, sort) =>
    return new Promise (resolve, reject) =>
      @model.find filter, null, { sort: sort }, (err, results) =>
        if err?
          reject(err);
        resolve(results);
  findOne: (filter) =>
    return new Promise (resolve, reject) =>
      @model.findOne filter, (err, result) =>
        if err?
          reject(err);
        if result?
          func.log "findOne [#{@model.modelName}] - [#{result._id}] found", filter
        else 
          func.log "findOne [#{@model.modelName}] not found", filter
        resolve(result);


class Pages extends ModelLogic
  modelName: "page";
  schema: schemas.Page
  getChildren: (page) =>
    return @find { parent: page._id }, { sort: { index: 'desc' } }

class Sites extends ModelLogic
  modelName: "site";
  schema: schemas.Site
  getRootPage: (site) =>
    return @db.logic.page.findOne { _id: site.root };
    
class Layouts extends ModelLogic
  modelName: "layout";
  schema: schemas.Layout

class Sublayouts extends ModelLogic
  modelName: "sublayout";
  schema: schemas.Sublayout

class Database
  constructor: (@config) ->

  save: (model) ->
    return new Promise (resolve, reject) ->
      model.save () ->
        resolve();
    
  init: () =>
    return new Promise (resolve, reject) =>
      func.log "database init has started"
      @logic = {
        site: new Sites this
        page: new Pages this
        layout: new Layouts this
        sublayout: new Sublayouts this
      }
      @model = {
        site: @logic.site.model
        page: @logic.page.model
        layout: @logic.layout.model
        sublayout: @logic.sublayout.model
      }

      mongoose.connect("#{@config.database.ip}/#{@config.database.name}");
      @db = mongoose.connection;
      @db.on('error', console.error.bind(console, 'connection error:'));
      @db.once 'open', () =>
        resolve();

  clearDb: () =>
    return new Promise (resolve, reject) =>
      @logic.site.remove({})
      .then(@logic.page.remove({}))
      .then(@logic.layout.remove({}))
      .then(@logic.sublayout.remove({}))
      .then(() ->
        func.log("Database has been cleared!");
        resolve();
      )

module.exports = Database;