util = require "../lib/func";
Promise = require "bluebird";
class DataSetup
  constructor: (@main) ->
     { @db, @log } = @main;
  init: () =>
    return new Promise (resolve, reject) =>
      util.log "Creating Illisians Site";
      @log "DataSetup - init - Start"
      main = new @db.model.layout;
      main.name = "main";
      
      nav = new @db.model.sublayout;
      nav.name = "controls/nav";      

      content = new @db.model.sublayout;
      content.name = "content";
    
      panel = new @db.model.sublayout;
      panel.name = "controls/panel";

      home = new @db.model.page;
      home.index = 0;
      home.name = "Home";
      home.fields = { 
        panel1_header: "Services"
        panel1_content: "<ul class='list-group'> <li class='list-group-item'> Web Application Hosting </li> <li class='list-group-item'> Application Development </li> <li class='list-group-item'> Consultation </li><ul>"
        panel2_header: "Projects"
        panel2_content: "<ul class='list-group'> 
          <li class='list-group-item'> 
            <a href='https://github.com/Illisian/Nodes'>Nodes - CMS built in Node.Js</a> 
            <span style='float: right'>
              <iframe src='http://ghbtns.com/github-btn.html?user=Illisian&repo=Nodes&type=watch' allowtransparency='true' frameborder='0' scrolling='0' width='62' height='20'></iframe>
            </span>
          </li> 
          <ul>"
        panel3_header: "Contact Us"
        panel3_content: "<ul class='list-group'>
          <li class='list-group-item'>
            <button class='btn btn-primary' type='button' data-toggle='modal' data-target='#onlineRequest'>Online Request</button>
          </li> 
          <li class='list-group-item'> 
            Email: <a href='mailto:contactus@illisian.com.au'>contactus@illisian.com.au</a> 
          </li>
          <li class='list-group-item'>
            Mobile: +61 04 2620 6650
          </li>
          <ul>"
      }
      home.path = "/";
      home.isRoot = true;
      home.hasChildren = true;
    
      service = new @db.model.page;
      service.name = "Services";
      service.index = 1;
      service.fields = {  }
      service.path = "/services/";
      service.isRoot = false;
      service.hasChildren = false;

      projects = new @db.model.page;
      projects.name = "Projects";
      projects.index = 0;
      projects.fields = {  }
      projects.path = "/projects/";
      projects.isRoot = false;
      projects.hasChildren = true;
      projects_nodes = new @db.model.page;
      projects_nodes.name = "Nodes";
      projects_nodes.fields = {  }
      projects_nodes.path = "https://github.com/Illisian/Nodes";
      projects_nodes.isRoot = false;
      projects_nodes.hasChildren = false;
    

      site = new @db.model.site;
      site.name = "Illisian";
      site.hosts = ["127.0.0.1", "local.illisian.com.au", "clive.illisian.com.au"];
      site.fields = { sitename: "Illisian" }
      site.paths = {
        base: "/illisian/"
        sublayout: "sublayouts/"
        layout: "layouts/",
        module: "modules/",
        content: ["public/", "../admin/public/"]
      }
      site.modules = [];
      @log "DataSetup - init - committing variables"
      return @db.save(main).then () =>
        home.layout = { id: main._id }
        service.layout =  { id: main._id }
        projects.layout = { id: main._id }
        projects_nodes.layout = { id: main._id }
        return @db.save(panel).then () =>
          return @db.save(content).then () =>
            return @db.save(nav).then () =>
              panel1_attr = { header: "panel1_header", content: "panel1_content" }
              panel2_attr = { header: "panel2_header", content: "panel2_content" }
              panel3_attr = { header: "panel3_header", content: "panel3_content" }
              home.sublayouts = [
                { placeholder: "nav", id: nav._id, index: 0, attributes: {} }
                { placeholder: "content", id: content._id, index: 1, attributes: {} }
                { placeholder: "panels", id: panel._id, index: 2, attributes: panel1_attr }
                { placeholder: "panels", id: panel._id, index: 3, attributes: panel2_attr}
                { placeholder: "panels", id: panel._id, index: 4, attributes: panel3_attr }
              ]
              service.sublayouts = [
                { placeholder: "nav", id: nav._id, index: 0, attributes: {} }
              ]
              projects.sublayouts = [
                { placeholder: "nav", id: nav._id, index: 0, attributes: {} }
              ]
              return @db.save(home).then () =>
                site.root = home._id;
                return @db.save(site).then () =>
                  home.site = site._id
                  return @db.save(home).then () =>
                    service.parent = home._id;
                    service.site = site._id
                    projects.parent = home._id;
                    projects.site = site._id;
                    return @db.save(service).then () =>
                      return @db.save(projects).then () =>
                        projects_nodes.parent = projects._id;
                        return @db.save(projects_nodes).then () =>
                          @log "DataSetup - init - starting admin setup"
                          return @adminSetup(home, site).then () =>
                            @log "DataSetup - init - finished"
                            return resolve();
      .catch (err) =>
        @log err
    
  adminSetup: (home, site) =>
    return new Promise (resolve, reject) =>
      @log "DataSetup - adminSetup - start"
      admin = new @db.model.layout;
      admin.name = "../../admin/layouts/admin";
      
      adminMenu = new @db.model.sublayout;
      adminMenu.name = "../../admin/sublayouts/menu";
      
      pageeditor = new @db.model.sublayout;
      pageeditor.name = "../../admin/sublayouts/pageeditor";
      
      adminHome = new @db.model.page;
      adminHome.name = "Admin";
      adminHome.index = 2;
      adminHome.fields = {  }
      adminHome.path = "/admin/";
      adminHome.isRoot = false;
      adminHome.hasChildren = true;
      adminHome.site = site._id
      adminHome.parent = home._id;
      
      adminPageEditor = new @db.model.page;
      adminPageEditor.name = "Page Editor";
      adminPageEditor.index = 2;
      adminPageEditor.fields = {  }
      adminPageEditor.path = "/admin/pageeditor";
      adminPageEditor.isRoot = false;
      adminPageEditor.hasChildren = false;
      adminPageEditor.site = site._id
      adminPageEditor.parent = adminHome._id;
      
      
      return @db.save(admin).then () =>
        return @db.save(adminMenu).then () =>
          adminHome.layout = { id: admin._id }
          adminHome.sublayouts = [
            { placeholder: "menu", id: adminMenu._id, index: 0, attributes: {} }
          ]
          return @db.save(adminHome).then () =>
            
            return @db.save(pageeditor).then () =>
              adminPageEditor.layout = { id: admin._id }
              adminPageEditor.sublayouts = [
                { placeholder: "menu", id: adminMenu._id, index: 0, attributes: {} }
                { placeholder: "content", id: pageeditor._id, index: 0, attributes: {} }
              ]
              return @db.save(adminPageEditor).then () =>
                @log "DataSetup - adminSetup - finished"
                return resolve();
    
                      
module.exports = DataSetup