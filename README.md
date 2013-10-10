Nodes
=========

Nodes is a content management system coded in [coffee-script] for [node.js]. It uses [mongodb] for the backend

Features
----
  - Control typed components i.e. basic js/view implementation
  - Inline Tags to embedded controls

Tech
----
  - [express.js] - Http Engine
  - [bluebird] - Promises
  - [consolidate] - View Engine
  - [mongoose] - ORM
  - [mongodb] - Database

Future
----
  - Admin Console
  - Modulerised components
  - etc

Installation
---

This takes the assumption that you already are running a mongodb instance.

```sh
git clone https://github.com/Illisian/Nodes.git nodes
cd nodes
npm install

edit config.coffee & illisian/datasetup.coffee: site.hosts to match your settings

coffee app.coffee

```

  [consolidate]: https://github.com/visionmedia/consolidate.js
  [express.js]: http://expressjs.com/
  [coffee-script]: http://coffeescript.org/
  [node.js]: nodejs.org
  [bluebird]: https://github.com/petkaantonov/bluebird
  [mongoose]: http://mongoosejs.com/
  [mongodb]: http://www.mongodb.org/
    