Promise = require "bluebird";
util = require "util"
class Fields
  constructor: (@renderer) ->
    
#  onStart: () =>
#    return new Promise (resolve, reject) =>
#      resolve();

#  onControlProcessed: (control) =>
#    return new Promise (resolve, reject) =>
#      resolve();
      
  onPageFinish: (next) =>
    if @renderer.fields?
      arr = @renderer.$('[nodes-field]');
      for i in arr
        fieldName = @renderer.$(i).attr("nodes-field")
        if fieldName of @renderer.fields
          fieldContents = @renderer.fields[fieldName]
          @renderer.$(i).prepend(fieldContents)
    @renderer.$('[nodes-field]').removeAttr("nodes-field")
    @renderer.log "Fields onFinish resolved";
    next();

module.exports = Fields;