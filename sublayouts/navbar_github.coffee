
util = require 'util'
class navbar_github
  view: { file: 'navbar_github.jade', renderer: 'jade' }
  fields: {}
  constructor: () ->
    @fields = {}
  onData: (next) => # provide fields
    @fields.github = [ { title: "Github", url: "https://github.com/organizations/Illisian" } ]
    next();
  onHtml: (next) => #provide html
    next()

module.exports = navbar_github;