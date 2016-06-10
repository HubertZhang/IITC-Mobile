// ==UserScript==
// @id             iitc-plugin-canvas-render@jonatkins
// @name           IITC plugin: Use Canvas rendering
// @category       Tweaks
// @version        0.1.0.20150917.154202
// @namespace      https://github.com/jonatkins/ingress-intel-total-conversion
// @updateURL      https://secure.jonatkins.com/iitc/release/plugins/canvas-render.meta.js
// @downloadURL    https://secure.jonatkins.com/iitc/release/plugins/canvas-render.user.js
// @description    [jonatkins-2015-09-17-154202] EXPERIMENTAL: use canvas-based rendering. Can be faster when viewing dense areas. Limited testing of the feature so far
// @include        https://www.ingress.com/intel*
// @include        http://www.ingress.com/intel*
// @match          https://www.ingress.com/intel*
// @match          http://www.ingress.com/intel*
// @include        https://www.ingress.com/mission/*
// @include        http://www.ingress.com/mission/*
// @match          https://www.ingress.com/mission/*
// @match          http://www.ingress.com/mission/*
// @grant          unsafeWindow
// ==/UserScript==

// NON-STANDARD plugin - try and set the variable early, as
// we need this global variable set before leaflet initialises
window.L_PREFER_CANVAS = true;
if (typeof unsafeWindow !== 'undefined') unsafeWindow.L_PREFER_CANVAS = true;  //doesn't actually work... :/



function wrapper(plugin_info) {
// ensure plugin framework is there, even if iitc is not yet loaded
if(typeof window.plugin !== 'function') window.plugin = function() {};

//PLUGIN AUTHORS: writing a plugin outside of the IITC build environment? if so, delete these lines!!
//(leaving them in place might break the 'About IITC' page or break update checks)
plugin_info.buildName = 'jonatkins';
plugin_info.dateTimeVersion = '20150917.154202';
plugin_info.pluginId = 'canvas-render';
//END PLUGIN AUTHORS NOTE



// PLUGIN START ////////////////////////////////////////////////////////

// we need this global variable set before leaflet initialises
window.L_PREFER_CANVAS = true;

// use own namespace for plugin
window.plugin.canvasRendering = function() {};

window.plugin.canvasRendering.setup  = function() {

  // nothing we can do here - other than check that canvas rendering was enabled
  if (!L.Path.CANVAS) {
    dialog({
      title:'Canvas Render Warning',
      text:'The Canvas Rendering plugin failed to enable canvas rendering in leaflet. This will occur if it initialises too late.\n'
          +'Try re-ordering userscripts so Canvas Rendering is before the main IITC script.'
    });
  }

};

var setup =  window.plugin.canvasRendering.setup;

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


