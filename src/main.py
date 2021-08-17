
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
supportedFormats = {
    "images": [".png", ".jpeg", ".jpg", ".gif", ".webp", ".bmp",
               ".heic", ".raw", ".psd", ".tiff", ".hdr", ".exr",
               ".aai", ".apng", ".art", ".avif", ".avs",
               ".bmp", ".bmp2", ".bmp3", ".cin", ".dcx",
               ".dds", ".dib", ".dpx", ".epdf", ".exr", ".farbfeld",
               ".fax", ".fits", ".fl32", ".flif", ".fpx", ".gif",
               ".hdr", ".heic", ".heif", ".hrz",
               ".jbig", ".jng", ".jp2", ".j2c",
               ".j2k", ".jpg", ".jpeg", ".jxl", ".miff",
               ".mng", ".mpr",
               ".msl", ".mtv", ".mvg", ".otb", ".p7", ".palm",
               ".pbm", ".pcd", ".pcds", ".pcx", ".pdb", ".pdf",
               ".pfm", ".pgm", ".phm", ".pict", ".png",
               ".png00", ".png8", ".png24", ".png32", ".png48", ".png64",
               ".pnm", ".pocketmod", ".ppm", ".psb", ".psd", ".ptif",
               ".sgi", ".sun", ".tga", ".tif", ".tiff",
               ".txt", ".vicar", ".viff", ".wbmp",
               ".webp", ".x", ".xpm", ".xwd"]
}


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

    @Slot(list)
    def removeFromInputSelection(self, indices):
        global paths
        tmpPaths = []
        for i, val in enumerate(paths):
            if not i in indices:
                tmpPaths.append(val)
        paths = tmpPaths

    @Slot(result="QVariantMap")
    def getSupportedFormats(self):
        return supportedFormats

    @Slot()
    def callConversion(self):
        conversionthread.filePathQueue = paths.copy()
        conversionthread.targetExt = view.rootObject().findChild(QObject, "outputFormatBox").property("currentText")
        conversionthread.startStopConversion()

    @Slot(result=str)
    def getOutputPathUrl(self):
        return Path(conversionthread.outPath).as_uri()

    @Slot(result=list)
    def getClipboardUrls(self):
        clipboard = QGuiApplication.clipboard()
        return clipboard.mimeData().urls()


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
        view.rootObject().setFileControlsEnabled(True)
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
        view.rootObject().findChild(QObject, "logFlickable").scrollToBottom()

    progressEvent = Signal(int, int)

    @Slot(int, int)
    def onProgressEvent(self, done, total):
        progressBar = view.rootObject().findChild(QObject, "progressBar")
        progressBar.setProperty("value", done)
        progressBar.setProperty("to", total)


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    app.setOrganizationName("eramne")
    app.setOrganizationDomain("eramne.com")
    app.setApplicationName("umagos")

    view = QQuickView()
    conversionthread.app = app
    conversionthread.view = view
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    QQuickStyle.setStyle("Fusion")

    context = view.engine().rootContext()
    backend = Backend()
    context.setContextProperty("backend", backend)

    appdir = QDir.currentPath()
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        appdir = os.path.dirname(sys.executable)
    conversionthread.appdir = appdir

    qml_file = os.path.join(appdir, 'resources/main.qml')
    view.setSource(QUrl.fromLocalFile(qml_file))
    if view.status() == QQuickView.Error:
        sys.exit(-1)

    signalHandler = CustomSignalHandler()
    conversionthread.signalHandler = signalHandler
    context.setContextProperty("signalHandler", signalHandler)

    conversionthread.supportedFormats = supportedFormats
    conversionthread.outPath = appdir + "/tmp/converted"

    conversionthread.clearOutputDir()

    signalHandler.logEvent.emit(theme.INFOTEXT,"Info, errors, and warnings will appear here.")

    view.setTitle("umagos")
    view.show()

    res = app.exec_()
    del view
    sys.exit(res)
