class Module
  constructor: (options) ->
    #console.log "base", util.inspect options
    { @core, @site } = options;
    { @log, @db } = @core;
module.exports = Module;