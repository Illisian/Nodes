express = require "express"

class Config
  constructor: (@app) ->
    @host = {
      ip: null
      is_sock: true
      port: "/tmp/clive.sock" #process.env.PORT or 3000
    }
    @database = {
      ip: "127.0.0.1"
      name: "nodes"
    }
    @paths = {
      layout: __dirname + '/layouts/'
      sublayout: __dirname + '/sublayouts/'
    }
    @express = {
      enable: ["trust-proxy"]
      use: [
        express.favicon()
        express.logger("dev")
        #express.bodyParser()
        #express.methodOverride()
        express.cookieParser("your secret here")
        express.session({
          secret: 'keyboard cat',
          key: 'sid',
          #cookie: {httpOnly: true, secure: true}
          cookie: {httpOnly: true}
        })
        express.errorHandler() if "development" is @app.get("env")
      ]
        
      
    }


module.exports = Config