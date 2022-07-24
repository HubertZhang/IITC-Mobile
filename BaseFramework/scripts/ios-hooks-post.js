if (window.script_info
    && window.script_info.script
    && window.script_info.script.version
    && window.script_info.script.version.startsWith("0.26.")) {
    window.isSmartphone = function () {
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
}

if (!document.querySelector('meta[name="viewport"]')) {
    var viewportMeta = document.createElement("meta")
    viewportMeta.name = "viewport"
    viewportMeta.content = "width=device-width,user-scalable=no,initial-scale=1,viewport-fit=cover"
    document.head.appendChild(viewportMeta)
}
