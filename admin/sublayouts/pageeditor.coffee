Promise = require("bluebird");
Sublayout = require("../../lib/controls/sublayout");

class PageEditor extends Sublayout
  view: { file: 'pageeditor.ejs', renderer: 'ejs' }
  
  constructor: () ->
    super;
    @tagName = "div";
    @tagAttributes = {
      class: "col-xs-12"
    }


module.exports = PageEditor;