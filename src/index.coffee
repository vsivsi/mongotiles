###
#
# Copyright (C) 2013-2014 by Vaughn Iverson
#
# mongotiles
#
# With this you can use MongoDB GridFS as a "tilelive.js" source or sink for
# map tile / grid / tilejson data.
#
# See: https://github.com/mapbox/tilelive.js
#
# This project is free software released under the MIT/X11 license.
# See LICENSE file for more information.
#
###

path = require 'path'
fs = require 'fs'
url = require 'url'
querystring = require 'querystring'
mongodb = require 'mongodb'

LockCollection = require('gridfs-locks').LockCollection
Lock = require('gridfs-locks').Lock

protocol = 'mongotiles'

default_root = 'fs'

tile_name = (z, x, y) ->
    if x? and y? and z?
        name = "tile_#{z}_#{x}_#{y}"
    else
        name = 'tile_{z}_{x}_{y}'

grid_name = (z, x, y) ->
    if x? and y? and z?
        name = "grid_#{z}_#{x}_#{y}"
    else
        name = 'grid_{z}_{x}_{y}'

tilejson_name = "tilejson.json"

# Image type magic numbers snarfed from https://github.com/mapbox/node-tilejson
get_mime_type = (bytes) ->
    if (bytes[0] is 0x89 and bytes[1] is 0x50 and bytes[2] is 0x4E and
        bytes[3] is 0x47 and bytes[4] is 0x0D and bytes[5] is 0x0A and
        bytes[6] is 0x1A and bytes[7] is 0x0A)
            return 'image/png'
    else if (bytes[0] is 0xFF and bytes[1] is 0xD8 and
        bytes[bytes.length - 2] is 0xFF and bytes[bytes.length - 1] is 0xD9)
            return 'image/jpeg'
    else if (bytes[0] is 0x47 and bytes[1] is 0x49 and bytes[2] is 0x46 and
        bytes[3] is 0x38 and (bytes[4] is 0x39 or bytes[4] is 0x37) and
        bytes[5] is 0x61)
            return 'image/gif'
    else
        console.warn "#{protocol}: Image data with unknown MIME type in putTile call to get_mime_type."
        return 'application/octet-stream'

class Tilemongo

    _file_exists : (fn, cb) ->
        @files.findOne {filename: fn}, {_id: 1}, (err, doc) =>
            return cb err, doc

    _write_buffer : (fn, type, buffer, metadata, cb) ->

        write_it = (_id, l) =>
            gs = new mongodb.GridStore @db, _id, fn, 'w', { w : 1, root : @grid_root, content_type : type, metadata: metadata }
            gs.open (err, gs) =>
                return cb err if err
                gs.write buffer, (err, gs) =>
                    return cb err if err
                    gs.close (err) =>
                        l.releaseLock() if l
                        cb err

        @_file_exists fn, (err, doc) =>
            return cb err if err
            unless doc
                doc = { _id: new mongodb.ObjectID() }
            if @lockColl
                lock = Lock(doc._id, @lockColl, {}).obtainWriteLock()
                lock.on 'timed-out', () =>
                    cb new Error "Timed out waiting for write lock"
                lock.on 'error', (err) =>
                    cb err
                lock.on 'locked', (ld) =>
                    write_it doc._id, lock
            else
                write_it doc._id

    _read_buffer : (fn, cb) ->

        read_it = (_id, l) =>
            gs = new mongodb.GridStore @db, _id, 'r', { root : @grid_root }
            gs.open (err, gs) =>
                return cb err if err
                gs.read (err, buffer) =>
                    return cb err if err
                    gs.close (err) =>
                        l.releaseLock() if l
                        cb err, buffer

        @_file_exists fn, (err, doc) =>
            return cb err if err
            unless doc
                return cb null, null
            if @lockColl
                lock = Lock(doc._id, @lockColl, {}).obtainReadLock()
                lock.on 'timed-out', () =>
                    cb new Error "Timed out waiting for write lock"
                lock.on 'error', (err) =>
                    cb err
                lock.on 'locked', (ld) =>
                    read_it doc._id, lock
            else
                read_it doc._id

    @registerProtocols = (tilelive) ->
        tilelive.protocols["#{protocol}:"] = @

    @list = (filepath, callback) ->
        callback new Error ".list not implemented for #{protocol}"

    @findID = (filepath, id, callback) ->
        callback new Error ".findID not implemented for #{protocol}"

    constructor : (uri, callback) ->
        @starts = 0
        # uri seems to be preparsed, but make sure...
        if typeof uri is 'string'
            uri = url.parse uri, true
        if typeof uri.query is 'string'
            uri.query = querystring.parse uri.query
        unless uri.protocol is "#{protocol}:"
            return callback new Error "Bad uri protocol '#{uri.protocol}'.  Must be #{protocol}."
        tilepath_match = uri.pathname.match new RegExp "(/[^/]+/)([^/]+/)?"
        unless tilepath_match
            return callback new Error "Bad tile url path '#{uri.pathname}' for #{uri.protocol}."
        locking = uri.query?.locking ? false
        uri.query = ''
        uri.search = ''
        uri.hash = ''
        uri.protocol = 'http:'
        @source = url.format uri
        @db_name = tilepath_match[1][1...-1]
        @grid_root = tilepath_match[2]?[0...-1] or default_root
        uri.path = tilepath_match[1]
        uri.pathname = uri.path
        uri.protocol = 'mongodb:'
        @server = url.format(uri)[0...-1]
        mongodb.MongoClient.connect @server, (err, db) =>
            return callback err if err
            @db = db
            @db.collection "#{@grid_root}.files", { w: 1 }, (err, coll) =>
                return callback err if err
                @files = coll
                unless locking
                    return callback null, @
                else
                    @lockColl = LockCollection(@db,
                        root: @grid_root
                        timeOut: 60,
                        pollingInterval: 5,
                        lockExpiration: 30)

                    @lockColl.on 'ready', () =>
                        callback null, @

                    @lockColl.on 'error', (err) ->
                        callback err

    close : (callback) ->
        @db.close(callback)

    getInfo : (callback) ->
        @_read_buffer tilejson_name, (err, info) =>
            return callback err if err
            callback null, JSON.parse(info)

    getTile : (z, x, y, callback) ->
        tn = tile_name z, x, y
        @_read_buffer tn, (err, data) =>
            if err
                callback err
            else unless data
                callback new Error('Tile does not exist')
            else
                callback null, data

    getGrid : (z, x, y, callback) ->
        gn = grid_name z, x, y
        @_read_buffer gn, (err, data) =>
            if err
                callback err
            else unless data
                callback new Error('Grid does not exist')
            else
                callback null, JSON.parse(data)

    startWriting : (callback) ->
        @starts += 1
        callback null

    stopWriting : (callback) ->
        @starts -= 1
        callback null

    putInfo : (info, callback) ->
        unless @starts
            return callback new Error "Error, writing not started."
        tn = tile_name()
        info.tiles = [ "#{@source}#{tn}" ]
        if info.grids?
            gn = grid_name()
            info.grids = [ "#{@source}#{gn}" ]
        @_write_buffer tilejson_name, 'application/json', JSON.stringify(info), null, callback

    putTile : (z, x, y, tile, callback) ->
        unless @starts
            return callback new Error "Error, writing not started."
        tn = tile_name z, x, y
        type = get_mime_type tile
        @_write_buffer tn, type, tile, { type: "tile", x:x, y:y, z:z }, callback

    putGrid : (z, x, y, grid, callback) ->
        unless @starts
            return callback new Error "Error, writing not started."
        gn = grid_name z, x, y
        @_write_buffer gn, 'application/json', JSON.stringify(grid), { type: "grid", x:x, y:y, z:z }, callback

module.exports = Tilemongo
