class contact
  controls: [ "#txtEmailAddress" ]
  view: { file: 'contact.ejs', renderer: 'ejs' }
  constructor: () ->
    
  onData: (next) => # provide fields
    next();
  onHtml: (next) => #provide html
    next();


module.exports = contact;