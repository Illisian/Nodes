class navbar
  view: { file: 'navbar.jade', renderer: 'jade' }
  constructor: () ->
    
  onData: (next) => # provide fields
    next();
  onHtml: (next) => #provide html
    next()


module.exports = navbar;