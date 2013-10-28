Promise = require "bluebird";
Module = require "../lib/module";
class Fields extends Module

  onPageRequestFinish: (res, req, page) =>
    return new Promise (resolve, reject) =>
      @log "fields module started", page.fields?;
      if page.fields?
        @log "fields exist", page.fields?, page.$?;
        arr = page.$('[nodes-field]');
        @log "looking for fields", arr.length;
        for i in arr
          fieldName = page.$(i).attr("nodes-field")
          if fieldName of page.fields
            fieldContents = page.fields[fieldName]
            @log "Setting Field #{fieldName} - #{fieldContents}";
            page.$(i).prepend(fieldContents)
      page.$('[nodes-field]').removeAttr("nodes-field")
      @log "Fields onFinish resolved";
      resolve();

module.exports = Fields;