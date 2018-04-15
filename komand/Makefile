VERSION?=$(shell grep '^version: ' plugin.spec.yaml | sed 's/version: //')
NAME?=$(shell grep '^name: ' plugin.spec.yaml | sed 's/name: //')
ENCODING:=$(shell base64 icon.png 2>/dev/null | sed 's|/|\\/|g' | tr -d '\n')
VENDOR?=$(shell grep '^vendor: ' plugin.spec.yaml | sed 's/vendor: //')
CWD?=$(shell basename $(PWD))
_NAME?=$(shell echo $(NAME) | awk '{ print toupper(substr($$0,1,1)) tolower(substr($$0,2)) }')

PKG=$(VENDOR)-$(NAME)-$(VERSION).tar.gz

all: validate icon image tarball runner

plugin: build

build:
	python setup.py build
	python setup.py install

icon:
	@test -f icon.png && \
	sed -i.bu "/^icon/s/\(icon: \).*/\1\"data:image\/png;base64,$(ENCODING)\"/" plugin.spec.yaml || true
	@rm -f *.bu || true

tarball:
	rm -rf build
	rm -rf $(PKG)
	tar -cvzf $(PKG) --exclude=$(PKG) *

image:
	docker build --pull -t $(VENDOR)/$(NAME):$(VERSION) .
	docker tag $(VENDOR)/$(NAME):$(VERSION) $(VENDOR)/$(NAME):latest

regenerate:
	komand-plugin generate python --regenerate

runner:
	@ln -f -s ../tools/run run

help:
	@test -f ../tools/help.py || echo "Check spec tool not included in customer installs!"
	@test -f ../tools/help.py && python2 ../tools/help.py ./plugin.spec.yaml

validate:
	@test -f ../tools/check_spec.py || echo "Check spec tool not included in customer installs!"
	@test -f ../tools/check_spec.py && python2 ../tools/check_spec.py ./plugin.spec.yaml

export: image
	@printf "\n ---> Exporting Docker image to ./$(NAME).img\n"
	@docker save $(VENDOR)/$(NAME):$(VERSION) | gzip > $(NAME)_$(VERSION).img

.PHONY: all package image build plugin regenerate
