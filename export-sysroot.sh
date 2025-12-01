#!/bin/bash

mkdir -p sysroot
rm -rf sysroot/*
cp -aR /bin /sysroot/bin
cp -aR /lib /sysroot/lib
cp -aR /usr /sysroot/usr
cp -aR /etc /sysroot/etc
cp -aR /var /sysroot/var
cp -aR /home /sysroot/home
cp -aR /sbin /sysroot/sbin
mkdir -p /sysroot/emscripten/
cp -aR /sources/emscripten/* /sysroot/emscripten
#cp -aR /sources/emscripten/cache /sysroot/emscripten/cache
touch /sysroot/.emscripten
chmod 666 /sysroot/.emscripten
mkdir -p /sysroot/emscripten/cache
chmod -R 777 /sysroot/emscripten/cache

echo "#!/bin/bash" > /sysroot/emscripten/em++-wrapper.sh
echo "SCRIPT_DIR=\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)" >> /sysroot/emscripten/em++-wrapper.sh
echo "export EM_CONFIG=\"\$SCRIPT_DIR/../.emscripten\"" >> /sysroot/emscripten/em++-wrapper.sh
echo "exec \"\$SCRIPT_DIR/em++\" \"\$@\"" >> /sysroot/emscripten/em++-wrapper.sh
chmod +x /sysroot/emscripten/em++-wrapper.sh

echo "#!/bin/bash" > /sysroot/emscripten/emcc-wrapper.sh
echo "SCRIPT_DIR=\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)" >> /sysroot/emscripten/emcc-wrapper.sh
echo "export EM_CONFIG=\"\$SCRIPT_DIR/../.emscripten\"" >> /sysroot/emscripten/emcc-wrapper.sh
echo "exec \"\$SCRIPT_DIR/emcc\" \"\$@\"" >> /sysroot/emscripten/emcc-wrapper.sh
chmod +x /sysroot/emscripten/emcc-wrapper.sh

echo "#!/bin/bash" > /sysroot/emscripten/emrun-wrapper.sh
echo "SCRIPT_DIR=\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)" >> /sysroot/emscripten/emrun-wrapper.sh
echo "export EM_CONFIG=\"\$SCRIPT_DIR/../.emscripten\"" >> /sysroot/emscripten/emrun-wrapper.sh
echo "exec \"\$SCRIPT_DIR/emrun\" \"\$@\"" >> /sysroot/emscripten/emrun-wrapper.sh
chmod +x /sysroot/emscripten/emrun-wrapper.sh
