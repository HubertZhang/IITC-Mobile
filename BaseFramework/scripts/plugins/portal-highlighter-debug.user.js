// ==UserScript==
// @id             iitc-plugin-highlight-portals-debug
// @name           IITC plugin: Debug: Highlighers
// @category       Debug
// @version        0.1.0.20150917.154202
// @namespace      https://github.com/jonatkins/ingress-intel-total-conversion
// @updateURL      https://secure.jonatkins.com/iitc/release/plugins/portal-highlighter-debug.meta.js
// @downloadURL    https://secure.jonatkins.com/iitc/release/plugins/portal-highlighter-debug.user.js
// @description    [jonatkins-2015-09-17-154202] Various debug and/or temporary highlighters. Will change over time as needed.
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
plugin_info.pluginId = 'portal-highlighter-debug';
//END PLUGIN AUTHORS NOTE



// PLUGIN START ////////////////////////////////////////////////////////

// use own namespace for plugin
window.plugin.portalHighlighterDebug = function() {};

//window.plugin.portalHighlighterDebug.unknown11 = function(data) {
//  var opacity = 0.7;
//  var color = undefined;
//
//  if (data.portal.options.data.unknown_11) {
//    color='red';
//  }
//
//  if (color) {
//    data.portal.setStyle({fillColor: color, fillOpacity: opacity});
//  }
//}

var setup =  function() {
//  window.addPortalHighlighter('DEBUG: Unknoen_11', window.plugin.portalHighlighterDebug.unknown11);
}

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


