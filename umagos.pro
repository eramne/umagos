QT += core
QT += quick
QT += gui
QT += qml

CONFIG(debug, debug|release){
    BUILDMODE = debug
} else {
    BUILDMODE = release
}

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

RESOURCES += \
    src/umagos.qrc

SOURCES += \
        src/main.cpp \
        src/utils/ImageTools.cpp

HEADERS += \
    src/utils/ImageTools.h

DISTFILES += \
    uncrustify.cfg

INCLUDEPATH += src/

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

#win32 {
#    # windows
#
#    contains(QMAKE_TARGET.arch, x86) {
#        #x86
#
#        freeimagelib.path = $$PWD/lib/FreeImage/x32
#    } else {
#        #x64
#
#        freeimagelib.path = $$PWD/lib/FreeImage/x64
#    }
#
#    LIBS += -L$$freeimagelib.path -lFreeImage
#    INCLUDEPATH += $$freeimagelib.path
#    DEPENDPATH += $$freeimagelib.path
#    QMAKE_PRE_LINK = \"C:\MinGW\msys\1.0\bin\cp.exe\" \"$$freeimagelib.path/FreeImage.dll\" \"$$OUT_PWD/$${BUILDMODE}/FreeImage.dll\"
#}

win32:CONFIG(release, debug|release): LIBS += -L$$PWD/lib/FreeImagePlus/release/ -lfreeimageplus
else:win32:CONFIG(debug, debug|release): LIBS += -L$$PWD/lib/FreeImagePlus/debug/ -lfreeimageplus
else:unix: LIBS += -L$$PWD/lib/FreeImagePlus/ -lfreeimageplus

INCLUDEPATH += $$PWD/lib/FreeImagePlus
DEPENDPATH += $$PWD/lib/FreeImagePlus

win32-g++:CONFIG(release, debug|release): PRE_TARGETDEPS += $$PWD/lib/FreeImagePlus/release/libfreeimageplus.a
else:win32-g++:CONFIG(debug, debug|release): PRE_TARGETDEPS += $$PWD/lib/FreeImagePlus/debug/libfreeimageplus.a
else:win32:!win32-g++:CONFIG(release, debug|release): PRE_TARGETDEPS += $$PWD/lib/FreeImagePlus/release/freeimageplus.lib
else:win32:!win32-g++:CONFIG(debug, debug|release): PRE_TARGETDEPS += $$PWD/lib/FreeImagePlus/debug/freeimageplus.lib
else:unix: PRE_TARGETDEPS += $$PWD/lib/FreeImagePlus/libfreeimageplus.a
