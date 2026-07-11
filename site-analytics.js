(function () {
    "use strict";

    var measurementId = "G-3BN8PTSM9V";
    var productionHosts = {
        "greenforest.io": true,
        "www.greenforest.io": true
    };

    if (!productionHosts[window.location.hostname]) {
        return;
    }

    window.dataLayer = window.dataLayer || [];
    window.gtag = window.gtag || function () {
        window.dataLayer.push(arguments);
    };

    window.gtag("js", new Date());
    window.gtag("config", measurementId, {
        allow_google_signals: false,
        allow_ad_personalization_signals: false
    });

    function loadGoogleTag() {
        if (document.querySelector("script[data-greenforest-analytics]")) {
            return;
        }

        var script = document.createElement("script");
        script.async = true;
        script.fetchPriority = "low";
        script.dataset.greenforestAnalytics = "";
        script.src = "https://www.googletagmanager.com/gtag/js?id=" + encodeURIComponent(measurementId);
        document.head.appendChild(script);
    }

    // This file is loaded with `defer`, so parsing is already complete here.
    // Start the asynchronous tag request immediately: waiting for window.load
    // made analytics depend on every large article image finishing first and
    // missed short visits on image-heavy pages.
    loadGoogleTag();
}());
