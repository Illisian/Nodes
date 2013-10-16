Promise = require("bluebird");
Control = require("../../../core/abstract/control");

class Panel extends Control
  view: { file: 'panel.ejs', renderer: 'ejs' }

module.exports = Panel;