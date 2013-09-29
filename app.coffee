###
Module dependencies.
###
express = require "express"

http = require "http"
path = require "path"

nodes_config = require "./config"
nodes_router = require "./core/router"
nodes_database = require "./core/database"
nodes_util = require "./core/util"
demo_app = require("./illisian/app")
app = express()

cfg = new nodes_config app;
data = new nodes_database cfg
router = new nodes_router cfg, data
nutil = new nodes_util cfg, data


finish = (app) ->
  console.log "Nodes[express server] is listening on port " + app.get("port")


init = (next) ->
  data.init () ->
    
    demo = new demo_app(data)
    demo.initDemo();
    
    app.set "port", cfg.host.port 
    for setting in cfg.express.enable then app.enable(setting)
    for setting in cfg.express.use then app.use(setting)
    app.use router.processRequest
    http.createServer(app).listen app.get("port"), ->
      if cfg.host.is_sock
        nutil.freeforall cfg.host.port, () ->
          finish(app);
      else
        finish(app);

# Start Up 
if cfg.host.is_sock
  nutil.unlink cfg.host.port, () ->
    init();
else
  init();