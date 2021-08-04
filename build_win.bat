pyinstaller --name="umagos" --windowed src\main.py --noconfirm
xcopy /s "src\appdir\" "dist\umagos\"