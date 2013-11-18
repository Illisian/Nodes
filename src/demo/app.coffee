class Demo
  constructor: (@db) ->
    console.log "Demo construct"
    
  initDemo: () =>
    console.log "starting db clear"
    @db.clearDb () =>
      console.log "db cleared"
      @initSetup();
      
  initSetup: () =>
    console.log "Creating Demo Site";
    main = new @db.model.layout;
    main.name = "main";
      
    content = new @db.model.sublayout;
    content.name = "content";

    page = new @db.model.page;
    page.index = 0;
    page.name = "Home";
    page.fields = {  }
    page.path = "/";
    page.isRoot = true;
    page.hasChildren = true;
    
    site = new @db.model.site;
    site.name = "demo";
    site.hosts = ["127.0.0.1", "clive.illisian.com.au"];
    site.fields = { sitename: "SiteDemo" }
    site.paths = {
      base: "/demo/"
      sublayout: "sublayouts/"
      layout: "layouts/",
      content: "public/"
    }
    main.save () =>
      console.log "layout saved"
      page.layout = main._id
      content.save () =>
        console.log "sublayout saved"
        page.sublayouts = [{placeholder: "content", id: content._id}]
        page.save () =>
          console.log "page saved"
          site.root = page._id;
          site.save (err) =>
            console.log "site saved"
            page.site = site._id
            page.save () =>
              console.log "finished saving demo"

module.exports = Demo