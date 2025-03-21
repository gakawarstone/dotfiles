cd fonts

wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.tar.xz"
tar xvf Monaspace.tar.xz
rm Monaspace.tar.xz
find . -type f -name "Monaspice*" ! -iregex ".*Kr.*" -exec rm {} \;

wget "https://font.download/dl/font/helvetica-255.zip"
unzip helvetica-255.zip
rm helvetica-255.zip

rm LICENSE README.md
