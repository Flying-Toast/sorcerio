const express = require('express');
const socket = require('socket.io');

var exports = module.exports;

var app = express();

var port = process.env.PORT || '80';

var server = app.listen(port, function() {
  console.log('listening on port ' + port);
});

app.get('/tutorial', function(req, res) {
  res.sendFile(__dirname + '/public/tutorial.html');
});

app.get('/credits', function(req, res) {
  res.sendFile(__dirname + '/public/credits.txt');
});

app.get('/wiki', function(req, res) {
  res.sendFile(__dirname + '/public/wiki/wiki.html');
});

app.use('/', express.static('public'));

exports.io = socket(server);