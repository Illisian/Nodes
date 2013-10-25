Promise = require 'bluebird'
Promises = require './Promises'
util = require 'util'

#this is a test func for the Promises class

class Parent
  constructor: () ->
    @events = {
      onControlLoad: new Promises();
      onControlEnd: new Promises();
      };
  firePromises: (text, text2, text3) =>
    @events.onControlLoad.chain(text, text2, text3).then () =>
      @message("onControlLoadFinished").then () =>
        @events.onControlEnd.chain(text).then () =>
          console.log "finished";
  
  addPromises: (start) =>
    child = new Child(start);
    @events.onControlLoad.add child.onLoad, child;
    @events.onControlLoad.add child.onLoad, child;
    @events.onControlLoad.add child.onLoad, child, ["33333333333333333", "2222222222222", "1111111111"]
    @events.onControlLoad.add child.onLoad, child;
    @events.onControlEnd.add child.onFinish, child, ["ALASLDLA", "ASDASD", "ASDASDQWER"];
    @events.onControlEnd.add child.onFinish, child;
    @events.onControlEnd.add child.onFinish, child;
    @events.onControlEnd.add child.onFinish, child;
    

  message: (text) =>
    return new Promise (resolve, reject) =>
      console.log "#{text}"
      resolve();

class Child
  constructor: (@targets) ->
    
  onFinish: (text, text2, text3) =>
    return new Promise (resolve, reject) =>
      @targets++;
      console.log "onFinish - #{text}- #{text2}- #{text3} - #{@targets}"
      resolve();
  onLoad: (text, text2, text3) =>
    return new Promise (resolve, reject) =>
      @targets++;
      console.log "onLoad - #{text}- #{text2}- #{text3} - #{@targets}"
      resolve();



p = new Parent();
p.addPromises(1);
p.addPromises(100);
p.addPromises(1001);
p.firePromises("test", "ASd", "Asda");