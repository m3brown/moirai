# copyright David Greisen licensed under Apache License v 2.0
# derived from code from ShareJS https://github.com/share/ShareJS (MIT)
path = require('path')
fs = require('fs')
Promise = require('pantheon-helpers/lib/promise')
prompt = require('prompt')
prompt_get = Promise.denodeify(prompt.get).bind(prompt);
{exec} = require 'child_process'
pExec = Promise.denodeify(exec)
_ = require('underscore')

DIR = __dirname

task 'build', 'Build the .js files', (options) ->
  console.log('Compiling Coffee from src to lib')
  cp = exec "coffee --compile --output ./lib/ ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

task 'watch', 'Watch src directory and build the .js files', (options) ->
  console.log('Watching Coffee in src and compiling to lib')
  cp = exec "coffee --watch --output ./lib/ ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

task 'runtestserver', 'Run the server (port 5001); restart on change', (options) ->
  console.log('Running the server on port 5001; restarting on change')
  cp = exec "coffee --watch --output ./lib/ ./src/"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)
  cp = exec "nodemon --watch ./lib --ignore ./lib/design_docs ./lib/app.js"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

task 'runworker', 'Run the couchdb worker', (options) ->
  console.log('Running the couchdb worker')
  cp = exec "node ./lib/worker.js"
  cp.stdout.pipe(process.stdout)
  cp.stderr.pipe(process.stderr)

option '-t', '--db_type [type]', 'db type to update'

task 'sync_design_docs', 'sync all design docs with couchdb (options: -t [type])', (options) ->
  if options.db_type
    db_types = [options.db_type]
  else
    design_docs_dir = path.join(DIR, 'lib', 'design_docs')
    design_docs = fs.readdirSync(design_docs_dir)
    db_types = []
    design_docs.forEach((file_name) ->
      file_parts = file_name.split('.')
      db_types.push(file_parts[0]) if file_parts[1] == 'js'
    )
  for db_type in db_types
    console.log('Syncing couchdb ' + db_type + ' design docs ')
    require('./lib/couch_utils').sync_all_db_design_docs(db_type)

option '-v', '--verbose', 'verbose testing output'

task 'test', 'run all tests', (options) ->
  Promise.exec("./node_modules/coffee-script/bin/coffee --bare --compile --output ./spec/ ./spec/").then(() ->
    cmd = "./node_modules/istanbul/lib/cli.js cover ./node_modules/jasmine-node/bin/jasmine-node ./spec"
    cmd += if options.verbose then "--verbose " else ""
    cmd += " ./spec/"

    cp = exec(cmd)
    cp.stdout.pipe(process.stdout)
    cp.stderr.pipe(process.stderr)
    cp.on('exit', (code) -> process.exit(code))
  )

task 'start_design_doc', 'create a new kanso design doc directory', (options) ->
  prompt_get = Promise.denodeify(prompt.get).bind(prompt);
  console.log('')
  prompt.start()
  prompt_get({
    properties: {
      'name': {
        required: true
      },
      'description': {
        required: true
      },
    }
  }).then((resp) ->
    DD_SRC_DIR = path.join(DIR, 'src', 'design_docs', resp.name)
    DD_LIB_DIR = path.join(DIR, 'lib', 'design_docs', resp.name)
    TEMPLATE_DIR = path.join(DIR, 'node_modules', 'pantheon-helpers', 'templates', 'design_doc')

    console.log('\nMaking design doc dirs...')
    fs.mkdirSync(DD_SRC_DIR)
    fs.mkdirSync(DD_LIB_DIR)

    console.log('\nCopying files...')
    pExec('cp -r ' + path.join(TEMPLATE_DIR, 'src', '*') + ' ' + DD_SRC_DIR).then(() ->
      pExec('cp -r ' + path.join(TEMPLATE_DIR, 'lib', '*') + ' ' + DD_LIB_DIR)
    ).then(() ->
      console.log('\nCustomizing kanso.json...')
      KANSO_PATH = path.join(DD_LIB_DIR, 'kanso.json')
      console.log(KANSO_PATH)
      kanso_raw = fs.readFileSync(KANSO_PATH, 'utf8')
      console.log(kanso_raw)
      kanso = JSON.parse(kanso_raw)
      _.extend(kanso, resp)
      console.log(kanso)
      new_kanso_raw =JSON.stringify(kanso)
      console.log(new_kanso_raw)
      f = fs.openSync(KANSO_PATH, 'w')
      fs.writeSync(f, new_kanso_raw)

      fs.symlinkSync('../../../../node_modules/pantheon-helpers/', path.join(DD_LIB_DIR, 'packages', 'pantheon-helpers'))

      console.log('\nCleaning up...')
      cleanup = [DD_SRC_DIR, DD_LIB_DIR].map((subdir_path) ->
        return pExec("find . -type f -name '.empty' -exec rm {} +", {cwd: subdir_path});
      )
      Promise.all(cleanup);
    ).then(() ->
      console.log('\nRunning Kanso install...')
      pExec("kanso install", {cwd: DD_LIB_DIR})
    ).then(() ->
      console.log('\nBuilding coffeescript...')
      pExec("cake build", {cwd: DIR})
    ).then(() ->
      console.log('\nNEW DESIGN DOC READY at ' + DD_SRC_DIR)
      console.log()
    )
  ).catch((err) ->
    console.log('ERR:', err)
  )
