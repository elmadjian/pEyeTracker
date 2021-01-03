import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0



Rectangle {
    id: dropdown
    width:175
    height:260
    color: "#424242"
    Universal.theme: Universal.Dark
    Universal.accent: Universal.Lime
    z: 2

    property alias comboFrameRate: comboFrameRate
    property alias comboResolution: comboResolution
    property alias dialGamma: dialGamma
    property alias switchColor: switchColor
    property alias switchFlip: switchFlip
    property alias textFlip: textFlip

    Text {
        id: textFrameRate
        x: 25
        y: 20
        color: "#ffffff"
        text: qsTr("Frame Rate")
        font.pixelSize: 12
    }

    ComboBox {
        id: comboFrameRate
        x: 25
        y: 40
        width: 125
        height: 25
        z:3
        model:""
    }

    Text {
        id: textResolution
        x: 25
        y: 80
        color: "#ffffff"
        text: qsTr("Resolution")
        font.pixelSize: 12
    }

    ComboBox {
        id: comboResolution
        x: 25
        y: 100
        width: 125
        height: 25
        z:3
        model:""
    }

    Text {
        id: textGamma
        x: 25
        y: 145
        color: "#ffffff"
        text: qsTr("Gamma")
        font.pixelSize: 12
    }

    Dial {
        id: dialGamma
        x: 23
        y: 160
        width: 56
        height: 88
        wheelEnabled: false
        value: 1.0
        background: Rectangle {
            x: dialGamma.width / 2 - width / 2
            y: dialGamma.height / 2 - height / 2
            width: Math.max(64, Math.min(dialGamma.width, dialGamma.height))
            height: width
            color: "transparent"
            radius: width / 2
            border.color: dialGamma.pressed ? "white" : "gray"
            opacity: dialGamma.enabled ? 1 : 0.3
        }
        handle: Rectangle {
            id: handleItem
            x: dialGamma.background.x + dialGamma.background.width / 2 - width / 2
            y: dialGamma.background.y + dialGamma.background.height / 2 - height / 2
            width: 15
            height: 15
            color: dialGamma.pressed ? "#white" : "gray"
            radius: 8
            border.width: 0
            antialiasing: true
            opacity: dialGamma.enabled ? 1 : 0.3
            transform: [
                Translate {
                    y: -Math.min(dialGamma.background.width, dialGamma.background.height) * 0.4 + handleItem.height / 2
                },
                Rotation {
                    angle: dialGamma.angle
                    origin.x: handleItem.width / 2
                    origin.y: handleItem.height / 2
                }
            ]
        }
    }


    Text {
        id: textColor
        x: 115
        y: 145
        color: "#ffffff"
        text: qsTr("Color")
        font.pixelSize: 12
    }

    Switch {
        id: switchColor
        x: 100
        y: 156
        width: 61
        height: 44
        padding: 0
        rightPadding: 4
        bottomPadding: 4
        leftPadding: 4
        topPadding: 4
        spacing: 5
        checked: true
        font.pointSize: 8
    }

    Text {
        id: textFlip
        x: 115
        y: 201
        color: "#ffffff"
        text: qsTr("Flip")
        font.pixelSize: 12
    }

    Switch {
        id: switchFlip
        x: 100
        y: 210
        width: 61
        height: 44
        bottomPadding: 4
        font.pointSize: 8
        checked: false
        rightPadding: 4
        spacing: 5
        leftPadding: 4
        topPadding: 4
        padding: 0
    }

    Image {
        id: triangle
        x: 147
        y: 3
        width: 25
        height: 25
        source: "../imgs/triangle.png"

        ColorOverlay {
            id: triangleOverlay
            anchors.fill: triangle
            source: triangle
            color: "white"
            opacity: 0
        }


        MouseArea {
            hoverEnabled: true
            id:closeDropdown
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor;
            onEntered: {
                triangleOverlay.opacity = 1;
            }
            onExited: {
                triangleOverlay.opacity = 0;
            }
            onClicked: {
                dropdown.opacity = 0;
                dropdown.enabled = false;
            }
        }
    }


}


