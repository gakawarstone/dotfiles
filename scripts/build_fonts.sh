mkdir -p fonts
cd fonts

wget "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.tar.xz"
tar xvf Monaspace.tar.xz --wildcards 'MonaspiceKr*'
rm Monaspace.tar.xz

wget "https://font.download/dl/font/helvetica-255.zip"
unzip helvetica-255.zip
rm helvetica-255.zip
