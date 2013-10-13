Promise = require "bluebird";

class ControlRegistry
  constructor: (@renderer) ->
    
#  onStart: () =>
#    return new Promise (resolve, reject) =>
#      resolve();

#  onControlProcessed: (control) =>
#    return new Promise (resolve, reject) =>
#      resolve();
      
  onFinish: () =>
    return new Promise (resolve, reject) =>
      resolve();

module.exports = ControlRegistry;