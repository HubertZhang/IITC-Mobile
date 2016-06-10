// ==UserScript==
// @id             iitc-plugin-basemap-stamen@jonatkins
// @name           IITC plugin: Map layers from stamen.com
// @category       Map Tiles
// @version        0.2.0.20150917.154202
// @namespace      https://github.com/jonatkins/ingress-intel-total-conversion
// @updateURL      https://secure.jonatkins.com/iitc/release/plugins/basemap-stamen.meta.js
// @downloadURL    https://secure.jonatkins.com/iitc/release/plugins/basemap-stamen.user.js
// @description    [jonatkins-2015-09-17-154202] Add the 'Toner' and 'Watercolor' map layers from maps.stamen.com.
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
plugin_info.pluginId = 'basemap-stamen';
//END PLUGIN AUTHORS NOTE



// PLUGIN START ////////////////////////////////////////////////////////


// use own namespace for plugin
window.plugin.mapTileStamen = function() {};


window.plugin.mapTileStamen.addLayer = function() {

  var types = {
    'toner': [ 'Toner', 'png', 0, 20 ],
//    'toner-hybrid': [ ' Toner Hybrid', 'png', 0, 20 ],  // transparent layer. could be useful over satellite imagery or similar
//    'toner-labels': [ 'Toner Labels', 'png', 0, 20 ],  // transparent layer. could be useful over satellite imagery or similar
//    'toner-lines': [ 'Toner Lines', 'png', 0, 20 ],  // transparent layer. could be useful over satellite imagery or similar
    'toner-background': [ 'Toner Background', 'png', 0, 20 ],
    'toner-lite': [ 'Toner Lite', 'png', 0, 20 ],
    'watercolor': [ 'Watercolor', 'jpg', 1, 16 ],
  };

  var baseUrl = window.location.protocol == 'https:' ? 'https://stamen-tiles-{s}.a.ssl.fastly.net/' : 'http://{s}.tile.stamen.com/';


  for (var layer in types) {
    var info = types[layer];

    var name = info[0];
    var type = info[1];
    var minZoom = info[2];
    var maxZoom = info[3];

    var mapLayer = new L.TileLayer (baseUrl+'{layer}/{z}/{x}/{y}.{type}', {
      attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org">OpenStreetMap</a>, under <a href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>.',
      subdomains: 'abcd',    
      layer: layer,
      type: type,
      minZoom: minZoom,
      maxNativeZoom: maxZoom,
      maxZoom: 21
    });

    layerChooser.addBaseLayer(mapLayer,'Stamen '+name);
  }

};

var setup =  window.plugin.mapTileStamen.addLayer;

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


