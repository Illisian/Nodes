util = require "util"

class nav
  view: { file: 'nav.ejs', renderer: 'ejs' }
  constructor: () ->
    
  onData: (next) => # provide fields
    @db.logic.site.getRootPage(@site).then (page) =>
      if page?
        return @db.logic.page.getChildren(page).then (children) =>
          pages = [page].concat(children);
          @fields.pages = pages;
          #console.log "firing next";
          next();
      else
        next();
    
  onHtml: (next) => #provide html
    next();

module.exports = nav;