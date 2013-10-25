Promise = require "bluebird";

Module = require "../../lib/module";

util = require "util"
GoogleStrategy = require('passport-google-oauth').OAuth2Strategy;
passport = require "passport"


class Security extends Module
  constructor: (@options) ->
    super; # call this to make sure everything is set;
    @log "Illisian - Security Module - Constructor"
    
    @scope = 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email';
    
    @strategyOptions = {
      callbackURL: "http://clive.illisian.com.au/login/google/return"
      clientID: "644463448066.apps.googleusercontent.com"
      clientSecret: "dBc-sxheVrrxoWUNgWTGzafg"
    }
    passport.use new GoogleStrategy(@strategyOptions, @onStrategyComplete);
    @confirmRequest = passport.authenticate('google', { successRedirect: '/', failureRedirect: '/' });
    @authrequest = passport.authenticate('google',  { scope: @scope });
  onStrategyComplete: (accessToken, refreshToken, profile, done) =>
    # create user
    #done(err, user);
    @log "STRATEGY 2", @args
    #@options.req.session.userprofile = profile;
    @log "STRATEGY", accessToken, refreshToken, profile
    
    done(null, profile);
  
  processGoogleAuthReturn: (req, res) =>
    return new Promise (resolve, reject) =>
      @log "processGoogleAuthReturn"
      test = (opts) =>
        @log "processGoogleAuthReturn", arguments
        if opts.name == "InternalOAuthError"
          @log "Send result2", opts
          res.send(util.inspect(opts))
      @confirmRequest(req, res, test);
  
  processGoogleAuthRequest: (req, res) =>
    return new Promise (resolve, reject) =>
      @log "processGoogleAuthRequest"
      test = (opts) =>
        if opts.name == "InternalOAuthError"
          @log "Send result1", opts
          @res.send(util.inspect(opts))
      @authrequest(req, res, test);
  
  
  onSiteStart: (req, res) =>
    return new Promise (resolve, reject) =>
      @log "Illisian - Security Module - onSiteBeforePage", arguments
      path = req._parsedUrl.pathname
      if path.match('^/login/google/return')
        return @processGoogleAuthReturn(req, res).then resolve, reject;
      else if path.match('^/login/google$')
        return @processGoogleAuthReturn(res, res).then resolve, reject;
      resolve();

      
  onPageFinish: () =>
    return new Promise (resolve, reject) =>
      @log "SECURITY DOES NOT KILL";
      resolve();

module.exports = Security;