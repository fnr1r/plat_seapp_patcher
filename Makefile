VERSION := $(shell jq -r ".version" update.json)
MODULE_ZIP := plat_seapp_patcher-$(VERSION).zip
TEST_TEMP_PATH := /data/local/tmp/$(MODULE_ZIP)

.PHONY: all
all: $(MODULE_ZIP)

$(MODULE_ZIP):
	cd module && zip -r ../$@ *

.PHONY: clean
clean:
	rm $(MODULE_ZIP)

.PHONY: test
test: $(MODULE_ZIP)
	adb push $(MODULE_ZIP) $(TEST_TEMP_PATH)
	adb shell su -c ksud module install $(TEST_TEMP_PATH)
	adb shell rm -v $(TEST_TEMP_PATH)
