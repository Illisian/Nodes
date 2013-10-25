express = require "express"

class Config
  constructor: () ->
    @base_dir =  __dirname;
    @host = {
      ip: null
      is_sock: true
      port: "/tmp/clive.sock" #process.env.PORT or 3000
    }
    @database = {
      ip: "127.0.0.1"
      name: "nodes2"
    }
    @apps = [
      "illisian"
    ]
      
    @renderModules = [ "fields", "controlregistry" ]

    @express = {
      enable: ["trust-proxy"]
      use: [
        express.favicon()
        express.logger("dev")
        #express.methodOverride()
        express.cookieParser("your secret here")
        express.session({
          secret: 'keyboard cat',
          key: 'sid',
          #cookie: {httpOnly: true, secure: true}
          #cookie: {httpOnly: true}
        })
        #express.errorHandler() if "development" is @app.get("env")
      ]
        
      
    }

module.exports = Config