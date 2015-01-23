/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    readonly property string pageType: "about"

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    SilicaFlickable {
        id: aboutFlickable

        anchors.fill: parent
        contentHeight: header.height + aboutContainer.height

        PageHeader {
            id: header

            title: qsTr("About SailBlur")
        }

        Column {
            id: aboutContainer

            anchors.top: header.bottom
            width: (parent.width - (2 * Theme.paddingLarge))
            x: Theme.paddingLarge
            spacing: Theme.paddingLarge

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                wrapMode: Text.WordWrap
                text: qsTr("Version %1\n(C) 2015 by Luca Donaggio and Juho Rutila").arg(Qt.application.version)
            }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                linkColor: Theme.highlightColor
                text: qsTr("<p><i>SailBlur</i> is a native client for Newsblur.com on-line news reader service.</p>
    <p>You can <strike>search for and subscribe to new feeds, manage your feeds and</strike> access their content: as soon as you'll read an article, it will be marked as read on NewsBlur.com as well.</p>
    <p>This is an open source project released under the MIT license, source code is available <a href=\"https://github.com/jrutila/harbour-newsblur/\">here</a>.</p>
    <p>Issues or feature requests can be reported <a href=\"https://github.com/jrutila/harbour-newsblur/issues\">here</a>.</p>
    <p></p>")

                onLinkActivated: Qt.openUrlExternally(link)
            }
        }

        VerticalScrollDecorator { flickable: aboutFlickable }
    }
}
