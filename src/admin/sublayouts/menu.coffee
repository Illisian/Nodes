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
  onControlLoad: (req, res) =>
    return new Promise (resolve, reject) =>
      @menuItems = [{active: true, path: '/admin/pageeditor', name: "Page Editor" }]
      #@log "Menu - onControlRender", this;
      return resolve();


module.exports = Menu;