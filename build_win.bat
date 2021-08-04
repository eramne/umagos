pyinstaller --name="umagos" --windowed src\main.py --noconfirm
xcopy /s "src\appdir\resources\" "dist\umagos\resources\"
xcopy /s "src\appdir\win_only\" "dist\umagos\"
mkdir ".\dist\umagos\tmp\converted"
pause
