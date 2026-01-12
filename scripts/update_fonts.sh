mkdir -p $HOME/.local/share/fonts
mkdir $HOME/.cache/gkdot
cd $HOME/.cache/gkdot

wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.tar.xz"
mkdir mona
mv Monaspace.tar.xz mona
cd mona
tar xvf Monaspace.tar.xz
rm Monaspace.tar.xz
find . -type f -name "Monaspice*" ! -iregex ".*Kr.*" -exec rm {} \;
mv Monaspice* $HOME/.local/share/fonts
cd ..
rm -rf mona

wget "https://font.download/dl/font/helvetica-255.zip"
unzip helvetica-255.zip
mv *.otf *.ttf $HOME/.local/share/fonts
rm helvetica-255.zip

cd ..
rm -rf gkdot
