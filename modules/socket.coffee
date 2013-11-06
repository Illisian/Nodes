Promise = require "bluebird";
url = require 'url'
Module = require "../lib/module";
Promises = require "../lib/Promises";
util = require "util"
SessionSockets = require './lib/session.socket.io'
cacheStore = require '../lib/cacheStore'

class Sockets extends Module
  constructor: (@options) ->
    super; # call this to make sure everything is set;
    @log "Illisian - Sockets Module - Constructor"
  onAppConfig: (expressApp) =>
    return new Promise (resolve, reject) =>
      @log "Illisian - Sockets Module - onAppConfig"

      resolve();
  onAppStart: (expressApp, server) =>
    return new Promise (resolve, reject) =>
      @io = require('socket.io').listen(server);
      @session = new SessionSockets @io, @core.config.sessions.store, @core.config.sessions.cookie;
      
      @session.on "connection", (err, socket, session, info) =>
        uri = url.parse "http://#{info.host}";
        @core.sites.get(info.cookie, uri.hostname).then (site) =>
          if not site.sockets?
            site.sockets = new cacheStore();
          site.sockets.put(info.cookie, "socket", socket);
          
          #@log "fireing onSocketStart", site.events.onSocketStart.length;
          #return site.events.onSocketStart.chain(@socket).then () =>
            #@log "fireing onSocketStart - complete";
            #

          
      resolve();  
  
  onSocketStart: (socket) =>
    @log "inner onSocketStart";
  ###
  -- Memory Gap --
  ###
  
  onPageRequestStart: (req,res,control) =>
    return new Promise (resolve, reject) =>
      @log "Socket - OnPageRequestStart";
      return resolve();
  
  onPageLoad: (req, res, page) =>
    return new Promise (resolve, reject) =>
      page.sockets = {};
      resolve();
  
  onSiteLoad: (req, res, site) =>
    return new Promise (resolve, reject) =>
      return resolve();


module.exports = Sockets;