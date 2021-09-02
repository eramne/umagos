
# This Python file uses the following encoding: utf-8
import os
from urllib.parse import urlparse, unquote
from urllib.request import url2pathname
from pathlib import Path
import sys
import shutil
import platform
import uuid
import json
from ShellTask import ShellTask

from PySide2.QtCore import QObject, QUrl, Slot, QDir, QMimeData
from PySide2.QtQuick import QQuickView
from PySide2.QtQuickControls2 import QQuickStyle
from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import qmlRegisterType

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
               ".pbm", ".pcd", ".pcds", ".pcx", ".pdb",
               ".pfm", ".pgm", ".phm", ".pict", ".png",
               ".png00", ".png8", ".png24", ".png32", ".png48", ".png64",
               ".pnm", ".pocketmod", ".ppm", ".psb", ".psd", ".ptif",
               ".sgi", ".sun", ".tga", ".tif", ".tiff",
               ".txt", ".vicar", ".viff", ".wbmp",
               ".webp", ".x", ".xpm", ".xwd"]
}


class Backend(QObject):
    def __init__(self):
        super(Backend, self).__init__()

    @Slot(str, result=str)
    def pathToName(self, path):
        return os.path.basename(path)

    @Slot(str, result=str)
    def uriToPath(self, uri):
        parsed = urlparse(uri)
        host = "{0}{0}{mnt}{0}".format(os.path.sep, mnt=parsed.netloc)
        return os.path.normpath(
            os.path.join(host, url2pathname(unquote(parsed.path)))
        )

    @Slot(str, result=str)
    def pathToURI(self, path):
        return Path(path).as_uri()

    @Slot(result="QVariantMap")
    def getSupportedFormats(self):
        return supportedFormats

    @Slot(result=str)
    def makeUUID(self):
        return str(uuid.uuid4())

    @Slot(result=list)
    def getClipboardUrls(self):
        clipboard = QGuiApplication.clipboard()
        return clipboard.mimeData().urls()

    @Slot(str)
    def setClipboardUrls(self, urls):
        clipboard = QGuiApplication.clipboard()
        mimeData = QMimeData()
        mimeData.setUrls(urls.split("\r\n"))
        clipboard.setMimeData(mimeData)

    @Slot(result=str)
    def getMagickPath(self):
        magickPath = appdir + "/magick"
        if platform.system() == "Windows":
            magickPath = appdir + "/imagemagick/magick"
        if platform.system() == "Darwin":
            # assumes imagemagick is installed with homebrew on macOS
            os.environ["PATH"] = "/usr/local/bin:" + os.environ["PATH"]
            magickPath = shutil.which("magick")
        return os.path.realpath(magickPath)

    @Slot(str, result=str)
    def getFileNameWithoutExtension(self, path):
        return os.path.splitext(os.path.basename(path))[0]

    @Slot(str, result=str)
    def getFileExtension(self, path):
        return os.path.splitext(os.path.basename(path))[1].lower()

    @Slot(str, result=str)
    def getFileName(self, path):
        return os.path.basename(path)

    @Slot(str, str, result=str)
    def joinPaths(self, path1, path2):
        return os.path.join(path1, path2)

    @Slot(str, result=bool)
    def fileExists(self, path):
        return os.path.exists(path)

    @Slot(str, result=str)
    def getUsableName(self, originalOutputPath):
        path = originalOutputPath
        i = 0
        while os.path.exists(path):
            i += 1
            path = "{0}/{1} ({2}){3}".format(os.path.dirname(originalOutputPath),
                                             os.path.splitext(os.path.basename(originalOutputPath))[0],
                                             i,
                                             os.path.splitext(os.path.basename(originalOutputPath))[1].lower())
        if i > 0:
            originalName = os.path.basename(originalOutputPath)
            newName = os.path.basename(path)
        return path

    @Slot(str, result=str)
    def makeOutputPath(self, id):
        path = os.path.realpath(os.path.join(appdir, "tmp/" + id + "/out"))
        Path(path).mkdir(parents=True, exist_ok=True)
        return path

    @Slot(str)
    def clearOutputDir(self, outPath):
        shutil.rmtree(outPath)
        os.makedirs(outPath)

    @Slot()
    def clearTmpDir(self):
        tmpPath = appdir + "/tmp/"
        shutil.rmtree(tmpPath)
        os.makedirs(tmpPath)

    @Slot(str, result=list)
    def getOutputFiles(self, outputPath):
        return [f for f in os.listdir(outputPath) if os.path.isfile(os.path.join(outputPath, f))]


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    app.setOrganizationName("eramne")
    app.setOrganizationDomain("eramne.com")
    app.setApplicationName("umagos")

    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    QQuickStyle.setStyle("Fusion")

    context = view.engine().rootContext()
    backend = Backend()
    context.setContextProperty("Backend", backend)

    qmlRegisterType(ShellTask, "umagos.shellTask", 1, 0, "ShellTask")

    appdir = QDir.currentPath()
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        appdir = os.path.dirname(sys.executable)

    backend.clearTmpDir()

    view.engine().addImportPath(os.path.join(appdir, 'resources/'))

    style_file = os.path.join(appdir, 'resources/umagos/styles/Light.json')
    style = json.loads(Path(style_file).read_text())
    context.setContextProperty("Style", style)

    qml_file = os.path.join(appdir, 'resources/umagos/main/app.qml')
    view.setSource(QUrl.fromLocalFile(qml_file))
    if view.status() == QQuickView.Error:
        sys.exit(-1)

    view.setTitle("umagos")
    view.show()

    res = app.exec_()
    del view
    sys.exit(res)
