mongojs = require "mongojs"
class Data
  constructor: () ->
    @db = mongojs('127.0.0.1/nodes', ['layouts', 'sublayouts', 'pages']);
    @paths = {
      layout: __dirname + '/../layouts/'
      sublayout: __dirname + '/../sublayouts/'
    }
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