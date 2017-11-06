function Android() {
    this.copy = copy;
    function copy(text) {
        window.webkit.messageHandlers.ioscopy.postMessage(text);
    };

    this.reloadIITC = reloadIITC;
    function reloadIITC() {
        window.webkit.messageHandlers.reloadIITC.postMessage(null);
    };

    this.getFileRequestUrlPrefix = getFileRequestUrlPrefix;
    function getFileRequestUrlPrefix() {
        window.webkit.messageHandlers.getFileRequestUrlPrefix.postMessage(null);
    };

    // this.setActiveHighlighter = setActiveHighlighter;
    // function setActiveHighlighter(name) {
    //     window.webkit.messageHandlers.setActiveHighlighter.postMessage(name);
    // };

    this.setPermalink = setPermalink;
    function setPermalink(href) {
        window.webkit.messageHandlers.setPermalink.postMessage(href);
    };

    this.getVersionName = getVersionName;
    function getVersionName() {
        return "%@";
    };

    this.getVersionCode = getVersionCode;
    function getVersionCode() {
        return %d;
    };

    this.dialogOpened = dialogOpened;
    function dialogOpened(id, boolValue) {
        window.webkit.messageHandlers.dialogOpened.postMessage([id, boolValue]);
    };

    this.switchToPane = switchToPane;
    function switchToPane(id) {
        window.webkit.messageHandlers.switchToPane.postMessage(id);
    };

    this.setLayers = setLayers;
    function setLayers(baseLayersJSON, overlayLayersJSON) {
        window.webkit.messageHandlers.setLayers.postMessage([baseLayersJSON, overlayLayersJSON]);
    };

    this.dialogOpened = dialogOpened;
    function dialogOpened(id, boolValue) {
        window.webkit.messageHandlers.dialogOpened.postMessage([id, boolValue]);
    };

    // this.addPortalHighlighter = addPortalHighlighter;
    // function addPortalHighlighter(name) {
    //     window.webkit.messageHandlers.addPortalHighlighter.postMessage(name);
    // };

    this.spinnerEnabled = spinnerEnabled;
    function spinnerEnabled(boolValue) {
        window.webkit.messageHandlers.spinnerEnabled.postMessage(boolValue);
    };

    this.setProgress = setProgress;
    function setProgress(progress) {
        window.webkit.messageHandlers.setProgress.postMessage(progress);
    };

    this.bootFinished = bootFinished;
    function bootFinished() {
        window.webkit.messageHandlers.bootFinished.postMessage(null);
    };

    this.intentPosLink=intentPosLink;
    function intentPosLink(lat, lng, zoom, title, boolValue ){
        window.webkit.messageHandlers.intentPosLink.postMessage([lat,lng,zoom,title,boolValue]);
    };
    
    this.addPane=addPane;
    function addPane(name, label, icon) {
        window.webkit.messageHandlers.addPane.postMessage([name, label, icon]);
    }
}
var android=new Android();

window.isSmartphone = function() {
  // this check is also used in main.js. Note it should not detect
  // tablets because their display is large enough to use the desktop
  // version.

  // The stock intel site allows forcing mobile/full sites with a vp=m or vp=f
  // parameter - let's support the same. (stock only allows this for some
  // browsers - e.g. android phone/tablet. let's allow it for all, but
  // no promises it'll work right)
  var viewParam = getURLParam('vp');
  if (viewParam == 'm') return true;
  if (viewParam == 'f') return false;

  return navigator.userAgent.match(/Android.*Mobile/)
  || navigator.userAgent.match(/iPhone|iPad|iPod/i);
}

if(!window.bootPlugins) window.bootPlugins = [];