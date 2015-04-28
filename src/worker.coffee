worker = require('pantheon-helpers/lib/worker')
_ = require('underscore')
follow = require('follow')
couch_utils = require('./couch_utils')
get_doc_type = require('./design_docs/moirai/lib/actions').get_doc_type
ec2Client = require('./ec2Client')
Promise = require('pantheon-helpers/lib/promise')
handlers = require('./workerHandlers')

db = couch_utils.nano_system_user.use('moirai')
worker.start_worker(db,
                    handlers,
                    get_doc_type
                   )
