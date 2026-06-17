.PHONY: all build flash flash-fs monitor clean setup config help check-python

ENV := m5stick-s3

# PlatformIO requires Python 3.10–3.13.
# Check runs inside the recipe shell so pyenv/mise shims are active.
check-python:
	@python3 -c "\
import sys; \
maj, min_ = sys.version_info[:2]; \
ok = maj == 3 and 10 <= min_ <= 13; \
ok or print(f'\nERROR: PlatformIO requires Python 3.10-3.13.\n       Active version: {maj}.{min_}\n\nFix: let .python-version select 3.13 via pyenv or mise:\n  brew install pyenv && pyenv install 3.13 && pyenv rehash\n  or: brew install mise && mise install\n'); \
raise SystemExit(0 if ok else 1) \
"

# Default: build firmware
all: build

## Build firmware binary
build: check-python
	pio run -e $(ENV)

## Flash firmware to connected device
flash: check-python
	pio run -e $(ENV) -t upload

## Build and upload LittleFS filesystem image (GIF character packs)
flash-fs: check-python
	pio run -e $(ENV) -t uploadfs

## Flash both firmware and filesystem in one step
flash-all: flash flash-fs

## Open serial monitor (115200 baud)
monitor: check-python
	pio device monitor -e $(ENV)

## Flash and immediately open serial monitor
flash-monitor: flash monitor

## Remove build artifacts
clean: check-python
	pio run -e $(ENV) -t clean

## Install PlatformIO dependencies (libraries + toolchain)
setup: check-python
	pio pkg install -e $(ENV)

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
	@echo "First-time workflow:"
	@echo "  make setup && make config && \$$EDITOR wifi_config.h && make flash"
	@echo ""
