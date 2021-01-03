import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0



Rectangle {
    id: dropdownHMD
    width:200
    height:240
    color: "#424242"
    Universal.theme: Universal.Dark
    Universal.accent: Universal.Lime
    z: 2

    property alias buttonConnection: buttonConnection


    Text {
        id: textIPAddress
        x: 25
        y: 24
        color: "#ffffff"
        text: qsTr("Remote IP Address")
        font.pixelSize: 12
    }

    TextField {
        id: textfieldIP
        x: 25
        y: 45
        width: 150
        height: 27
        text: qsTr("")
        validator: RegExpValidator {
            regExp: /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/;
        }
        Component.onCompleted: {
            text = calibHMD.hmd_ip;
        }
    }

    Text {
        id: textPort
        x: 25
        y: 89
        color: "#ffffff"
        text: qsTr("Remote Port")
        font.pixelSize: 12
    }

    TextField {
        id: textfieldPort
        x: 25
        y: 110
        width: 150
        height: 27
        text: qsTr("")
        validator: RegExpValidator {
            regExp: /[0-9]{1,5}/;
        }
        Component.onCompleted: {
            text = calibHMD.hmd_port;
        }
    }

    Button {
        id: buttonConnection
        x: 25
        y: 168
        text: qsTr("Connect")

        onClicked: {
            if (textfieldIP.acceptableInput && textfieldPort.acceptableInput) {
                errorMsg.opacity = 0;
                calibHMD.update_network(textfieldIP.text, textfieldPort.text);
                mainWindow.activate_HMD_calibration();
                dropdownHMD.enabled = false;
                dropdownHMD.opacity = 0;
            }
            else {
                errorMsg.opacity = 1;
            }

        }
    }

    Text {
        id: errorMsg
        x: 25
        y: 145
        color: "#ff3b3b"
        text: qsTr("Invalid input!")
        font.pixelSize: 12
        opacity: 0
    }

    Image {
        id: triangle
        x: 3
        y: 3
        width: 25
        height: 25
        antialiasing: true
        rotation: 270
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
                dropdownHMD.enabled = false;
                dropdownHMD.opacity = 0;
            }
        }
    }


}


