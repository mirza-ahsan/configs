import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import qs.Commons as Commons

// Wi-Fi hotspot bar widget. A bar icon that opens a popup with an on/off
// switch, network name, password and band. All the real work is done by
// bin/omarchy-hotspot (NetworkManager's shared-connection mode); this file only
// presents it with Omarchy's own components, so colors, fonts, corner radius
// and borders follow the active theme with no overrides of its own.
Panel {
  id: root
  moduleName: "aztrek.hotspot"
  ipcTarget: "aztrek.hotspot"
  // This panel owns the single IpcHandler its target permits (see below), so
  // it can also expose `power`.
  manageIpc: false

  readonly property string script: String(Qt.resolvedUrl("bin/omarchy-hotspot")).replace(/^file:\/\//, "")

  readonly property string iconOn: "󰀂"   // access-point-network
  readonly property string iconOff: "󰯡"  // access-point-network-off
  readonly property string glyphCheck: "󰄬"
  readonly property string glyphEye: "󰛐"
  readonly property string glyphEyeOff: "󰛑"

  property var status: ({
    available: true, iface: "", active: false, ssid: "", band: "5", bandActual: "",
    band5Available: false, channel: 0, clients: 0, uplink: "", canStart: false,
    hasPassword: false, note: "", error: ""
  })
  property bool loaded: false
  property bool busy: false
  property string busyText: ""
  property string errorText: ""
  property bool revealed: false
  property bool gotResult: false
  // The name the field was last filled from the backend with. Polling only
  // refreshes the field while it still shows that value, so a half-typed name
  // is never overwritten underneath the user.
  property string ssidSynced: ""

  readonly property bool hotspotActive: !!status.active
  // The band the hotspot is on, or would use if started now.
  readonly property string effectiveBand: {
    if (hotspotActive && status.bandActual !== "") return status.bandActual
    if (status.band === "5" && !status.band5Available) return "2.4"
    return status.band
  }
  readonly property string heroCaption: {
    if (busy) return busyText
    if (!loaded) return "CHECKING…"
    if (!status.available) return "NO WI-FI ADAPTER"
    if (hotspotActive) {
      const n = status.clients
      return "ON · " + effectiveBand + " GHZ · " + n + (n === 1 ? " DEVICE" : " DEVICES")
    }
    if (!status.canStart) return "NEEDS ETHERNET"
    return "OFF"
  }
  readonly property string barTooltip: {
    if (!status.available) return "Hotspot: no Wi-Fi adapter"
    if (hotspotActive) return "Hotspot on: " + status.ssid + " (" + effectiveBand + " GHz, " + status.clients + " connected)"
    return "Hotspot off"
  }

  // Keyboard cursor, shared with the mouse like the built-in panels.
  // Rows: power switch, network name, password, band chips.
  readonly property var rows: ["power", "ssid", "password", "band"]
  property int rowIndex: 0
  property int bandIndex: 0
  property bool cursorActive: false
  readonly property string focusRow: rows[rowIndex]

  function parseResult(text, isAction) {
    var parsed = null
    try { parsed = JSON.parse(String(text || "").trim()) } catch (e) {}
    if (!parsed || typeof parsed !== "object") {
      if (isAction) errorText = "The hotspot helper returned an unexpected answer"
      return false
    }
    status = parsed
    loaded = true
    if (isAction) errorText = parsed.error || ""
    const incoming = parsed.ssid || ""
    if (!ssidField.activeFocus && (ssidField.text === ssidSynced || !opened)) ssidField.text = incoming
    ssidSynced = incoming
    return true
  }

  function runAction(args, label) {
    if (busy) return
    busy = true
    busyText = label
    errorText = ""
    gotResult = false
    actionProc.command = [script].concat(args)
    actionProc.running = true
  }

  function toggleHotspot() {
    if (busy || !status.available) return
    if (!hotspotActive && !status.canStart) {
      errorText = "Connect Ethernet (or another non-Wi-Fi link) first. The hotspot uses the Wi-Fi radio."
      return
    }
    runAction([hotspotActive ? "off" : "on"], hotspotActive ? "STOPPING…" : "STARTING…")
  }

  function applySsid() {
    var name = ssidField.text
    if (name === "" || name === status.ssid) return
    runAction(["set-ssid", name], "APPLYING…")
  }

  function applyPassword() {
    var pw = pwField.text
    if (pw === "") return
    if (pw.length < 8 || pw.length > 63) {
      errorText = "Password must be 8-63 characters"
      return
    }
    runAction(["set-password", pw], "APPLYING…")
  }

  function setBand(band) {
    if (band === "5" && !status.band5Available) return
    if (band === effectiveBand && band === status.band) return
    runAction(["set-band", band], "SWITCHING BAND…")
  }

  function toggleReveal() {
    if (revealed) {
      revealed = false
      pwField.text = ""
      return
    }
    if (pwField.text === "") {
      if (!pwProc.running) pwProc.running = true
    } else {
      revealed = true
    }
  }

  function refresh() {
    if (!busy && !statusProc.running) statusProc.running = true
  }

  function clearSecrets() {
    pwField.text = ""
    revealed = false
  }

  function clampCursor() {
    if (rowIndex < 0) rowIndex = 0
    if (rowIndex > rows.length - 1) rowIndex = rows.length - 1
  }

  function moveCursor(dy) {
    rowIndex = Math.max(0, Math.min(rows.length - 1, rowIndex + dy))
    if (focusRow === "band") bandIndex = effectiveBand === "5" ? 0 : 1
  }

  function activateCursor() {
    if (focusRow === "power") toggleHotspot()
    else if (focusRow === "ssid") ssidField.forceActiveFocus()
    else if (focusRow === "password") pwField.forceActiveFocus()
    else if (focusRow === "band") setBand(bandIndex === 0 ? "5" : "2.4")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: refresh()

  onOpenedChanged: {
    if (opened) {
      refresh()
      rowIndex = 0
      cursorActive = false
      errorText = ""
    } else {
      clearSecrets()
    }
  }

  Timer {
    interval: root.opened ? 3000 : 15000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: [root.script, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseResult(text, false)
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.gotResult = root.parseResult(text, true)
    }
    onExited: function(exitCode) {
      root.busy = false
      // Drop the arguments (they can carry the new password) as soon as the
      // helper is done with them.
      actionProc.command = []
      if (!root.gotResult && root.errorText === "") root.errorText = "The hotspot helper failed (exit " + exitCode + ")"
      if (exitCode === 0) {
        // A password or name change succeeded: the typed secret has done its job.
        if (!root.revealed) pwField.text = ""
      }
      // The fields are disabled while busy, which drops their focus; put the
      // keyboard back on the panel so Esc closes it again.
      if (root.opened) Qt.callLater(function() { keyCatcher.forceActiveFocus() })
      root.refresh()
    }
  }

  // Fetches the current password only when the user clicks the eye; it lives in
  // the (cleared-on-close) field and nowhere else.
  Process {
    id: pwProc
    command: [root.script, "get-password"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        // The popup may have been closed while this was running; the password
        // must not reappear in a closed panel.
        if (!root.opened) return
        const pw = String(text || "").replace(/\n$/, "")
        if (pw !== "") {
          pwField.text = pw
          root.revealed = true
        } else {
          root.errorText = "Could not read the current password"
        }
      }
    }
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function power(): void { root.toggleHotspot() }
    function on(): void { if (!root.hotspotActive) root.toggleHotspot() }
    function off(): void { if (root.hotspotActive) root.toggleHotspot() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.hotspotActive ? root.iconOn : root.iconOff
    dimmed: !root.hotspotActive
    useActiveColor: false
    tooltipText: root.barTooltip
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleHotspot()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight + Style.space(4), Style.space(620))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      // The text fields own the keyboard while one of them is focused.
      blocked: ssidField.activeFocus || pwField.activeFocus

      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0 && root.focusRow === "band") root.bandIndex = Math.max(0, Math.min(1, root.bandIndex + dx))
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(14)

        // ---------- Hero: icon, title and status, power switch ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: root.hotspotActive ? root.iconOn : root.iconOff
            color: root.bar.foreground
            opacity: root.hotspotActive ? 1.0 : 0.6
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: powerSwitch.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Hotspot"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.heroCaption
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          ToggleSwitch {
            id: powerSwitch
            visible: root.status.available
            checked: root.hotspotActive
            busy: root.busy
            hasCursor: root.cursorActive && root.focusRow === "power"
            foreground: root.bar.foreground
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onHovered: function(on) { if (on) { root.cursorActive = true; root.rowIndex = 0 } }
            onToggled: root.toggleHotspot()

            PanelToolTip {
              visible: powerSwitch.containsMouse
              text: root.hotspotActive ? "Turn hotspot off" : "Turn hotspot on"
              fontFamily: root.bar.fontFamily
            }
          }
        }

        // ---------- Network name ----------
        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "NETWORK NAME"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Item {
            width: parent.width
            implicitHeight: ssidField.implicitHeight

            TextField {
              id: ssidField
              anchors.left: parent.left
              anchors.right: ssidApply.left
              anchors.rightMargin: Style.space(6)
              placeholderText: "Network name"
              maximumLength: 32
              foreground: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              horizontalPadding: Style.spacing.controlGap
              verticalPadding: Style.spacing.controlPaddingY
              enabled: !root.busy
              hasCursor: root.cursorActive && root.focusRow === "ssid"
              onAccepted: { root.applySsid(); keyCatcher.forceActiveFocus() }
              Keys.onEscapePressed: {
                text = root.status.ssid || ""
                keyCatcher.forceActiveFocus()
              }
              onHoveredChanged: if (hovered) { root.cursorActive = true; root.rowIndex = 1 }
            }

            PanelActionButton {
              id: ssidApply
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              enabled: !root.busy && ssidField.text !== "" && ssidField.text !== root.status.ssid
              iconText: root.glyphCheck
              tooltipText: "Apply name"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              onClicked: root.applySsid()
            }
          }
        }

        // ---------- Password ----------
        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "PASSWORD"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Item {
            width: parent.width
            implicitHeight: pwField.implicitHeight

            TextField {
              id: pwField
              anchors.left: parent.left
              anchors.right: pwReveal.left
              anchors.rightMargin: Style.space(6)
              password: !root.revealed
              placeholderText: root.status.hasPassword ? "New password (8-63 characters)" : "Set a password (8-63 characters)"
              maximumLength: 63
              foreground: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              horizontalPadding: Style.spacing.controlGap
              verticalPadding: Style.spacing.controlPaddingY
              enabled: !root.busy
              hasCursor: root.cursorActive && root.focusRow === "password"
              onAccepted: { root.applyPassword(); keyCatcher.forceActiveFocus() }
              Keys.onEscapePressed: {
                text = ""
                root.revealed = false
                keyCatcher.forceActiveFocus()
              }
              onHoveredChanged: if (hovered) { root.cursorActive = true; root.rowIndex = 2 }
            }

            PanelActionButton {
              id: pwReveal
              anchors.right: pwApply.left
              anchors.rightMargin: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              enabled: !root.busy && root.status.hasPassword
              iconText: root.revealed ? root.glyphEyeOff : root.glyphEye
              tooltipText: root.revealed ? "Hide password" : "Show current password"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              onClicked: root.toggleReveal()
            }

            PanelActionButton {
              id: pwApply
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              enabled: !root.busy && pwField.text.length >= 8
              iconText: root.glyphCheck
              tooltipText: "Apply password"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              onClicked: root.applyPassword()
            }
          }
        }

        // ---------- Band ----------
        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "BAND"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Row {
            spacing: Style.spacing.md

            BandChip {
              chipIndex: 0
              bandValue: "5"
              text: "5 GHz"
              usable: root.status.band5Available
            }

            BandChip {
              chipIndex: 1
              bandValue: "2.4"
              text: "2.4 GHz"
              usable: true
            }
          }

          Text {
            visible: text !== ""
            width: parent.width
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            text: {
              if (root.hotspotActive && root.status.note !== "") return root.status.note
              if (!root.status.band5Available) return "5 GHz isn't allowed by this Wi-Fi card here right now, so 2.4 GHz is used."
              return ""
            }
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        // ---------- Details ----------
        PanelSeparator {
          visible: root.hotspotActive || root.status.uplink !== ""
          foreground: root.bar.foreground
        }

        Column {
          visible: root.hotspotActive || root.status.uplink !== ""
          width: parent.width
          spacing: Style.space(4)

          DetailRow {
            label: "Sharing"
            value: root.status.uplink !== "" ? root.status.uplink : "nothing to share"
          }
          DetailRow {
            visible: root.hotspotActive
            label: "Channel"
            value: root.status.channel > 0 ? String(root.status.channel) : "–"
          }
          DetailRow {
            visible: root.hotspotActive
            label: "Connected"
            value: String(root.status.clients)
          }
        }

        // ---------- Errors ----------
        Text {
          visible: root.errorText !== ""
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          text: root.errorText
          color: root.bar.urgent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Item {
          width: parent.width
          height: Style.space(2)
        }
      }
    }
  }

  component DetailRow: Item {
    id: detail
    property string label: ""
    property string value: ""
    width: parent ? parent.width : 0
    implicitHeight: Math.max(detailLabel.implicitHeight, detailValue.implicitHeight)

    Text {
      id: detailLabel
      textFormat: Text.PlainText
      text: detail.label
      color: Qt.darker(root.bar.foreground, 1.4)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
      anchors.left: parent.left
      anchors.leftMargin: Style.space(6)
    }

    Text {
      id: detailValue
      textFormat: Text.PlainText
      text: detail.value
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideMiddle
      horizontalAlignment: Text.AlignRight
      anchors.right: parent.right
      anchors.rightMargin: Style.space(6)
      anchors.left: detailLabel.right
      anchors.leftMargin: Style.space(12)
    }
  }

  component BandChip: Button {
    id: chip
    required property int chipIndex
    required property string bandValue
    property bool usable: true

    fontSize: Style.font.caption
    foreground: root.bar.foreground
    fontFamily: root.bar.fontFamily
    horizontalPadding: Style.spacing.md
    verticalPadding: Style.spacing.controlPaddingY
    bordered: true
    enabled: usable && !root.busy
    opacity: usable ? 1.0 : 0.45
    tooltipText: usable ? "" : "Not allowed by this Wi-Fi card here right now"

    active: root.effectiveBand === bandValue
    hasCursor: root.cursorActive && root.focusRow === "band" && root.bandIndex === chipIndex

    onClicked: root.setBand(bandValue)
    onHovered: function(isHovered) {
      if (!isHovered) return
      root.cursorActive = true
      root.rowIndex = 3
      root.bandIndex = chipIndex
    }
  }
}
