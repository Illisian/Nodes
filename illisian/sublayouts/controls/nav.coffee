util = require "util"
Promise = require("bluebird");
Control = require("../../../lib/templateControl");

class Nav extends Control
  view: { file: 'nav.ejs', renderer: 'ejs' }
  onControlDataBind: () => # provide fields
    return new Promise (resolve, reject) =>
      @log "onControlDataBind getRootPage"
      @db.logic.site.getRootPage(@site.siteData).then (pageData) =>
        @log "onControlDataBind getRootPage page response"
        if pageData?
          @log "onControlDataBind getChildren children"
          @db.logic.page.getChildren(pageData).then (childrenData) =>
            @log "onControlDataBind getChildren children response"
            pages = [pageData].concat(childrenData);
            @fields.pages = pages;
            @security = @security || {};
            @log "Nav Fields Set!";
            return resolve();
        else
          @log "Nav onControlDataBind page not found";
          return resolve();


module.exports = Nav;