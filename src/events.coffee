Promise = require 'bluebird'
Promises = require './Promises'
events = require './events';


class Events
  
  constructor: () ->
    @log = console.log
    #@reference = [];
    @objects = [];
    @events = {};
    # for i in [1...arguments.length]
    #   @reference.push arguments[i];
    
  length: (eventName) =>
    if @events[eventName]?
      return @events[eventName].length;
    return 0;
  print: () =>
    for i of @events
      @log i, @events[i].length
  add: (object) =>
    for event of @events
      if object[event]?
        @events[event].add object[event], object
  
  addPromise: (eventName, promise, object) =>
    if @events[eventName]?
      @events[eventName].add promise, object
    
  register: (name) =>
    @events[name] = new Promises();
    
  refresh: (eventName) =>
    return new Promise (resolve, reject) =>
      if @events[eventName]?
        @events[eventName].clear();
        for o in @objects
          if o[eventName]?
            @events[eventName].add o[eventName], o
        resolve();
      else
        reject();
  
  get: (eventName) =>
    return @events[eventName];

  chain: (eventName) =>
    args = [];
    if arguments.length > 1
      args.push arguments[i] for i in [1...arguments.length]
    return new Promise (resolve, reject) =>
      if @events[eventName]?
        return @events[eventName].chain.apply(@events[eventName], args).then () =>
          return resolve()
        , reject
      return resolve();
    
    
module.exports = Events
    
