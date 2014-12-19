/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license
*/

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#ifndef NEWSBLUR_CLIENT_ID
#define NEWSBLUR_CLIENT_ID "sandbox"
#endif

#ifndef NEWSBLUR_CLIENT_SECRET
#define NEWSBLUR_CLIENT_SECRET ""
#endif

#ifndef APP_VERSION
#define APP_VERSION "0.0"
#endif

#include <QScopedPointer>
#include <QVariant>
#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <sailfishapp.h>


int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/template.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //
    // To display the view, call "show()" (will show fullscreen on device).

//    return SailfishApp::main(argc, argv);

    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

//    app->setOrganizationName("Cthulhu Scrolls");
//    app->setOrganizationDomain("cthulhuscrolls.com");
//    app->setApplicationName("harbour-feedhaven");
    app->setApplicationVersion(QString(APP_VERSION));

    view->rootContext()->setContextProperty(QString("feedlyClientId"), QVariant(NEWSBLUR_CLIENT_ID));
    view->rootContext()->setContextProperty(QString("feedlyClientSecret"), QVariant(NEWSBLUR_CLIENT_SECRET));
    view->setSource(SailfishApp::pathTo(QString("qml/harbour-newsblur.qml")));
    view->show();
    return app->exec();
}

