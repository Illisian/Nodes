Promise = require("bluebird");
Control = require("../../core/abstract/control");

class Main extends Control
  view: { file: 'main.jade', renderer: 'jade' }

module.exports = Main;