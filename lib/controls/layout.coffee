Promise = require("bluebird");
TemplateControl = require("../templateControl");

class Layout extends TemplateControl
  constructor: () ->
    super;
    @isLayout = true;


module.exports = Layout;