import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.0

ColumnLayout {
    x: 30
    y: 30

    property alias calibrationBtn: calibrationBtn
    property alias calibration: calibration
    property alias calibrationDisabledOverlay: calibrationDisabledOverlay

    Text {
        id: calibrationLabel
        text: qsTr("Calibrate")
        color: "white"
        horizontalAlignment: Text.AlignHCenter
    }
    Image {
        id: calibration
        sourceSize.width: 60
        sourceSize.height: 60
        fillMode: Image.PreserveAspectFit
        Layout.preferredHeight: 60
        Layout.preferredWidth: 60
        source: "../imgs/calibration.png"
        enabled: true
        z:1

        ColorOverlay {
            id: calibrationDisabledOverlay
            anchors.fill: calibration
            source: calibration
            color: "#555555"
            opacity: 1
        }

        ColorOverlay {
            id: calibrationOverlay
            anchors.fill: calibration
            source: calibration
            color: "white"
            opacity: 0
        }

        MouseArea {
            id: calibrationBtn
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            anchors.fill: parent
            onEntered: {
                calibrationOverlay.opacity = 1
            }
            onExited: {
                calibrationOverlay.opacity = 0
            }
        }
    }
}
