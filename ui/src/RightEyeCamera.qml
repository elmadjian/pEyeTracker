import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0

GroupBox {
    id: rightEyeGroup
    visible: true
    label: Text {
        id:rightEyeTitle
        color: "white"
        text: "Right Eye Camera"
        font.weight: Font.Light
    }
    property bool video: false
    property alias rightIcon3d: rightIcon3d

    Image {
        id: rightIcon3d
        z: 2
        x: 261
        y: 174
        width: 35
        height: 35
        source: "../imgs/reload-icon.png"
        fillMode: Image.PreserveAspectFit
        opacity: 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        MouseArea {
            id: rightIcon3dButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            anchors.fill: parent
            onClicked: {
                rightEyeCam.reset();
            }
        }
    }

    ComboBox {
        id: rightEyeBox
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
                rightEyeFileDialog.visible = true;
            }
            else if (textAt(index) === "No feed") {
                rightEyeGroup.video?
                            camManager.stop_reye_cam(true):
                            camManager.stop_reye_cam(false);
                reyeImage.source = "../imgs/novideo.png";
            }
            else {
                rightEyeGroup.video = false;
                camManager.set_camera_source(rightEyeTitle.text, textAt(index));
                mainWindow.activate_config_type("rightEye");
                mainWindow.enable_calibration();
            }
        }
    }

    FileDialog {
        id: rightEyeFileDialog
        title: "Please, select a scene video file"
        folder: shortcuts.home
        visible: false
        nameFilters: ["Video files (*.avi, *.mkv, *.mpeg, *.mp4)", "All files (*)"]
        onAccepted: {
            var file = rightEyeFileDialog.fileUrl.toString();
            var suffix = file.substring(file.indexOf("/")+2);
            camManager.load_video(rightEyeTitle.text, suffix);
            rightEyeGroup.video = true;
            playImg.enabled = true;
        }
        onRejected: {
            rightEyeBox.currentIndex = 0;
        }
    }

    Image {
        id: reyeImage
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
        Component.onCompleted: rightEyeCam.update_image.connect(updateImage);

        Connections {
            target: reyeImage
            function onUpdateImage() {
                reyeImage.counter = !reyeImage.counter; //hack to force update
                reyeImage.source = "image://reyeimg/eye" + reyeImage.counter;
            }
        }
    }


}
