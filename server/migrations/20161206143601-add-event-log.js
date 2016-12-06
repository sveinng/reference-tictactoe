'use strict';

var dbm;
var type;
var seed;

/**
  * We receive the dbmigrate dependency from dbmigrate initially.
  * This enables us to not have to rely on NODE_PATH.
  */
exports.setup = function(options, seedLink) {
  dbm = options.dbmigrate;
  type = dbm.dataType;
  seed = seedLink;
};

exports.up = function(db,callback) {
  db.createTable('eventlog', {
    timestamp:{ type:'datetime'},
    id: { type: 'string', primaryKey: true },
    aggregate_id: 'string',
    json: 'string'
  }, callback);};

exports.down = function(db) {
  db.dropTable('eventlog', callback);
};

exports._meta = {
  "version": 1
};
