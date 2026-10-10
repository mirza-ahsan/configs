import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property string helperScript: Paths.strip(Paths.config) + "/plugins/hotspotControl/scripts/hotspot-ctl.sh"
    // nmcli connection up/down can take well over Proc's 10s default
    readonly property int actionTimeoutMs: 120000
    // Proc merges calls that share an id, so each instance (bar pill, CC tile) needs its own
    readonly property string procKey: Math.random().toString(36).slice(2)

    // State properties
    property bool isActive: false
    property bool isWorking: false
    property string statusSSID: ""
    property string statusPassword: ""
    property string statusBand: "bg"
    property string statusDevice: "wlan0"
    property string statusIP: ""
    property int statusClients: 0
    property string statusUpstream: ""
    property string statusMode: ""
    property bool statusWifiBlocked: false

    readonly property bool concurrentEnabled: !!pluginData.concurrent
    readonly property string upstreamLabel: (!statusUpstream || statusUpstream === "none") ? "None" : statusUpstream

    // Editable fields for popout (reset from status each time it opens)
    property string editSSID: ""
    property string editPassword: ""
    property string editBand: "bg"
    property bool showPasswordText: false

    // Control Center properties
    ccWidgetIcon: isActive ? "wifi_tethering" : "wifi_tethering_off"
    ccWidgetPrimaryText: "Hotspot"
    ccWidgetSecondaryText: {
        if (isWorking) return "Updating...";
        if (isActive) {
            const clientInfo = statusClients > 0 ? ` (${statusClients} device${statusClients === 1 ? "" : "s"})` : "";
            return `${statusSSID}${clientInfo}`;
        }
        return "Off";
    }
    ccWidgetIsActive: isActive
    ccWidgetIsToggle: true

    onCcWidgetToggled: {
        toggleHotspot();
    }

    Component.onCompleted: {
        refreshStatus();
    }

    onPluginDataChanged: refreshStatus()

    // Poll periodically to stay in sync with changes made outside DMS
    Timer {
        id: statusPoller
        interval: root.isActive ? 5000 : 15000
        repeat: true
        running: true
        onTriggered: root.refreshStatus()
    }

    Connections {
        target: NetworkService
        function onConnectionChanged() {
            root.refreshStatus();
        }
    }

    function refreshStatus() {
        Proc.runCommand(
            `hotspot.status.${procKey}`,
            [helperScript, "status"],
            (output, exitCode) => {
                if (exitCode === 0 && output && output.trim()) {
                    try {
                        const data = JSON.parse(output.trim());
                        root.isActive = !!data.active;
                        root.statusSSID = data.ssid || "";
                        root.statusPassword = data.password || "";
                        root.statusBand = data.band || "bg";
                        root.statusDevice = data.device || "wlan0";
                        root.statusIP = data.ip || "";
                        root.statusClients = data.clients || 0;
                        root.statusUpstream = data.upstream || "";
                        root.statusMode = data.mode || "";
                        root.statusWifiBlocked = !!data.wifiBlocked;
                    } catch (e) {
                        console.log("hotspotControl: failed to parse status", e);
                    }
                }
            },
            undefined,
            undefined,
            root
        );
    }

    function resetEditFields() {
        editSSID = statusSSID;
        editPassword = statusPassword;
        editBand = statusBand === "a" ? "a" : "bg";
        showPasswordText = false;
    }

    function toggleHotspot() {
        if (isWorking) return;
        isWorking = true;
        const wasActive = isActive;
        Proc.runCommand(
            "hotspot.toggle",
            [helperScript, "toggle"],
            (output, exitCode) => {
                isWorking = false;
                refreshStatus();
                if (exitCode === 0) {
                    ToastService.showInfo("Wi-Fi Hotspot", wasActive ? "Hotspot turned off" : "Hotspot activated");
                } else {
                    ToastService.showError("Hotspot Error", (output || "").trim() || "Failed to toggle hotspot");
                }
            },
            0,
            actionTimeoutMs
        );
    }

    function applySettings(newSsid, newPass, newBand) {
        if (isWorking) return;
        if (!newSsid || newSsid.trim() === "") {
            ToastService.showError("Validation Error", "SSID cannot be empty");
            return;
        }
        // SSIDs are limited to 32 bytes (UTF-8), not characters
        const ssidBytes = encodeURIComponent(newSsid.trim()).replace(/%[0-9A-F]{2}/g, "x").length;
        if (ssidBytes > 32) {
            ToastService.showError("Validation Error", `SSID is too long (${ssidBytes} bytes, max 32; accented letters and emoji take 2-4 bytes each)`);
            return;
        }
        if (newPass && (newPass.length < 8 || newPass.length > 63)) {
            ToastService.showError("Validation Error", "Password must be 8-63 characters");
            return;
        }
        if (newPass && !/^[\x20-\x7E]*$/.test(newPass)) {
            ToastService.showError("Validation Error", "Password can only contain standard keyboard characters (no accents or emoji)");
            return;
        }
        const bandChanged = newBand !== "" && newBand !== (statusBand === "a" ? "a" : "bg");
        if (newSsid.trim() === statusSSID && (!newPass || newPass === statusPassword) && !bandChanged) {
            ToastService.showInfo("Wi-Fi Hotspot", "No changes to save");
            return;
        }

        isWorking = true;
        Proc.runCommand(
            "hotspot.configure",
            [helperScript, "configure", newSsid.trim(), newPass, newBand],
            (output, exitCode) => {
                isWorking = false;
                refreshStatus();
                if (exitCode === 0) {
                    ToastService.showInfo("Hotspot Configured", "Settings updated successfully");
                } else {
                    ToastService.showError("Configuration Failed", (output || "").trim() || "Error applying settings");
                }
            },
            0,
            actionTimeoutMs
        );
    }

    function copyToClipboard(textToCopy, label) {
        Proc.runCommand(
            "hotspot.copy",
            ["dms", "clipboard", "copy", textToCopy],
            (output, exitCode) => {
                if (exitCode === 0) {
                    ToastService.showInfo("Copied", `${label} copied to clipboard`);
                } else {
                    ToastService.showError("Copy Failed", `Could not copy ${label.toLowerCase()}`);
                }
            }
        );
    }

    // -------------------------------------------------------------
    // Horizontal Bar Pill (Top / Bottom DankBar)
    // -------------------------------------------------------------
    // Icon only; SSID and client count live in the popout and CC tile
    horizontalBarPill: Component {
        DankIcon {
            name: root.isActive ? "wifi_tethering" : "wifi_tethering_off"
            color: root.isActive ? Theme.primary : Theme.surfaceVariantText
            size: Theme.iconSize - 4
        }
    }

    // -------------------------------------------------------------
    // Vertical Bar Pill (Left / Right DankBar)
    // -------------------------------------------------------------
    verticalBarPill: Component {
        DankIcon {
            name: root.isActive ? "wifi_tethering" : "wifi_tethering_off"
            color: root.isActive ? Theme.primary : Theme.surfaceVariantText
            size: Theme.iconSize - 4
        }
    }

    // -------------------------------------------------------------
    // Control Center Dropdown Detail View
    // -------------------------------------------------------------
    ccDetailHeight: 250
    ccDetailContent: Component {
        Rectangle {
            id: detailRoot
            implicitHeight: detailCol.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: detailCol
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                // Header status
                RowLayout {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: root.isActive ? "wifi_tethering" : "wifi_tethering_off"
                        color: root.isActive ? Theme.primary : Theme.surfaceVariantText
                        size: Theme.iconSizeLarge
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            width: parent.width
                            text: root.isActive ? "Hotspot Active" : "Hotspot Disabled"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: root.isActive ? Theme.primary : Theme.surfaceText
                            elide: Text.ElideRight
                        }

                        StyledText {
                            width: parent.width
                            text: root.isActive ? `SSID: ${root.statusSSID} • ${root.statusClients} connected` : "Tap toggle to broadcast"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            elide: Text.ElideRight
                        }
                    }

                    DankButton {
                        text: root.isActive ? "Turn Off" : "Turn On"
                        iconName: root.isActive ? "power_settings_new" : "wifi_tethering"
                        backgroundColor: root.isActive ? Theme.withAlpha(Theme.error, 0.15) : Theme.primary
                        textColor: root.isActive ? Theme.error : Theme.onPrimary
                        buttonHeight: 36
                        enabled: !root.isWorking
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.toggleHotspot()
                    }
                }

                // Info Rows
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.withAlpha(Theme.surfaceVariantText, 0.2)
                }

                RowLayout {
                    width: parent.width
                    spacing: Theme.spacingL

                    Column {
                        spacing: 4
                        StyledText {
                            text: "Password"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        StyledText {
                            text: root.statusPassword
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                    }

                    Column {
                        spacing: 4
                        StyledText {
                            text: "Band"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        StyledText {
                            text: root.statusBand === "a" ? "5 GHz" : "2.4 GHz"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                    }

                    Column {
                        spacing: 4
                        StyledText {
                            text: "Gateway IP"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                        StyledText {
                            text: root.statusIP || "—"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    DankButton {
                        text: "Copy Pass"
                        iconName: "content_copy"
                        backgroundColor: Theme.surfaceContainerHighest
                        textColor: Theme.surfaceText
                        buttonHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.copyToClipboard(root.statusPassword, "Password")
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------
    // Popout Dialog (Opens on DankBar pill click)
    // -------------------------------------------------------------
    popoutWidth: 380
    popoutHeight: 500
    popoutContent: Component {
        PopoutComponent {
            id: popoutRoot
            headerText: "Wi-Fi Hotspot"
            detailsText: {
                if (!root.isActive) return root.concurrentEnabled ? "Shares your Wi-Fi connection" : "Portable Wi-Fi hotspot";
                return `Broadcasting on ${root.statusDevice} • ${root.statusBand === 'a' ? '5 GHz' : '2.4 GHz'}`;
            }
            showCloseButton: true

            Component.onCompleted: root.resetEditFields()

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // --- 1. Main Power / Status Card ---
                Rectangle {
                    width: parent.width
                    height: 64
                    radius: Theme.cornerRadius
                    color: root.isActive ? Theme.withAlpha(Theme.primary, 0.12) : Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: root.isActive ? Theme.primary : Theme.withAlpha(Theme.surfaceVariantText, 0.15)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        DankIcon {
                            name: root.isActive ? "wifi_tethering" : "wifi_tethering_off"
                            color: root.isActive ? Theme.primary : Theme.surfaceVariantText
                            size: Theme.iconSizeLarge
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            StyledText {
                                text: root.isWorking ? "Working..." : (root.isActive ? "Hotspot Active" : "Hotspot Inactive")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: root.isActive ? Theme.primary : Theme.surfaceText
                            }

                            StyledText {
                                text: root.isActive ? `${root.statusClients} connected client${root.statusClients === 1 ? "" : "s"}` : "Ready to start"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }

                        DankButton {
                            text: root.isActive ? "Stop" : "Start"
                            iconName: root.isActive ? "power_settings_new" : "wifi_tethering"
                            backgroundColor: root.isActive ? Theme.withAlpha(Theme.error, 0.15) : Theme.primary
                            textColor: root.isActive ? Theme.error : Theme.onPrimary
                            buttonHeight: 36
                            enabled: !root.isWorking
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: root.toggleHotspot()
                        }
                    }
                }

                // --- 2. Configuration Form ---
                Rectangle {
                    width: parent.width
                    height: configCol.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: configCol
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        StyledText {
                            text: "Hotspot Settings"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        // SSID input
                        StyledText {
                            text: "Network Name (SSID)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        DankTextField {
                            id: ssidField
                            width: parent.width
                            text: root.editSSID
                            placeholderText: "SSID name"
                            leftIconName: "wifi"
                            onTextChanged: root.editSSID = text
                        }

                        // Password input
                        StyledText {
                            text: "Password (WPA2-PSK)"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingXS

                            DankTextField {
                                id: passField
                                width: parent.width - 44
                                text: root.editPassword
                                placeholderText: "Min 8 characters"
                                echoMode: root.showPasswordText ? TextInput.Normal : TextInput.Password
                                leftIconName: "lock"
                                onTextChanged: root.editPassword = text
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                radius: Theme.cornerRadius
                                color: eyeMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                                anchors.verticalCenter: parent.verticalCenter

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: root.showPasswordText ? "visibility_off" : "visibility"
                                    size: Theme.iconSize - 4
                                    color: Theme.surfaceText
                                }

                                MouseArea {
                                    id: eyeMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showPasswordText = !root.showPasswordText
                                }
                            }
                        }

                        // Band selection
                        StyledText {
                            text: root.concurrentEnabled ? "Frequency Band (follows your Wi-Fi network while sharing)" : "Frequency Band"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS
                            enabled: !root.concurrentEnabled
                            opacity: enabled ? 1 : 0.5

                            Rectangle {
                                width: (parent.width - Theme.spacingS) / 2
                                height: 36
                                radius: Theme.cornerRadius
                                color: root.editBand === "bg" ? Theme.primary : Theme.surfaceContainerHighest

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS
                                    DankIcon {
                                        name: "wifi"
                                        size: Theme.iconSize - 6
                                        color: root.editBand === "bg" ? Theme.onPrimary : Theme.surfaceText
                                    }
                                    StyledText {
                                        text: "2.4 GHz"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: root.editBand === "bg" ? Theme.onPrimary : Theme.surfaceText
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.editBand = "bg"
                                }
                            }

                            Rectangle {
                                width: (parent.width - Theme.spacingS) / 2
                                height: 36
                                radius: Theme.cornerRadius
                                color: root.editBand === "a" ? Theme.primary : Theme.surfaceContainerHighest

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS
                                    DankIcon {
                                        name: "bolt"
                                        size: Theme.iconSize - 6
                                        color: root.editBand === "a" ? Theme.onPrimary : Theme.surfaceText
                                    }
                                    StyledText {
                                        text: "5 GHz"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: root.editBand === "a" ? Theme.onPrimary : Theme.surfaceText
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.editBand = "a"
                                }
                            }
                        }

                        Item { width: 1; height: Theme.spacingXS }

                        // Save Button
                        DankButton {
                            width: parent.width
                            text: root.isActive ? "Save & Restart Hotspot" : "Save Changes"
                            iconName: "save"
                            backgroundColor: Theme.primary
                            textColor: Theme.onPrimary
                            buttonHeight: 38
                            enabled: !root.isWorking
                            onClicked: {
                                // Band is dictated by the upstream channel in concurrent mode
                                root.applySettings(root.editSSID, root.editPassword, root.concurrentEnabled ? "" : root.editBand);
                            }
                        }
                    }
                }

                // --- 3. Gateway & Network Info ---
                RowLayout {
                    width: parent.width
                    spacing: Theme.spacingM

                    StyledText {
                        text: `Gateway: ${root.statusIP || '—'} • Upstream: ${root.upstreamLabel}`
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    DankButton {
                        text: "Copy Pass"
                        iconName: "content_copy"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        buttonHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root.copyToClipboard(root.statusPassword, "Password")
                    }
                }
            }
        }
    }
}
