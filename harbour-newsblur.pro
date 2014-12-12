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

CONFIG += sailfishapp

SOURCES += src/harbour-newsblur.cpp

OTHER_FILES += qml/harbour-newsblur.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/SecondPage.qml \
    rpm/harbour-newsblur.changes.in \
    rpm/harbour-newsblur.spec \
    rpm/harbour-newsblur.yaml \
    translations/*.ts \
    harbour-newsblur.desktop

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
TRANSLATIONS += translations/harbour-newsblur-de.ts

