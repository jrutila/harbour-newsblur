/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "api.js" as FeedlyAPI
import "../feedlib/lib/dbmanager.js" as DB

QtObject {
    id: feedly

    property string userId: ""
    property string refreshToken: ""
    property string accessToken: ""
    property string expires: ""
    property bool signedIn: false
    property bool busy: false
    property var pendingRequest: null
    property var currentEntry: null
    property string continuation: ""
    property int totalUnread: 0
    property int uniqueFeeds: 0
    property QtObject feedsListModel: null
    property QtObject articlesListModel: null
    property Item _statusIndicator: null
    property Item _errorIndicator: null
    property int page: 1

    signal error(string message)
    signal searchFeedCompleted(var results)
    signal getCategoriesCompleted(var categories)
    signal entryUnsaved(int index)

    function streamIsTag(streamId) {
        // TODO: Implement
        return false;
    }
    function streamIsCategory(streamId) {
        // TODO: Implement
        return false;
    }

    /*
     * Return URL to sign in into Feedly
     */
    function getSignInUrl() {
        var url = FeedlyAPI.getUrl("auth", { 'response_type': 'code', 'client_id': feedlyClientId, 'redirect_uri': FeedlyAPI._redirectUri })
        console.log(url);
        return url;
    }

    /*
     * Parse URL and extract authorization code
     */
    function getAuthCodeFromUrl(url) {
        var retObj = { "authCode": "", "error": false };

        if ((url !== getSignInUrl()) && (url.indexOf(FeedlyAPI._redirectUri) >= 0)) {
            var startPos = url.indexOf("?");
            if (startPos >= 0) {
                var param = url.substring(startPos+1).split('&');
                for (var p in param)
                {
                    var key = param[p].split("=")[0];
                    if (key == "code")
                        retObj.authCode = param[p].split("=")[1];
                }
                // DEBUG
                // console.log("Feedly auth code: " + retObj.authCode);
            } else {
                retObj.error = true;
            }
        }
        return retObj;
    }

    /*
     * Check API response for authentication errors
     */
    function checkResponse(retObj, callback) {
        var retval = false;

        switch(retObj.status) {
            case 200:
                retval = true;
                break;
            case 401:
                pendingRequest = new Object({ "method": retObj.callMethod, "param": retObj.callParams, "callback": callback });
                getAccessToken();
                break;
            default:
                // DEBUG
                // console.log(JSON.stringify(retObj));
                busy = false;
                error("");
                break;
        }

        return retval;
    }

    /*
     * Reset authorization
     */
    function resetAuthorization() {
        userId = "";
        accessToken = "";
        expires = "";
        refreshToken = ""
        signedIn = false;
        DB.saveAuthTokens(feedly);
    }

    /*
     * Reset object's properties
     */
    function resetProperties() {
        busy = false; // Experimental
        pendingRequest = null;
        currentEntry = null;
        continuation = "";
        totalUnread = 0;
        uniqueFeeds = 0;
        if (feedsListModel) feedsListModel.clear();
        if (articlesListModel) articlesListModel.clear();
    }

    /*
     * Get access and refresh tokens
     */
    function getAccessToken(authCode) {
        var param;

        if (authCode || refreshToken) {
            if (authCode) {
                param = { "code": authCode, "client_id": feedlyClientId, "client_secret": feedlyClientSecret, "redirect_uri": FeedlyAPI._redirectUri, "grant_type": "authorization_code" };
            } else {
                param = { "refresh_token": refreshToken, "client_id": feedlyClientId, "client_secret": feedlyClientSecret, "grant_type": "refresh_token" };
            }
            busy = true;
            FeedlyAPI.call("authRefreshToken", param, accessTokenDoneCB);
        } else error(qsTr("Neither authCode nor refreshToken found."));
    }

    function accessTokenDoneCB(retObj) {
        if (retObj.status == 200) {
            userId = "default" //retObj.response.id;
            accessToken = retObj.response.access_token;
            var tmpDate = new Date();
            tmpDate.setSeconds(tmpDate.getSeconds() + retObj.response.expires_in);
            expires = tmpDate.getTime();
            if (typeof retObj.response.refresh_token !== "undefined") refreshToken = retObj.response.refresh_token;
            signedIn = true;
            DB.saveAuthTokens(feedly);
            if (pendingRequest !== null) {
                FeedlyAPI.call(pendingRequest.method, pendingRequest.param, pendingRequest.callback);
                pendingRequest = null;
            } else busy = false;
        } else {
            // ERROR
            signedIn = false;
            busy = false;
            error(qsTr("Feedly authentication error"));
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Revoke refresh token
     */
    function revokeRefreshToken() {
        if (refreshToken) {
            var param = { "refresh_token": refreshToken, "client_id": feedlyClientId, "client_secret": feedlyClientSecret, "grant_type": "revoke_token" };
            busy = true;
            FeedlyAPI.call("authRefreshToken", param, revokeRefreshTokenDoneCB);
        } else error(qsTr("No refreshToken found."));
    }

    function revokeRefreshTokenDoneCB(retObj) {
        resetAuthorization();
        busy = false;
        if (retObj.status != 200) error(qsTr("Error revoking refreshToken"));
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Get subscriptions
     */
    function getSubscriptions() {
        busy = true;
        FeedlyAPI.call("subscriptions", null, subscriptionsDoneCB, accessToken);
    }

    function subscriptionsDoneCB(retObj) {
        if (checkResponse(retObj, subscriptionsDoneCB)) {
            var tmpSubscriptions = [];
            feedsListModel.clear();
            uniqueFeeds = 0;
            var positiveCount = 0;
            var neutralCount = 0;
            var resp = retObj.response;

            var addFeed = function(feed, category) {
                if (!feed) return;
                var model =
                        ({
                             "id": feed.id.toString(),
                             "title": feed.feed_title,
                             "category": category ? category : qsTr("Uncategorized"),
                                                    "categories": [],
                             "imgUrl": feed.favicon_url,
                             "unreadCount": feed.ng + feed.nt + feed.ps,
                                                    "positive": feed.ps,
                                                    "neutral": feed.nt,
                                                    "negative": feed.ng,
                                                    "lang": "",
                                                    "busy": false,
                         });
                positiveCount += feed.ps;
                neutralCount += feed.nt;
                tmpSubscriptions.push(model);
            }

            for (var f in resp.folders)
            {
                var folder = resp.folders[f];
                if (parseInt(folder) > 0)
                {
                    addFeed(resp.feeds[parseInt(folder)]);
                } else {
                    var folder_title = Object.keys(folder)[0];
                    for (var e in folder[folder_title])
                    {
                        addFeed(resp.feeds[folder[folder_title][e]], folder_title);
                    }
                }
            }

            // Sort subscriptions by category
            tmpSubscriptions.sort(function (a, b) {
                if (a.category > b.category) return 1;
                if (a.category < b.category) return -1;
                if (a.positive > b.positive) return -1;
                if (a.positive < b.positive) return 1;
                return 0;
            });
            if (tmpSubscriptions.length) {
                // Add "All feeds" fake subscription
                if (userId) {
                    /*
                    feedsListModel.append({ "id": "user/" + userId + "/tag/global.saved",
                                              "title": qsTr("Saved for later"),
                                              "category": "",
                                              "categories": [],
                                              "imgUrl": "",
                                              "lang": "",
                                              "unreadCount": 0,
                                              "busy": false });
                    */
                    feedsListModel.append({ "id": "user/" + userId + "/category/global.all",
                                              "title": qsTr("All feeds"),
                                              "category": "",
                                              "categories": [],
                                              "imgUrl": "",
                                              "lang": "",
                                              "neutral": neutralCount,
                                              "positive": positiveCount,
                                              "unreadCount": neutralCount+positiveCount,
                                              "busy": false });
                    feedsListModel.append({ "id": "user/" + userId + "/category/global.positive",
                                              "title": qsTr("Important"),
                                              "category": "",
                                              "categories": [],
                                              "imgUrl": "",
                                              "lang": "",
                                              "positive": positiveCount,
                                              "unreadCount": positiveCount,
                                              "busy": false });
                }
                // Populate ListModel
                for (var i = 0; i < tmpSubscriptions.length; i++) {
                    feedsListModel.append(tmpSubscriptions[i]);
                }
            }
        }
        busy = false;
        if (feedsListModel.count > 0) {
            getMarkersCounts();
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Get markers counts
     */
    function getMarkersCounts() {
        if (accessToken) {
            busy = true;
            FeedlyAPI.call("markersCounts", null, markersCountsDoneCB, accessToken);
        } else error(qsTr("No accessToken found."));
    }

    function markersCountsDoneCB(retObj) {
        if (checkResponse(retObj, markersCountsDoneCB)) {
            for (var feed_id in retObj.response.feeds)
            {
                var tmpObj = retObj.response.feeds[feed_id];
                tmpObj.count = tmpObj.ps + tmpObj.nt + tmpObj.ng;
                var tmpTotUnreadUpd = false;
                for (var j = 0; j < feedsListModel.length; j++)
                {
                    if (feedsListModel.get(j).id === feed_id) {
                        feedsListModel.setProperty(j, "unreadCount", tmpObj.count);
                        if (userId) {
                            if (tmpObj.id === ("user/" + userId + "/category/global.all")) totalUnread = tmpObj.count;
                        } else {
                            if (!tmpTotUnreadUpd) {
                                totalUnread += tmpObj.count;
                                tmpTotUnreadUpd = true;
                            }
                        }
                    }
                }
            }
            busy = false;
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Get stream content (subscribed feeds)
     */
    function getStreamContent(subscriptionId, more) {
        if (subscriptionId) {
            busy = true;
            if (!more) page = 1;
            else page++;
            var param = { "streamId": subscriptionId, "read_filter": "unread", 'page': page };
            FeedlyAPI.call("streamContent", param, streamContentDoneCB, accessToken);
        } else error(qsTr("No subscriptionId found."));
    }

    function streamContentDoneCB(retObj) {
        if (checkResponse(retObj, streamContentDoneCB)) {
            var stripHtmlTags = new RegExp("<[^>]*>", "gi");
            var normalizeSpaces = new RegExp("\\s+", "g");
            if (!retObj.callParams.page) articlesListModel.clear();
            continuation = true;
            var streamTitle = "-";

            for (var j = 0; j < feedsListModel.count; j++) {
                var feed = feedsListModel.get(j);
                if (feed && feed.id === retObj.callParams['streamId'])
                    streamTitle = feed.title;
            }

            if (Array.isArray(retObj.response.stories)) {
                for (var i = 0; i < retObj.response.stories.length; i++) {
                    var tmpObj = retObj.response.stories[i];
                    // Create updated date object
                    var tmpUpd = new Date(tmpObj.story_date);
                    // Extract date part
                    var tmpUpdDate = new Date(tmpUpd.getFullYear(), tmpUpd.getMonth(), tmpUpd.getDate());
                    // Create article summary
                    var tmpSummary = "" // No summaries in NewsBlur //((typeof tmpObj.story_title !== "undefined") ? tmpObj.story_title : ((typeof tmpObj.story_content !== "undefined") ? tmpObj.story_content : ""));
                    if (tmpSummary) tmpSummary = tmpSummary.replace(stripHtmlTags, " ").replace(normalizeSpaces, " ").trim().substr(0, 320);
                    var article = { "id": tmpObj.story_hash,
                                               "title": ((typeof tmpObj.story_title !== "undefined") ? tmpObj.story_title : qsTr("No title")),
                                               "author": ((typeof tmpObj.story_authors !== "undefined") ? tmpObj.story_authors : qsTr("Unknown")),
                                               "updated": tmpUpd,
                                               "sectionLabel": Format.formatDate(tmpUpd, Formatter.TimepointSectionRelative),
                                               "imgUrl": (((typeof tmpObj.image_urls === "Array") && tmpObj.image_urls.length > 0) ? tmpObj.image_urls[0] : ""),
                                               "unread": !tmpObj.read_status,
                                               "summary": "", //(tmpSummary ? tmpSummary : qsTr("No preview")),
                                               "content": ((typeof tmpObj.story_content !== "undefined") ? tmpObj.story_content : ""),
                                               "contentUrl": ((typeof tmpObj.story_permalink !== "undefined") ? tmpObj.story_permalink : ""),
                                               "streamId": ((typeof tmpObj.story_feed_id !== "undefined") ? tmpObj.story_feed_id : retObj.response.feed_id),
                                               "streamTitle": streamTitle,
                                               "busy": false,
                                               "tagging": false,
                                               "priority": 0
                                             };
                    for (var ii in tmpObj.intelligence)
                    {
                        article.priority += tmpObj.intelligence[ii];
                    }

                    articlesListModel.append(article)
                }
            }
            busy = false;
            if (!retObj.callParams.page) getMarkersCounts();
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Mark feed as read
     */
    function markFeedAsRead(feedId, lastEntryId) {
        if (feedId) {
            var param = { "action": "markAsRead" };
            if (feedId.indexOf("/category/global.all") >= 0) {
                // "All feeds" actually is a category
                param.type = "categories";
                param.categoryIds = [feedId];
            } else {
                param.type = "feeds";
                param.feedIds = [feedId];
            }
            if (lastEntryId) param.lastReadEntryId = lastEntryId;
            else param.asOf = Date.now();
            FeedlyAPI.call("markers", param, markFeedAsReadDoneCB, accessToken);
        } else error(qsTr("No feedId found."));
    }

    function markFeedAsReadDoneCB(retObj) {
        if (checkResponse(retObj, markFeedAsReadDoneCB)) {
            if (articlesListModel.count > 0) {
                var lastModelIndex = ((typeof retObj.callParams.lastReadEntryId !== "undefined") ? -1 : 0);
                for (var i = 0; i < articlesListModel.count; i++) {
                    if ((lastModelIndex === -1) && (articlesListModel.get(i).id === retObj.callParams.lastReadEntryId)) lastModelIndex = i;
                    if ((lastModelIndex >= 0) && (i >= lastModelIndex)) articlesListModel.setProperty(i, "unread", false);
                }
            }
            busy = false;
            getMarkersCounts();
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Mark entry
     * Possible actions are: markAsRead, keepUnread, markAsSaved, markAsUnsaved
     */
    function markEntry(entryId, action) {
        var actions = ["markAsRead", "keepUnread", "markAsSaved", "markAsUnsaved"];
        if (actions.indexOf(action) >= 0) {
            if (entryId) {
                // Set item indicator accordingly to action
                if (articlesListModel.count > 0) {
                    for (var i = 0; i < articlesListModel.count; i++) {
                        if (articlesListModel.get(i).id === entryId) {
                            switch (action) {
                                case "markAsRead":
                                case "keepUnread":
                                    articlesListModel.setProperty(i, "busy", true);
                                    break;
                                case "markAsSaved":
                                case "markAsUnsaved":
                                    articlesListModel.setProperty(i, "tagging", true);
                                    break;
                            }
                        }
                    }
                }
                var route = "";
                if (action == "markAsRead") route = "mark_story_hashes_as_read";
                if (action == "keepUnread") route = "mark_story_hash_as_unread";

                var param = { "story_hash": entryId, "action": action, "route": route };
                FeedlyAPI.call("markers", param, markEntryDoneCB, accessToken);
            } else error(qsTr("No entryId found."));
        } else error(qsTr("Unknown marker action."));
    }

    function markEntryDoneCB(retObj) {
        var entryId = retObj.callParams.story_hash;
        var articleIdx = -1;
        var streamId = "";
        if (entryId && (articlesListModel.count > 0)) {
            for (var i = 0; i < articlesListModel.count; i++) {
                if (articlesListModel.get(i).id === entryId) {
                    switch (retObj.callParams.action) {
                        case "markAsRead":
                        case "keepUnread":
                            articlesListModel.setProperty(i, "busy", false);
                            break;
                        case "markAsSaved":
                        case "markAsUnsaved":
                            articlesListModel.setProperty(i, "tagging", false);
                            break;
                    }
                    articleIdx = i;
                    streamId = articlesListModel.get(i).streamId;
                }
            }
        }
        if (checkResponse(retObj, markEntryDoneCB)) {
            if (articleIdx >= 0) {
                var article = articlesListModel.get(articleIdx);
                var unreadCountChanged = false;
                switch (retObj.callParams.action) {
                    case "markAsRead":
                        if (articlesListModel.get(articleIdx).unread) {
                            articlesListModel.setProperty(articleIdx, "unread", false);
                            unreadCountChanged = true;
                        }
                        break;
                    case "keepUnread":
                        if (!articlesListModel.get(articleIdx).unread) {
                            articlesListModel.setProperty(articleIdx, "unread", true);
                            unreadCountChanged = true;
                        }
                        break;
                    case "markAsSaved":
                        break;
                    case "markAsUnsaved":
                        entryUnsaved(articleIdx);
                        break;
                }
                if (unreadCountChanged) {
                    var allFeedsIdx = -1;
                    for (var j = 0; j < feedsListModel.count; j++) {
                        if (feedsListModel.get(j).id.indexOf("/category/global.all") >= 0) allFeedsIdx = j;
                        if (feedsListModel.get(j).id === streamId.toString()) {
                            var pr = "neutral";
                            if (article.priority > 0) pr = "positive";
                            var tmpUnreadCount = feedsListModel.get(j)[pr];
                            if ((retObj.callParams.action === "markAsRead") && (tmpUnreadCount > 0)) tmpUnreadCount--;
                            else if (retObj.callParams.action === "keepUnread") tmpUnreadCount++;
                            feedsListModel.setProperty(j, pr, tmpUnreadCount);
                        }
                    }
                    if ((retObj.callParams.action === "markAsRead") && (totalUnread > 0)) totalUnread--;
                    else if (retObj.callParams.action === "keepUnread") totalUnread++;
                    if (allFeedsIdx >= 0) feedsListModel.setProperty(allFeedsIdx, "unreadCount", totalUnread);
                }
            }
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Search feed
     */
    function searchFeed(searchString) {
        if (searchString) {
            var param = { "q": searchString, "n": 20, "locale": Qt.locale().name };
            FeedlyAPI.call("searchFeed", param, searchFeedDoneCB, accessToken);
        } else error(qsTr("No search string or URL given."));
    }

    function searchFeedDoneCB(retObj) {
        if (checkResponse(retObj, searchFeedDoneCB)) {
            var results = [];
            if (Array.isArray(retObj.response.results)) {
                for (var i = 0; i < retObj.response.results.length; i++) {
                    var tmpObj = retObj.response.results[i];
                    results.push({ "id": tmpObj.feedId,
                                   "title": tmpObj.title,
                                   "description": ((typeof tmpObj.description !== "undefined") ? tmpObj.description : ""),
                                   "imgUrl": ((typeof tmpObj.visualUrl !== "undefined") ? tmpObj.visualUrl : ""),
                                   "lang": ((typeof tmpObj.language !== "undefined") ? tmpObj.language : ""),
                                   "subscribers": tmpObj.subscribers });
                }
            }
            searchFeedCompleted(results);
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Update subscription
     */
    function updateSubscription(subscriptionId, title, categories) {
        if (subscriptionId) {
            busy = true;
            var param = { "id": subscriptionId }
            if (title) param.title = title;
            if (Array.isArray(categories) && categories.length) param.categories = categories
            FeedlyAPI.call("updateSubscription", param, updateSubscriptionDoneCB, accessToken);
        } else error(qsTr("No subscriptionId found."))
    }

    function updateSubscriptionDoneCB(retObj) {
        if (checkResponse(retObj, updateSubscriptionDoneCB)) {
            busy = false;
            getSubscriptions();
        }
        // DEBUG
        // console.log(JSON.stringify(retObj));
    }

    /*
     * Unsubscribe
     */
    function unsubscribe(subscriptionId) {
        if (subscriptionId) {
            // Mark single feed item as busy
            for (var j = 0; j < feedsListModel.count; j++) {
                if (feedsListModel.get(j).id === subscriptionId) feedsListModel.setProperty(j, "busy", true);
            }
            FeedlyAPI.call("unsubscribe", subscriptionId, unsubscribeDoneCB, accessToken);
        } else error(qsTr("No subscriptionId found."))
    }

    function unsubscribeDoneCB(retObj) {
        var unreadCount = 0;
        var j = 0;
        if (retObj.callParams) {
            for (j = 0; j < feedsListModel.count; j++) {
                if (feedsListModel.get(j).id === retObj.callParams) {
                    feedsListModel.setProperty(j, "busy", false);
                    if (!unreadCount) unreadCount = feedsListModel.get(j).unreadCount;
                }
            }
        }
        if (checkResponse(retObj, unsubscribeDoneCB)) {
            for (j = 0; j < feedsListModel.count; j++) {
                if (feedsListModel.get(j).id.indexOf("/category/global.all") >= 0) {
                    feedsListModel.setProperty(j, "unreadCount", (feedsListModel.get(j).unreadCount - unreadCount));
                }
                if (feedsListModel.get(j).id === retObj.callParams) feedsListModel.remove(j);
            }
        }
    }

    /*
     * Get categories
     */
    function getCategories() {
        busy = true;
        FeedlyAPI.call("categories", null, categoriesDoneCB, accessToken);
    }

    function categoriesDoneCB(retObj) {
        if (checkResponse(retObj, categoriesDoneCB)) {
            var categories;
            if (Array.isArray(retObj.response)) categories = retObj.response;
            else categories = [];
            busy = false;
            getCategoriesCompleted(categories);
        }
    }

    /*
     * Load status indicator item when needed
     */
    function _createStatusIndicator() {
        var retVal = true;

        if (_statusIndicator === null) {
            var component = Qt.createComponent("StatusIndicator.qml");
            if (component.status === Component.Ready) _statusIndicator = component.createObject(null);
            else retVal = false;
        }
        return retVal;
    }

    /*
     * Load status indicator item when needed
     */
    function _createErrorIndicator() {
        var retVal = true;

        if (_errorIndicator === null) {
            var component = Qt.createComponent("ErrorIndicator.qml");
            if (component.status === Component.Ready) _errorIndicator = component.createObject(null);
            else retVal = false;
        }
        return retVal;
    }

    /*
     * Reparent status indicator item
     */
    function acquireStatusIndicator(container) {
        if (_createStatusIndicator()) _statusIndicator.parent = container;
    }

    /*
     *
     */
    function acquireErrorIndicator(container) {
        if (_createErrorIndicator()) _errorIndicator.parent = container;
    }

    onBusyChanged: {
        if (_createStatusIndicator()) _statusIndicator.visible = busy;
    }

    onSignedInChanged: {
        if (signedIn) getSubscriptions();
        else resetProperties();
    }

    onError: {
        if (_createErrorIndicator()) _errorIndicator.show(message);
    }

    Component.onCompleted: {
        var useTest = (feedlyClientId === "sandbox");
        FeedlyAPI.init(useTest);
        feedsListModel = Qt.createQmlObject('import QtQuick 2.0; ListModel { }', feedly);
        articlesListModel = Qt.createQmlObject('import QtQuick 2.0; ListModel { }', feedly);
        DB.getAuthTokens(feedly);
        if (refreshToken) {
            var tmpDate = new Date();
            tmpDate.setHours(tmpDate.getHours() + 1);
            if (!accessToken || (expires < tmpDate.getTime())) getAccessToken();
            else signedIn = true;
        }
    }
}
