class content
  view: { file: 'content.ejs', renderer: 'ejs' }
  constructor: () ->
    
  onData: (next) => # provide fields
    next();
  onHtml: (next) => #provide html
    next();


module.exports = content;