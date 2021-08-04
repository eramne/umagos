pyinstaller --name="umagos" --windowed src\main.py --noconfirm
xcopy /s workingdir "dist\umagos"