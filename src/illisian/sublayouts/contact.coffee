Promise = require("bluebird");
Control = require("../../lib/templateControl");

class Contact extends Control
  controls: [ "#txtEmailAddress" ]
  view: { file: 'contact.ejs', renderer: 'ejs' }

module.exports = Contact;