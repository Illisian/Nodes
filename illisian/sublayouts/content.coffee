Promise = require("bluebird");
Control = require("../../lib/templateControl");


class Content extends Control
  view: { file: 'content.ejs', renderer: 'ejs' }


module.exports = Content;