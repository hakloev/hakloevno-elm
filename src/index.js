// Require CSS/SASS here
require('../static/styles/main.scss');

// Inject Elm app into div#root
var Elm = require('./Main.elm');
var mountPoint = document.getElementById('root');

var app = Elm.Main.embed(mountPoint);
