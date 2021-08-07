source ~/qtenv/bin/activate #replace this with the path to your python virtual environment
pyinstaller --name="umagos" --windowed src/main.py --noconfirm
cp -R "src/appdir/resources/" "dist/umagos.app/Contents/MacOS/resources/"
mkdir -p "dist/umagos.app/Contents/MacOS/tmp/converted"
rm -r "dist/umagos/"