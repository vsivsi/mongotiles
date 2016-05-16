mongotiles
==============================

mongotiles is a [tilelive.js](https://github.com/mapbox/tilelive.js) backend (source/sink) plug-in for MongoDB [GridFS](http://docs.mongodb.org/manual/core/gridfs/)

Q: What the heck does that mean?

A: With this installed, you can use MongoDB's built-in GridFS file store to read/write map image tiles from/to other tilelive.js sources/sinks (mbtiles, Mapnik, TileJSON, S3, etc.)

Q: Come again?

A: You can use MongoDB to serve maps (via an HTTP front-end to GridFS)

Q: Why would one want to do that?

A: Everybody loves MongoDB, [Right](https://duckduckgo.com/?q=why+I+love+mongodb)?  Also, [Meteor](https://www.meteor.com/).

Q: Where do the maps come from?

A: That's a really big question. Many days of poking around may be required to fully grok what you are asking here.

Places to start:

+ [OpenStreetMap](http://www.openstreetmap.org)
+ [TileMill](https://www.mapbox.com/tilemill/)

**Note:** A similar project that stores tile data as blobs directly within MongoDB documents (as opposed to using gridFS files) also exists: [tilelive-foxgis](https://github.com/FoxGIS/tilelive-foxgis)

#### Installation

You need [node.js](http://nodejs.org/).  Then:

     npm install mongotiles

And you can test it (assuming mongodb is running on localhost:27017) by:

	cd node_modules/mongotiles
    npm install
    npm test

Nice!  Now what?

#### Usage

Obviously, this works with (and depends upon) tilelive.js and MongoDB.

For example: Let's say you already have map tiles rendered with TileMill sitting in a `.mbtiles` file, and using something like [TileStream](https://github.com/mapbox/tilestream) to serve tiles alongside an application server isn't doing it for you. And you also happen to have an up-to-date MongoDB server running locally.

You should be able to easily copy all of your data from the `.mbtiles` file to your local MongoDB instance by setting up these other things:

     npm install tilelive
     npm install mbtiles

And then:

     ./node_modules/tilelive/bin/tilelive-copy -s pyramid --minzoom=10 --maxzoom=18  \
          "mbtiles:///Users/user/maps/Columbus.mbtiles" \
          "mongotiles://127.0.0.1:27017/columbus_tiles/"

The `copy` command above is a sample application provided by tilelive.js, and it has a bunch more options that you should check out. Tilelive is actually an API that any other app can use, so mongotiles should enable MongoDB to play nicely with apps and other data sources/sinks that also support tilelive. The source and sink URIs have custom protocols (`mbtiles:` and `mongotiles:`) that tilelive knows what to do with via the backend plugins you've now installed.

Serving your tiles out of MongoDB over HTTP requires one more piece: [an HTTP server that can use GridFS as its filestore](https://github.com/search?q=gridFS+HTTP) (there are many options).  In this example, mongotiles will use the default `fs` GridFS bucket in the `columbus_tiles` database, so you'll need to configure your HTTP server to look there for GridFS files.

Note: if you wish to use a GridFS "bucket" other than the default (`fs`), then simply append that bucket name to the end of the `mongotiles:` URI you use with tilelive, for example:

     mongotiles://127.0.0.1:27017/columbus_tiles/my_bucket/

Once that's up-and-running, point a [Leaflet](http://leafletjs.com/) enabled web page to e.g. `http://127.0.0.1/columbus_tiles/tile_{z}_{x}_{y}` and you'll be serving up map tiles from MongoDB (the URL path before `tile_{z}_{x}_{y}` will depend on how you configure the HTTP server).

For what it's worth, this also lets you serve up the [TileJSON](https://github.com/mapbox/tilejson-spec) information for your maps, just use, e.g. `http://127.0.0.1/columbus_tiles/tilejson.json`

New in v0.1.0: You can enable gridFS locking (for a small performance penalty). This makes it safe to live update a running server that is sharing and using an existing gridFS store. This assumes that the server is also using `gridfs-locks` for safe concurrency. Enable it by adding the `locking=true` query to the end of the `mongotiles` URI:

     mongotiles://127.0.0.1:27017/columbus_tiles/my_bucket/?locking=true

Also new in v0.1.0, the `x`, `y`, `z` coordinates, and the data type `[tile|grid]` are written to the gridFS file document metadata object, so you can easily build your own URL format in http and do metadata based lookups to fulfill requests. If you use this, you'll probably want to ensure that your mongoDB has a compound index on the metadata you'll be using.
