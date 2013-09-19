
###
Module dependencies.
###
express = require("express")
#routes = require("./routes")
#user = require("./routes/user")
fs = require "fs"
http = require("http")
path = require("path")
fs.unlink "/tmp/clive.sock", (err) ->
  app = express()
  app.enable('trust proxy');
  # all environments
  app.set "port", "/tmp/clive.sock" #process.env.PORT or 3000
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser("your secret here")
  app.use express.session()
  app.use app.router
  app.use require("less-middleware")(src: __dirname + "/public")
  app.use require("./core/router")
  app.use express.static(path.join(__dirname, "public"))
  app.use express.errorHandler()  if "development" is app.get("env")
  http.createServer(app).listen app.get("port"), ->
    setTimeout () ->
      fs.chmod "/tmp/clive.sock", 0x777, (callback) ->
        console.log "Express server listening on port " + app.get("port")
      , 2000

