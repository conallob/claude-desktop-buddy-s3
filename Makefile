.PHONY: all build flash flash-fs monitor clean setup config help

ENV := m5stick-s3
PIO := pio

# Default: build firmware
all: build

## Build firmware binary
build:
	$(PIO) run -e $(ENV)

## Flash firmware to connected device
flash:
	$(PIO) run -e $(ENV) -t upload

## Build and upload LittleFS filesystem image (GIF character packs)
flash-fs:
	$(PIO) run -e $(ENV) -t uploadfs

## Flash both firmware and filesystem in one step
flash-all: flash flash-fs

## Open serial monitor (115200 baud)
monitor:
	$(PIO) device monitor -e $(ENV)

## Flash and immediately open serial monitor
flash-monitor: flash monitor

## Remove build artifacts
clean:
	$(PIO) run -e $(ENV) -t clean

## Install PlatformIO via pipx (isolated under pyenv Python 3.13) and project dependencies
## Prerequisite: brew install pipx && brew install pyenv && pyenv install 3.13
setup:
	pipx install platformio --python $(shell pyenv which python3) --force
	$(PIO) pkg install -e $(ENV)

## Create wifi_config.h from the example file if it doesn't exist
config:
	@if [ -f wifi_config.h ]; then \
		echo "wifi_config.h already exists — edit it directly."; \
	else \
		cp wifi_config.h.example wifi_config.h; \
		echo "Created wifi_config.h — fill in your WiFi and MQTT credentials before building."; \
	fi

## Show available targets
help:
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "  config        Create wifi_config.h from example (first-time setup)"
	@echo "  build         Compile firmware"
	@echo "  flash         Flash firmware to device"
	@echo "  flash-fs      Upload LittleFS filesystem (GIF character packs)"
	@echo "  flash-all     Flash firmware + filesystem"
	@echo "  monitor       Open serial monitor"
	@echo "  flash-monitor Flash then open serial monitor"
	@echo "  clean         Remove build artifacts"
	@echo "  setup         Install PlatformIO via pipx + project libraries"
	@echo ""
	@echo "Prerequisites (one-time):"
	@echo "  brew install pipx pyenv && pyenv install 3.13"
	@echo ""
	@echo "First-time workflow:"
	@echo "  make setup && make config && \$$EDITOR wifi_config.h && make flash"
	@echo ""
