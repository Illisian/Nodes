Promise = require("bluebird");
Control = require("../../../lib/templateControl");

class Panel extends Control
  view: { file: 'panel.ejs', renderer: 'ejs' }

module.exports = Panel;