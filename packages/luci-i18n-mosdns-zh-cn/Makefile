# SPDX-License-Identifier: Apache-2.0
#
# Prebuilt luci-i18n-mosdns-zh-cn (extracted from sbwml release ipk)
# sbwml/luci-app-mosdns v5 branch does not include i18n source

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-i18n-mosdns-zh-cn
PKG_VERSION:=26.157.32907
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0

include $(INCLUDE_DIR)/package.mk

define Package/luci-i18n-mosdns-zh-cn
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=8. Modules
  TITLE:=Translation for mosdns - Chinese (zh-cn)
  PKGARCH:=all
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-i18n-mosdns-zh-cn/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/luci-i18n-mosdns-zh-cn $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/i18n/mosdns.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/
endef

$(eval $(call BuildPackage,luci-i18n-mosdns-zh-cn))
