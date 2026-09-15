import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  ipcTarget: ""
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var metrics: ({
    cpu: { usage: null, ghz: null },
    ram: { usage: null, used_gb: null, total_gb: null },
    ssd: { usage: null, used_gb: null, total_gb: null }
  })
  property bool loading: false

  readonly property color contentForeground: bar ? bar.barForeground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string scriptPath: Qt.resolvedUrl("system-stats").toString().replace(/^file:\/\//, "")

  function number(value) {
    if (value === null || value === undefined || value === "") return null
    var result = Number(value)
    return isFinite(result) ? result : null
  }

  function applyMetrics(raw) {
    try {
      var parsed = JSON.parse(String(raw || ""))
      if (parsed && parsed.cpu && parsed.ram && parsed.ssd)
        root.metrics = parsed
    } catch (error) {
      // Keep the last good sample visible when a command is interrupted.
    }
    root.loading = false
  }

  function refresh() {
    if (statsProc.running) return
    root.loading = true
    statsProc.running = true
  }

  function percent(value) {
    var result = number(value)
    return result === null ? "--" : Math.round(Math.max(0, Math.min(100, result))) + "%"
  }

  function ghz(value) {
    var result = number(value)
    return result === null ? "--" : result.toFixed(2) + " GHz"
  }

  function pair(used, total) {
    var usedValue = number(used)
    var totalValue = number(total)
    return usedValue === null || totalValue === null
      ? "--"
      : usedValue.toFixed(2) + " / " + totalValue.toFixed(2) + " GB"
  }

  function detailRows() {
    var cpu = metrics.cpu || {}
    var ram = metrics.ram || {}
    var ssd = metrics.ssd || {}

    return [
      { label: "CPU", value: percent(cpu.usage), progress: number(cpu.usage), detail: ghz(cpu.ghz) },
      { label: "RAM", value: percent(ram.usage), progress: number(ram.usage), detail: pair(ram.used_gb, ram.total_gb) + " in use" },
      { label: "SSD", value: percent(ssd.usage), progress: number(ssd.usage), detail: pair(ssd.used_gb, ssd.total_gb) + " in use" }
    ]
  }

  Process {
    id: statsProc
    command: ["bash", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyMetrics(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.loading = false
    }
  }

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onOpenedChanged: if (root.opened) root.refresh()

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(statsColumn.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.refresh()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
    }

    Flickable {
      id: statsScroll
      anchors.fill: parent
      contentWidth: width
      contentHeight: statsColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      Column {
        id: statsColumn
        width: statsScroll.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "System usage"
          meta: root.loading ? "UPDATING" : "LIVE · EVERY 2 SECONDS"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          iconComponent: Component {
            Text {
              text: "󰍛"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
              anchors.centerIn: parent
            }
          }
        }

        Repeater {
          model: root.detailRows()

          delegate: Item {
            required property var modelData
            width: statsColumn.width
            height: rowColumn.implicitHeight

            Column {
              id: rowColumn
              width: parent.width
              spacing: Style.space(4)

              Row {
                width: parent.width
                spacing: Style.space(8)

                Text {
                  id: metricLabel
                  text: modelData.label
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Item { width: Math.max(0, parent.width - metricLabel.width - rowValue.implicitWidth - parent.spacing); height: 1 }

                Text {
                  id: rowValue
                  text: modelData.value
                  color: modelData.progress === null ? Qt.darker(root.contentForeground, 1.35) : Color.accent
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
              }

              Text {
                width: parent.width
                text: modelData.detail
                color: Qt.darker(root.contentForeground, 1.35)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }

              Rectangle {
                width: parent.width
                height: Style.space(6)
                radius: height / 2
                color: Style.selectedFillFor(root.contentForeground, Color.accent)

                Rectangle {
                  width: parent.width * (modelData.progress === null ? 0 : Math.max(0, Math.min(100, modelData.progress)) / 100)
                  height: parent.height
                  radius: parent.radius
                  color: Color.accent
                }
              }
            }
          }
        }
      }
    }
  }
}
