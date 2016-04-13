var cookies = require('cookie-parser');
var express = require('express');
var app = module.exports = express();
var main = require('../../package.json').main;
var ftoggleLib = require('../../' + main);

var ftoggle = new ftoggleLib();
ftoggle.setConfig(require('./ftoggle.js')).addConfig(require('./config.js'));

app.use(cookies());
app.use(ftoggle.createConfig);

app.get('/ftoggle-config', function(req, res, next) {
  req.jsonResponse = req.ftoggle.toggleConfig;
  next();
});

app.get('/features', function(req, res, next) {
  req.jsonResponse = req.ftoggle.getFeatureVals();
  next();
});

app.get('/isFeatureEnabled/:feature', function(req, res, next) {
  req.jsonResponse = { enabled: req.ftoggle.isFeatureEnabled(req.params.feature) };
  next();
});

app.get('/findEnabledChildren/:feature?', function(req, res, next) {
  req.jsonResponse = req.ftoggle.findEnabledChildren(req.params.feature);
  next();
});

app.get('/doesFeatureExist/:feature', function(req, res, next) {
  req.jsonResponse = { exists: req.ftoggle.doesFeatureExist(req.params.feature) };
  next();
});

app.get('/featureVal/:name', function(req, res, next) {
  req.jsonResponse = { val: req.ftoggle.featureVal(req.params.name) };
  next();
});

app.get('/user-config', function(req, res, next) {
  req.jsonResponse = req.ftoggle.config;
  next();
});

app.get('/enable/:feature', function(req, res, next) {
  req.ftoggle.enable(req.params.feature);
  req.jsonResponse = req.ftoggle.config;
  next();
});

app.get('/disable/:feature', function(req, res, next) {
  req.ftoggle.disable(req.params.feature);
  req.jsonResponse = req.ftoggle.config;
  next();
});

app.use(ftoggle.setCookie);
app.use(function(req, res, next) {
  res.status(200).json(req.jsonResponse);
});

app.listen(8009, function() {
  console.log('Test server listening');
});
