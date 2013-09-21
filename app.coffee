###
Module dependencies.
###
express = require "express"
fs = require "fs"
http = require "http"
path = require "path"

nodes_config = require "./config"
nodes_router = require "./core/router"
nodes_data = require "./core/data"

app = express()

cfg = new nodes_config app;
data = new nodes_data cfg
router = new nodes_router cfg, data

unlink = (next) ->
  fs.unlink cfg.host.port, (err) ->
    next()
freeforall = (next) ->
  setTimeout () ->
    fs.chmod cfg.host.port, 0x777, () ->
      next();
    , 2000

finish = (app) ->
  console.log "Nodes[express server] is listening on port " + app.get("port")


init = (next) ->
  app.set "port", cfg.host.port 
  for setting in cfg.express.enable then app.enable(setting)
  for setting in cfg.express.use then app.use(setting)
  app.use router.processRequest
  app.use express.static(path.join(__dirname, "public"))
  http.createServer(app).listen app.get("port"), ->
    if cfg.host.is_sock
      freeforall () ->
        finish(app);
    else
      finish(app);

# Start Up 
if cfg.host.is_sock
  unlink () ->
    init();
else
  init();