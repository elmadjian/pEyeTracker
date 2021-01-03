import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0


    GroupBox {
        id: camGroup
        label: Text {
            id: camTitle
            color: "white"
            text: "Scene Camera"
            font.weight: Font.Light
        }
        property bool video: false
        property alias leyePrediction: leyePrediction
        property alias reyePrediction: reyePrediction

        ComboBox {
            id: sceneBox
            currentIndex: 0
            z: 1
            x: 493
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
                    sceneFileDialog.visible = true;
                }
                else if (textAt(index) === "No feed") {
                    camGroup.video?
                                camManager.stop_scene_cam(true) :
                                camManager.stop_scene_cam(false);
                    sceneImage.source = "../imgs/novideo.png";
                }
                else {
                    camGroup.video = false;
                    camManager.set_camera_source(camTitle.text, textAt(index));
                    mainWindow.activate_config_type("scene");
                    mainWindow.enable_calibration();
                }
            }
        }

        FileDialog {
            id: sceneFileDialog
            title: "Please, select a scene video file"
            folder: shortcuts.home
            visible: false
            nameFilters: ["Video files (*.avi, *.mkv, *.mpeg, *.mp4)", "All files (*)"]
            onAccepted: {
                var file = sceneFileDialog.fileUrl.toString();
                var suffix = file.substring(file.indexOf("/")+2);
                camManager.load_video(camTitle.text, suffix);
                camGroup.video = true;
                camGroup.parent.playImg.enabled = true;
            }
            onRejected: {
                sceneBox.currentIndex = 0;
            }
        }

        Image {
            id: sceneImage
            property bool counter: false
            height: 433
            anchors.rightMargin: -10
            anchors.leftMargin: -10
            anchors.bottomMargin: -10
            anchors.topMargin: -10
            anchors.fill: parent
            source: "../imgs/novideo.png"
            fillMode: Image.Stretch
            cache: false

            signal updateImage()
            Component.onCompleted: sceneCam.update_image.connect(updateImage);

            Connections {
                target: sceneImage
                function onUpdateImage() {
                    sceneImage.counter = !sceneImage.counter; //hack to force update
                    sceneImage.source = "image://sceneimg/scene" + sceneImage.counter;
                    var gazePoints = calibControl.predict;
                    //@disable-check M126
                    if (gazePoints[0] != -1.0 || gazePoints[2] != -1.0) {
                        //console.log('GP: ' + gazePoints[0] +' '+ gazePoints[1] + ' '+ gazePoints[2] + ' ' + gazePoints[3]);
                        leyePrediction.x = gazePoints[0] * sceneImage.width - leyePrediction.width/2;
                        leyePrediction.y = gazePoints[1] * sceneImage.height - leyePrediction.width/2;
                        reyePrediction.x = gazePoints[2] * sceneImage.width - reyePrediction.width/2;
                        reyePrediction.y = gazePoints[3] * sceneImage.height - reyePrediction.width/2;
                    }
                }
            }
            Rectangle {
                id: leyePrediction
                x: 10
                y: 10
                z: 3
                width: sceneImage.width/25
                height: width
                color: "purple"
                radius: width*0.5
                Text {
                    anchors.centerIn: parent
                    color: "white"
                    text: "L"
                }
            }

            Rectangle {
                id: reyePrediction
                x: 50
                y: 10
                z: 3
                width: sceneImage.width/25
                height: width
                color: "green"
                radius: width*0.5
                Text {
                    anchors.centerIn: parent
                    color: "white"
                    text: "R"
                }
            }
        }
    }
