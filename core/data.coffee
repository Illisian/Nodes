mongojs = require "mongojs"
class Data
  constructor: (@config) ->
    @db = mongojs("#{@config.database.ip}/#{@config.database.name}", ['layouts', 'sublayouts', 'pages']);
  getSublayout: (id, next) =>
    @db.sublayouts.findOne { _id:mongojs.ObjectId(id) }, (err,doc) =>
      next doc;
  getLayout: (id, next) =>
    @db.layouts.findOne { _id:mongojs.ObjectId(id) }, (err,doc) =>
      next doc;
  getPage: (url, next) =>
    @db.pages.findOne { url:url }, (err,doc) =>
      next doc;
module.exports = Data;