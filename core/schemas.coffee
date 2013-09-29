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
  hosts: []
  root: { type: Schema.Types.ObjectId }
  fields: { type: Schema.Types.Mixed }
  paths: {
    base: { type: String, required: true }
    layout: { type: String, required: true }
    sublayout: { type: String, required: true }
    content: { type: String, required: true }
  }
}


Page = new Schema {
  site: { type: Schema.Types.ObjectId, index: true }
  name: { type: String, required: true, index: true }
  index: { type: Number }
  path: { type: String, required: true, index: true }
  layout: { type: Schema.Types.ObjectId }
  hasChildren:  { type: Boolean }
  isRoot: { type: Boolean }
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