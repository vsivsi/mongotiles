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
# License:
#
# This project is free software released under the MIT/X11 license:
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
###

path = require 'path'
fs = require 'fs'
url = require 'url'
tilelive = require 'tilelive'
mongodb = require 'mongodb'

LockCollection = require('grid-locks').LockCollection
Lock = require('grid-locks').Lock

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

    _write_buffer : (fn, type, buffer, metadata, cb) ->
        gs = new mongodb.GridStore @db, fn, 'w', { root : @grid_root, content_type : type, metadata: metadata }
        gs.open (err, gs) =>
            return cb err if err
            gs.write buffer, (err, gs) =>
                return cb err if err
                gs.close cb

    _read_buffer : (fn, cb) ->
        mongodb.GridStore.exist @db, fn, @grid_root, {}, (err, exists) =>
            return cb err if err
            unless exists
                return cb null, null
            gs = new mongodb.GridStore @db, fn, 'r', { root : @grid_root }
            gs.open (err, gs) =>
                return cb err if err
                gs.read (err, buffer) =>
                    return cb err if err
                    gs.close (err) =>
                        cb err, buffer

    @registerProtocols = (tilelive) ->
        tilelive.protocols["#{protocol}:"] = @
        # tilelive.protocols["locking#{protocol}:"] = @

    @list = (filepath, callback) ->
        callback new Error ".list not implemented for #{protocol}"

    @findID = (filepath, id, callback) ->
        callback new Error ".findID not implemented for #{protocol}"

    constructor : (uri, callback) ->
        @starts = 0
        tile_url = url.parse uri
        unless tile_url.protocol is "#{protocol}:" or tile_url.protocol is "locking#{protocol}:"
            return callback new Error "Bad uri protocol '#{tile_url.protocol}'.  Must be #{protocol} or locking#{protocol}."
        tilepath_match = tile_url.pathname.match new RegExp "(/[^/]+/)([^/]+/)?"
        unless tilepath_match
            return callback new Error "Bad tile url path '#{tile_url.pathname}' for #{tile_url.protocol}."
        tile_url.query = ''
        tile_url.search = ''
        tile_url.hash = ''
        tile_url.protocol = 'http:'
        @source = url.format tile_url
        @db_name = tilepath_match[1][1...-1]
        @grid_root = tilepath_match[2]?[0...-1] or default_root
        tile_url.path = tilepath_match[1]
        tile_url.pathname = tile_url.path
        tile_url.protocol = 'mongodb:'
        @server = url.format tile_url
        mongodb.MongoClient.connect @server, (err, db) =>
            return callback err if err
            @db = db
            # @lockColl = LockCollection(@db,
            #     root: @grid_root
            #     timeOut: 60,
            #     pollingInterval: 5,
            #     lockExpiration: 30)

            # @lockColl.on 'ready', () ->
            #     callback null, @

            # @lockColl.on 'error', (err) ->
            #     callback err
            callback null, @

    close : (callback) ->
        @db.close()
        callback null

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

