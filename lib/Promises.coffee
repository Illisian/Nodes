Promise = require 'bluebird'

#Promise.longStackTraces();

class Promises
  constructor: (@promises = []) ->
    @length = @promises.length;
  all: () =>
    return new Promise (resolve, reject) =>
      arrs = []
      for i in @promises
        args = i.args || arguments
        arrs.push i.promise.apply(i.context, args);
      Promise.all(arrs).then () =>
        resolve();
  chain: () =>
    return Promises.chainUtil(0, @promises, arguments);
  add: (promise, context, args) =>
    @promises.push { promise: promise, context: context, args: args };
    @length = @promises.length;
  push: (promise, context, args) =>
    this.add promise, context, args;
    
  @chainUtil: (i, array, originalArgs, collect) ->
    return new Promise (resolve, reject) =>
      if not array?
        throw "Promises - chainUtil - array is not defined";
      if not collect?
        collect = [];
      if array[i]?
        if array[i].args?
          args = array[i].args;
        else 
          args = originalArgs;
        return array[i].promise.apply(array[i].context, args).then () =>
          collect.push arguments
          return @chainUtil(i+1, array, originalArgs, collect).then(resolve, reject);
      else
        return resolve(collect);
  
module.exports = Promises;
