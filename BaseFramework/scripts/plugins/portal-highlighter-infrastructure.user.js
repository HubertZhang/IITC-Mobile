// ==UserScript==
// @id             iitc-plugin-highlight-portal-infrastructure@vita10gy
// @name           IITC plugin: highlight portals with infrastructure problems
// @category       Highlighter
// @version        0.2.1.20150917.154202
// @namespace      https://github.com/jonatkins/ingress-intel-total-conversion
// @updateURL      https://secure.jonatkins.com/iitc/release/plugins/portal-highlighter-infrastructure.meta.js
// @downloadURL    https://secure.jonatkins.com/iitc/release/plugins/portal-highlighter-infrastructure.user.js
// @description    [jonatkins-2015-09-17-154202] Use the portal fill color to denote if the portal has any infrastructure problems. Red: no picture. Yellow: potential title issue. Orange:  both of these.
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
plugin_info.pluginId = 'portal-highlighter-infrastructure';
//END PLUGIN AUTHORS NOTE



// PLUGIN START ////////////////////////////////////////////////////////

// use own namespace for plugin
window.plugin.portalInfrastructure = function() {};

window.plugin.portalInfrastructure.badTitles = ['^statue$',
                                                '^fountain$',
                                                '^sculpture$',
                                                '^post office$',
                                                '^us post office$',
                                                '^church$',
                                                'untitled',
                                                'no title'];

window.plugin.portalInfrastructure.highlight = function(data) {
  var d = data.portal.options.data;
  var color = '';
  var opa = .75;

  if(!(d.image)) {
    color = 'red';
  }

  if((new RegExp(window.plugin.portalInfrastructure.badTitles.join("|"),'i')).test(d.title)) {
    color = color == 'red' ? 'orange' : 'yellow';
    opa = .9;
  }
  
  if(color !== '') {
    var params = {fillColor: color, fillOpacity: opa};
    data.portal.setStyle(params);  
  }
 
}

var setup =  function() {
  window.addPortalHighlighter('Infrastructure', window.plugin.portalInfrastructure.highlight);
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


