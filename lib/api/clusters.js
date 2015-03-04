// Generated by IcedCoffeeScript 1.8.0-c
(function() {
  var clusters, iced, _, __iced_k, __iced_k_noop;

  iced = require('iced-runtime');
  __iced_k = __iced_k_noop = function() {};

  _ = require('underscore');

  clusters = {};

  clusters.get_cluster = function(client, cluster_id, callback) {
    return client.get(cluster_id, callback);
  };

  clusters.handle_get_cluster = function(req, resp) {
    var client, cluster_id;
    cluster_id = req.params.cluster_id;
    client = req.couch;
    return clusters.get_cluster(client, cluster_id).pipe(resp);
  };

  clusters.create_cluster = function(client, opts, callback) {
    var err, out, resp, ___iced_passed_deferral, __iced_deferrals, __iced_k;
    __iced_k = __iced_k_noop;
    ___iced_passed_deferral = iced.findDeferral(arguments);
    (function(_this) {
      return (function(__iced_k) {
        __iced_deferrals = new iced.Deferrals(__iced_k, {
          parent: ___iced_passed_deferral,
          filename: "/opt/moirai/src/api/clusters.iced",
          funcname: "create_cluster"
        });
        client.insert(opts, __iced_deferrals.defer({
          assign_fn: (function() {
            return function() {
              err = arguments[0];
              return resp = arguments[1];
            };
          })(),
          lineno: 13
        }));
        __iced_deferrals._fulfill();
      });
    })(this)((function(_this) {
      return function() {
        if (err) {
          return callback(err);
        }
        out = _.extend({}, opts, {
          _id: resp.id,
          _rev: resp.rev
        });
        return callback(null, out);
      };
    })(this));
  };

  clusters.handle_create_cluster = function(req, resp) {
    var cluster_doc, cluster_opts, err, ___iced_passed_deferral, __iced_deferrals, __iced_k;
    __iced_k = __iced_k_noop;
    ___iced_passed_deferral = iced.findDeferral(arguments);
    cluster_opts = req.body || {};
    (function(_this) {
      return (function(__iced_k) {
        __iced_deferrals = new iced.Deferrals(__iced_k, {
          parent: ___iced_passed_deferral,
          filename: "/opt/moirai/src/api/clusters.iced",
          funcname: "handle_create_cluster"
        });
        clusters.create_cluster(req.couch, cluster_opts, __iced_deferrals.defer({
          assign_fn: (function() {
            return function() {
              err = arguments[0];
              return cluster_doc = arguments[1];
            };
          })(),
          lineno: 20
        }));
        __iced_deferrals._fulfill();
      });
    })(this)((function(_this) {
      return function() {
        if (err) {
          return resp.status(500).send(JSON.stringify({
            error: 'internal error',
            msg: 'internal error'
          }));
        }
        return resp.status(201).send(JSON.stringify(cluster_doc));
      };
    })(this));
  };

  clusters.handle_get_clusters = function(req, resp) {
    return resp.send('NOT IMPLEMENTED');
  };

  clusters.handle_get_cluster = function(req, resp) {
    return resp.send('NOT IMPLEMENTED');
  };

  clusters.handle_update_cluster = function(req, resp) {
    return resp.send('NOT IMPLEMENTED');
  };

  clusters.handle_destroy_cluster = function(req, resp) {
    return resp.send('NOT IMPLEMENTED');
  };

  clusters.handle_add_instance = function(req, resp) {
    return resp.send('NOT IMPLEMENTED');
  };

  module.exports = clusters;

}).call(this);