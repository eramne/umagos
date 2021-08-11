# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass

import threading
import os
import shutil
import platform
from theme import theme

from PySide2.QtCore import QObject, QProcess

conversionThread = None
process = None
abort = False

# initialized in main.py to avoid circular dependency
view = None
app = None
signalHandler = None
filePathQueue = None
supportedFormats = None
targetExt = None
outPath = None
appdir = None


def startStopConversion():
    global conversionThread
    global abort
    if type(conversionThread) is threading.Thread:
        if conversionThread.is_alive():
            if type(process) is QProcess:
                process.kill()
            abort = True
        else:
            startConversion()
    else:
        startConversion()


def startConversion():
    global conversionThread
    conversionThread = threading.Thread(target=threadTask, args=())
    conversionThread.start()
    view.rootObject().findChild(QObject, "btn_convert").setProperty("text", "Cancel")
    view.rootObject().findChild(QObject, "inputFileViewDropArea").setAcceptDrop(False)
    view.rootObject().findChild(QObject, "btn_clearInputSelection")._setEnabled(False)
    view.rootObject().findChild(QObject, "outputFormatBox")._setEnabled(False)
    view.rootObject().findChild(QObject, "outFormatLabel").setProperty("opacity", 0.5)


def threadTask():
    global abort
    signalHandler.logEvent.emit(theme.INFOTEXT, "Conversion starting.")
    signalHandler.progressEvent.emit(0, 1)
    errorCheck()
    clearOutputDir()
    for i in range(len(filePathQueue)):
        if abort:
            break
        path = filePathQueue[i]
        convert(path, i, len(filePathQueue))
    abort = False
    signalHandler.finishEvent.emit()
    signalHandler.progressEvent.emit(1, 1)


def convert(inPath, iteration, total):
    global process
    inName = os.path.splitext(os.path.basename(inPath))[0]
    inExt = os.path.splitext(os.path.basename(inPath))[1].lower()
    outFile = getUsableName("{0}/{1}{2}".format(outPath, inName, targetExt), inPath)
    arguments = ["convert", inPath, outFile]
    try:
        signalHandler.logEvent.emit(theme.INFOTEXT, "File {0}/{1}, converting file {2}{3} from {3} to {4}. Full path of original: {5}".format(iteration+1, total, inName, inExt, targetExt, inPath))
        process = QProcess()
        magickPath = appdir + "/magick"
        if platform.system() == "Darwin":
            # assumes imagemagick is installed with homebrew on macOS
            os.environ["PATH"] = "/usr/local/bin:" + os.environ["PATH"]
            magickPath = shutil.which("magick")
        process.start(magickPath, arguments)
        process.waitForStarted(-1)
        process.waitForFinished(-1)
    except Exception as e:
        print(e)
    signalHandler.outputFilesUpdateEvent.emit()
    signalHandler.progressEvent.emit(iteration + 1, total)


def errorCheck():
    global filePathQueue
    global supportedFormats
    if len(filePathQueue) > 0:
        tempOldCount = len(filePathQueue)
        filePathQueue = list(dict.fromkeys(filePathQueue))
        duplicatesCount = tempOldCount - len(filePathQueue)
        if (duplicatesCount > 0):
            signalHandler.logEvent.emit(theme.WARNINGTEXT, "Warning: There were {0} duplicate files, these will be ignored during conversion.".format(duplicatesCount))

        unsupportedFormats = []
        numFilesUnsupported = 0
        tempFilePathQueue = []
        for i in range(len(filePathQueue)):
            path = filePathQueue[i]
            ext = os.path.splitext(filePathQueue[i])[1].lower()
            if ext not in supportedFormats["images"]:
                if ext not in unsupportedFormats:
                    unsupportedFormats.append(ext)
                numFilesUnsupported += 1
            else:
                tempFilePathQueue.append(path)
        filePathQueue = tempFilePathQueue
        if numFilesUnsupported > 0:
            signalHandler.logEvent.emit(theme.WARNINGTEXT, "Warning: Unsupported formats: {0}. {1} file(s) of those unsupported formats will be ignored during conversion.".format(", ".join(unsupportedFormats), numFilesUnsupported))
    else:
        signalHandler.logEvent.emit(theme.ERRORTEXT, "Error: Drag and drop your files to the left box, then click the Convert button to convert your files!");


def clearOutputDir():
    shutil.rmtree(outPath)
    os.makedirs(outPath)
    signalHandler.outputFilesUpdateEvent.emit()


def getUsableName(originalOutputPath, originalInputPath):
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
        signalHandler.logEvent.emit(theme.WARNINGTEXT, "Warning: File {0} already exists in output folder, most likely caused by two files with the same name being converted, file renamed to {1}. Full path of original: {2}".format(originalName, newName, originalInputPath))
    return path
