clusters = require('./api/clusters')

module.exports = (app) ->

    app.get('/moirai/clusters', clusters.handle_get_clusters)
    app.post('/moirai/clusters', clusters.handle_create_cluster)

    app.get('/moirai/clusters/:cluster_id', clusters.handle_get_cluster)
#    app.patch('/moirai/clusters/:cluster_id', clusters.handle_update_cluster)
    app.delete('/moirai/clusters/:cluster_id', clusters.handle_destroy_cluster)

    app.put('/moirai/clusters/:cluster_id/keys', clusters.handle_set_keys)
    app.put('/moirai/clusters/:cluster_id/start', clusters.handle_start_cluster)
    app.put('/moirai/clusters/:cluster_id/stop', clusters.handle_stop_cluster)

#    app.post('/moirai/clusters/:cluster_id/instances', clusters.handle_add_instance)
