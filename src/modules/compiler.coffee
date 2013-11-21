Promise = require "bluebird";
Promises = require "../lib/Promises";
Module = require "../lib/module";
util = require "util"

fs = require "fs";
coffee = require "coffee-script"
paths = require "path";
cacheStore = require "../lib/cacheStore";

exists = Promise.promisify(require("fs").exists);

class Compiler extends Module
  donotcache: true
  onSiteLoad: (req, res, site) =>
    return new Promise (resolve, reject) =>
      site.mod_compiler = new cacheStore();
      resolve();

  onSiteRequestStart: (req, res, site) =>
    return new Promise (resolve, reject) =>
      return resolve();# broke it on purpose, needs to be turned into a more generic system.

module.exports = Compiler;