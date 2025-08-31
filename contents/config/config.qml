// Should be in: contents/config/config.qml
// X-Seti Jan 2019, 2025 - config.qml
// SmartLife Controller Widget - Configuration Schema

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "configGeneral.qml"
    }
}