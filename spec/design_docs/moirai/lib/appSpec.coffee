app = require('../../../../lib/design_docs/moirai/lib/app')

describe 'views.active_clusters.map', () ->
  beforeEach () ->
    app.emitted = []

  it 'emits a doc id for a cluster doc if it has an unterminated instance', () ->
    cut = app.views.active_clusters.map
    cut({_id: 'cluster_1', instances: [{}]})
    expect(app.emitted).toEqual([{k: 'cluster_1', v: undefined}])

  it 'does not emit when there are no instances', () ->
    cut = app.views.active_clusters.map
    cut({_id: 'cluster_1', instances: []})
    expect(app.emitted).toEqual([])

  it 'does not emit when doc is not a cluster', () ->
    cut = app.views.active_clusters.map
    cut({_id: '1', instances: [{}]})
    expect(app.emitted).toEqual([])
  
  it 'does not emit when all instance states are "terminate"', () ->
    cut = app.views.active_clusters.map
    cut({_id: 'cluster_1', instances: [{state: 'terminate'}]})
    expect(app.emitted).toEqual([])
  
  it 'emits when at least one instance state is not "terminate"', () ->
    cut = app.views.active_clusters.map
    cut({_id: 'cluster_1', instances: [{}, {state: 'terminate'}]})
    expect(app.emitted).toEqual([{k: 'cluster_1', v: undefined}])

  
  it 'emits when at least one instance state is not "terminate"', () ->
    doc = {"_id":"cluster_a262ec74cd0c8e344da6d88c5f00889b","_rev":"1-9c26756d05635129e35aca24d74008ea","audit":[{"a":"c+","record":{"instances":[{"InstanceType":"t1.micro","tags":{"Name":"awsdevtestname"},"id":"ca458ffa-f874-4e4c-96e1-28cf1bd82c92"}],"name":"a_cluster"},"id":"0cd20e09-85f4-481f-af6c-757edcc3adf0","u":"admin","dt":1427488607244}],"name":"a_cluster","created":1427488607244,"instances":[{"id":"ca458ffa-f874-4e4c-96e1-28cf1bd82c92","name":"awsdevtestname","size":"t1.micro"}]}
    cut = app.views.active_clusters.map
    cut(doc)
    expect(app.emitted).toEqual([{k: 'cluster_a262ec74cd0c8e344da6d88c5f00889b', v: undefined}])

