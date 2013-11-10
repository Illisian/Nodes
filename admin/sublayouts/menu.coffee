Promise = require("bluebird");
Sublayout = require("../../lib/controls/sublayout");

class Menu extends Sublayout
  view: { file: 'menu.ejs', renderer: 'ejs' }
  
  constructor: () ->
    super;
    @tagName = "ul";
    @tagAttributes = {
      class: "nav nav-tabs"
    }


module.exports = Menu;