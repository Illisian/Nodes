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
  onControlRender: (req, res) =>
    return new Promise (resolve, reject) =>
      if req.query.siteid? and req.query.pageid?
        siteid = req.query.siteid
        pageid = req.query.pageid;
        return @db.logic.page.findOne({site: siteid, _id: pageid}).then (page) =>
          @log "FOUND"
          res.send "PAGE FOUND - insert loading code here";
        , () =>
          @log "NOT FOUND"
          res.send "REJECTED NOT FOUND";
      else
        return resolve();

module.exports = PageEditor;