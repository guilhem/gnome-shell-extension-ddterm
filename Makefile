SHELL := /bin/bash

all: schemas/gschemas.compiled lint pack

.PHONY: all

SCHEMAS := $(wildcard schemas/*.gschema.xml)

schemas/gschemas.compiled: $(SCHEMAS)
	glib-compile-schemas --strict $(dir $@)

lint/eslintrc-gjs.yml:
	curl -o $@ 'https://gitlab.gnome.org/GNOME/gjs/-/raw/master/.eslintrc.yml'

lint: lint/eslintrc-gjs.yml
	eslint .

.PHONY: lint

EXTENSION_UUID := ddterm@amezin.github.com
DEVELOP_SYMLINK := $(HOME)/.local/share/gnome-shell/extensions/$(EXTENSION_UUID)

develop: schemas/gschemas.compiled
	mkdir -p "$(dir $(DEVELOP_SYMLINK))"
	if [[ "$(abspath .)" != "$(abspath $(DEVELOP_SYMLINK))" ]]; then \
		ln -snf "$(abspath .)" "$(DEVELOP_SYMLINK)"; \
	fi

.PHONY: develop

develop-uninstall:
	if [[ -L "$(DEVELOP_SYMLINK)" ]]; then \
		unlink "$(DEVELOP_SYMLINK)"; \
	fi

.PHONY: develop-uninstall

prefs enable disable reset info show:
	gnome-extensions $@ $(EXTENSION_UUID)

.PHONY: prefs enable disable reset info show

EXTENSION_PACK := $(EXTENSION_UUID).shell-extension.zip
$(EXTENSION_PACK): EXTRA_SOURCES := $(filter-out extension.js prefs.js,$(wildcard *.ui *.js))
$(EXTENSION_PACK): $(SCHEMAS) $(EXTRA_SOURCES) extension.js prefs.js metadata.json
	gnome-extensions pack -f $(addprefix --schema=,$(SCHEMAS)) $(addprefix --extra-source=,$(EXTRA_SOURCES)) .

pack: $(EXTENSION_PACK)
.PHONY: pack

install: $(EXTENSION_PACK) develop-uninstall
	gnome-extensions install -f $<

.PHONY: install

uninstall: develop-uninstall
	gnome-extensions uninstall $(EXTENSION_UUID)

.PHONY: uninstall
