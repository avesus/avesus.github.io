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

    function scheduleGoogleTag() {
        if ("requestIdleCallback" in window) {
            window.requestIdleCallback(loadGoogleTag, { timeout: 3000 });
            return;
        }

        window.setTimeout(loadGoogleTag, 0);
    }

    if (document.readyState === "complete") {
        scheduleGoogleTag();
    } else {
        window.addEventListener("load", scheduleGoogleTag, { once: true });
    }
}());
