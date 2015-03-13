instances = require('./api/instances')
clusters = require('./api/clusters')

module.exports = (app) ->

    app.get('/moirai/instances', instances.handle_get_instances)
    app.post('/moirai/instances', instances.handle_create_instance)

    app.get('/moirai/instances/:instance_id', instances.handle_get_instance)
    app.patch('/moirai/instances/:instance_id', instances.handle_update_instance)
    app.delete('/moirai/instances/:instance_id', instances.handle_destroy_instance)

    app.get('/moirai/clusters', clusters.handle_get_clusters)
    app.post('/moirai/clusters', clusters.handle_create_cluster)

    app.get('/moirai/clusters/:cluster_id', clusters.handle_get_cluster)
    app.patch('/moirai/clusters/:cluster_id', clusters.handle_update_cluster)
    app.delete('/moirai/clusters/:cluster_id', clusters.handle_destroy_cluster)

    app.post('/moirai/clusters/:cluster_id/instances', clusters.handle_add_instance)

###
    cluster -> timer, sprinkler, restart, stop
    instance -> instance metadata, restart, stop

    thoughts:
     -  when we hit "reset timer" the timer will reset for all boxes? if so it doesn't make sense then that there is a reset button next to each instance
     -  we want the ability to create a new cluster, but also create a new instance by itself (i.e. cluster of one).  what about creating a new instance inside an existing cluster?

     application
     
     # pseudocode
     create_instance(name, type)
        cluster_id = create_cluster(name, instances=[{name, type}])

        cluster_id = create_cluster(name, opts)
	instance_id = aws.create_instance(cluster_id, name, type)

        return couch.cluster[cluster_id].instances[0].id

     clone_cluster(cluster_id, opts) // returns a clust_id
     create_cluster(name, instances=[{name, type}]
        cluster = new Cluster(name)
        for instance in instances:
            metadata = aws.createinstance(instance['name'], instance['type'])
            couch.instances[metadata.id] = metadata
            couch.cluster.instances.add(metadata.id)
        return cluster.id

     reset_instance_timer(id)
         reset_cluster_timer(couch.instances[id].cluster)

###

