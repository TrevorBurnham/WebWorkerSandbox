crypto   = require 'crypto'
express  = require 'express'
fs       = require 'fs'
mongoose = require 'mongoose'
stylus   = require 'stylus'

# Connect to MongoDB
{username, password, address, db} = JSON.parse(fs.readFileSync('mongodb.json'))
mongoose.connect "mongodb://#{username}:#{password}@#{address}/#{db}"

StateSchema = new mongoose.Schema
  master: {type: String, set: ((m) -> @masterHash = makeHash(m); m)}
  worker: {type: String, set: ((w) -> @workerHash = makeHash(w); w)}
  masterHash: {type: String, index: true}
  workerHash: {type: String, index: true}
State = mongoose.model 'State', StateSchema

defaultStateId = '4f5113f03cf7dc5636000011'

# Initialize server
app = express.createServer()
app.set 'view options', layout: false
app.use express.logger('dev')
app.use express.staticCache()
app.use express.static('public')
app.use stylus.middleware({
  src:  'stylesheets'
  dest: 'public'
  compile: (str, path) ->
    stylus(str)
    .use(require('nib')())
    .set('compress', true)
    .set('filename', path)
    .set('include css', true)
})
app.use express.bodyParser()
app.use express.cookieParser()

# Routes
app.get '/worker.js', (req, res, next) ->
  State.findById req.cookies.state_id, (err, state) ->
    return next(err) if err
    res.contentType 'worker.js'
    res.end state.worker

app.get '/:id', defaultRouteHandler = (req, res, next) ->
  {id} = req.params
  id ?= defaultStateId
  State.findById id, (err, state) ->
    return next(err) if err
    res.cookie 'state_id', id
    res.render 'index.ejs', {state}

app.get '/', defaultRouteHandler

app.post '/run', (req, res, next) ->
  {master, worker} = req.body
  state = new State({master, worker})
  {masterHash, workerHash} = state
  # Check if this is a duplicate
  State.findOne {masterHash, workerHash}, (err, matchingState) ->
    return next(err) if err
    if matchingState
      res.redirect "/#{matchingState._id}"
    else
      state.save (err) ->
        return next(err) if err
        res.redirect "/#{state._id}"

port = if process.env.NODE_ENV is 'production' then 80 else 5555
app.listen port
console.log "WebWorkerSandbox is running on port #{port}"

# Utility functions
makeHash = (raw) -> crypto.createHash('sha256').update(raw).digest('base64')
