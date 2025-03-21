mkdir build

git clone --depth 1 https://git.suckless.org/dwm build/dwm
cp dwm.config.h build/dwm/config.h
cp -r patches build/dwm/
cd build/dwm
patch -p1 < patches/dwm-pertag-20200914-61bb8b2.diff
patch -p1 < patches/dwm-alwayscenter-20200625-f04cac6.diff
make
cd ../..

git clone --depth 1 https://git.suckless.org/dmenu build/dmenu
cp dmenu.config.h build/dmenu/config.h
cd build/dmenu
make
cd ../..

git clone --depth 1 https://git.suckless.org/slstatus build/slstatus
cp slstatus.config.h build/slstatus/config.h
cd build/slstatus
make
cd ../..

git clone --depth 1 https://git.suckless.org/st build/st
cp st.config.h build/st/config.h
cd build/st
make
cd ../..

mkdir bin
ln -s $(pwd)/build/dwm/dwm $(pwd)/bin/dwm
ln -s $(pwd)/build/dmenu/dmenu $(pwd)/bin/dmenu
ln -s $(pwd)/build/slstatus/slstatus $(pwd)/bin/slstatus
ln -s $(pwd)/build/slstatus/st $(pwd)/bin/st
