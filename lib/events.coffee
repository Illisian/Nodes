Promise = require 'bluebird'
Promises = require './Promises'


class Events
  
  create: (event) =>
    @[event] = new Promises();
  get: (event) =>
    return @[event];
    
  constructor: () ->
    @eventList = {}
    
