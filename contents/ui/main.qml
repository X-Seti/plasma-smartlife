// Should be in: contents/ui/main.qml
// X-Seti Jan 2019, 2025 - main.qml
// SmartLife Controller Widget - Main UI

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    
    // Property to store devices
    property var deviceList: []
    property bool scanning: false
    property bool showOfflineDevices: plasmoid.configuration.showOfflineDevices || false
    
    // Set compact representation for panel
    compactRepresentation: Item {
        id: compactRoot
        
        Layout.minimumWidth: Kirigami.Units.gridUnit * 1.5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 1.5
        
        Kirigami.Icon {
            id: icon
            source: "preferences-system-network-sharing"
            anchors.fill: parent
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: plasmoid.expanded = !plasmoid.expanded
            console.log("Device clicked in list");
            controlDevice();
        }
        z: -1 // Behind the buttons
    }
    
    // Full representation (popup)
    fullRepresentation: Item {
        id: fullRoot
        
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 24
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 28
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            
            // Title and scan button
            RowLayout {
                Layout.fillWidth: true
                
                Kirigami.Heading {
                    level: 2
                    text: "SmartLife Devices"
                    Layout.fillWidth: true
                }
                
                Button {
                    id: scanButton
                    text: scanning ? "Scanning..." : "Scan Network"
                    icon.name: "view-refresh"
                    enabled: !scanning
                    onClicked: {
                        scanNetwork();
                    }
                }
            }
            
            // Filters and options
            RowLayout {
                Layout.fillWidth: true
                
                CheckBox {
                    id: showOfflineCheck
                    text: "Show Offline"
                    checked: showOfflineDevices
                    onCheckedChanged: {
                        showOfflineDevices = checked;
                        Plasmoid.configuration.showOfflineDevices = checked;
                    }
                }
                
                TextField {
                    id: filterField
                    placeholderText: "Filter devices..."
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "Add Device"
                    icon.name: "list-add"
                    onClicked: {
                        addDeviceDialog.open();
                    }
                }
            }
            
            // Device list
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ListView {
                    id: deviceListView
                    clip: true
                    model: getFilteredDevices()
                    
                    delegate: DeviceItem {
                        width: deviceListView.width
                        deviceName: modelData.name
                        deviceIp: modelData.ipAddress
                        deviceState: modelData.state
                        deviceType: modelData.type
                        deviceBrightness: modelData.brightness || 0
                        deviceColor: modelData.color || "#FFFFFF"
                        deviceTimerOn: modelData.timerOn
                        deviceTimerOff: modelData.timerOff
                        
                        onToggleDevice: {
                            toggleDeviceState(modelData.id);
                        }
                        
                        onControlDevice: {
                            openDeviceControl(modelData);
                        }
                        
                        onRemoveDevice: {
                            deleteDevice(modelData.id);
                        }
                    }
                    
                    // Empty state
                    Item {
                        anchors.fill: parent
                        visible: deviceListView.count === 0
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Kirigami.Units.largeSpacing
                            
                            Kirigami.Icon {
                                source: "network-wireless"
                                width: Kirigami.Units.iconSizes.huge
                                height: width
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Kirigami.Heading {
                                level: 3
                                text: "No devices found"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: "Scan your network to find SmartLife devices"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Button {
                                text: "Scan Now"
                                icon.name: "view-refresh"
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: scanNetwork()
                            }
                        }
                    }
                }
            }
            
            // Status bar
            RowLayout {
                Layout.fillWidth: true
                
                Label {
                    text: scanning ? 
                          "Scanning network..." : 
                          (deviceList.length > 0 ? 
                           deviceList.length + " device(s) found" : 
                           "Ready to scan")
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "ESP filter: ON"
                    visible: Plasmoid.configuration.espFilter
                }
            }
        }
        
        // Add device dialog
        Dialog {
            id: addDeviceDialog
            title: "Add SmartLife Device"
            standardButtons: Dialog.Ok | Dialog.Cancel
            
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            width: Kirigami.Units.gridUnit * 20
            modal: true
            
            onAccepted: {
                if (deviceNameField.text && deviceIpField.text) {
                    addDevice({
                        id: Date.now(),
                        name: deviceNameField.text,
                        ipAddress: deviceIpField.text,
                        type: deviceTypeCombo.currentText.toLowerCase(),
                        state: false,
                        brightness: 100,
                        color: "#FFFFFF"
                    });
                    deviceNameField.text = "";
                    deviceIpField.text = "";
                }
            }
            
            onClosed: {
                deviceNameField.text = "";
                deviceIpField.text = "";
            }
            
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                
                Label {
                    text: "Device Name:"
                }
                
                TextField {
                    id: deviceNameField
                    placeholderText: "Living Room Light"
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "IP Address:"
                }
                
                TextField {
                    id: deviceIpField
                    placeholderText: "192.168.1.100"
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "Device Type:"
                }
                
                ComboBox {
                    id: deviceTypeCombo
                    model: ["Light", "Switch", "Outlet", "Thermostat", "Other"]
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "Scan for ESP Devices"
                    icon.name: "network-wireless"
                    Layout.fillWidth: true
                    onClicked: {
                        scanForEspDevices();
                    }
                }
            }
        }
        
        // Device control dialog
        Dialog {
            id: deviceControlDialog
            title: "Device Control"
            standardButtons: Dialog.Close
            
            property var currentDevice: null
            
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            width: Kirigami.Units.gridUnit * 24
            height: Kirigami.Units.gridUnit * 28
            modal: true
            
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                
                // Device name and IP
                RowLayout {
                    Layout.fillWidth: true
                    
                    Kirigami.Heading {
                        level: 3
                        text: deviceControlDialog.currentDevice ? 
                              deviceControlDialog.currentDevice.name : ""
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: deviceControlDialog.currentDevice ? 
                              deviceControlDialog.currentDevice.ipAddress : ""
                        opacity: 0.7
                    }
                }
                
                // Tab bar for different control options
                TabBar {
                    id: controlTabs
                    Layout.fillWidth: true
                    
                    TabButton {
                        text: "Basic"
                        icon.name: "configure"
                    }
                    
                    TabButton {
                        text: "Colors"
                        icon.name: "preferences-desktop-color"
                        visible: deviceControlDialog.currentDevice && 
                                 deviceControlDialog.currentDevice.type === "light"
                    }
                    
                    TabButton {
                        text: "Timer"
                        icon.name: "chronometer"
                    }
                }
                
                // Stacked layout for tab content
                StackLayout {
                    currentIndex: controlTabs.currentIndex
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // Basic controls
                    ColumnLayout {
                        spacing: Kirigami.Units.largeSpacing
                        
                        GroupBox {
                            title: "Power"
                            Layout.fillWidth: true
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                Switch {
                                    id: deviceSwitch
                                    text: checked ? "ON" : "OFF"
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                                    checked: deviceControlDialog.currentDevice ? 
                                             deviceControlDialog.currentDevice.state : false
                                    onCheckedChanged: {
                                        if (deviceControlDialog.currentDevice) {
                                            updateDeviceProperty(
                                                deviceControlDialog.currentDevice.id, 
                                                "state", 
                                                checked
                                            );
                                        }
                                    }
                                }
                            }
                        }
                        
                        GroupBox {
                            title: "Brightness"
                            Layout.fillWidth: true
                            visible: deviceControlDialog.currentDevice && 
                                     deviceControlDialog.currentDevice.type === "light"
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Kirigami.Icon {
                                        source: "low-brightness"
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                    }
                                    
                                    Slider {
                                        id: brightnessSlider
                                        from: 1
                                        to: 100
                                        value: deviceControlDialog.currentDevice && 
                                               deviceControlDialog.currentDevice.type === "light" ? 
                                               deviceControlDialog.currentDevice.brightness : 100
                                        Layout.fillWidth: true
                                        onValueChanged: {
                                            if (deviceControlDialog.currentDevice && 
                                                deviceControlDialog.currentDevice.type === "light") {
                                                updateDeviceProperty(
                                                    deviceControlDialog.currentDevice.id, 
                                                    "brightness", 
                                                    Math.round(value)
                                                );
                                            }
                                        }
                                    }
                                    
                                    Kirigami.Icon {
                                        source: "high-brightness"
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                    }
                                    
                                    Label {
                                        text: Math.round(brightnessSlider.value) + "%"
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                        
                        GroupBox {
                            title: "Light Temperature"
                            Layout.fillWidth: true
                            visible: deviceControlDialog.currentDevice && 
                                     deviceControlDialog.currentDevice.type === "light"
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Kirigami.Icon {
                                        source: "weather-clear-night"
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                    }
                                    
                                    Slider {
                                        id: temperatureSlider
                                        from: 1
                                        to: 100
                                        value: 50
                                        Layout.fillWidth: true
                                    }
                                    
                                    Kirigami.Icon {
                                        source: "weather-clear"
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                    }
                                    
                                    Label {
                                        text: temperatureSlider.value < 33 ? "Cool" : 
                                             (temperatureSlider.value < 66 ? "Neutral" : "Warm")
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                        
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                    
                    // Color controls
                    ColumnLayout {
                        spacing: Kirigami.Units.largeSpacing
                        visible: deviceControlDialog.currentDevice && 
                                 deviceControlDialog.currentDevice.type === "light"
                        
                        GroupBox {
                            title: "RGB Color"
                            Layout.fillWidth: true
                            
                            GridLayout {
                                columns: 3
                                rowSpacing: Kirigami.Units.smallSpacing
                                columnSpacing: Kirigami.Units.smallSpacing
                                anchors.fill: parent
                                
                                Label { text: "Red:" }
                                Slider {
                                    id: redSlider
                                    from: 0
                                    to: 255
                                    value: 255
                                    Layout.fillWidth: true
                                    onValueChanged: updateColorFromRGB()
                                }
                                SpinBox {
                                    from: 0
                                    to: 255
                                    value: redSlider.value
                                    onValueChanged: {
                                        redSlider.value = value;
                                        updateColorFromRGB();
                                    }
                                }
                                
                                Label { text: "Green:" }
                                Slider {
                                    id: greenSlider
                                    from: 0
                                    to: 255
                                    value: 255
                                    Layout.fillWidth: true
                                    onValueChanged: updateColorFromRGB()
                                }
                                SpinBox {
                                    from: 0
                                    to: 255
                                    value: greenSlider.value
                                    onValueChanged: {
                                        greenSlider.value = value;
                                        updateColorFromRGB();
                                    }
                                }
                                
                                Label { text: "Blue:" }
                                Slider {
                                    id: blueSlider
                                    from: 0
                                    to: 255
                                    value: 255
                                    Layout.fillWidth: true
                                    onValueChanged: updateColorFromRGB()
                                }
                                SpinBox {
                                    from: 0
                                    to: 255
                                    value: blueSlider.value
                                    onValueChanged: {
                                        blueSlider.value = value;
                                        updateColorFromRGB();
                                    }
                                }
                            }
                        }
                        
                        GroupBox {
                            title: "Color Presets"
                            Layout.fillWidth: true
                            
                            GridLayout {
                                columns: 4
                                anchors.fill: parent
                                rowSpacing: Kirigami.Units.smallSpacing
                                columnSpacing: Kirigami.Units.smallSpacing
                                
                                Repeater {
                                    model: [
                                        "#FFFFFF", "#FFF4E0", "#FFD700", "#FF6347", 
                                        "#87CEFA", "#90EE90", "#FF00FF", "#FF5500",
                                        "#00FFFF", "#00FF88", "#AAAAFF", "#FF0000"
                                    ]
                                    
                                    Rectangle {
                                        width: Kirigami.Units.gridUnit * 2.5
                                        height: Kirigami.Units.gridUnit * 2.5
                                        color: modelData
                                        border.width: deviceControlDialog.currentDevice && 
                                                     deviceControlDialog.currentDevice.color === modelData ? 3 : 1
                                        border.color: deviceControlDialog.currentDevice && 
                                                     deviceControlDialog.currentDevice.color === modelData ? 
                                                     Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                        radius: 4
                                        
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (deviceControlDialog.currentDevice) {
                                                    updateDeviceProperty(
                                                        deviceControlDialog.currentDevice.id, 
                                                        "color", 
                                                        modelData
                                                    );
                                                    setRGBSlidersFromColor(modelData);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            id: colorPreview
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                            color: deviceControlDialog.currentDevice ? 
                                   deviceControlDialog.currentDevice.color : "#FFFFFF"
                            border.width: 1
                            border.color: Kirigami.Theme.disabledTextColor
                            radius: 4
                            
                            Label {
                                anchors.centerIn: parent
                                text: deviceControlDialog.currentDevice ? 
                                      deviceControlDialog.currentDevice.color : "#FFFFFF"
                                color: isDarkColor(parent.color) ? "white" : "black"
                                font.bold: true
                            }
                        }
                        
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                    
                    // Timer controls
                    ColumnLayout {
                        spacing: Kirigami.Units.largeSpacing
                        
                        GroupBox {
                            title: "Turn ON Timer"
                            Layout.fillWidth: true
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    CheckBox {
                                        id: timerOnEnabled
                                        text: "Enable"
                                        checked: deviceControlDialog.currentDevice && 
                                                deviceControlDialog.currentDevice.timerOn !== null
                                    }
                                    
                                    Label {
                                        text: "Time:"
                                        visible: timerOnEnabled.checked
                                    }
                                    
                                    SpinBox {
                                        id: timerOnHours
                                        from: 0
                                        to: 23
                                        value: 18
                                        visible: timerOnEnabled.checked
                                    }
                                    
                                    Label {
                                        text: ":"
                                        visible: timerOnEnabled.checked
                                    }
                                    
                                    SpinBox {
                                        id: timerOnMinutes
                                        from: 0
                                        to: 59
                                        value: 0
                                        visible: timerOnEnabled.checked
                                    }
                                    
                                    Button {
                                        text: "Apply"
                                        icon.name: "dialog-ok-apply"
                                        visible: timerOnEnabled.checked
                                        onClicked: {
                                            if (deviceControlDialog.currentDevice) {
                                                let timerValue = null;
                                                if (timerOnEnabled.checked) {
                                                    timerValue = {
                                                        hours: timerOnHours.value,
                                                        minutes: timerOnMinutes.value
                                                    };
                                                }
                                                updateDeviceProperty(
                                                    deviceControlDialog.currentDevice.id,
                                                    "timerOn",
                                                    timerValue
                                                );
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        GroupBox {
                            title: "Turn OFF Timer"
                            Layout.fillWidth: true
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    CheckBox {
                                        id: timerOffEnabled
                                        text: "Enable"
                                        checked: deviceControlDialog.currentDevice && 
                                                deviceControlDialog.currentDevice.timerOff !== null
                                    }
                                    
                                    Label {
                                        text: "Time:"
                                        visible: timerOffEnabled.checked
                                    }
                                    
                                    SpinBox {
                                        id: timerOffHours
                                        from: 0
                                        to: 23
                                        value: 23
                                        visible: timerOffEnabled.checked
                                    }
                                    
                                    Label {
                                        text: ":"
                                        visible: timerOffEnabled.checked
                                    }
                                    
                                    SpinBox {
                                        id: timerOffMinutes
                                        from: 0
                                        to: 59
                                        value: 0
                                        visible: timerOffEnabled.checked
                                    }
                                    
                                    Button {
                                        text: "Apply"
                                        icon.name: "dialog-ok-apply"
                                        visible: timerOffEnabled.checked
                                        onClicked: {
                                            if (deviceControlDialog.currentDevice) {
                                                let timerValue = null;
                                                if (timerOffEnabled.checked) {
                                                    timerValue = {
                                                        hours: timerOffHours.value,
                                                        minutes: timerOffMinutes.value
                                                    };
                                                }
                                                updateDeviceProperty(
                                                    deviceControlDialog.currentDevice.id,
                                                    "timerOff",
                                                    timerValue
                                                );
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        GroupBox {
                            title: "Timer Status"
                            Layout.fillWidth: true
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                Label {
                                    text: getTimerStatusText()
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
            
            // Set RGB sliders when dialog opens
            onOpened: {
                if (currentDevice && currentDevice.type === "light") {
                    setRGBSlidersFromColor(currentDevice.color);
                }
                
                // Set timer values
                if (currentDevice) {
                    if (currentDevice.timerOn) {
                        timerOnHours.value = currentDevice.timerOn.hours;
                        timerOnMinutes.value = currentDevice.timerOn.minutes;
                    } else {
                        timerOnHours.value = 18;
                        timerOnMinutes.value = 0;
                    }
                    
                    if (currentDevice.timerOff) {
                        timerOffHours.value = currentDevice.timerOff.hours;
                        timerOffMinutes.value = currentDevice.timerOff.minutes;
                    } else {
                        timerOffHours.value = 23;
                        timerOffMinutes.value = 0;
                    }
                }
            }
            
            function updateColorFromRGB() {
                if (!deviceControlDialog.currentDevice) return;
                
                // Convert RGB to hex
                const r = Math.round(redSlider.value).toString(16).padStart(2, '0');
                const g = Math.round(greenSlider.value).toString(16).padStart(2, '0');
                const b = Math.round(blueSlider.value).toString(16).padStart(2, '0');
                const colorHex = "#" + r + g + b;
                
                updateDeviceProperty(
                    deviceControlDialog.currentDevice.id,
                    "color",
                    colorHex.toUpperCase()
                );
            }
            
            function setRGBSlidersFromColor(colorHex) {
                // Parse hex color to RGB
                const r = parseInt(colorHex.substring(1, 3), 16);
                const g = parseInt(colorHex.substring(3, 5), 16);
                const b = parseInt(colorHex.substring(5, 7), 16);
                
                // Update sliders
                redSlider.value = r;
                greenSlider.value = g;
                blueSlider.value = b;
            }
            
            function isDarkColor(colorHex) {
                // Convert hex to RGB
                const r = parseInt(colorHex.substring(1, 3), 16);
                const g = parseInt(colorHex.substring(3, 5), 16);
                const b = parseInt(colorHex.substring(5, 7), 16);
                
                // Calculate perceived brightness
                const brightness = (r * 299 + g * 587 + b * 114) / 1000;
                
                // Return true if dark
                return brightness < 128;
            }
            
            function getTimerStatusText() {
                if (!deviceControlDialog.currentDevice) return "No device selected";
                
                let text = "";
                if (deviceControlDialog.currentDevice.timerOn) {
                    const h = deviceControlDialog.currentDevice.timerOn.hours;
                    const m = deviceControlDialog.currentDevice.timerOn.minutes;
                    text += `Will turn ON at ${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}\n`;
                }
                
                if (deviceControlDialog.currentDevice.timerOff) {
                    const h = deviceControlDialog.currentDevice.timerOff.hours;
                    const m = deviceControlDialog.currentDevice.timerOff.minutes;
                    text += `Will turn OFF at ${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
                }
                
                return text || "No timers set";
            }
        }
    }
    
    Component.onCompleted: {
        // Load saved devices
        loadSavedDevices();
    }
    
    // Function to filter devices based on search text and showOffline setting
    function getFilteredDevices() {
        if (!deviceList) return [];
        
        let filtered = deviceList;
        
        // Filter by search text
        if (filterField && filterField.text) {
            const searchText = filterField.text.toLowerCase();
            filtered = filtered.filter(device => 
                device.name.toLowerCase().includes(searchText) || 
                device.ipAddress.toLowerCase().includes(searchText)
            );
        }
        
        // Filter offline devices if needed
        if (!showOfflineDevices) {
            filtered = filtered.filter(device => device.state);
        }
        
        return filtered;
    }
    
    // Function to load saved devices
    function loadSavedDevices() {
        console.log("Loading devices from configuration...");
        
        // First try to load from configuration
        let savedDevices = plasmoid.configuration.savedDevices || "";
        console.log("Saved devices from configuration:", savedDevices);
        
        // Fix for empty or invalid JSON
        if (!savedDevices || savedDevices.trim() === "" || savedDevices === "[]") {
            // Set a default sample device if nothing is configured
            savedDevices = `[
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
            // Save this default for future use
            plasmoid.configuration.savedDevices = savedDevices;
            console.log("Set default sample device");
        }
        
        try {
            const parsed = JSON.parse(savedDevices);
            if (parsed && parsed.length > 0) {
                console.log("Successfully parsed devices from configuration:", parsed.length, "devices found");
                deviceList = parsed;
                deviceListView.model = getFilteredDevices();
                return;
            } else {
                console.log("No devices found in configuration, checking device-config.json");
            }
        } catch (e) {
            console.error("Error parsing saved devices from configuration:", e);
            
            // Try to recover from a parse error by resetting to a sample device
            savedDevices = `[
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
            plasmoid.configuration.savedDevices = savedDevices;
            try {
                deviceList = JSON.parse(savedDevices);
                deviceListView.model = getFilteredDevices();
                console.log("Recovered with sample device");
                return;
            } catch (e2) {
                console.error("Could not recover from parse error:", e2);
            }
        }
        
        // If no devices in configuration, try to load from device-config.json
        try {
            console.log("Attempting to load from device-config.json");
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "file://" + plasmoid.file("", "contents/code/device-config.json"), false); // Synchronous request
            xhr.send();
            
            if (xhr.status === 200) {
                console.log("device-config.json loaded successfully, content:", xhr.responseText);
                const configDevices = JSON.parse(xhr.responseText);
                if (configDevices && configDevices.length > 0) {
                    console.log("Parsed", configDevices.length, "devices from device-config.json");
                    deviceList = configDevices;
                    deviceListView.model = getFilteredDevices();
                    // Save to configuration for future use
                    saveDevices();
                    return;
                } else {
                    console.log("device-config.json did not contain any devices");
                }
            } else {
                console.error("Failed to load device-config.json, status:", xhr.status);
            }
        } catch (e) {
            console.error("Error loading device-config.json:", e);
        }
        
        // Also check if there's a reload flag file
        try {
            const checkReload = new XMLHttpRequest();
            checkReload.open("GET", "file://" + plasmoid.file("", "contents/code/reload_config"), false);
            checkReload.send();
            
            if (checkReload.status === 200) {
                console.log("Reload flag file found, refreshing configuration");
                // Try loading the device-config.json again with a slight delay
                Qt.setTimeout(function() {
                    loadFromDeviceConfig();
                }, 500);
                
                // Remove the reload flag file
                // Note: We can't actually remove it from QML, but we can mark it as processed
                console.log("Reload flag processed");
            }
        } catch (e) {
            // This is expected if the file doesn't exist
        }
        
        // If all failed, set default sample device
        console.log("Could not load devices from any source, using sample device");
        const sampleDevice = [{
            id: 1,
            name: "Sample Light",
            ipAddress: "192.168.1.100",
            type: "light",
            state: false,
            brightness: 80,
            color: "#FFFFFF",
            timerOn: null,
            timerOff: null
        }];
        deviceList = sampleDevice;
        deviceListView.model = getFilteredDevices();
        saveDevices();
    }
    
    // Helper function to load from device-config.json
    function loadFromDeviceConfig() {
        try {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "file://" + plasmoid.file("", "contents/code/device-config.json"), false);
            xhr.send();
            
            if (xhr.status === 200) {
                const configDevices = JSON.parse(xhr.responseText);
                if (configDevices && configDevices.length > 0) {
                    deviceList = configDevices;
                    deviceListView.model = getFilteredDevices();
                    saveDevices();
                    console.log("Devices reloaded from device-config.json:", deviceList.length, "devices");
                }
            }
        } catch (e) {
            console.error("Error in loadFromDeviceConfig:", e);
        }
    }
    
    // Function to save devices
    function saveDevices() {
        console.log("Saving devices to configuration:", JSON.stringify(deviceList));
        plasmoid.configuration.savedDevices = JSON.stringify(deviceList);
    }
    
    // Function to add a device
    function addDevice(device) {
        deviceList.push(device);
        saveDevices();
        deviceListView.model = getFilteredDevices();
    }
    
    // Function to delete a device
    function deleteDevice(id) {
        deviceList = deviceList.filter(d => d.id !== id);
        saveDevices();
        deviceListView.model = getFilteredDevices();
    }
    
    // Function to toggle device state
    function toggleDeviceState(id) {
        console.log("toggleDevice called for id:", id);
        const index = deviceList.findIndex(d => d.id === id);
        if (index >= 0) {
            deviceList[index].state = !deviceList[index].state;
            saveDevices();
            deviceListView.model = getFilteredDevices();
            
            // In a real implementation, this would send a command to the actual device
            console.log("Toggling device:", deviceList[index].name, "to", deviceList[index].state);
            
            // This would call the Python script to control the device
            // Example: plasmoid.runCommand("python", ["/path/to/network-scanner.py", "toggle", deviceList[index].ipAddress]);
        }
    }
    
    // Function to update a device property
    function updateDeviceProperty(id, property, value) {
        const index = deviceList.findIndex(d => d.id === id);
        if (index >= 0) {
            deviceList[index][property] = value;
            saveDevices();
            deviceListView.model = getFilteredDevices();
            
            // In a real implementation, this would send the updated property to the device
            console.log("Updating device:", deviceList[index].name, property, "to", value);
        }
    }
    
    // Function to open device control dialog
    function openDeviceControl(device) {
        deviceControlDialog.currentDevice = device;
        deviceControlDialog.open();
    }
    
    // Function to scan the network for devices
    function scanNetwork() {
        scanning = true;
        
        // In a real implementation, this would call a Python script to scan the network
        // Example: plasmoid.runCommand("python", ["/path/to/network-scanner.py", "scan"]);
        
        // For demo purposes, simulate finding devices after a delay
        Timer.setTimeout(function() {
            // Look for new ESP devices
            const espAddresses = [
                "192.168.1.238", "192.168.1.104", "192.168.1.242", "192.168.1.218",
                "192.168.1.83", "192.168.1.137", "192.168.1.131", "192.168.1.118"
            ];
            
            // Get current device IPs to avoid duplicates
            const existingIps = deviceList.map(d => d.ipAddress);
            
            // List of new ESP devices found during scan
            let newDevicesFound = 0;
            
            // Check each ESP address
            for (let i = 0; i < espAddresses.length; i++) {
                const ip = espAddresses[i];
                
                // Skip if device already exists
                if (existingIps.includes(ip)) continue;
                
                // Create new device with default settings
                const newDevice = {
                    id: Date.now() + i,
                    name: `ESP_${Math.random().toString(16).substring(2, 8).toUpperCase()}`,
                    ipAddress: ip,
                    type: Math.random() > 0.5 ? "light" : "outlet",
                    state: false,
                    brightness: 100,
                    color: "#FFFFFF",
                    timerOn: null,
                    timerOff: null
                };
                
                deviceList.push(newDevice);
                newDevicesFound++;
            }
            
            // Also add a few simulated smart devices
            if (Math.random() > 0.5) {
                const smartplug = {
                    id: Date.now() + 100,
                    name: "Smart Plug",
                    ipAddress: `192.168.1.${Math.floor(Math.random() * 254) + 1}`,
                    type: "outlet",
                    state: false,
                    timerOn: null,
                    timerOff: null
                };
                
                // Only add if IP is unique
                if (!existingIps.includes(smartplug.ipAddress)) {
                    deviceList.push(smartplug);
                    newDevicesFound++;
                }
            }
            
            if (Math.random() > 0.5) {
                const smartswitch = {
                    id: Date.now() + 101,
                    name: "Smart Switch",
                    ipAddress: `192.168.1.${Math.floor(Math.random() * 254) + 1}`,
                    type: "switch",
                    state: false,
                    timerOn: null,
                    timerOff: null
                };
                
                // Only add if IP is unique
                if (!existingIps.includes(smartswitch.ipAddress)) {
                    deviceList.push(smartswitch);
                    newDevicesFound++;
                }
            }
            
            saveDevices();
            deviceListView.model = getFilteredDevices();
            
            // Show notification
            if (newDevicesFound > 0) {
                showNotification(`Found ${newDevicesFound} new device(s)`, "dialog-information");
            } else {
                showNotification("No new devices found", "dialog-information");
            }
            
            scanning = false;
        }, 2000);
    }
    
    // Function to scan specifically for ESP devices
    function scanForEspDevices() {
        // In a real implementation, this would execute a Python script to find ESP devices
        // Example: plasmoid.runCommand("python", ["/path/to/network-scanner.py", "scan-esp"]);
        
        // For demo purposes, simulate finding ESP devices after a delay
        Timer.setTimeout(function() {
            // Simulate finding ESP devices based on provided list
            const espDevices = [
                { name: "ESP_554DC9", ipAddress: "192.168.1.238" },
                { name: "ESP_554E12", ipAddress: "192.168.1.104" },
                { name: "ESP_554E9C", ipAddress: "192.168.1.242" },
                { name: "ESP_554F53", ipAddress: "192.168.1.218" },
                { name: "ESP_559186", ipAddress: "192.168.1.83" },
                { name: "ESP_5E7404", ipAddress: "192.168.1.137" },
                { name: "ESP_648294", ipAddress: "192.168.1.131" },
                { name: "ESP_650D34", ipAddress: "192.168.1.118" }
            ];
            
            // Select a random ESP device from the list
            if (espDevices.length > 0) {
                const randomIndex = Math.floor(Math.random() * espDevices.length);
                deviceNameField.text = espDevices[randomIndex].name;
                deviceIpField.text = espDevices[randomIndex].ipAddress;
            }
        }, 1500);
    }
    
    // Function to show a notification
    function showNotification(message, icon) {
        // In a real implementation, this would show a plasma notification
        console.log(`Notification: ${message}`);
    }
}
