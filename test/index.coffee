# Unit tests

assert = require 'assert'
mongo = require 'mongodb'
tilelive = require 'tilelive'

describe 'Test test', () ->
  before (done) ->
    done()

  it "should run a test", () ->
    assert true

  after (done) ->
    done()

# describe 'gridfs-locks', () ->

#   db = null

#   before (done) ->
#     server = new mongo.Server 'localhost', 27017
#     db = new mongo.Db 'gridfs_locks_test', server, {w:0}
#     db.open () ->
#       done()

#   describe 'LockCollection', () ->

#     lockColl = null

#     before (done) ->
#       lockColl = LockCollection db
#       lockColl.on 'ready', done

#     it "should be a function", () ->
#       assert 'function' is typeof LockCollection

#     it "should create instances without the new keyword", () ->
#       assert lockColl instanceof LockCollection

#     it "should require a valid mongo db connection object", (done) ->
#       LockCollection(null).on 'error', (e) ->
#         assert.throws (() -> throw e), /parameter must be a valid Mongodb connection object/
#         done()

#     it "should require options to be an object", (done) ->
#       LockCollection(db, 1).on 'error', (e) ->
#         assert.throws (() -> throw e), /parameter must be an object/
#         done()

#     it "should require a non-falsy root to be a string", (done) ->
#       LockCollection(db, {root: 1}).on 'error', (e) ->
#         assert.throws (() -> throw e), /must be a string or falsy/
#         done()

#     it "should create a valid mongodb collection", () ->
#       assert lockColl.collection?
#       assert.equal typeof lockColl.collection.find, 'function'

#     it "should properly index the .locks collection", (done) ->
#       lockColl.collection.indexExists "files_id_1", (e, ii) ->
#         assert.ifError e
#         assert.equal ii, true
#         done()

#     it "should use the default GridFS collection root when no root is given", () ->
#       assert.equal lockColl.collection.collectionName, mongo.GridStore.DEFAULT_ROOT_COLLECTION + ".locks"

#     it "should have ten keys", () ->
#       assert.equal Object.keys(lockColl).length, 10

#     it "should properly record all options", (done) ->
#       lc = LockCollection db, { root: "test", w: 16, timeOut: 16, pollingInterval: 16, lockExpiration: 16, metaData: 16 }
#       lc.on 'ready', () ->
#         assert.equal lc.collection.collectionName, "test.locks"
#         assert.equal lc.writeConcern, 16
#         assert.equal lc.timeOut, 16
#         assert.equal lc.pollingInterval, 16
#         assert.equal lc.lockExpiration, 16
#         assert.equal lc.metaData, 16
#         done()

#   describe 'Lock', () ->

#     lockColl = null
#     lock = null
#     fileId = null

#     before (done) ->
#       fileId = new mongo.BSONPure.ObjectID
#       lockColl = LockCollection db
#       lockColl.on 'ready', () ->
#         lock = Lock fileId, lockColl, {}
#         done()

#     it "should be a function", () ->
#       assert 'function' is typeof Lock

#     it "should create instances without the new keyword", () ->
#       assert lock instanceof Lock

#     it "should require options to be an object", (done) ->
#       Lock(1, lockColl, 1).on 'error', (e) ->
#         assert.throws (() -> throw e), /parameter must be an object/
#         done()

#     it "should require lockCollection to be a valid lockCollection object", (done) ->
#       Lock(1, 1).on 'error', (e) ->
#         assert.throws (() -> throw e), /invalid 'lockCollection' object/
#         done()

#     it "should require lockCollection to be ready", (done) ->
#       Lock(1, LockCollection db).on 'error', (e) ->
#         assert.throws (() -> throw e), /'lockCollection' must be 'ready'/
#         done()

#     it "should have 14 keys", () ->
#       assert.equal Object.keys(lock).length, 14

#     it "should create a valid timeCreated Date", () ->
#       assert lock.timeCreated instanceof Date

#     it "should initialize state keys to null", () ->
#       assert lock.lockType is null
#       assert lock.query is null
#       assert lock.update is null
#       assert lock.heldLock is null

#     it "should properly record all options", () ->
#       l = new Lock fileId, lockColl, { timeOut: 16, pollingInterval: 16, lockExpiration: 32, metaData: 16 }
#       assert.equal l.timeOut, 16000
#       assert.equal l.pollingInterval, 16000
#       assert.equal l.lockExpiration, 32000
#       assert.equal l.metaData, 16
#       assert.equal l.lockCollection, lockColl
#       assert.equal l.collection, lockColl.collection
#       assert.equal l.fileId, fileId

#     describe 'obtainReadLock', () ->

#       lock1 = null
#       lock2 = null
#       id = null

#       before () ->
#         id = new mongo.BSONPure.ObjectID
#         lock1 = Lock id, lockColl, {}
#         lock2 = Lock id, lockColl, {}

#       afterEach () ->
#         lock1.removeAllListeners()
#         lock2.removeAllListeners()

#       it "should return a valid lock document", (done) ->
#         lock1.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           assert id.equals ld.files_id
#           assert ld.expires instanceof Date
#           assert ld.expires > lock1.timeCreated
#           assert.equal ld.read_locks, 1
#           assert.equal ld.write_lock, false
#           assert.equal ld.write_req, false
#           assert.equal ld.reads, 1
#           assert.equal ld.writes, 0
#           assert.equal ld.meta, null
#           assert.equal lock1.heldLock, ld
#           done()

#       it "should properly set the lock state on a held read lock", () ->
#         assert.equal lock1.lockType, 'r'
#         assert lock1.query?
#         assert lock1.update?

#       it "should fail to return a second lock document for a lock object that already holds a lock", (done) ->
#         lock1.obtainReadLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /cannot obtain an already held lock/
#           done()
#         lock1.on 'locked', (ld) ->
#           console.log "Here!", ld
#           assert false

#       it "should return a valid second read lock on a different lock object", (done) ->
#         lock2.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           assert id.equals ld.files_id
#           assert ld.expires instanceof Date
#           assert ld.expires > lock2.timeCreated
#           assert.equal ld.read_locks, 2
#           assert.equal ld.write_lock, false
#           assert.equal ld.write_req, false
#           assert.equal ld.reads, 2
#           assert.equal ld.writes, 0
#           assert.equal ld.meta, null
#           assert.equal lock2.heldLock, ld
#           done()

#       describe 'releaseLock', () ->
#         it "should return a valid lock document", (done) ->
#           lock2.releaseLock().on 'released', (ld) ->
#             assert ld?
#             assert id.equals ld.files_id
#             assert ld.expires instanceof Date
#             assert ld.expires > lock2.timeCreated
#             assert.equal ld.read_locks, 1
#             assert.equal ld.write_lock, false
#             assert.equal ld.write_req, false
#             assert.equal ld.reads, 2
#             assert.equal ld.writes, 0
#             assert.equal ld.meta, null
#             done()

#         it "should properly clear the lock state on a released read lock", () ->
#           assert.equal lock2.lockType, null
#           assert.equal lock2.query, null
#           assert.equal lock2.update, null
#           assert.equal lock2.heldLock, null

#       describe 'obtainWriteLock', () ->
#         it "should fail to return a valid write lock", (done) ->
#           lock2.obtainWriteLock().on 'timed-out', () ->
#             done()
#           lock2.on 'locked', () ->
#             assert false

#     describe 'obtainWriteLock', () ->

#       lock1 = null
#       lock2 = null
#       id = null

#       before () ->
#         id = new mongo.BSONPure.ObjectID
#         lock1 = Lock id, lockColl, {}
#         lock2 = Lock id, lockColl, {}

#       afterEach () ->
#         lock1.removeAllListeners()
#         lock2.removeAllListeners()

#       it "should return a valid lock document", (done) ->
#         lock1.obtainWriteLock().on 'locked', (ld) ->
#           assert ld?
#           assert id.equals ld.files_id
#           assert ld.expires instanceof Date
#           assert ld.expires > lock1.timeCreated
#           assert.equal ld.read_locks, 0
#           assert.equal ld.write_lock, true
#           assert.equal ld.write_req, false
#           assert.equal ld.reads, 0
#           assert.equal ld.writes, 1
#           assert.equal ld.meta, null
#           assert.equal lock1.heldLock, ld
#           done()

#       it "should properly set the lock state on a held write lock", () ->
#         assert.equal lock1.lockType, 'w'
#         assert lock1.query?
#         assert lock1.update?

#       it "should fail to return a second lock document for a lock object that already holds a lock", (done) ->
#         lock1.obtainWriteLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /cannot obtain an already held lock/
#           done()
#         lock1.on 'locked', () ->
#           assert false

#       it "should fail to return a valid second write lock", (done) ->
#         lock2.obtainWriteLock().on 'timed-out', () ->
#           done()
#         lock2.on 'locked', () ->
#           assert false

#       it "obtainReadLock should fail to return a valid read lock", (done) ->
#         lock2.obtainReadLock().on 'timed-out', () ->
#           done()
#         lock2.on 'locked', () ->
#           assert false

#       describe 'releaseLock', () ->
#         it "should return a valid lock document", (done) ->
#           lock1.releaseLock().on 'released', (ld) ->
#             assert ld?
#             assert id.equals ld.files_id
#             assert ld.expires instanceof Date
#             assert ld.expires > lock1.timeCreated
#             assert.equal ld.read_locks, 0
#             assert.equal ld.write_lock, false
#             assert.equal ld.write_req, false
#             assert.equal ld.reads, 0
#             assert.equal ld.writes, 1
#             assert.equal ld.meta, null
#             done()

#         it "should properly clear the lock state on a released write lock", () ->
#           assert.equal lock1.lockType, null
#           assert.equal lock1.query, null
#           assert.equal lock1.update, null
#           assert.equal lock1.heldLock, null

#       describe 'removeLock', () ->

#         before (done) ->
#           lock2.obtainWriteLock().on 'locked', (ld) ->
#             assert ld?
#             done()

#         it "should return a valid lock document", (done) ->
#           lock2.removeLock().on 'removed', (ld) ->
#             assert ld?
#             assert id.equals ld.files_id
#             assert ld.expires instanceof Date
#             assert ld.expires > lock2.timeCreated
#             assert.equal ld.read_locks, 0
#             assert.equal ld.write_lock, false
#             assert.equal ld.write_req, false
#             assert.equal ld.reads, 0
#             assert ld.writes > 1
#             assert.equal ld.meta, null
#             done()

#         it "should properly clear the lock state on a removed write lock", () ->
#           assert.equal lock2.lockType, null
#           assert.equal lock2.query, null
#           assert.equal lock2.update, null
#           assert.equal lock2.heldLock, null

#     describe 'releaseLock', () ->
#       lock1 = null
#       lock2 = null
#       id = null
#       id2 = null

#       before (done) ->
#         id = new mongo.BSONPure.ObjectID
#         id2 = new mongo.BSONPure.ObjectID
#         lock1 = Lock id, lockColl, {}
#         lock2 = Lock id, lockColl, {}
#         lock2.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           done()

#       afterEach () ->
#         lock1.removeAllListeners()
#         lock2.removeAllListeners()

#       it "should fail to release an unheld lock", (done) ->
#         lock1.releaseLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /cannot release an unheld lock/
#           done()
#         lock1.on 'released', () ->
#           assert false

#       it "should fail on unsupported lockType", (done) ->
#         lock2.lockType = "X"
#         lock2.releaseLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /invalid lockType/
#           lock2.lockType = "r"
#           done()
#         lock2.on 'released', () ->
#           assert false

#       it "should fail on missing lock document", (done) ->
#         lock2.fileId = id2
#         lock2.releaseLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /document not found in collection/
#           done()
#         lock2.on 'released', () ->
#           assert false

#     describe 'removeLock', () ->
#       lock1 = null
#       lock2 = null
#       id = null
#       id2 = null

#       before (done) ->
#         id = new mongo.BSONPure.ObjectID
#         id2 = new mongo.BSONPure.ObjectID
#         lock1 = Lock id, lockColl, {}
#         lock2 = Lock id, lockColl, {}
#         lock2.obtainWriteLock().on 'locked', (ld) ->
#           assert ld?
#           done()

#       afterEach () ->
#         lock1.removeAllListeners()
#         lock2.removeAllListeners()

#       it "should fail to release an unheld lock", (done) ->
#         lock1.removeLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /cannot release an unheld lock/
#           done()
#         lock1.on 'released', () ->
#           assert false

#       it "should fail on unsupported lockType", (done) ->
#         lock2.lockType = "X"
#         lock2.removeLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /invalid lockType/
#           lock2.lockType = "w"
#           done()
#         lock2.on 'released', () ->
#           assert false

#       it "should fail on a read locked document", (done) ->
#         lock2.lockType = "r"
#         lock2.removeLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /cannot remove a readLock/
#           lock2.lockType = "w"
#           done()
#         lock2.on 'released', () ->
#           assert false

#       it "should fail on missing lock document", (done) ->
#         lock2.fileId = id2
#         lock2.removeLock().on 'error', (e) ->
#           assert.throws (() -> throw e), /document not found in collection/
#           done()
#         lock2.on 'released', () ->
#           assert false

#     describe 'renewLock', () ->
#       lock1 = null
#       lock2 = null
#       id = null

#       before (done) ->
#         id = new mongo.BSONPure.ObjectID
#         lock1 = Lock id, lockColl, { lockExpiration: 60 }
#         lock1.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           done()

#       afterEach () ->
#         lock1.removeAllListeners()

#       it "should successfully extend the lock time", (done) ->
#         expiresBefore = lock1.heldLock.expires
#         lock1.renewLock().on 'renewed', (ld) ->
#           assert expiresBefore <= ld.expires
#           assert.equal ld.expires, lock1.heldLock.expires
#           done()

#       it "shouldn't decrease the time to expire of a read lock when another lock holder already has a longer expiration", (done) ->
#         lock2 = Lock id, lockColl, { lockExpiration: 600 }
#         lock2.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           expiresBefore = lock2.heldLock.expires
#           lock1.renewLock().on 'renewed', (ld) ->
#             assert.equal expiresBefore.getTime(), ld.expires.getTime()
#             assert.equal ld.expires.getTime(), lock1.heldLock.expires.getTime()
#             lock2.releaseLock().on 'released', (ld) ->
#               done()

#       it "should fail to renew an unheld lock", (done) ->
#         lock1.releaseLock().on 'released', (ld) ->
#           lock1.renewLock().on 'error', (e) ->
#             assert.throws (() -> throw e), /cannot renew an unheld lock/
#             done()
#         lock1.on 'renewed', () ->
#           assert false

#   describe 'waiting for locks', () ->

#     this.timeout 5000
#     lockColl = null
#     lock1 = null
#     lock2 = null
#     lock3 = null
#     id = null

#     before (done) ->
#       lockColl = LockCollection db, { timeOut: 2, pollingInterval: 1 }
#       lockColl.on 'ready', done

#     beforeEach () ->
#       id = new mongo.BSONPure.ObjectID
#       lock1 = Lock id, lockColl, {}
#       lock2 = Lock id, lockColl, {}
#       lock3 = Lock id, lockColl, {}
#       # These are too fast for production, but speed up the tests
#       lock1.pollingInterval = 100
#       lock2.pollingInterval = 100
#       lock3.pollingInterval = 100

#     it "should work for a write request waiting on a read lock", (done) ->
#       expectedOrder = "1122"
#       order = ''
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on 'locked', (ld) ->
#           assert ld?
#           order += '2'
#           lock2.releaseLock().on 'released', (ld) ->
#             assert ld?
#             order += '2'
#             assert.equal order, expectedOrder
#             done()
#         lock1.releaseLock().on 'released', (ld) ->
#           assert ld?
#           order += '1'

#     it "should work for a write request waiting on multiple read locks", (done) ->
#       expectedOrder = "122133"
#       order = ''
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           order += '2'
#           lock3.obtainWriteLock().on 'locked', (ld) ->
#             assert ld?
#             order += '3'
#             lock3.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '3'
#               assert order is expectedOrder
#               done()
#           lock2.releaseLock().on 'released', (ld) ->
#             assert ld?
#             order += '2'
#             lock1.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '1'

#     it "should work for a read request waiting on a write lock", (done) ->
#       expectedOrder = "1122"
#       order = ''
#       lock1.obtainWriteLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           order += '2'
#           lock2.releaseLock().on 'released', (ld) ->
#             assert ld?
#             order += '2'
#             assert.equal order, expectedOrder
#             done()
#         lock1.releaseLock().on 'released', (ld) ->
#           assert ld?
#           order += '1'

#     it "should give priority to a write request waiting on a read lock over a subsequent read request", (done) ->
#       expectedOrder = "112233"
#       order = ''
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on('locked', (ld) ->
#             assert ld?
#             order += '2'
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '2'
#         ).once('write-req-set', () ->
#             lock3.obtainReadLock().on 'locked', (ld) ->
#               assert ld?
#               order += '3'
#               lock3.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 order += '3'
#                 assert.equal order, expectedOrder
#                 done()
#             lock1.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '1');

#     it "should give priority to a write request waiting on a write lock over a subsequent read request", (done) ->
#       expectedOrder = "112233"
#       order = ''
#       lock1.obtainWriteLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on('locked', (ld) ->
#             assert ld?
#             order += '2'
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '2'
#         ).once('write-req-set', () ->
#             lock3.obtainReadLock().on 'locked', (ld) ->
#               assert ld?
#               order += '3'
#               lock3.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 order += '3'
#                 assert.equal order, expectedOrder
#                 done()
#             lock1.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '1');

#     it "should allow a read request to proceed when a prior write request times out", (done) ->
#       expectedOrder = "1331"
#       order = ''
#       lock2.timeOut = 150
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on('locked', (ld) ->
#             # This write lock request should time out
#             assert false
#         ).once('write-req-set', () ->
#             lock3.obtainReadLock().on 'locked', (ld) ->
#               assert ld?
#               order += '3'
#               lock3.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 order += '3'
#                 lock1.releaseLock().on 'released', (ld) ->
#                   assert ld?
#                   order += '1'
#                   assert.equal order, expectedOrder
#                   done());

#   describe 'lock expiration', () ->

#     this.timeout 5000

#     lockColl = null
#     lock1 = null
#     lock2 = null
#     lock3 = null
#     id = null

#     before (done) ->
#       lockColl = LockCollection db, { timeOut: 2, pollingInterval: 1, lockExpiration: 1 }
#       lockColl.on 'ready', done

#     beforeEach () ->
#       id = new mongo.BSONPure.ObjectID
#       lock1 = Lock id, lockColl, {}
#       lock2 = Lock id, lockColl, {}
#       lock3 = Lock id, lockColl, {}
#       # These are too fast for production, but speed up the tests
#       lock1.pollingInterval = 100
#       lock2.pollingInterval = 100
#       lock3.pollingInterval = 100
#       lock1.lockExpiration = 250
#       lock2.lockExpiration = 250
#       lock3.lockExpiration = 250

#     it "should generate expires-soon and expired events", (done) ->
#       lock1.obtainReadLock().on 'expires-soon', (ld) ->
#         assert ld?
#         assert lock1.heldLock?
#         assert.equal lock1.expired, false
#         lock1.on 'expired', (ld) ->
#           assert ld?
#           assert.equal lock1.expired, true
#           assert.equal lock1.heldLock, null
#           done()

#     it "should generate multiple expires-soon events when renewed", (done) ->
#       renewed = false
#       lock1.obtainReadLock().on 'expires-soon', (ld) ->
#         assert ld?
#         assert lock1.heldLock?
#         assert.equal lock1.expired, false
#         if renewed
#           lock1.on 'expired', (ld) ->
#             assert ld?
#             assert.equal lock1.expired, true
#             assert.equal lock1.heldLock, null
#             done()
#         else
#           lock1.renewLock().on 'renewed', (ld) ->
#             assert ld?
#             renewed = true

#     it "should work for a write request waiting on a dead read lock", (done) ->
#       expectedOrder = "122"
#       order = ''
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on 'locked', (ld) ->
#           assert ld?
#           order += '2'
#           lock2.releaseLock().on 'released', (ld) ->
#             assert ld?
#             order += '2'
#             assert.equal order, expectedOrder
#             done()

#     it "should work for a write request waiting on multiple dead read locks", (done) ->
#       expectedOrder = "1233"
#       order = ''
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           order += '2'
#           lock3.obtainWriteLock().on 'locked', (ld) ->
#             assert ld?
#             order += '3'
#             lock3.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '3'
#               assert order is expectedOrder
#               done()

#     it "should work for a read request waiting on a dead write lock", (done) ->
#       expectedOrder = "122"
#       order = ''
#       lock1.obtainWriteLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainReadLock().on 'locked', (ld) ->
#           assert ld?
#           order += '2'
#           lock2.releaseLock().on 'released', (ld) ->
#             assert ld?
#             order += '2'
#             assert.equal order, expectedOrder
#             done()

#     it "should give priority to a write request waiting on a dead read lock over a subsequent read request", (done) ->
#       expectedOrder = "12233"
#       order = ''
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on('locked', (ld) ->
#             assert ld?
#             order += '2'
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '2'
#         ).once('write-req-set', () ->
#             lock3.obtainReadLock().on 'locked', (ld) ->
#               assert ld?
#               order += '3'
#               lock3.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 order += '3'
#                 assert.equal order, expectedOrder
#                 done());

#     it "should give priority to a write request waiting on a dead write lock over a subsequent read request", (done) ->
#       expectedOrder = "12233"
#       order = ''
#       lock1.obtainWriteLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on('locked', (ld) ->
#             assert ld?
#             order += '2'
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               order += '2'
#         ).once('write-req-set', () ->
#             lock3.obtainReadLock().on 'locked', (ld) ->
#               assert ld?
#               order += '3'
#               lock3.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 order += '3'
#                 assert.equal order, expectedOrder
#                 done());

#     it "should allow a read request to proceed when a prior write request dies without releasing write_req", (done) ->
#       expectedOrder = "1331"
#       order = ''
#       lock2.timeOut = 100
#       lock1.lockExpiration = 1000
#       lock3.lockExpiration = 1000
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on('locked', (ld) ->
#             # This write lock request should time out
#             assert false
#         ).once('write-req-set', () ->
#             lock3.obtainReadLock().on 'locked', (ld) ->
#               assert ld?
#               order += '3'
#               lock3.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 order += '3'
#                 lock1.releaseLock().on 'released', (ld) ->
#                   assert ld?
#                   order += '1'
#                   assert.equal order, expectedOrder
#                   done());

#     it "should allow a read request to proceed when a prior write request dies waiting for a dead write lock without releasing write_req", (done) ->
#       expectedOrder = "133"
#       order = ''
#       lock2.timeOut = 100
#       lock3.lockExpiration = 1000
#       lock1.obtainWriteLock().on 'locked', (ld) ->
#         assert ld?
#         order += '1'
#         lock2.obtainWriteLock().on('locked', (ld) ->
#             # This write lock request should time out
#             assert false
#         ).once('write-req-set', () ->
#             lock3.obtainReadLock().on 'locked', (ld) ->
#               assert ld?
#               order += '3'
#               lock3.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 order += '3'
#                 assert.equal order, expectedOrder
#                 done());

#     it "of a new read lock shouldn't be affected by when the previous write lock was due to expire", (done) ->
#       lock1.lockExpiration = 0  # Never expires
#       lock1.obtainWriteLock().on 'locked', (ld) ->
#         assert ld?
#         lock1.releaseLock().on 'released', (ld) ->
#           assert ld?
#           lock2.obtainReadLock().on 'locked', (ld) ->
#             assert ld?
#             assert ld.expires.getTime() is lock2.lockExpireTime.getTime()
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               done()

#     it "of a new read lock shouldn't be affected by when the previous read lock was due to expire", (done) ->
#       lock1.lockExpiration = 0  # Never expires
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         lock1.releaseLock().on 'released', (ld) ->
#           assert ld?
#           lock2.obtainReadLock().on 'locked', (ld) ->
#             assert ld?
#             assert ld.expires.getTime() is lock2.lockExpireTime.getTime()
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               done()

#     it "shouldn't allow a later read lock to shorten the expiration of an already held read lock", (done) ->
#       lock1.lockExpiration = 5000
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         lock2.obtainReadLock().on 'locked', (ld2) ->
#           assert ld2?
#           assert.equal ld2.expires.getTime(), ld.expires.getTime()
#           lock1.releaseLock().on 'released', (ld) ->
#             assert ld?
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               done()

#     it "should allow a later read lock to lengthen the expiration of an already held read lock", (done) ->
#       lock2.lockExpiration = 5000
#       lock1.obtainReadLock().on 'locked', (ld) ->
#         assert ld?
#         lock2.obtainReadLock().on 'locked', (ld2) ->
#           assert ld2?
#           assert ld2.expires.getTime() > ld.expires.getTime()
#           lock1.releaseLock().on 'released', (ld) ->
#             assert ld?
#             lock2.releaseLock().on 'released', (ld) ->
#               assert ld?
#               done()

#   describe 'testing under load', () ->

#     this.timeout 300000

#     lockColl = null
#     locksArray = []
#     numLocks = 5000
#     writeLockFraction = 0.01

#     myTimeout = (t, p, cb) ->
#       setTimeout cb, Math.floor(Math.random()*t), p

#     before (done) ->
#       lockColl = LockCollection db, { timeOut: 60, pollingInterval: 1, lockExpiration: 120 }
#       lockColl.on 'ready', done

#     beforeEach () ->
#       id = new mongo.BSONPure.ObjectID
#       locksArray = (Lock(id, lockColl, {}) for x in [0...numLocks])

#     it 'should accomodate hundreds of simultaneous readers on a resource', (done) ->
#       released = 0
#       for l in locksArray
#         myTimeout Math.floor(10000*Math.random()), l, (l) ->
#           l.obtainReadLock().on 'locked', (ld) ->
#             # console.log "RL", released, ld.write_lock, ld.write_req, ld.read_locks
#             assert ld?
#             myTimeout 5, l, (l) ->
#               l.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 released++
#                 # console.log "RUL", released, ld.write_lock, ld.write_req, ld.read_locks
#                 done() if released is numLocks

#     it 'should accomodate hundreds of simultaneous writers on a resource', (done) ->
#       released = 0
#       currentValue = 0
#       for l, x in locksArray when x < numLocks*writeLockFraction
#         myTimeout Math.floor(10000*Math.random()), l, (l) ->
#           l.obtainWriteLock().on 'locked', (ld) ->
#             # console.log "WL", released, ld.write_lock, ld.write_req, ld.read_locks
#             assert ld?
#             assert.equal Math.floor(currentValue), currentValue
#             currentValue += 0.5
#             myTimeout 5, l, (l) ->
#               currentValue += 0.5
#               l.releaseLock().on 'released', (ld) ->
#                 assert ld?
#                 released++
#                 # console.log "WUL", released, ld.write_lock, ld.write_req, ld.read_locks
#                 done() if released is numLocks*writeLockFraction

#     it 'should accomodate hundreds of simultaneous readers/writers on a resource', (done) ->
#       released = 0
#       currentValue = 0
#       for l, x in locksArray
#         myTimeout Math.floor(10000*Math.random()), l, (l) ->
#           if Math.random() <= writeLockFraction
#             l.obtainWriteLock().on 'locked', (ld) ->
#               # console.log "WL", new Date().toJSON(), released, JSON.stringify(ld), JSON.stringify(l.query), JSON.stringify(l.update)
#               assert ld?
#               assert ld.expires.getTime() > new Date().getTime() + 100000
#               assert.equal Math.floor(currentValue), currentValue
#               currentValue += 0.5
#               myTimeout 5, l, (l) ->
#                 currentValue += 0.5
#                 l.releaseLock().on 'released', (ld) ->
#                   assert ld?
#                   released++
#                   # console.log "WUL", new Date().toJSON(), released, JSON.stringify(ld)
#                   done() if released is numLocks
#           else
#             l.obtainReadLock().on 'locked', (ld) ->
#               # console.log "RL", new Date().toJSON(), released, JSON.stringify(ld), JSON.stringify(l.query), JSON.stringify(l.update)
#               assert ld?
#               assert ld.expires.getTime() > new Date().getTime() + 100000
#               assert.equal Math.floor(currentValue), currentValue
#               myTimeout 5, l, (l) ->
#                 l.releaseLock().on 'released', (ld) ->
#                   assert ld?
#                   released++
#                   # console.log "RUL", new Date().toJSON(), released, JSON.stringify(ld)
#                   done() if released is numLocks

#   describe 'testing with timeouts and expiration under load', () ->

#     this.timeout 300000

#     lockColl = null
#     locksArray = []
#     numLocks = 5000
#     writeLockFraction = 0.01
#     deadLockFraction = 0.001

#     myTimeout = (t, p, cb) ->
#       setTimeout cb, Math.floor(Math.random()*t), p

#     before (done) ->
#       lockColl = LockCollection db, { timeOut: 10, pollingInterval: 1, lockExpiration: 5 }
#       lockColl.on 'ready', done

#     beforeEach () ->
#       id = new mongo.BSONPure.ObjectID
#       locksArray = (Lock(id, lockColl, {}) for x in [0...numLocks])

#     it 'should accomodate hundreds of simultaneous readers/writers on a resource', (done) ->
#       released = 0
#       timedOut = 0
#       expired = 0
#       currentValue = 0
#       for l, x in locksArray
#         myTimeout Math.floor(10000*Math.random()), l, (l) ->
#           ex = false
#           if Math.random() <= writeLockFraction
#             l.obtainWriteLock().on 'locked', (ld) ->
#               # console.log "** WL", released+timedOut+expired, released, timedOut, expired, ld.write_lock, ld.write_req, ld.read_locks
#               assert ld?
#               assert.equal Math.floor(currentValue), currentValue
#               l.on 'expired', () ->
#                 ex = true
#                 expired++
#                 # console.log "** WEX", released+timedOut+expired, released, timedOut, expired, ld.write_lock, ld.write_req, ld.read_locks
#                 done() if released+timedOut+expired is numLocks
#               myTimeout 5, l, (l) ->
#                 unless ex or Math.random() < deadLockFraction
#                   currentValue += 1.0
#                   l.releaseLock().on 'released', (ld) ->
#                     assert ld?
#                     released++
#                     # console.log "** WUL", released+timedOut+expired, released, timedOut, expired, ld.write_lock, ld.write_req, ld.read_locks
#                     done() if released+timedOut+expired is numLocks
#             l.on 'timed-out', () ->
#               timedOut++
#               # console.log "** WTO", released+timedOut+expired, released, timedOut, expired
#               done() if released+timedOut+expired is numLocks
#           else
#             l.obtainReadLock().on 'locked', (ld) ->
#               # console.log "RL", released+timedOut+expired, released, timedOut, expired, ld.write_lock, ld.write_req, ld.read_locks
#               assert ld?
#               assert.equal Math.floor(currentValue), currentValue
#               l.on 'expired', () ->
#                 ex = true
#                 expired++
#                 # console.log "REX", released+timedOut+expired, released, timedOut, expired
#                 done() if released+timedOut+expired is numLocks
#               myTimeout 5, l, (l) ->
#                 unless ex or Math.random() < deadLockFraction
#                   l.releaseLock().on 'released', (ld) ->
#                     assert ld?
#                     released++
#                     # console.log "RUL", released+timedOut+expired, released, timedOut, expired, ld.write_lock, ld.write_req, ld.read_locks
#                     done() if released+timedOut+expired is numLocks
#             l.on 'timed-out', () ->
#               timedOut++
#               # console.log "RTO", released+timedOut+expired, released, timedOut, expired
#               done() if released+timedOut+expired is numLocks

#   after (done) ->
#     db.dropDatabase () ->
#       db.close true, done


