import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property var bar
  property string moduleName: "local.fan-control"
  property var settings: ({})
  property bool popupOpen: false
  property bool maxActive: false
  property bool fixedActive: false
  property string pendingMaxMode: ""
  property bool busy: false
  property int cpuTemp: -1
  property int lowTemp: 60
  property int midTemp: 73
  property int maxTemp: 90
  property int fixedPercent: 50
  property string message: ""

  implicitWidth: bar && bar.vertical ? bar.barSize : Style.space(50)
  implicitHeight: bar ? bar.barSize : Style.bar.sizeHorizontal

  function refresh() {
    if (!cpuTempProc.running) cpuTempProc.running = true
    if (!maxStatusProc.running) maxStatusProc.running = true
    if (!fixedStatusProc.running) fixedStatusProc.running = true
    if (!curveStatusProc.running) curveStatusProc.running = true
  }

  function open() {
    refresh()
    popupOpen = true
  }

  function close() {
    popupOpen = false
  }

  function toggle() {
    if (popupOpen) close()
    else open()
  }

  function parseMaxStatus(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      maxActive = data.class === "active"
    } catch (e) {
      maxActive = false
    }
  }

  function parseFixedStatus(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      fixedActive = data.active === true
      var parsed = Number(data.percent)
      if (parsed >= 20 && parsed <= 100) fixedPercent = Math.round(parsed)
    } catch (e) {
      fixedActive = false
    }
  }

  function parseCpuTemp(raw) {
    var match = String(raw || "").match(/[0-9]+/)
    cpuTemp = match ? parseInt(match[0], 10) : -1
  }

  function parseCurveStatus(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      lowTemp = Number(data.low) || lowTemp
      midTemp = Number(data.mid) || midTemp
      maxTemp = Number(data.max) || maxTemp
      if (!minField.activeFocus) minField.text = String(lowTemp)
      if (!midField.activeFocus) midField.text = String(midTemp)
      if (!maxField.activeFocus) maxField.text = String(maxTemp)
    } catch (e) {
      message = "Eğri okunamadı"
    }
  }

  function validCurve(low, mid, max) {
    return Math.floor(low) === low && Math.floor(mid) === mid && Math.floor(max) === max
      && low >= 30 && low < mid && mid < max && max <= 90
  }

  function parseTemp(field) {
    var raw = String(field.text || "").trim()
    return /^[0-9]{2,3}$/.test(raw) ? parseInt(raw, 10) : -1
  }

  function setMax(mode) {
    if (busy) return
    busy = true
    message = "Yetkilendirme bekleniyor..."
    if (mode === "on" && fixedActive) {
      pendingMaxMode = mode
      fixedSetProc.command = ["pkexec", "/home/anon/.config/omarchy/bar/scripts/omarchy-fan-fixed-set", "off"]
      fixedSetProc.running = true
      return
    }
    actionProc.command = ["pkexec", "/usr/local/bin/omarchy-fan-max-toggle", mode]
    actionProc.running = true
  }

  function setFixed() {
    if (busy) return
    busy = true
    message = "Yetkilendirme bekleniyor..."
    pendingMaxMode = ""
    fixedSetProc.command = ["pkexec", "/home/anon/.config/omarchy/bar/scripts/omarchy-fan-fixed-set", String(Math.round(fixedPercent))]
    fixedSetProc.running = true
  }

  function setAuto() {
    if (busy) return
    busy = true
    message = "Yetkilendirme bekleniyor..."
    if (fixedActive) {
      pendingMaxMode = ""
      fixedSetProc.command = ["pkexec", "/home/anon/.config/omarchy/bar/scripts/omarchy-fan-fixed-set", "off"]
      fixedSetProc.running = true
    } else {
      actionProc.command = ["pkexec", "/usr/local/bin/omarchy-fan-max-toggle", "off"]
      actionProc.running = true
    }
  }

  function saveCurve() {
    if (busy) return
    var low = root.parseTemp(minField)
    var mid = root.parseTemp(midField)
    var max = root.parseTemp(maxField)
    if (!validCurve(low, mid, max)) {
      message = "Min/Mid/Max: 30–90°C ve Min < Mid < Max olmalı (girilen: " + low + "/" + mid + "/" + max + ")"
      return
    }
    busy = true
    message = "Yetkilendirme bekleniyor..."
    curveSetProc.command = ["pkexec", "/usr/local/bin/omarchy-fan-curve-set", String(low), String(mid), String(max)]
    curveSetProc.running = true
  }

  BorderSurface {
    id: trigger
    anchors.fill: parent
    color: triggerMouse.containsMouse
      ? Style.hoverFillFor(root.maxActive ? Color.accent : (root.bar ? root.bar.foreground : Color.foreground), Color.accent)
      : "transparent"
    borderSpec: Border.none()
    radius: Style.cornerRadius

    Text {
      anchors.centerIn: parent
      text: root.cpuTemp >= 0 ? root.cpuTemp + "°C" : "--°C"
      color: root.maxActive ? Color.accent : (root.bar ? root.bar.foreground : Color.foreground)
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
    }

    MouseArea {
      id: triggerMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggle()
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(contentColumn.implicitHeight)

    Column {
      id: contentColumn
      anchors.fill: parent
      spacing: Style.space(8)

      Text {
        text: "Fan kontrolü"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.heading
        font.bold: true
      }

      Text {
        text: "Fan modu"
        color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Button {
        width: parent.width
        text: root.maxActive ? "Max Fan (aktif)" : "Max Fan"
        iconText: "󰈐"
        leftAlign: true
        selected: root.maxActive
        enabled: !root.busy
        onClicked: root.setMax(root.maxActive ? "off" : "on")
      }

      Item {
        width: parent.width
        height: Style.space(24)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Sabit fan hızı"
          color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: Math.round(fixedSlider.dragging ? fixedSlider.liveValue : root.fixedPercent) + "%"
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      Item {
        width: parent.width
        height: fixedSlider.implicitHeight

        PanelSlider {
          id: fixedSlider
          anchors.fill: parent
          bar: root.bar
          minimum: 20
          maximum: 100
          step: 1
          integer: true
          value: root.fixedPercent
          tickCount: 5
          enabled: !root.busy
          onMoved: function(value) { root.fixedPercent = Math.round(value) }
        }
      }

      Button {
        width: parent.width
        text: root.fixedActive ? "Sabit hızı uygula (" + root.fixedPercent + "%)" : "Sabit hızı uygula"
        iconText: "󰈐"
        leftAlign: true
        selected: root.fixedActive
        enabled: !root.busy
        onClicked: root.setFixed()
      }

      Button {
        width: parent.width
        text: "Otomatik eğriye dön"
        iconText: "󰒓"
        leftAlign: true
        enabled: !root.busy && (root.maxActive || root.fixedActive)
        onClicked: root.setAuto()
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 2.5)
        opacity: 0.35
      }

      Text {
        text: "Fan curve sıcaklıkları (°C)"
        color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
      }

      Item {
        width: parent.width
        height: Style.space(32)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(150)
          text: "Min"
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        TextField {
          id: minField
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(70)
          text: String(root.lowTemp)
          horizontalAlignment: TextInput.AlignHCenter
          enabled: true
          readOnly: false
          selectByMouse: true
          inputMethodHints: Qt.ImhDigitsOnly
        }
      }

      Item {
        width: parent.width
        height: Style.space(32)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(150)
          text: "Mid / ramp başlangıcı"
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        TextField {
          id: midField
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(70)
          text: String(root.midTemp)
          horizontalAlignment: TextInput.AlignHCenter
          enabled: true
          readOnly: false
          selectByMouse: true
          inputMethodHints: Qt.ImhDigitsOnly
        }
      }

      Item {
        width: parent.width
        height: Style.space(32)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(150)
          text: "Max"
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }

        TextField {
          id: maxField
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(70)
          text: String(root.maxTemp)
          horizontalAlignment: TextInput.AlignHCenter
          enabled: true
          readOnly: false
          selectByMouse: true
          inputMethodHints: Qt.ImhDigitsOnly
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(7)

        Button {
          text: "Uygula"
          iconText: "󰄬"
          enabled: !root.busy
          onClicked: root.saveCurve()
        }

        Button {
          text: "Yenile"
          iconText: "󰑓"
          enabled: !root.busy
          onClicked: root.refresh()
        }
      }

      Text {
        width: parent.width
        visible: root.message !== ""
        text: root.message
        color: root.message.indexOf("uygulanamadı") !== -1 || root.message.indexOf("okunamadı") !== -1
          ? Color.urgent : Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  Process {
    id: cpuTempProc
    command: ["/home/anon/.config/omarchy/bar/scripts/cpu-temperature"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseCpuTemp(text)
    }
  }

  Process {
    id: maxStatusProc
    command: ["/usr/local/bin/omarchy-fan-max-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseMaxStatus(text)
    }
  }

  Process {
    id: fixedStatusProc
    command: ["/home/anon/.config/omarchy/bar/scripts/omarchy-fan-fixed-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseFixedStatus(text)
    }
  }

  Process {
    id: curveStatusProc
    command: ["/usr/local/bin/omarchy-fan-curve-status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseCurveStatus(text)
    }
  }

  Process {
    id: actionProc
    onExited: function(exitCode) {
      root.busy = false
      root.message = exitCode === 0 ? "Fan modu güncellendi" : "Fan modu uygulanamadı"
      root.refresh()
    }
  }

  Process {
    id: fixedSetProc
    onExited: function(exitCode) {
      if (exitCode === 0 && root.pendingMaxMode !== "") {
        var nextMode = root.pendingMaxMode
        root.pendingMaxMode = ""
        actionProc.command = ["pkexec", "/usr/local/bin/omarchy-fan-max-toggle", nextMode]
        actionProc.running = true
        return
      }
      root.pendingMaxMode = ""
      root.busy = false
      root.message = exitCode === 0 ? "Sabit fan hızı uygulandı" : "Sabit fan hızı uygulanamadı"
      root.refresh()
    }
  }

  Process {
    id: curveSetProc
    onExited: function(exitCode) {
      root.busy = false
      root.message = exitCode === 0 ? "Fan curve kaydedildi" : "Fan curve uygulanamadı"
      root.refresh()
    }
  }

  Timer {
    interval: 5000
    running: !root.popupOpen
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
