TARGET := iphone:clang:15.0:14.0
ARCHS = arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoUpdateAlert
NoUpdateAlert_FILES = Tweak.x
NoUpdateAlert_CFLAGS = -fobjc-arc
NoUpdateAlert_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
