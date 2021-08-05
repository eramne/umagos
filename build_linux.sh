source ~/qtenv/bin/activate #replace this with the path to your python virtual environment
pyinstaller --name="umagos" --windowed src/main.py --noconfirm
cp -RT "src/appdir/resources/" "dist/umagos/resources/"
cp -RT "src/appdir/linux_only/" "dist/umagos/"
mkdir -p "dist/umagos/tmp/converted"
