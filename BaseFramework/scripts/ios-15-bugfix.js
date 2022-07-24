var styles = `
    .leaflet-control-container .leaflet-top,
    .leaflet-control-container .leaflet-bottom {
        will-change: transform;
    }
`

var styleSheet = document.createElement("style")
styleSheet.innerHTML = styles
document.head.appendChild(styleSheet)
