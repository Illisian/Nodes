Promise = require "bluebird";

Module = require "../lib/module";

util = require "util"
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy;
GitHubStrategy = require('passport-github').Strategy;
FacebookStrategy = require('passport-facebook').Strategy;

passport = require "passport"


passport.serializeUser (user, done) ->
  done(null, user);

passport.deserializeUser (obj, done) ->
  done(null, obj);


class Security extends Module
  constructor: (@options) ->
    super; # call this to make sure everything is set;
    @log "Illisian - Security Module - Constructor"
    
    passport.use new GoogleStrategy(@core.config.security.google, @onStrategyComplete);
    passport.use new FacebookStrategy(@core.config.security.facebook, @onStrategyComplete);
    passport.use new GitHubStrategy(@core.config.security.github, @onStrategyComplete);
    
    @proxies = [];
    @proxies["google"] = Promise.promisify(passport.authenticate('google', { successRedirect: '/' }));
    @proxies["github"] = Promise.promisify(passport.authenticate('github', { successRedirect: '/' }));
    @proxies["facebook"] = Promise.promisify(passport.authenticate('facebook', { successRedirect: '/' }));
  
  
  onAppConfig: (expressApp) =>
    return new Promise (resolve, reject) =>
      expressApp.use passport.initialize()
      expressApp.use passport.session()
      return resolve();
      
  onSiteRequestStart: (req, res) =>
    return new Promise (resolve, reject) =>
      path = req._parsedUrl.pathname
      if path.match('^/auth')
        return @processAuth(req, res).then resolve, reject;
      else if path.match('^/logout$')
        return @logout(req, res);
      resolve();

  onStrategyComplete: (accessToken, refreshToken, profile, done) =>
    # create user
    #done(err, user);
    console.log "onStrategyComplete"
    
    #return this.pass(profile);
    return done(null, profile);
  
  processAuth: (req, res) =>
    return new Promise (resolve, reject) =>
      @log "processAuth"
      path = req._parsedUrl.pathname
      sec = {}
      if path.match('^/auth/google')
        sec = @proxies["google"]
      if path.match('^/auth/github')
        sec = @proxies["github"]
      if path.match('^/auth/facebook')
        sec = @proxies["facebook"]
      
      sec(req, res).then () =>
        @log "processAuth Return", req.isAuthenticated();
        @redirect(req,res);
      .catch (err) =>
        @log "processAuth Error", arguments;
        res.send err
  
  redirect: (req, res) =>
    @log "redirectUser"
    res.redirect "http://clive.illisian.com.au/";
  

      
  logout: (req, res) =>
    return new Promise (resolve, reject) =>
      req.logout();
      res.redirect "http://clive.illisian.com.au/";
      #resolve();
  
  redirectToGoogle: (req, res) =>
    return new Promise (resolve, reject) =>
      res.redirect('/login/google');
      resolve();
    
  
  checkAuthentication: (req, res) =>
    return new Promise (resolve, reject) =>
      return Promise.promisify(passport.authenticate('google', (err, user, info) =>
        if err 
          throw err
        if user?
          return req.logIn(user, (err) =>
            if err 
              throw err
            return resolve(user);
          )
        return resolve(user);
      ));

module.exports = Security;