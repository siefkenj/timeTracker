/*
 * Basic Node.js express server that runs a socket.io instance
 * to mirror all data sent by one client to all others (in the same
 * socket.io room)
 */
var PORT = process.env.PORT ? process.env.PORT : 9000;

// Preliminaries
var express = require('express'),
    compression = require('compression'),
    app = express(),
    http = require('http'),
    server = http.createServer(app),
    coffeeMiddleware = require('coffee-middleware'),
    stylus = require('stylus'),
    nib = require('nib'),
    path = require('path');

//render the jade templates
app.set('views', [ path.join(__dirname + '/www'), path.join(__dirname + '/www/templates') ]);
app.set('view engine', 'jade');

// render coffeescript on the fly
app.use(coffeeMiddleware({
    dest: __dirname + '/www/js',
    src: __dirname + '/www/js',
    prefix: '/js',
    compress: true
}));

app.use(stylus.middleware({
    src: __dirname + '/www/css', 
    dest: __dirname + '/www/css', 
    compile: function (str, path) { 
        return stylus(str)
            .set('filename', path)
            .use(nib())
            .import('nib');
    }
}));

// when sending the files make them compressed
app.use(compression());
// Statically serve pages from the public directory
app.use(express.static(__dirname + '/www'));

// now the server will by default render the jade!!!
app.get('/', function(req, res, next){
    res.render('main');
});

app.get("/templates/:file", function(req, res, next){
    res.render(req.params.file.replace("html", 'jade'));
});

// Start the server
server.listen(PORT);
console.log('Server listening on port ' + PORT);
