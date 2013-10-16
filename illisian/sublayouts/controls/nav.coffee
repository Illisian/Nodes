util = require "util"
Promise = require("bluebird");
Control = require("../../../core/abstract/control");

class Nav extends Control
  view: { file: 'nav.ejs', renderer: 'ejs' }
  onControlDataBind: (next) => # provide fields
    @log "onControlDataBind getRootPage"
    @renderer.db.logic.site.getRootPage(@renderer.site).then (page) =>
      @log "onControlDataBind getRootPage page response"
      if page?
        @log "onControlDataBind getChildren children"
        @renderer.db.logic.page.getChildren(page).then (children) =>
          @log "onControlDataBind getChildren children response"
          pages = [page].concat(children);
          @fields.pages = pages;
          @log "Nav Fields Set!";
          return next();
      else
        @log "Nav onControlDataBind page not found";
        return next();


module.exports = Nav;