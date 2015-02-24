couch_utils = require('./couch_utils')
basic_auth = require('basic-auth')
conf = require('./config')

module.exports = 
  couch: (req, resp, next) ->
    # look for admin credentials in basic auth, and if valid, login user as admin.
    credentials = basic_auth(req);
    if credentials and credentials.name == 'admin' and credentials.pass = conf.COUCH_PWD
        req.session.user = 'admin'

    # add to the request a couch client tied to the logged in user
    req.couch = couch_utils.nano_user(req.session.user)

    if req.session.user == 'admin'
      return next()
    else
      return resp.status(401).end(JSON.stringify({error: "unauthorized", msg: "You are not authorized."}))
