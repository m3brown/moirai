conf = require('../lib/config')
conf.AWS.PRIVATE_KEY_FILE = 'test-keyfile'
conf.AWS.SSH_USER = 'test-user'
ec2KeyManagement = require('../lib/ec2KeyManagement')
ec2Client = require('../lib/ec2Client')
Promise = require('pantheon-helpers/lib/promise')

describe 'setSSHKeys', () ->
  beforeEach () ->
    spyOn(ec2KeyManagement, 'exec').andCallFake((command) =>
      if this.sshFailConnect
        return Promise.reject({code: 1, signal: 0})

      return Promise.resolve()
    )
    spyOn(ec2Client, 'startInstances').andCallFake((aws_id) =>
      return Promise.resolve({State: {Name: 'running'}})
    )
    spyOn(ec2Client, 'stopInstances').andCallFake((aws_id) =>
      return Promise.resolve({State: {Name: 'halted'}})
    )
    spyOn(Promise, 'setTimeout').andCallFake((seconds) =>
      return Promise.resolve()
    )
    spyOn(ec2Client, 'getSingleInstance').andCallFake((aws_id) =>
      if this.awsFailConnect
        return Promise.reject("failed to connect")
      if this.awsHaltedInstance
        return Promise.resolve({State: {Name: 'halted'}})
      if this.awsPendingInstance
        return Promise.resolve({State: {Name: 'pending'}})
      else
        return Promise.resolve({State: {Name: 'running'}})
    )
    this.sshFailConnect = false
    this.awsFailConnect = false
    this.awsPendingInstance = false
    this.awsHaltedInstance = false
    this.pubkeys = [
      'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost1.company'
      'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF6 Username2@RandomHost2.company'
    ]

#  it 'does not try to connect if a badly formatted pubkey is provided', (done) ->
#    cut = ec2KeyManagement.setSSHKeys
#    bad_pubkeys = [
#      "AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost2.company",
#      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5",
#      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1!",
#      "ssh-rsa AAAA Username1"
#    ]
#    cut("host", [bad_pubkeys[0]]).catch(() ->
#      expect(ec2KeyManagement.exec.calls.length).toEqual(0)
#      cut("host", [bad_pubkeys[1]])
#    ).catch(() ->
#      expect(ec2KeyManagement.exec.calls.length).toEqual(0)
#      cut("host", [bad_pubkeys[2]])
#    ).catch(() ->
#      expect(ec2KeyManagement.exec.calls.length).toEqual(0)
#      result = cut("host", [bad_pubkeys[3]])
#    ).catch(() ->
#      expect(ec2KeyManagement.exec.calls.length).toEqual(0)
#      done()
#      return Promise.reject()
#    ).then(() ->
#      done('Test failed, promise should have been rejected but was resolved')
#    )

  it 'runs exec if the connection and command succeeds', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    cut("host", this.pubkeys).catch(() ->
      done('Test failed, promise should have been resolved but was rejected')
    ).then(() ->
      expect(ec2KeyManagement.exec.calls.length).toEqual(1)
      done()
    )

#  it 'does not try to connect if one of many keys is badly formatted', (done) ->
#    cut = ec2KeyManagement.setSSHKeys
#    this.pubkeys.push("ssh-rsa AAAA Username1")
#    cut("host", this.pubkeys).then(() ->
#      done('Test failed, promise should have been rejected but was resolved')
#    ).catch(() ->
#      expect(ec2KeyManagement.exec.calls.length).toEqual(0)
#      done()
#    )

  it 'resolves if the connection and command succeeds', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    cut("host", this.pubkeys).then(() ->
      expect(ec2KeyManagement.exec.calls.length).toEqual(1)
      done()
    ).catch(() ->
      done('Test failed, promise should have been resolved but was rejected')
    )

  it 'does not call startInstances or stopInstances if the instance is running', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    cut("host", this.pubkeys).then(() ->
      expect(ec2Client.getSingleInstance.calls.length).toEqual(1)
      expect(ec2Client.startInstances.calls.length).toEqual(0)
      expect(ec2Client.stopInstances.calls.length).toEqual(0)
      done()
    ).catch(() ->
      done('Test failed, promise should have been resolved but was rejected')
    )

  it 'retries 5 times and rejects if the connection fails', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    this.sshFailConnect = true
    cut("host", this.pubkeys).then(() =>
      done('Test failed, promise should have been rejected but was resolved')
    ).catch((err) =>
      expect(ec2KeyManagement.exec.calls.length).toEqual(5)
      done()
    )

  it 'execs if instance state is pending', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    this.awsPendingInstance = true
    cut("host", this.pubkeys).catch(() ->
      done('Test failed, promise should have been resolved but was rejected')
    ).then(() ->
      expect(ec2KeyManagement.exec.calls.length).toEqual(1)
      done()
    )

  it 'does not call startInstances or stopInstances if the instance state is pending', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    this.awsPendingInstance = true
    cut("host", this.pubkeys).then(() ->
      expect(ec2Client.getSingleInstance.calls.length).toEqual(1)
      expect(ec2Client.startInstances.calls.length).toEqual(0)
      expect(ec2Client.stopInstances.calls.length).toEqual(0)
      done()
    ).catch(() ->
      done('Test failed, promise should have been resolved but was rejected')
    )

  it 'execs if instance state is halted', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    this.awsHaltedInstance = true
    cut("host", this.pubkeys).catch(() ->
      done('Test failed, promise should have been resolved but was rejected')
    ).then(() ->
      expect(ec2KeyManagement.exec.calls.length).toEqual(1)
      done()
    )

  it 'runs startInstances and stopInstances if the instance state is halted', (done) ->
    cut = ec2KeyManagement.setSSHKeys
    this.awsHaltedInstance = true
    cut("host", this.pubkeys).then(() ->
      expect(ec2Client.getSingleInstance.calls.length).toEqual(1)
      expect(ec2Client.startInstances.calls.length).toEqual(1)
      expect(ec2Client.stopInstances.calls.length).toEqual(1)
      done()
    ).catch(() ->
      done('Test failed, promise should have been resolved but was rejected')
    )

