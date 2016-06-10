// ==UserScript==
// @id             iitc-plugin-basemap-kartverket@sollie
// @name           IITC plugin: Kartverket.no map tiles
// @category       Map Tiles
// @version        0.1.0.20150917.154202
// @namespace      https://github.com/jonatkins/ingress-intel-total-conversion
// @updateURL      https://secure.jonatkins.com/iitc/release/plugins/basemap-kartverket.meta.js
// @downloadURL    https://secure.jonatkins.com/iitc/release/plugins/basemap-kartverket.user.js
// @description    [jonatkins-2015-09-17-154202] Add the color and grayscale map tiles from Kartverket.no as an optional layer.
// @include        https://www.ingress.com/intel*
// @include        http://www.ingress.com/intel*
// @match          https://www.ingress.com/intel*
// @match          http://www.ingress.com/intel*
// @include        https://www.ingress.com/mission/*
// @include        http://www.ingress.com/mission/*
// @match          https://www.ingress.com/mission/*
// @match          http://www.ingress.com/mission/*
// @grant          none
// ==/UserScript==


function wrapper(plugin_info) {
// ensure plugin framework is there, even if iitc is not yet loaded
if(typeof window.plugin !== 'function') window.plugin = function() {};

//PLUGIN AUTHORS: writing a plugin outside of the IITC build environment? if so, delete these lines!!
//(leaving them in place might break the 'About IITC' page or break update checks)
plugin_info.buildName = 'jonatkins';
plugin_info.dateTimeVersion = '20150917.154202';
plugin_info.pluginId = 'basemap-kartverket';
//END PLUGIN AUTHORS NOTE



// PLUGIN START ////////////////////////////////////////////////////////


// use own namespace for plugin
window.plugin.mapTileKartverketMap = function() {};

window.plugin.mapTileKartverketMap.addLayer = function() {

  // Map data from Kartverket (http://statkart.no/en/)
  kartverketAttribution = 'Map data © Kartverket';
  var kartverketOpt = {attribution: kartverketAttribution, maxNativeZoom: 18, maxZoom: 21, subdomains: ['opencache', 'opencache2', 'opencache3']};
  var kartverketTopo2 = new L.TileLayer('http://{s}.statkart.no/gatekeeper/gk/gk.open_gmaps?layers=topo2&zoom={z}&x={x}&y={y}', kartverketOpt);
  var kartverketTopo2Grayscale = new L.TileLayer('http://{s}.statkart.no/gatekeeper/gk/gk.open_gmaps?layers=topo2graatone&zoom={z}&x={x}&y={y}', kartverketOpt);

  layerChooser.addBaseLayer(kartverketTopo2, "Norway Topo");
  layerChooser.addBaseLayer(kartverketTopo2Grayscale, "Norway Topo Grayscale");
};

var setup =  window.plugin.mapTileKartverketMap.addLayer;

// PLUGIN END //////////////////////////////////////////////////////////


setup.info = plugin_info; //add the script info data to the function as a property
if(!window.bootPlugins) window.bootPlugins = [];
window.bootPlugins.push(setup);
// if IITC has already booted, immediately run the 'setup' function
if(window.iitcLoaded && typeof setup === 'function') setup();
} // wrapper end
// inject code into site context
var script = document.createElement('script');
var info = {};
if (typeof GM_info !== 'undefined' && GM_info && GM_info.script) info.script = { version: GM_info.script.version, name: GM_info.script.name, description: GM_info.script.description };
script.appendChild(document.createTextNode('('+ wrapper +')('+JSON.stringify(info)+');'));
(document.body || document.head || document.documentElement).appendChild(script);



