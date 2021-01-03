import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0

GroupBox {
    id: leftEyeGroup
    label: Text {
        id: eyeTitle
        color: "white"
        text: "Left Eye Camera"
        font.weight: Font.Light
    }
    property bool video: false
    property alias leftIcon3d: leftIcon3d


    Image {
        id: leftIcon3d
        z: 2
        x: 256
        y: 174
        width: 35
        height: 35
        source: "../imgs/reload-icon.png"
        fillMode: Image.PreserveAspectFit
        opacity: 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        MouseArea {
            id: leftIcon3dButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            anchors.fill: parent
            onClicked: {
                leftEyeCam.reset();
            }
        }
    }

    ComboBox {
        id: eyeBox
        currentIndex: 0
        z: 1
        x: 141
        y: -12
        height: 28
        Component.onCompleted: {
            model = camManager.camera_list;
        }
        onPressedChanged: {
            if (pressed)
                model = camManager.camera_list;
        }
        onActivated:  {
            if (textAt(index) === "File...") {
                eyeFileDialog.visible = true;
            }
            else if (textAt(index) === "No feed") {
                leftEyeGroup.video?
                            camManager.stop_leye_cam(true):
                            camManager.stop_leye_cam(false);
                eyeImage.source = "../imgs/novideo.png";
            }
            else {
                leftEyeGroup.video = false;
                camManager.set_camera_source(eyeTitle.text, textAt(index));
                mainWindow.activate_config_type("leftEye");
                mainWindow.enable_calibration();
            }
        }
    }

    FileDialog {
        id: eyeFileDialog
        title: "Please, select a scene video file"
        folder: shortcuts.home
        visible: false
        nameFilters: ["Video files (*.avi, *.mkv, *.mpeg, *.mp4)", "All files (*)"]
        onAccepted: {
            var file = eyeFileDialog.fileUrl.toString();
            var suffix = file.substring(file.indexOf("/")+2);
            camManager.load_video(eyeTitle.text, suffix);
            leftEyeGroup.video = true;
            leftEyeGroup.parent.playImg.enabled = true;
        }
        onRejected: {
            eyeBox.currentIndex = 0;
        }
    }

    Image {
        id: eyeImage
        property bool counter: false
        anchors.rightMargin: -10
        anchors.leftMargin: -10
        anchors.bottomMargin: -10
        anchors.topMargin: -10
        source: "../imgs/novideo.png"
        anchors.fill: parent
        fillMode: Image.Stretch
        cache: false

        signal updateImage()
        Component.onCompleted: leftEyeCam.update_image.connect(updateImage);

        Connections {
            target: eyeImage
            function onUpdateImage() {
                eyeImage.counter = !eyeImage.counter; //hack to force update
                eyeImage.source = "image://leyeimg/eye" + eyeImage.counter;
            }
        }
    }

}
