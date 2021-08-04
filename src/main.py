
# This Python file uses the following encoding: utf-8
import os
from urllib.parse import urlparse, unquote
from urllib.request import url2pathname
from pathlib import Path
import sys
import conversionthread
from theme import theme

from PySide2.QtCore import QObject, QUrl, Slot, Signal, QDir
from PySide2.QtQuick import QQuickView
from PySide2.QtQuickControls2 import QQuickStyle
from PySide2.QtGui import QGuiApplication

paths = []
supportedImageFormats = [".png", ".jpeg", ".jpg", ".heic", ".heif", ".gif",
                         ".bmp", ".psd", ".tiff", ".hdr", ".exr", ".webp"]


def uri_to_path(uri):
    parsed = urlparse(uri)
    host = "{0}{0}{mnt}{0}".format(os.path.sep, mnt=parsed.netloc)
    return os.path.normpath(
        os.path.join(host, url2pathname(unquote(parsed.path)))
    )


class Backend(QObject):
    def __init__(self):
        super(Backend, self).__init__()
        # self._strtest = "String taken from python"

    @Slot(str)
    def addToPaths(self, path):
        paths.append(uri_to_path(path))
        self.updateInputFilesList()

    @Slot()
    def updateInputFilesList(self):
        fileNames = [os.path.basename(path) for path in paths]
        view.rootObject().findChild(QObject, "inputFileView").updateList(fileNames)

    @Slot()
    def clearInputSelection(self):
        paths.clear()
        self.updateInputFilesList()

    @Slot(result=list)
    def getSupportedImageFormats(self):
        return supportedImageFormats

    @Slot()
    def callConversion(self):
        conversionthread.filePathQueue = paths.copy()
        conversionthread.targetExt = view.rootObject().findChild(QObject, "outputFormatBox").property("currentText")
        conversionthread.startStopConversion()

    @Slot(result=str)
    def getOutputPathUrl(self):
        return Path(conversionthread.outPath).as_uri()


class CustomSignalHandler(QObject):
    def __init__(self):
        super(CustomSignalHandler, self).__init__()
        self.finishEvent.connect(self.onFinish)
        self.outputFilesUpdateEvent.connect(self.onOutputFileUpdate)
        self.logEvent.connect(self.onLogEvent)
        self.progressEvent.connect(self.onProgressEvent)

    finishEvent = Signal()

    @Slot()
    def onFinish(self):
        view.rootObject().findChild(QObject, "btn_convert").setProperty("text", "Convert")
        view.rootObject().findChild(QObject, "inputFileViewDropArea").setAcceptDrop(True)
        view.rootObject().findChild(QObject, "btn_clearInputSelection")._setEnabled(True)
        view.rootObject().findChild(QObject, "outputFormatBox")._setEnabled(True)
        signalHandler.logEvent.emit(theme.SUCCESSTEXT, "Conversion finished.")

    outputFilesUpdateEvent = Signal()

    @Slot()
    def onOutputFileUpdate(self):
        path = conversionthread.outPath
        files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]
        view.rootObject().findChild(QObject, "outputFileView").updateList(files)

    logEvent = Signal(str, str)

    @Slot(str, str)
    def onLogEvent(self, color, text):
        logObject = view.rootObject().findChild(QObject, "log")
        logText = logObject.property("text")
        logText += "<p style='color: {0}'>{1}</p>\n".format(color, text)
        logObject.setProperty("text", logText)
        view.rootObject().findChild(QObject, "logScrollView").scrollToBottom()

    progressEvent = Signal(int, int)

    @Slot(int, int)
    def onProgressEvent(self, done, total):
        progressBar = view.rootObject().findChild(QObject, "progressBar")
        progressBar.setProperty("value", done)
        progressBar.setProperty("to", total)


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)

    view = QQuickView()
    conversionthread.app = app
    conversionthread.view = view
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    QQuickStyle.setStyle("Fusion")

    context = view.engine().rootContext()
    backend = Backend()
    context.setContextProperty("backend", backend)

    qml_file = os.path.join(QDir.currentPath(), 'resources/main.qml')
    view.setSource(QUrl.fromLocalFile(qml_file))
    if view.status() == QQuickView.Error:
        sys.exit(-1)

    signalHandler = CustomSignalHandler()
    conversionthread.signalHandler = signalHandler
    context.setContextProperty("signalHandler", signalHandler)

    conversionthread.supportedImageFormats = supportedImageFormats
    conversionthread.outPath = QDir.currentPath() + "/tmp/converted"

    conversionthread.clearOutputDir()

    signalHandler.logEvent.emit(theme.INFOTEXT,"Info, errors, and warnings will appear here.")

    view.setTitle("Hello World!")
    view.show()

    res = app.exec_()
    del view
    sys.exit(res)