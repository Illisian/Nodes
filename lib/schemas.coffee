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
  modules: []
  root: { type: Schema.Types.ObjectId }
  fields: { type: Schema.Types.Mixed }
  paths: {
    base: { type: String, required: true }
    layout: { type: String, required: true }
    sublayout: { type: String, required: true }
    content: { type: String, required: true }
    module: { type: String, required: true }
  }
}


Page = new Schema {
  site: { type: Schema.Types.ObjectId, index: true }
  parent: { type: Schema.Types.ObjectId, index: true }
  name: { type: String, required: true, index: true }
  index: { type: Number }
  path: { type: String, required: true, index: true }
  layout: { 
      id: { type: Schema.Types.ObjectId }
      attributes: { type: Schema.Types.Mixed }
  }
  hasChildren:  { type: Boolean }
  isRoot: { type: Boolean }
  sublayouts: [{
    placeholder: { type: String }
    id: { type: Schema.Types.ObjectId }
    attributes: { type: Schema.Types.Mixed }
    index: { type: Number }
  }]
  fields: { type: Schema.Types.Mixed }
}

module.exports = {
  Layout: Layout
  Sublayout: Sublayout
  Site: Site
  Page: Page
}