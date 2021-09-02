# This Python file uses the following encoding: utf-8
from PySide2.QtCore import QObject, QProcess, Signal, Slot
import threading


class ShellTask(QObject):
    __thread = None
    __currentCommandProcess = None
    __kill = False

    def __init__(self):
        super(ShellTask, self).__init__()

    @Slot("QVariantList")
    def start(self, cmds):
        self.__thread = threading.Thread(target=self.threadTask, args=(cmds,))
        self.started.emit()
        self.__thread.start()

    started = Signal()

    def threadTask(self, cmds):
        for i in range(len(cmds)):
            if self.__kill:
                break
            cmd = cmds[i]
            self.__currentCommandProcess = QProcess()
            self.__currentCommandProcess.start(cmd["exe"], cmd["args"])
            self.__currentCommandProcess.waitForStarted(-1)
            self.__currentCommandProcess.waitForFinished(-1)
        self.__kill = False
        self.finished.emit()

    finished = Signal()

    @Slot()
    def kill(self):
        if self.isRunning():
            self.__kill = True
        if type(self.__currentCommandProcess) is QProcess:
            self.__currentCommandProcess.kill()

    def isRunning(self):
        if type(self.__thread) is threading.Thread:
            if self.__thread.is_alive():
                return True
        return False
