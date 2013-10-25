Promise = require("bluebird");
TemplateControl = require("../../lib/templateControl");

class Main extends TemplateControl
  view: { file: 'main.jade', renderer: 'jade' }

module.exports = Main;