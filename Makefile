ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

ifeq ($(strip $(CTRULIB)),)
$(error "Please set CTRULIB in your environment. export DEVKITARM=<path to>ctrulib/libctru")
endif

ifeq ($(filter $(DEVKITARM)/bin,$(PATH)),)
export PATH:=$(DEVKITARM)/bin:$(PATH)
endif

# FIRMVERSION = OLD_MEMMAP
# FIRMVERSION = NEW_MEMMAP

# CNVERSION = WEST
# CNVERSION = JPN
# ROVERSION = 1024
# ROVERSION = 2049
# ROVERSION = 3074
# ROVERSION = 4096
# SPIDERVERSION = 2050
# SPIDERVERSION = 3074
# SPIDERVERSION = 4096

export FIRMVERSION
export CNVERSION
export ROVERSION
export SPIDERVERSION
export MENUVERSION

OUTNAME = $(FIRMVERSION)_$(CNVERSION)_$(MENUVERSION)

SCRIPTS = "scripts"

.PHONY: directories all build/constants firm_constants/constants.txt spider_constants/constants.txt cn_constants/constants.txt cn_qr_initial_loader/cn_qr_initial_loader.bin.png cn_save_initial_loader/cn_save_initial_loader.bin cn_secondary_payload/cn_secondary_payload.bin cn_bootloader/cn_bootloader.bin menu_payload/menu_payload.bin

all: directories build/constants q/$(OUTNAME).png p/$(OUTNAME).bin build/cn_save_initial_loader.bin
directories:
	@mkdir -p build && mkdir -p build/cro
	@mkdir -p p
	@mkdir -p q

q/$(OUTNAME).png: build/cn_qr_initial_loader.bin.png
	@cp build/cn_qr_initial_loader.bin.png q/$(OUTNAME).png

p/$(OUTNAME).bin: build/cn_secondary_payload.bin
	@cp build/cn_secondary_payload.bin p/$(OUTNAME).bin

firm_constants/constants.txt:
	@cd firm_constants && make
spider_constants/constants.txt:
	@cd spider_constants && make
cn_constants/constants.txt:
	@cd cn_constants && make

build/constants: firm_constants/constants.txt spider_constants/constants.txt cn_constants/constants.txt
	@python $(SCRIPTS)/makeHeaders.py $(FIRMVERSION) $(CNVERSION) $(SPIDERVERSION) $(ROVERSION) $(MENUVERSION) build/constants $^

build/cn_qr_initial_loader.bin.png: cn_qr_initial_loader/cn_qr_initial_loader.bin.png
	@cp cn_qr_initial_loader/cn_qr_initial_loader.bin.png build
cn_qr_initial_loader/cn_qr_initial_loader.bin.png:
	@cd cn_qr_initial_loader && make


build/cn_save_initial_loader.bin: cn_save_initial_loader/cn_save_initial_loader.bin
	@cp cn_save_initial_loader/cn_save_initial_loader.bin build
cn_save_initial_loader/cn_save_initial_loader.bin:
	@cd cn_save_initial_loader && make


build/cn_secondary_payload.bin: cn_secondary_payload/cn_secondary_payload.bin
	@python $(SCRIPTS)/blowfish.py cn_secondary_payload/cn_secondary_payload.bin build/cn_secondary_payload.bin scripts
cn_secondary_payload/cn_secondary_payload.bin: build/cn_save_initial_loader.bin build/menu_payload.bin
	@mkdir -p cn_secondary_payload/data
	@cp build/cn_save_initial_loader.bin cn_secondary_payload/data/
	@cp build/menu_payload.bin cn_secondary_payload/data/
	@cd cn_secondary_payload && make

build/menu_payload.bin: menu_payload/menu_payload.bin
	@cp menu_payload/menu_payload.bin build
menu_payload/menu_payload.bin:
	@cd menu_payload && make


clean:
	@rm -rf build/*
	@cd firm_constants && make clean
	@cd cn_constants && make clean
	@cd spider_constants && make clean
	@cd cn_qr_initial_loader && make clean
	@cd cn_save_initial_loader && make clean
	@cd cn_secondary_payload && make clean
	@cd menu_payload && make clean
	@echo "all cleaned up !"
