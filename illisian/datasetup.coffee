util = require "../core/func";
Promise = require "bluebird";
class DataSetup
  constructor: (@main) ->
     { @db } = @main;
  init:() =>
    return new Promise (resolve, reject) =>
      util.log "Creating Illisians Site";
      main = new @db.model.layout;
      main.name = "main";

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
      site.hosts = ["127.0.0.1", "clive.illisian.com.au"];
      site.fields = { sitename: "Illisian" }
      site.paths = {
        base: "/illisian/"
        sublayout: "sublayouts/"
        layout: "layouts/",
        module: "modules/",
        content: "public/"
      }
      site.modules = ["security","security1"];
    
      @db.save(main).then () =>
        home.layout = { id: main._id }
        service.layout =  { id: main._id }
        projects.layout = { id: main._id }
        projects_nodes.layout = { id: main._id }
        return @db.save(panel).then () =>
          return @db.save(content).then () =>
            panel1_attr = { header: "panel1_header", content: "panel1_content" }
            panel2_attr = { header: "panel2_header", content: "panel2_content" }
            panel3_attr = { header: "panel3_header", content: "panel3_content" }
            home.sublayouts = [
              { placeholder: "content", id: content._id, index: 0, attributes: {} }
              { placeholder: "panels", id: panel._id, index: 1, attributes: panel1_attr }
              { placeholder: "panels", id: panel._id, index: 2, attributes: panel2_attr}
              { placeholder: "panels", id: panel._id, index: 3, attributes: panel3_attr }
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
                        util.log "Site Created";
                        resolve();
                      
module.exports = DataSetup