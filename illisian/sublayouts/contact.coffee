Promise = require("bluebird");
Control = require("../../core/abstract/control");

class Contact extends Control
  controls: [ "#txtEmailAddress" ]
  view: { file: 'contact.ejs', renderer: 'ejs' }

module.exports = Contact;