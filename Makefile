.PHONY: all build flash flash-fs monitor clean setup config help

ENV := m5stick-s3
# Invoke PlatformIO via the pyenv-selected Python so the interpreter is
# always 3.13 regardless of which Python the system `pio` binary was built with.
PIO := pyenv exec python3 -m platformio

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

## Install PlatformIO into the pyenv Python and install project dependencies
setup:
	pyenv exec pip install platformio
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
	@echo "  setup         Install PlatformIO libraries and toolchain"
	@echo ""
	@echo "Requires Python 3.10-3.13 (PlatformIO constraint)."
	@echo ".python-version pins 3.13 automatically for pyenv and mise users."
	@echo ""
	@echo "First-time workflow:"
	@echo "  make setup && make config && \$$EDITOR wifi_config.h && make flash"
	@echo ""
