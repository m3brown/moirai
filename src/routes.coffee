clusters = require('./api/clusters')

module.exports = (app) ->

    app.get('/moirai/clusters', clusters.handleGetClusters)
    app.post('/moirai/clusters', clusters.handleCreateCluster)

    app.get('/moirai/clusters/:cluster_id', clusters.handleGetCluster)
#    app.patch('/moirai/clusters/:cluster_id', clusters.handleUpdateCluster)
    app.delete('/moirai/clusters/:cluster_id', clusters.handleDestroyCluster)

    app.put('/moirai/clusters/:cluster_id/keys', clusters.handleSetKeys)
    app.put('/moirai/clusters/:cluster_id/start', clusters.handleStartCluster)
    app.put('/moirai/clusters/:cluster_id/stop', clusters.handleStopCluster)

#    app.post('/moirai/clusters/:cluster_id/instances', clusters.handleAddInstance)
