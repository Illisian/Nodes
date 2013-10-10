class panel
  view: { file: 'panel.ejs', renderer: 'ejs' }
  constructor: () ->
    
  onData: (next) => # provide fields
    next();

  onHtml: (next) => #provide html
    next();

module.exports = panel;