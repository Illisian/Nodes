###
    @layouts = [
      { _id: "#1", name: "main" }
    ]
    @sublayouts = [
      { _id: "#2", name: "navbar" }
      { _id: "#3", name: "content" }
      { _id: "#4", name: "navbar_github" }
    ]
    @pages = [
      {
        parent: null
        id: "#5",
        name: "Home"
        url: "/",
        layout:  "#1"
        sublayouts: [
          { placeholder: "nav", id: "#2" },
          { placeholder: "content", id: "#3" }
          { placeholder: "navbar_github", id: "#4" }
        ]
        fields: { title: "Illisian" }
      },
      {
        parent: "#5"
        id: "#6",
        name: "Services"
        url: "/services",
        layout:  "#1"
        sublayouts: [
          { placeholder: "nav", id: "#2" }
          { placeholder: "navbar_github", id: "#4" }
        ]
        fields: { title: "Illisian" }
      }
    ]
    @sites = [
      {
        domain: [ { name: "clive.illisian.com.au" } ]
        root: "#5"
      }
    ]
  getSublayout: (id, next) =>
    current = sublayout for sublayout in @sublayouts when sublayout._id is id;
    next current
  getLayout: (id, next) =>
    current = layout for layout in @layouts when layout._id is id;
    next current
  getPage: (url, next) =>
    current = page for page in @pages when page.url is url;
    next current
  getSite: (domain, next) =>
    current = site for site in @sites when sites.domain.where name:domain;
###
    
    #@db.layouts.find({});
    #@db.sublayouts.find({});
    #@db.pages.find({});
    ###
    @db.layouts.save({ name: "main" });
    
    @db.sublayouts.save({ name: "navbar" });
    @db.sublayouts.save({ name: "content" });
    @db.sublayouts.save({ name: "navbar_github" });
    
    @db.pages.save({
        parent: null
        name: "Home"
        url: "/",
        layout:  "#1"
        sublayouts: [
          { placeholder: "nav", id: "#2" },
          { placeholder: "content", id: "#3" }
          { placeholder: "navbar_github", id: "#4" }
        ]
        fields: { title: "Illisian" }
      });
    @db.pages.save({
        parent: "#5"
        name: "Services"
        url: "/services",
        layout:  "#1"
        sublayouts: [
          { placeholder: "nav", id: "#2" }
          { placeholder: "navbar_github", id: "#4" }
        ]
        fields: { title: "Illisian" }
      });
    ###