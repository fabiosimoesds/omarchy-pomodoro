import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "Strings.js" as Strings

// Pomodoro timer: a tomato in the bar, followed by the remaining time while
// a session runs. Hovering reveals a popup with 15/30/45 minute presets and a
// custom minutes field. When the timer ends it plays a soft chime and the
// tomato grows and keeps shaking until it is clicked. Labels follow the
// system language unless the "language" setting overrides it.
BarWidget {
  id: root
  moduleName: "fabiosimoesds.pomodoro"

  readonly property string chimeSound: "/usr/share/sounds/freedesktop/stereo/complete.oga"

  property bool running: false
  property real endTime: 0
  property int remainingSeconds: 0
  property int customMinutes: 25
  // True while the custom field is being typed into. A hover popup never
  // gets keyboard focus on its own, so editing takes a Hyprland focus grab.
  property bool editing: false
  // True from the end of a session until the tomato is clicked.
  property bool alarming: false

  readonly property bool opened: popup.open
  readonly property bool hovering: widgetHover.hovered || popup.containsMouse
  readonly property string remainingText: formatTime(remainingSeconds)
  readonly property var tr: Strings.forLanguage(setting("language", "") || Qt.locale().name)

  function formatTime(total) {
    var h = Math.floor(total / 3600)
    var m = Math.floor((total % 3600) / 60)
    var s = total % 60
    var mm = (m < 10 ? "0" : "") + m
    var ss = (s < 10 ? "0" : "") + s
    return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss
  }

  function start(minutes) {
    var value = parseInt(minutes, 10)
    if (isNaN(value) || value <= 0) return
    alarming = false
    endTime = Date.now() + value * 60 * 1000
    running = true
    tick()
    close()
  }

  function setCustom(value) {
    customMinutes = Math.max(1, Math.min(600, value))
    customField.text = String(customMinutes)
  }

  function beginEditing() {
    editing = true
    Qt.callLater(function() {
      customField.forceActiveFocus()
      customField.selectAll()
    })
  }

  function endEditing() {
    editing = false
    customField.focus = false
    var v = parseInt(customField.text, 10)
    setCustom(isNaN(v) ? customMinutes : v)
    if (!hovering) closeDelay.restart()
  }

  function stop() {
    running = false
    remainingSeconds = 0
  }

  function tick() {
    if (!running) return
    var left = Math.max(0, Math.round((endTime - Date.now()) / 1000))
    remainingSeconds = left
    if (left === 0) finish()
  }

  function finish() {
    running = false
    remainingSeconds = 0
    if (root.bar) root.bar.run("pw-play --volume 0.45 " + root.chimeSound + " || paplay " + root.chimeSound)
    alarming = true
  }

  // Popout coordinator contract: the bar closes the active popup through
  // these when another widget opens its own.
  function open() { closeDelay.stop(); popup.open = true }
  function close() { closeDelay.stop(); editing = false; popup.open = false }
  function closeForPopoutSwitch() { close() }

  implicitWidth: row.implicitWidth + Style.space(16)
  implicitHeight: barSize

  onHoveringChanged: {
    if (hovering) open()
    else closeDelay.restart()
  }

  Timer {
    id: closeDelay
    interval: 350
    onTriggered: if (!root.hovering && !root.editing) root.close()
  }

  HyprlandFocusGrab {
    active: root.editing && popup.open
    windows: popup.anchorWindow ? [popup, popup.anchorWindow] : [popup]
    onCleared: root.endEditing()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.running
    triggeredOnStart: true
    onTriggered: root.tick()
  }

  HoverHandler {
    id: widgetHover
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (root.alarming) root.alarming = false
      else if (mouse.button === Qt.RightButton && root.running) root.stop()
      else popup.open ? root.close() : root.open()
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(5)

    Text {
      id: tomato
      anchors.verticalCenter: parent.verticalCenter
      text: "🍅"
      font.family: "Noto Color Emoji"
      font.pixelSize: Math.round(Style.bar.iconFont * 0.95)
      transformOrigin: Item.Center
    }

    Text {
      visible: root.running
      anchors.verticalCenter: parent.verticalCenter
      text: root.remainingText
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      font.features: { "tnum": 1 }
    }
  }

  // Finish animation: grow, then shake in bursts until dismissed.
  SequentialAnimation {
    running: root.alarming

    NumberAnimation { target: tomato; property: "scale"; to: 1.6; duration: 180; easing.type: Easing.OutBack }
    SequentialAnimation {
      loops: Animation.Infinite
      SequentialAnimation {
        loops: 3
        NumberAnimation { target: tomato; property: "rotation"; to: 14; duration: 45; easing.type: Easing.InOutSine }
        NumberAnimation { target: tomato; property: "rotation"; to: -14; duration: 90; easing.type: Easing.InOutSine }
        NumberAnimation { target: tomato; property: "rotation"; to: 0; duration: 45; easing.type: Easing.InOutSine }
      }
      PauseAnimation { duration: 350 }
    }
  }

  onAlarmingChanged: if (!alarming) settle.restart()

  // Settle back from wherever the shake was stopped.
  ParallelAnimation {
    id: settle
    NumberAnimation { target: tomato; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.InOutQuad }
    NumberAnimation { target: tomato; property: "rotation"; to: 0; duration: 120; easing.type: Easing.OutQuad }
  }

  // Small square −/+ button; holding it repeats.
  component StepButton: Rectangle {
    id: step
    property string label: ""
    signal activated()

    width: Style.space(32)
    height: Style.space(32)
    radius: Style.cornerRadius
    color: stepMouse.containsMouse ? Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.22)
                                   : Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.12)

    Text {
      anchors.centerIn: parent
      text: step.label
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }

    MouseArea {
      id: stepMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onPressed: { step.activated(); repeat.start() }
      onReleased: repeat.stop()
      onCanceled: repeat.stop()
      onWheel: function(wheel) { step.activated(); wheel.accepted = true }
    }

    Timer {
      id: repeat
      interval: 400
      repeat: true
      onTriggered: { interval = 70; step.activated() }
      onRunningChanged: if (!running) interval = 400
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    triggerMode: "hover"
    contentWidth: Style.space(270)
    contentHeight: fittedContentHeight(content.implicitHeight)

    readonly property color fg: Color.popups.text
    readonly property color subtle: Qt.rgba(fg.r, fg.g, fg.b, 0.12)
    readonly property color subtleHover: Qt.rgba(fg.r, fg.g, fg.b, 0.22)

    Column {
      id: content
      width: parent.width
      spacing: Style.space(10)

      Text {
        width: parent.width
        text: root.running ? "🍅  " + root.tr.left.arg(root.remainingText) : "🍅  Pomodoro"
        color: popup.fg
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: [15, 30, 45]

          Rectangle {
            required property int modelData
            width: (content.width - Style.space(12)) / 3
            height: Style.space(32)
            radius: Style.cornerRadius
            color: presetMouse.containsMouse ? popup.subtleHover : popup.subtle

            Text {
              anchors.centerIn: parent
              text: parent.modelData + " " + root.tr.min
              color: popup.fg
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }

            MouseArea {
              id: presetMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.start(parent.modelData)
            }
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        StepButton {
          label: "−"
          onActivated: root.setCustom(root.customMinutes - 1)
        }

        Rectangle {
          width: parent.width - startButton.width - Style.space(32) * 2 - Style.space(6) * 3
          height: Style.space(32)
          radius: Style.cornerRadius
          color: popup.subtle
          border.width: root.editing ? 1 : 0
          border.color: popup.fg

          TextInput {
            id: customField
            anchors.fill: parent
            anchors.leftMargin: Style.space(8)
            anchors.rightMargin: Style.space(30)
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignRight
            text: String(root.customMinutes)
            color: popup.fg
            selectionColor: popup.subtleHover
            selectedTextColor: popup.fg
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 1; top: 600 }
            onAccepted: { root.endEditing(); root.start(root.customMinutes) }
            onTextEdited: {
              var v = parseInt(text, 10)
              if (!isNaN(v)) root.customMinutes = v
            }
            Keys.onEscapePressed: root.endEditing()
            Keys.onUpPressed: root.setCustom(root.customMinutes + 1)
            Keys.onDownPressed: root.setCustom(root.customMinutes - 1)
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: root.tr.min
            color: Qt.rgba(popup.fg.r, popup.fg.g, popup.fg.b, 0.5)
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }

          // Click to type; scroll to nudge the value.
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: root.beginEditing()
            onWheel: function(wheel) {
              root.setCustom(root.customMinutes + (wheel.angleDelta.y > 0 ? 1 : -1))
              wheel.accepted = true
            }
          }
        }

        StepButton {
          label: "+"
          onActivated: root.setCustom(root.customMinutes + 1)
        }

        Rectangle {
          id: startButton
          width: Math.max(Style.space(64), startLabel.implicitWidth + Style.space(16))
          height: Style.space(32)
          radius: Style.cornerRadius
          color: startMouse.containsMouse ? popup.subtleHover : popup.subtle

          Text {
            id: startLabel
            anchors.centerIn: parent
            text: root.tr.start
            color: popup.fg
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          MouseArea {
            id: startMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { root.endEditing(); root.start(root.customMinutes) }
          }
        }
      }

      Rectangle {
        visible: root.running
        width: parent.width
        height: Style.space(28)
        radius: Style.cornerRadius
        color: stopMouse.containsMouse ? popup.subtleHover : "transparent"
        border.width: 1
        border.color: popup.subtle

        Text {
          anchors.centerIn: parent
          text: root.tr.stop
          color: popup.fg
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        MouseArea {
          id: stopMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.stop(); root.close() }
        }
      }
    }
  }
}
