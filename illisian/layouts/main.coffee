Promise = require("bluebird");
Layout = require("../../lib/controls/layout");

class Main extends Layout
  view: { file: 'main.jade', renderer: 'jade' }

module.exports = Main;