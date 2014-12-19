.pragma library

// Newsblur api

Qt.include("../feedlib/lib/api.js")

var _redirectUri = "https://feedhaven.com";
var _apiCalls = {
    "auth": { "method": "GET", "protocol": "https", "url": "account/authorize/" },
    "authRefreshToken": { "method": "POST", "protocol": "https", "url":  "account/token/" },
    "subscriptions": { "method": "GET", "protocol": "http", "url": "reader/feeds" },
    "markers": { "method": "POST", "protocol": "http", "url": "reader/:route" },
    "markersCounts": { "method": "GET", "protocol": "http", "url": "reader/refresh_feeds" },
    "streamContent": { "method": "GET", "protocol": "http", "url": "reader/feed/:streamId" },
    "entries": { "method": "GET", "protocol": "http", "url": "entries" },
    "searchFeed": { "method": "GET", "protocol": "http", "url": "search/feeds" },
    "updateSubscription": { "method": "POST", "protocol": "https", "url": "subscriptions"},
    "unsubscribe": { "method": "DELETE", "protocol": "https", "url": "subscriptions"},
    "categories": { "method": "GET", "protocol": "http", "url": "categories" }
}

var _apiCallBack = function(useTest) {
    if (useTest) return "dev.newsblur.com/";
    return "www.newsblur.com/";
}
