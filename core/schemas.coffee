mongoose = require 'mongoose';
Schema = mongoose.Schema

Layout = new Schema {
  name: { type: String, required: true }
}
Sublayout = new Schema {
  name: { type: String, required: true }
}
Site = new Schema {
  name: { type: String, required: true }
  host: { type: String, required: true, index: true }
  root: { type: Schema.Types.ObjectId }
}

Page = new Schema {
  site: { type: Schema.Types.ObjectId, index: true }
  name: { type: String, required: true, index: true }
  path: { type: String, required: true, index: true }
  layout: { type: Schema.Types.ObjectId }
  sublayouts: [{
    placeholder: { type: String }
    id: { type: Schema.Types.ObjectId }
  }]
  fields: { type: Schema.Types.Mixed }
}

module.exports = {
  Layout: Layout
  Sublayout: Sublayout
  Site: Site
  Page: Page
}