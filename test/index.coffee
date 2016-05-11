# Unit tests

assert = require 'assert'
mongo = require 'mongodb'
tilelive = require 'tilelive'
mbtiles = require('mbtiles').registerProtocols(tilelive)
mongotiles = require('../lib/index.js').registerProtocols(tilelive)

describe 'Copy test', () ->
  source = sink = null
  db = null
  collection = null

  before (done) ->
    server = new mongo.Server '127.0.0.1', 27017
    db = new mongo.Db 'mongotiles_test', server, {w:0}
    db.open () ->
      db.collection "testcoll.files", { w: 0 }, (err, coll) =>
        collection = coll
        done(err)

  it 'should open the mbtiles source', (done) ->
    tilelive.load 'mbtiles://' + __dirname + '/test_tiles.mbtiles', (err, s) ->
      source = s
      done err

  it 'should open the mongotiles sink', (done) ->
    tilelive.load 'mongotiles://127.0.0.1:27017/mongotiles_test/testcoll', (err, s) ->
      sink = s
      done err

  it 'should copy', (done) ->
    this.timeout 15000

    readStream = tilelive.createReadStream source,
      type: 'scanline'
      bbox: [ -180, -84, 180, 84 ]
      minzoom: 0
      maxzoom: 4

    readStream.on 'error', (e) -> throw e
    writeStream = tilelive.createWriteStream sink
    writeStream.on 'error', (e) -> throw e
    writeStream.on 'stop', done
    readStream.pipe(writeStream)

  it "should contain 342 files", (done) ->
    collection.count (err, c) ->
      assert.equal c, 342
      done err

  after (done) ->
    db.dropDatabase () ->
      db.close true, done
