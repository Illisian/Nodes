Promise = require("bluebird");
Control = require("../../core/abstract/control");


class Content extends Control
  view: { file: 'content.ejs', renderer: 'ejs' }


module.exports = Content;