export ARCHS = arm64
export TARGET=iphone:11.2:10.0
export TARGET_CODESIGN_FLAGS="-Ssign.plist"
SYSROOT=$(THEOS)/sdks/iPhoneOS12.4.sdk

include $(THEOS)/makefiles/common.mk

TOOL_NAME = installipa15
installipa15_FILES = \
					UIDevice-Capabilities/UIDevice-Capabilities.m \
					main.m

installipa15_FRAMEWORKS = UIKit CoreGraphics Foundation
installipa15_PRIVATE_FRAMEWORKS = GraphicsServices MobileCoreServices
installipa15_CFLAGS = -fno-objc-arc
installipa15_INSTALL_PATH = /var/jb/usr/bin/

include $(THEOS)/makefiles/tool.mk
include $(THEOS)/makefiles/aggregate.mk

