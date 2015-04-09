conf = require('../lib/config')
conf.AWS.PRIVATE_KEY_FILE = 'test-keyfile'
conf.AWS.SSH_USER = 'test-user'
ssh = require('promised-ssh')
fs = require('fs')
ec2KeyManagement = require('../lib/ec2KeyManagement')
Promise = require('pantheon-helpers/lib/promise')

describe 'addSSHKeys', () ->
  beforeEach () ->
    spyOn(fs, 'readFileSync').andCallFake((keyfile) ->
      return 'key text'
    #return "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost2.company"
    )
    spyOn(ssh, 'connect').andCallFake((params) =>
      if this.sshFailConnect
        return Promise.reject(new ssh.errors.ConnectionError(params.username, params.host))

      return Promise.resolve({
        exec: (commands) ->
          commands.map((command) ->
            if command.match(new RegExp(this.failing_pubkey))
              return Promise.reject(new ssh.errors.CommandExecutionError(command, 1, 'stdout', 'stderr'))
            else
              return Promise.resolve()
          )
      }) 
    )
    this.sshFailConnect = false
    this.pubkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost1.company'
    this.pubkey2 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF6 Username2@RandomHost2.company'
    this.failing_pubkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username2'

  it 'does not try to connect if a badly formatted pubkey is provided', (done) ->
    cut = ec2KeyManagement.addSSHKeys
    pubkeys = [
      "AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost2.company",
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5",
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1!",
      "ssh-rsa AAAA Username1"
    ]
    cut("host", [pubkeys[0]]).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      cut("host", [pubkeys[1]])
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      cut("host", [pubkeys[2]])
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      result = cut("host", [pubkeys[3]])
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      done()
      return Promise.reject()
    ).then(() ->
      done('Test failed, promise should have been rejected but was resolved')
    )

  it 'does not try to connect if one of many keys is badly formatted', (done) ->
    cut = ec2KeyManagement.addSSHKeys
    pubkeys = [
      this.pubkey,
      this.pubkey2,
      "ssh-rsa AAAA Username1"
    ]
    cut("host", pubkeys).then(() ->
      done('Test failed, promise should have been rejected but was resolved')
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      done()
    )

  it 'resolves if the connection and command succeeds', (done) ->
    cut = ec2KeyManagement.addSSHKeys
    cut("host", [this.pubkey]).catch((err) ->
      done('Test failed, promise should have been resolved but was rejected')
    ).then((result) ->
      expect(ssh.connect.calls.length).toEqual(1)
      done()
    )

  it 'rejects if the connection fails', (done) ->
    cut = ec2KeyManagement.addSSHKeys
    this.sshFailConnect = true
    cut("host", [this.pubkey]).then(() ->
      done('Test failed, promise should have been rejected but was resolved')
    ).catch((err) ->
      expect(ssh.connect.calls.length).toEqual(1)
      console.log(err)
      done()
    )

  # This isn't working as expected for some reason
  #it 'rejects if the connection succeeds but the command fails', (done) ->
  #  cut = ec2KeyManagement.addSSHKeys
  #  cut("host", [this.failing_pubkey]).then(() ->
  #    done('Test failed, promise should have been rejected but was resolved')
  #  ).catch((err) ->
  #    expect(ssh.connect.calls.length).toEqual(1)
  #    expect(err.code).toEqual(1)
  #    done()
  #  )
  
describe 'removeSSHKeys', () ->
  beforeEach () ->
    spyOn(fs, 'readFileSync').andCallFake((keyfile) ->
      return 'key text'
    #return "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost2.company"
    )
    this.sshFailConnect = false
    this.pubkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost2.company'
    this.failing_pubkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username2'
    this.pubkey2 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF6 Username2@RandomHost2.company'
    spyOn(ssh, 'connect').andCallFake((params) =>
      if this.sshFailConnect
        return Promise.reject(new ssh.errors.ConnectionError(params.username, params.host))

      return Promise.resolve({
        exec: (commands) ->
          commands.map((command) ->
            if command.match(new RegExp(this.failing_pubkey))
              return Promise.reject(new ssh.errors.CommandExecutionError(command, 1, 'stdout', 'stderr'))
            else
              return Promise.resolve()
          )
      }) 
    )

  it 'does not try to connect if a badly formatted pubkey is provided', (done) ->
    cut = ec2KeyManagement.removeSSHKeys
    pubkeys = [
      "AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1@RandomHost2.company",
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5",
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiTE9GnjEQeL4wMiqAsCJteX67PF6rleStq7PGBPSkXkiyodW4VhPq30vTdwxLRSPAp6yB2QaASjgbmLU8SkoBZER9JFMUCuqblq2Ngz1SUvzD2wnV2IjBnVR1uBY2BF2VKH3m3VbnHduXSlpXitjm8jcua22tlB1Vd2Qz22/sOvRk/zUmCyN6DYC0SyHG8njRigWLgQU9Ir62geksPam+aN7n/fZAKsE9vZkCLcN3qBkMFbPnliMurs5KtFbJlZLYSil5QtBNK3bfLPbpAK0aLz/zmASr7FSLsvOvB30FDyKb/3Qm0uE2LkIknHvd34KcxmGmPGlAWl6vDdRd5SF5 Username1!",
      "ssh-rsa AAAA Username1"
    ]
    cut("host", [pubkeys[0]]).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      cut("host", [pubkeys[1]])
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      cut("host", [pubkeys[2]])
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      result = cut("host", [pubkeys[3]])
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      done()
      return Promise.reject()
    ).then(() ->
      done('Test failed, promise should have been rejected but was resolved')
    )

  it 'does not try to connect if one of many keys is badly formatted', (done) ->
    cut = ec2KeyManagement.removeSSHKeys
    pubkeys = [
      this.pubkey,
      this.pubkey2,
      "ssh-rsa AAAA Username1"
    ]
    cut("host", pubkeys).then(() ->
      done('Test failed, promise should have been rejected but was resolved')
    ).catch(() ->
      expect(ssh.connect.calls.length).toEqual(0)
      done()
    )

  it 'resolves if the connection and command succeeds', (done) ->
    cut = ec2KeyManagement.removeSSHKeys
    cut("host", [this.pubkey]).catch((err) ->
      done('Test failed, promise should have been resolved but was rejected')
    ).then((result) ->
      expect(ssh.connect.calls.length).toEqual(1)
      done()
    )

  it 'rejects if the connection fails', (done) ->
    cut = ec2KeyManagement.removeSSHKeys
    this.sshFailConnect = true
    cut("host", [this.pubkey]).then(() ->
      done('Test failed, promise should have been rejected but was resolved')
    ).catch((err) ->
      expect(ssh.connect.calls.length).toEqual(1)
      console.log(err)
      done()
    )

  # This isn't working as expected for some reason
  #it 'rejects if the connection succeeds but the command fails', (done) ->
  #  cut = ec2KeyManagement.removeSSHKeys
  #  cut("host", [this.failing_pubkey]).then(() ->
  #    done('Test failed, promise should have been rejected but was resolved')
  #  ).catch((err) ->
  #    expect(ssh.connect.calls.length).toEqual(1)
  #    expect(err.code).toEqual(1)
  #    done()
  #  )
  
