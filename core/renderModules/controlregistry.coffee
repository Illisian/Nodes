Promise = require "bluebird";

class ControlRegistry
  constructor: (@renderer) ->
    
#  onStart: () =>
#    return new Promise (resolve, reject) =>
#      resolve();

#  onControlProcessed: (control) =>
#    return new Promise (resolve, reject) =>
#      resolve();
      
  onPageFinish: (next) =>
    next();

module.exports = ControlRegistry;