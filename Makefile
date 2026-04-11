.PHONY: all clean build deps copy-libs build-app

APP=project1
LPI=project1.lpi

ARCH := $(shell uname -m)
OS := $(shell uname -s | tr A-Z a-z)

TARGET_DIR=lib/external/$(ARCH)-$(OS)

SODIUM_DIR=libraries/libsodium
UPNP_DIR=libraries/miniupnp

all: deps build-libs copy-libs build-app

deps:
	@echo "Building libsodium..."
	cd $(SODIUM_DIR) && \
	./autogen.sh && \
	./configure --enable-static --disable-shared && \
	make -j4

	@echo "Building miniupnpc..."
	cd $(UPNP_DIR) && \
	make

copy-libs:
	@echo "Copying static libs..."

	mkdir -p $(TARGET_DIR)

	find $(SODIUM_DIR) -name "*.a" -exec cp {} $(TARGET_DIR)/ \;
	find $(UPNP_DIR) -name "*.a" -exec cp {} $(TARGET_DIR)/ \;

	@echo "Done copying libs to $(TARGET_DIR)"

build-app:
	@echo "Building Lazarus project..."

	lazbuild $(LPI)

clean:
	cd $(SODIUM_DIR) && make clean || true
	cd $(UPNP_DIR) && make clean || true
	rm -rf $(TARGET_DIR)