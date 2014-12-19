import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    anchors { top: parent.top; left: parent.left; leftMargin: Theme.paddingLarge; right: parent.right; rightMargin: Theme.paddingLarge }
    height: Theme.itemSizeSmall
    visible: !busy

    Image {
        id: feedVisual

        readonly property string _defaultSource: "../../icons/icon-s-rss.png"

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: Theme.iconSizeSmall
        height: width
        fillMode: Image.PreserveAspectFit
        smooth: true
        clip: true
        source: (imgUrl ? imgUrl : _defaultSource)

        onStatusChanged: {
            if (status === Image.Error) source = _defaultSource;
        }
    }

    Label {
        anchors {
            left: feedVisual.right
            right: neutralCountLabel.left
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        truncationMode: TruncationMode.Fade
        text: title
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
    }

    Label {
        id: neutralCountLabel

        anchors {
            right: positiveCountLabel.left;
            verticalCenter: parent.verticalCenter;
            rightMargin: 5;
        }
        text: neutral
        visible: (neutral > 0)
        color: Theme.secondaryHighlightColor
        font.pointSize: Theme.fontSizeTiny
    }
    Label {
        id: positiveCountLabel

        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: positive;
        visible: (positive > 0)
        color: Theme.highlightColor
    }
}
