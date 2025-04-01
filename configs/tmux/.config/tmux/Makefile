install:
	mkdir -p plugins
	git clone https://github.com/tmux-plugins/tpm plugins/tpm
	./plugins/tpm/bin/install_plugins

clean:
	rm -rf plugins

update:
	./plugins/tpm/bin/update_plugins

all: clean install
