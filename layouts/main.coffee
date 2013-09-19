class Main
  view: { file: 'main.jade', renderer: 'jade' }
  constructor: () ->
    #@view = 'main.jade'
  onData: (next) => # provide fields
    console.log "ondata"
    #@context.page.fields.title = "O HAI!";
    next();
  
  onHtml: (next) => #provide html
    console.log "onhtml"
    next();


module.exports = Main;