Promise = require("bluebird");
Layout = require("../../lib/controls/layout");

class Admin extends Layout
  view: { file: 'admin.jade', renderer: 'jade' }
  
  constructor: () ->
    super;
    
    @magician = {
      tag: "html"
    }


module.exports = Admin;