datasetup = require "./datasetup";

class App
  constructor: (@main) ->
    
  init: () =>
    setup = new datasetup(@main);
    return setup.init();
    

module.exports = App