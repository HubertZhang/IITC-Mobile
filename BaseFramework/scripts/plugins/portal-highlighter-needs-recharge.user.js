// ==UserScript==
// @id             iitc-plugin-highlight-needs-recharge@vita10gy
// @name           IITC plugin: hightlight portals that need recharging
// @category       Highlighter
// @version        0.1.2.20150917.154202
// @namespace      https://github.com/jonatkins/ingress-intel-total-conversion
// @updateURL      https://secure.jonatkins.com/iitc/release/plugins/portal-highlighter-needs-recharge.meta.js
// @downloadURL    https://secure.jonatkins.com/iitc/release/plugins/portal-highlighter-needs-recharge.user.js
// @description    [jonatkins-2015-09-17-154202] Use the portal fill color to denote if the portal needs recharging and how much. Yellow: above 85%. Orange: above 50%. Red: above 15%. Magenta: below 15%.
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
plugin_info.pluginId = 'portal-highlighter-needs-recharge';
//END PLUGIN AUTHORS NOTE



// PLUGIN START ////////////////////////////////////////////////////////

// use own namespace for plugin
window.plugin.portalHighlighterNeedsRecharge = function() {};

window.plugin.portalHighlighterNeedsRecharge.highlight = function(data) {
  var d = data.portal.options.data;
  var health = d.health;

  if(health !== undefined && data.portal.options.team != TEAM_NONE && health < 100) {
    var color,fill_opacity;
    if (health > 95) {
      color = 'yellow';
      fill_opacity = (1-health/100)*.50 + .50;
    } else if (health > 75) {
      color = 'DarkOrange';
      fill_opacity = (1-health/100)*.50 + .50;
    } else if (health > 15) {
      color = 'red';
      fill_opacity = (1-health/100)*.75 + .25;
    } else {
      color = 'magenta';
      fill_opacity = (1-health/100)*.75 + .25;
    }

    var params = {fillColor: color, fillOpacity: fill_opacity};
    data.portal.setStyle(params);
  }
}

var setup =  function() {
  window.addPortalHighlighter('Needs Recharge (Health)', window.plugin.portalHighlighterNeedsRecharge.highlight);
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


