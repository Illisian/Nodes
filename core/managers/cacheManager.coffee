func = require "../func";

util = require 'util'
express = require "express";
http = require "http";
fs = require "fs";
url = require 'url'

Promise = require "bluebird"
Promise.longStackTraces();

class CacheManager
  
  constructor: (@core) ->
    {@log} = @core;
    @cache = {}
    @cache.controls = [];
    
  getObject: (path) =>
    if @cache.controls[path]?
      return @cache.controls[path];
    mod = require(path)
    @cache.controls[path] = mod;
    return mod;
  
  loadNewObject: (modname) =>
    @log "Loading loadNewControl #{modname}"
    mod = @getObject(modname);
    instance = new mod(arguments);
    instance.log = @log;
    instance.core = @core;
    return instance;

module.exports = CacheManager