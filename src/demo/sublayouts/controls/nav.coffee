util = require "util"

class nav
  view: { file: 'nav.ejs', renderer: 'ejs' }
  constructor: () ->
    
  onData: (next) => # provide fields
    console.log "calling getRootPage", @context.logic;
    
    @context.data.logic.sites.getRootPage(@context.site, (err, page) =>
      #console.log "getRootPage", util.inspect(page), util.inspect(@context.site);
      @context.data.logic.pages.getChildren page, (err, children) =>
        @fields = {
          pages: children
        }
        #console.log "firing next";
        next();
    )
  onHtml: (next) => #provide html
    next();

module.exports = nav;