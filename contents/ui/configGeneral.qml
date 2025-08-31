// Should be in: contents/ui/configGeneral.qml
// X-Seti Jan 2019, 2025 - configGeneral.qml
// SmartLife Controller Widget - Configuration UI

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

Item {
    id: root
    
    property alias cfg_showOfflineDevices: showOfflineCheck.checked
    property alias cfg_espFilter: espFilterCheck.checked
    property alias cfg_savedDevices: savedDevicesField.text
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.largeSpacing
        
        GroupBox {
            title: "Display Options"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                
                CheckBox {
                    id: showOfflineCheck
                    text: "Show offline devices"
                    Layout.fillWidth: true
                }
                
                CheckBox {
                    id: espFilterCheck
                    text: "Filter for ESP devices when scanning"
                    checked: true
                    Layout.fillWidth: true
                }
            }
        }
        
        GroupBox {
            title: "Device List"
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    TextArea {
                        id: savedDevicesField
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        placeholderText: "[]"
                        readOnly: false
                    }
                }
                
                Label {
                    text: "Note: This is the raw device data in JSON format. Edit with caution."
                    font.italic: true
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Button {
                        text: "Reset Device List"
                        icon.name: "edit-clear-all"
                        onClicked: {
                            // Set a valid default JSON instead of empty array
                            savedDevicesField.text = `[
  {
    "id": 1,
    "name": "Sample Light",
    "ipAddress": "192.168.1.100",
    "type": "light",
    "state": false,
    "brightness": 80,
    "color": "#FFFFFF",
    "timerOn": null,
    "timerOff": null
  }
]`;
                        }
                    }
                    
                    Button {
                        text: "Validate JSON"
                        icon.name: "dialog-ok-apply"
                        onClicked: {
                            validateJson();
                        }
                    }
                    
                    Item {
                        Layout.fillWidth: true
                    }
                    
                    Button {
                        text: "Run Configuration Generator"
                        icon.name: "network-wireless"
                        onClicked: {
                            runConfigGenerator();
                        }
                    }
                }
            }
        }
        
        GroupBox {
            title: "Device Controls Information"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                Label {
                    text: "<b>How to access device controls:</b>"
                    textFormat: Text.StyledText
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "1. Click on any device in the main widget"
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "2. Use the tabs to switch between control modes:"
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "   • <b>Basic</b>: Power controls and brightness"
                    textFormat: Text.StyledText
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                }
                
                Label {
                    text: "   • <b>Colors</b>: RGB color control (for lights)"
                    textFormat: Text.StyledText
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                }
                
                Label {
                    text: "   • <b>Timer</b>: Schedule automatic on/off times"
                    textFormat: Text.StyledText
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                }
            }
        }
    }
    
    function validateJson() {
        try {
            JSON.parse(savedDevicesField.text);
            showNotification("JSON is valid", "dialog-ok-apply");
        } catch (e) {
            showNotification("Invalid JSON: " + e.message, "dialog-error");
        }
    }
    
    function showNotification(message, icon) {
        // Create a notification dialog
        var notification = Qt.createQmlObject(`
            import QtQuick
            import QtQuick.Controls
            import QtQuick.Layouts
            import org.kde.kirigami as Kirigami
            
            Dialog {
                id: notificationDialog
                title: "Notification"
                standardButtons: Dialog.Ok
                
                x: Math.round((parent.width - width) / 2)
                y: Math.round((parent.height - height) / 2)
                width: Kirigami.Units.gridUnit * 20
                height: Kirigami.Units.gridUnit * 8
                modal: true
                
                RowLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.Icon {
                        source: "${icon}"
                        width: Kirigami.Units.iconSizes.large
                        height: width
                    }
                    
                    Label {
                        text: "${message}"
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }
                
                // Auto-close after 3 seconds
                Timer {
                    interval: 3000
                    running: true
                    onTriggered: notificationDialog.close()
                }
            }
        `, root, "notificationDialog");
        
        notification.open();
    }
    
    function runConfigGenerator() {
        // Try to run the configuration generator script
        var process = new XMLHttpRequest();
        process.open("GET", "file://" + plasmoid.file("", "contents/code/generate-config.py"), false);
        process.send();
        
        if (process.status === 200) {
            // The script exists, now we need to execute it
            showNotification("Running device scanner...", "network-wireless");
            
            // We can't directly execute scripts from QML, so we'll need to tell the user
            // how to do it manually
            var scriptPath = plasmoid.file("", "contents/code/generate-config.py");
            
            // Create a dialog to show instructions
            var dialog = Qt.createQmlObject(`
                import QtQuick
                import QtQuick.Controls
                import QtQuick.Layouts
                import org.kde.kirigami as Kirigami
                
                Dialog {
                    id: runScriptDialog
                    title: "Run Configuration Generator"
                    standardButtons: Dialog.Ok
                    
                    x: Math.round((parent.width - width) / 2)
                    y: Math.round((parent.height - height) / 2)
                    width: Kirigami.Units.gridUnit * 30
                    height: Kirigami.Units.gridUnit * 15
                    modal: true
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.largeSpacing
                        
                        Label {
                            text: "To scan for devices, run the following command in a terminal:"
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                        
                        TextField {
                            text: "python3 " + "${scriptPath}"
                            readOnly: true
                            Layout.fillWidth: true
                            
                            background: Rectangle {
                                color: Kirigami.Theme.backgroundColor
                                border.color: Kirigami.Theme.disabledTextColor
                                radius: 2
                            }
                        }
                        
                        Label {
                            text: "After running the scanner:"
                            Layout.fillWidth: true
                            font.bold: true
                            Layout.topMargin: Kirigami.Units.largeSpacing
                        }
                        
                        Label {
                            text: "1. The script will display found devices\n2. When it finishes, copy the JSON output\n3. Paste it into the Device List field above\n4. Click 'OK' to save the configuration"
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                        
                        Label {
                            text: "Note: If you don't see your devices after scanning, try the different scan modes offered by the script."
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font.italic: true
                        }
                    }
                }
            `, root, "runScriptDialog");
            
            dialog.open();
        } else {
            showNotification("Could not find configuration generator script", "dialog-error");
        }
    }
}