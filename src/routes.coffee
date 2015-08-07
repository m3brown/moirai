clusters = require('./api/clusters')

module.exports = (app) ->

    app.get('/moirai/clusters', clusters.handleGetClusters)
#    app.get('/moirai/instancesToShutdown', clusters.handleGetInstancesToShutdown)
    app.post('/moirai/clusters', clusters.handleCreateCluster)

    app.get('/moirai/clusters/:clusterId', clusters.handleGetCluster)
#    app.patch('/moirai/clusters/:clusterId', clusters.handleUpdateCluster)
    app.delete('/moirai/clusters/:clusterId', clusters.handleDestroyCluster)

    app.put('/moirai/clusters/:clusterId/keys', clusters.handleSetKeys)
#    app.put('/moirai/clusters/:clusterId/state', clusters.handleSetClusterState)
    app.put('/moirai/clusters/:clusterId/start', clusters.handleStartCluster)
    app.put('/moirai/clusters/:clusterId/stop', clusters.handleStopCluster)

#    app.post('/moirai/clusters/:clusterId/instances', clusters.handleAddInstance)
