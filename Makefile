.PHONY: all clean deps copy-libs build-app locales

APP=mcServium
LPI=mcServium.lpi

ARCH := $(shell fpc -iTP)
OS   := $(shell fpc -iTO)

PO_FILES := $(wildcard language/*.po)
MO_FILES := $(patsubst language/%.po,bin/locale/%.mo,$(PO_FILES))

TARGET_BIN_DIR=bin
TARGET_LIB_DIR=lib/external/$(ARCH)-$(OS)

SODIUM_DIR=libraries/libsodium
UPNP_DIR=libraries/miniupnp/miniupnpc

all: deps copy-libs build-app locales

deps:
	@echo "Building libsodium..."
	cd $(SODIUM_DIR) && \
	./autogen.sh && \
	./configure --enable-static --enable-shared && \
	make -j4

	@echo "Building miniupnpc..."
	cd $(UPNP_DIR) && \
	make

copy-libs:
	@echo "Copying libraries to $(TARGET_LIB_DIR)..."

	mkdir -p $(TARGET_LIB_DIR)

	find $(SODIUM_DIR) -type f | grep -E '\.(a|lib|so|dll|dylib)$$' | xargs -I {} cp "{}" $(TARGET_LIB_DIR)/
	find $(UPNP_DIR) -type f | grep -E '\.(a|lib|so|dll|dylib)$$' | xargs -I {} cp "{}" $(TARGET_LIB_DIR)/

	@echo "Done copying libs to $(TARGET_LIB_DIR)"

build-app:
	@echo "Building Lazarus project..."

	lazbuild $(LPI)

locales: $(MO_FILES)

bin/locale/%.mo: language/%.po
	@mkdir -p bin/locale
	msgfmt -o $@ $<	

clean:
	cd $(SODIUM_DIR) && make clean || true
	cd $(UPNP_DIR) && make clean || true
	rm -rf $(TARGET_LIB_DIR)