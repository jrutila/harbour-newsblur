# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-newsblur

CONFIG += sailfishapp \
          sailfishapp_no_deploy_qml

SOURCES += src/harbour-newsblur.cpp

OTHER_FILES += qml/harbour-newsblur.qml \
    rpm/harbour-newsblur.changes.in \
    rpm/harbour-newsblur.spec \
    rpm/harbour-newsblur.yaml \
    translations/*.ts \
    harbour-newsblur.desktop \
    qml/feedlib/pages/SignInPage.qml \
    qml/feedlib/pages/FeedsListPage.qml \
    qml/feedlib/pages/FeedSearchPage.qml \
    qml/feedlib/pages/ArticlesListPage.qml \
    qml/feedlib/pages/ArticlePage.qml \
    qml/feedlib/pages/ArticleInfoPage.qml \
    qml/feedlib/pages/AboutPage.qml \
    qml/feedlib/cover/DefaultCover.qml \
    qml/feedlib/lib/dbmanager.js \
    qml/feedlib/lib/api.js \
    qml/feedlib/dialogs/UpdateFeedDialog.qml \
    qml/feedlib/dialogs/SelectCategoriesDialog.qml \
    qml/newsblur/api.js \
    qml/newsblur/FeedItem.qml \
    qml/newsblur/Api.qml \
    api-config.pri \
    qml/provider/api.js \
    qml/provider/FeedItem.qml \
    qml/provider/Api.qml \
    qml/provider/AboutPage.qml \
    qml/harbour-newsblur.qml

qml.files += qml
unix:qml.extra = rm -Rf /home/mersdk/share/SailfishProjects/harbour-newsblur/qml/feedlib/.git
qml.path = /usr/share/$${TARGET}
INSTALLS += qml

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
TRANSLATIONS += translations/harbour-newsblur-de.ts

# Feedly API keys
NEWSBLUR_API_CONFIG = api-config.pri
exists($${NEWSBLUR_API_CONFIG}) include($${NEWSBLUR_API_CONFIG})
