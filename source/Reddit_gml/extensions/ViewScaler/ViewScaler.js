
function scale_canvas(baseWidth, baseHeight, targetWidth, targetHeight,callback) {
    var aspect = (baseWidth / baseHeight);
 
    // Calculate pixel ratio and new canvas size
    var pixelRatio = window.devicePixelRatio || 1;
    var backStoreRatio = (g_CurrentGraphics.webkitBackingStorePixelRatio || g_CurrentGraphics.mozBackingStorePixelRatio || g_CurrentGraphics.msBackingStorePixelRatio ||
                          g_CurrentGraphics.oBackingStorePixelRatio || g_CurrentGraphics.backingStorePixelRatio || 1);
    var pixelScale = pixelRatio / backStoreRatio;
 
    var scaledWidth = targetWidth * pixelScale;
    var scaledHeight = targetHeight * pixelScale;
 
    var posx = 0;
    var posy = 0;
    if ((scaledWidth / aspect) > scaledHeight) {
        var sW = scaledWidth;
        scaledWidth = scaledHeight * aspect;
        posx = Math.round(((sW - scaledWidth) / pixelScale) / 2);
        scaledWidth = Math.round(scaledWidth);
    } else {
        var sH = scaledHeight;
        scaledHeight = scaledWidth / aspect;
        posy = Math.round(((sH - scaledHeight) / pixelScale) / 2);
        scaledHeight = Math.round(scaledHeight);
    }
 
    // Update canvas size
	callback(null, null, JSON.stringify({ width: scaledWidth, height: scaledHeight, x: posx, y: posy }));
 
    // Scale back canvas with CSS
    if(pixelScale != 1) {
        canvas.style.width = (scaledWidth / pixelScale) + "px";
        canvas.style.height = (scaledHeight / pixelScale) + "px";
    } else {
        canvas.style.width = "";
        canvas.style.height = "";
    }
 
    // Update canvas scale
    if(typeof g_CurrentGraphics.scale === "function")
        g_CurrentGraphics.scale(pixelScale, pixelScale);
}

function view_scaler_resize_canvas(width,height, callback) {
    var displayWidth = window.innerWidth;
    var displayHeight = window.innerHeight;
  
    scale_canvas(width, height, displayWidth, displayHeight, callback);
}

