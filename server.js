/*
 * Basic Node.js express server that runs a socket.io instance
 * to mirror all data sent by one client to all others (in the same
 * socket.io room)
 */
var PORT = process.env.PORT ? process.env.PORT : 8008;

// Preliminaries
var express = require('express'),
    compression = require('compression'),
    app = express(),
    http = require('http'),
    server = http.createServer(app),
    path = require('path');

//render the jade templates
app.set('views', path.join(__dirname + '/html'));
app.set('view engine', 'jade');

// when sending the files make them compressed
app.use(compression());
// Statically serve pages from the public directory
app.use(express.static(__dirname + '/html'));

// now the server will by default render the jade!!!
app.get('/', function(req, res, next){
    res.render('main');
});

// Start the server
server.listen(PORT);
console.log('Server listening on port ' + PORT);
