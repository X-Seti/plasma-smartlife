// Should be in: contents/ui/DeviceItem.qml
// X-Seti Jan 2019, 2025 - DeviceItem.qml
// SmartLife Controller Widget - Device List Item Component

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string deviceName: ""
    property string deviceIp: ""
    property bool deviceState: false
    property string deviceType: "light"
    property int deviceBrightness: 0
    property string deviceColor: "#FFFFFF"
    property var deviceTimerOn: null
    property var deviceTimerOff: null
    property var deviceData: null  // Add this to hold the entire device object

    // Change the signals to pass the entire device object
    signal toggleDeviceClicked(var device)
    signal controlDeviceClicked(var device)
    signal removeDeviceClicked(var device)

    height: Kirigami.Units.gridUnit * 3.5

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 4
        color: deviceState ? Kirigami.Theme.backgroundColor : Kirigami.Theme.disabledTextColor
        opacity: deviceState ? 1.0 : 0.7

        border.width: 1
        border.color: Kirigami.Theme.disabledTextColor

        // Color indicator for lights
        Rectangle {
            width: 4
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            visible: deviceType === "light" && deviceState
            color: deviceColor || "#FFFFFF"
            radius: 4
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            // Device icon
            Kirigami.Icon {
                source: {
                    switch(deviceType) {
                        case "light": return "light-bulb";
                        case "switch": return "dialog-ok-apply";
                        case "outlet": return "power-plug";
                        case "thermostat": return "temperature-normal";
                        default: return "network-connect";
                    }
                }
                width: Kirigami.Units.iconSizes.medium
                height: width
                color: deviceState ?
                       (deviceType === "light" ? "gold" : Kirigami.Theme.positiveTextColor) :
                       Kirigami.Theme.disabledTextColor
            }

            // Device info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: deviceName
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text: deviceIp
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                    opacity: 0.7
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Label {
                        text: deviceType === "light" && deviceState ?
                            "Brightness: " + deviceBrightness + "%" :
                            (deviceState ? "ON" : "OFF")
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                        opacity: 0.9
                    }

                    // Timer indicators
                    Row {
                        spacing: 2
                        visible: deviceTimerOn !== null || deviceTimerOff !== null

                        Kirigami.Icon {
                            source: "chronometer"
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            opacity: 0.7
                            visible: deviceTimerOn !== null

                            ToolTip.visible: timerOnMA.containsMouse
                            ToolTip.text: deviceTimerOn ?
                                       `ON at ${deviceTimerOn.hours.toString().padStart(2, '0')}:${deviceTimerOn.minutes.toString().padStart(2, '0')}` :
                                       ""

                            MouseArea {
                                id: timerOnMA
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }

                        Kirigami.Icon {
                            source: "chronometer-pause"
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            opacity: 0.7
                            visible: deviceTimerOff !== null

                            ToolTip.visible: timerOffMA.containsMouse
                            ToolTip.text: deviceTimerOff ?
                                       `OFF at ${deviceTimerOff.hours.toString().padStart(2, '0')}:${deviceTimerOff.minutes.toString().padStart(2, '0')}` :
                                       ""

                            MouseArea {
                                id: timerOffMA
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            // Controls
            Row {
                spacing: Kirigami.Units.smallSpacing

                Button {
                    id: controlButton
                    icon.name: "configure"
                    display: Button.IconOnly
                    onClicked: {
                        console.log("Control button clicked for: " + deviceName);
                        controlDeviceClicked(deviceData);
                    }

                    // Create a tooltip for the button
                    ToolTip.text: "Open Device Controls"
                    ToolTip.visible: hovered
                }

                Button {
                    icon.name: deviceState ? "dialog-cancel" : "dialog-ok-apply"
                    display: Button.IconOnly
                    ToolTip.text: deviceState ? "Turn Off" : "Turn On"
                    ToolTip.visible: hovered
                    onClicked: {
                        console.log("Toggle button clicked for: " + deviceName);
                        toggleDeviceClicked(deviceData);
                    }
                }

                Button {
                    icon.name: "edit-delete"
                    display: Button.IconOnly
                    ToolTip.text: "Remove Device"
                    ToolTip.visible: hovered
                    onClicked: {
                        console.log("Remove button clicked for: " + deviceName);
                        removeDeviceClicked(deviceData);
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            console.log("Device clicked: " + deviceName);
            controlDeviceClicked(deviceData);
        }
        z: -1 // Behind the buttons
    }

    // Set the deviceData when the component is completed
    Component.onCompleted: {
        deviceData = {
            id: parent.modelData.id,
            name: deviceName,
            ipAddress: deviceIp,
            type: deviceType,
            state: deviceState,
            brightness: deviceBrightness,
            color: deviceColor,
            timerOn: deviceTimerOn,
            timerOff: deviceTimerOff
        };
    }
}
