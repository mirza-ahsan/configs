import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "hotspotControl"

    StyledText {
        width: parent.width
        text: "Wi-Fi Hotspot Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Network name, password and band are stored in the NetworkManager \"Hotspot\" profile. Change them from the hotspot popout in DankBar."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "device"
        label: "Wireless Interface"
        description: "Wi-Fi card used for the hotspot"
        placeholder: "wlan0"
        defaultValue: "wlan0"
    }

    ToggleSetting {
        settingKey: "concurrent"
        label: "Share Wi-Fi Connection"
        description: "Keep your Wi-Fi connected and run the hotspot on a virtual interface (ap0) on the same channel, so no Ethernet is needed. The band follows your Wi-Fi network. Needs a one-time setup: sudo ~/.config/DankMaterialShell/plugins/hotspotControl/scripts/setup-concurrent.sh"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "autoUnblock"
        label: "Auto-Unblock Wi-Fi Radio"
        description: "Run rfkill unblock before starting the hotspot"
        defaultValue: true
    }
}
