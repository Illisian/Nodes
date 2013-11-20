util = require "util"
Promise = require("bluebird");
Promises = require("../../../lib/Promises");
Control = require("../../../lib/templateControl");

class Nav extends Control
  view: { file: 'nav.ejs', renderer: 'ejs' }
  onControlDataBind: (req, res) => # provide fields
    return new Promise (resolve, reject) =>
      @security = @security || {};
      if req.isAuthenticated()
        @security.name = req.session.passport.user.displayName;
        if req.session.passport.user.photos?
          @security.photo = req.session.passport.user.photos[0]
      
      
      @log "onControlDataBind getRootPage"
      return @db.logic.site.getRootPage(@site.siteData).then (pageData) =>
        @log "onControlDataBind getRootPage page response"
        if pageData?
          @log "onControlDataBind getChildren children"
          return @db.logic.page.getChildren(pageData).then (childrenData) =>
            @log "onControlDataBind getChildren children response"
            pages = [].concat(childrenData);
            promises = new Promises();
            for parentPage in pages 
              promises.push @processChildren , this, [ parentPage ]
            @log "onControlDataBind getChildren childrens"
            return promises.chain().then (results) =>
              @pages = [pageData]
              for r in results
                @pages.push r[0];
              @log "Nav Fields Set!";
              return resolve();
            , reject
          , (err) =>
            @log "REJECTED no children", err
            #resolve();
            
            
        else
          @log "Nav onControlDataBind page not found";
          return resolve();
      .catch (err) =>
        @log err ,err.stack;
  processChildren: (pageData) =>
    return new Promise (resolve, reject) =>
      return @db.logic.page.getChildren(pageData).then (children) =>
        @log "processChildren"
        pageData.children = children;
        pageData.showDropdown = false;
        if pageData.children.length > 0 and not pageData.isRoot
          pageData.showDropdown = true;
        
        return resolve(pageData);
      , reject
        

module.exports = Nav;