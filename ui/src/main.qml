import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.0

Window {
    id: mainWindow
    visible: true
    width: 1050
    height: 650
    color: "#202020"
    title: qsTr("pEye Tracker")
    Universal.theme: Universal.Dark
    Universal.accent: Universal.Lime
    // @disable-check M16
    onClosing: {
        console.log("closing window");
        calibControl.save_session();
        //calibHMD.save_session();
        if (sceneGroup.video || leftEyeGroup.video || rightEyeGroup.video) {
            camManager.stop_cameras(true);
        } else {
            camManager.stop_cameras(false);
        }
    }

    /*
    Scene Camera
    ------------
    */
    SceneCamera {
        id: sceneGroup
        x: 30
        y: 140
        width: 660
        height: 490
        topPadding: 32
        rightPadding: 12
        leftPadding: 12
    }

    /*
    Left Eye Camera
    ---------------
    */
    LeftEyeCamera {
        id: leftEyeGroup
        x: 710
        y: 140
        width: 315
        height: 238
    }

    /*
    Right Eye Camera
    ----------------
    */
    RightEyeCamera {
        id: rightEyeGroup
        x: 710
        y: 391
        width: 315
        height: 238
    }



    //Helper functions
    //----------------
    function update_comboboxes(uid, camType) {
        uid.comboFrameRate.model = camType.fps_list;
        uid.comboResolution.model = camType.modes_list;
        uid.comboFrameRate.currentIndex = camType.current_fps_index;
        uid.comboResolution.currentIndex = camType.current_res_index;
    }

    function activate_dropdown(uid_active, uid2, uid3) {
        uid_active.enabled = !uid_active.enabled;
        uid_active.opacity = !uid_active.opacity;
        uid2.enabled = false;
        uid2.opacity = 0;
        uid3.enabled = false;
        uid3.opacity = 0;
    }

    function activate_config(overlay, prefImg) {
        overlay.enabled = false;
        overlay.opacity = 0;
        prefImg.enabled = true;
    }

    function activate_config_type(groupType) {
        if (groupType === "scene")
            activate_config(sceneDisabledOverlay, prefSceneImg);
        else if (groupType === "leftEye")
            activate_config(leftEyeDisabledOverlay, prefLeftEyeImg);
        else
            activate_config(rightEyeDisabledOverlay, prefRightEyeImg);
    }

    function enable_calibration() {
        if (calibrationModeBox.currentText == "Screen") {
            if (prefSceneImg.enabled && (prefLeftEyeImg.enabled || prefRightEyeImg.enabled)) {
                calibration.enabled = true;
                calibrationDisabledOverlay.opacity = 0;
            }
        }
        else if (calibrationModeBox.currentText == "HMD") {
            if (prefLeftEyeImg.enabled && prefRightEyeImg.enabled) {
                calibration.enabled = true;
                calibrationDisabledOverlay.opacity = 0;
            }
        }
    }

    function activate_HMD_calibration() {
        calibHMDitem.visible = true;
        calibHMDitem.keyListenerHMD.focus = true;
    }


    /*
    PLAYBACK CONTROL
    ---------------- */
    GroupBox {
        id: playbackSettings
        x: 500
        y: 16
        width: 110
        height: 110
        label: Text {
            color:"gray"
            text:"Playback"
        }

        ColumnLayout {
            y:0
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: playLabel
                text: qsTr("Play")
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                id: playImg
                sourceSize.width: 50
                sourceSize.height: 50
                fillMode: Image.PreserveAspectFit
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                source: "../imgs/play.png"
                enabled: false
                z:1
                states: [
                    State {
                        name: "stalled"
                        PropertyChanges {
                            target: playImg
                            source: "../imgs/play.png"
                        }
                    },
                    State {
                        name: "playing"
                        PropertyChanges {
                            target: playImg
                            source: "../imgs/play.png"
                        }
                    },
                    State {
                        name: "paused"
                        PropertyChanges {
                            target: playImg
                            source: "../imgs/pause.png"
                        }
                    }
                ]
                Component.onCompleted: state = "stalled";

                ColorOverlay {
                    id: playDisabledOverlay
                    anchors.fill: playImg
                    source: playImg
                    color: "#555555"
                    opacity: 1
                }

                ColorOverlay {
                    id: playOverlay
                    anchors.fill: playImg
                    source: playImg
                    color: "white"
                    opacity: 0
                }

                MouseArea {
                    id: playBtn
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onEntered: {
                        playOverlay.opacity = 1
                    }
                    onExited: {
                        playOverlay.opacity = 0
                    }
                    onClicked: {
                        if (playImg.state == "stalled" || playImg.state == "paused") {
                            camManager.play_cams(sceneGroup.video, leftEyeGroup.video, rightEyeGroup.video);
                            playImg.state = "playing";
                        }
                        else if (playImg.state == "playing") {
                            camManager.pause_cams(sceneGroup.video, leftEyeGroup.video, rightEyeGroup.video);
                            playImg.state = "paused";
                        }
                    }
                }
            }
        }
    }

    // CAMERA SETTINGS
    //---------------------
    GroupBox {
        id: cameraSettings
        x: 710
        y: 16
        width: 315
        height: 110
        visible: true
        label: Text {
            color:"gray"
            text:"Camera Settings"
        }
        ColumnLayout {
            y: 0
            width: 65
            height: 60
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: prefSceneLabel
                text: qsTr("Scene")
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                id: prefSceneImg
                sourceSize.height: 45
                sourceSize.width: 45
                fillMode: Image.PreserveAspectFit
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                source: "../imgs/scene.png"
                enabled: false
                z:1

                ColorOverlay {
                    id: sceneDisabledOverlay
                    anchors.fill: prefSceneImg
                    source: prefSceneImg
                    color: "#555555"
                    opacity: 1
                }

                ColorOverlay {
                    id: sceneOverlayImg
                    anchors.fill: prefSceneImg
                    source: prefSceneImg
                    color: "white"
                    opacity: 0
                }

                MouseArea {
                    id: prefSceneBtn
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onEntered: {
                        sceneOverlayImg.opacity = 1
                    }
                    onExited: {
                        sceneOverlayImg.opacity = 0
                    }
                    onClicked: {
                        update_comboboxes(scenePrefDropdown, sceneCam);
                        activate_dropdown(scenePrefDropdown, leftEyePrefDropdown, rightEyePrefDropdown);
                    }
                }
                Dropdown {
                    id:scenePrefDropdown
                    x: -143
                    y: 49
                    enabled: false;
                    opacity: 0;
                    comboFrameRate.onActivated: {
                        sceneCam.set_mode(comboFrameRate.currentText, comboResolution.currentText);
                        update_comboboxes(scenePrefDropdown, sceneCam);
                    }
                    comboResolution.onActivated: {
                        sceneCam.set_mode(comboFrameRate.currentText, comboResolution.currentText);
                        update_comboboxes(scenePrefDropdown, sceneCam);
                    }
                    dialGamma.onMoved: {
                        sceneCam.set_gamma(dialGamma.value);
                    }
                    switchColor.onToggled: {
                        sceneCam.set_color(switchColor.position);
                    }
                    switchFlip.visible: false
                    textFlip.visible: false
                }
            }

        }

        ColumnLayout{
            x: 104
            y: 0
            width: 65
            height: 60
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: prefLeftLabel
                text: qsTr("Left Eye")
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                id: prefLeftEyeImg
                sourceSize.height: 45
                sourceSize.width: 45
                fillMode: Image.PreserveAspectFit
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                source: "../imgs/eye-left.png"
                enabled: false
                z:1

                ColorOverlay {
                    id: leftEyeDisabledOverlay
                    anchors.fill: prefLeftEyeImg
                    source: prefLeftEyeImg
                    color: "#555555"
                    opacity: 1
                }

                ColorOverlay {
                    id: leftEyeOverlayImg
                    anchors.fill: prefLeftEyeImg
                    source: prefLeftEyeImg
                    color: "white"
                    opacity: 0
                }

                MouseArea {
                    id: prefLeftEyeBtn
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onEntered: {
                        leftEyeOverlayImg.opacity = 1
                    }
                    onExited: {
                        leftEyeOverlayImg.opacity = 0
                    }
                    onClicked: {
                        update_comboboxes(leftEyePrefDropdown, leftEyeCam);
                        activate_dropdown(leftEyePrefDropdown, scenePrefDropdown, rightEyePrefDropdown);
                    }
                }
                Dropdown {
                    id:leftEyePrefDropdown
                    x: -143
                    y: 49
                    enabled: false;
                    opacity: 0;
                    comboFrameRate.onActivated: {
                        leftEyeCam.set_mode(comboFrameRate.currentText, comboResolution.currentText);
                        update_comboboxes(leftEyePrefDropdown, leftEyeCam);
                    }
                    comboResolution.onActivated: {
                        leftEyeCam.set_mode(comboFrameRate.currentText, comboResolution.currentText);
                        update_comboboxes(leftEyePrefDropdown, leftEyeCam);
                    }
                    dialGamma.onMoved: {
                        leftEyeCam.set_gamma(dialGamma.value);
                    }
                    switchColor.onToggled: {
                        leftEyeCam.set_color(switchColor.position);
                    }
                    switchFlip.onToggled: {
                        leftEyeCam.flip_image(switchFlip.position);
                    }
                }
            }
        }


        ColumnLayout {
            x: 210
            y: 0
            width: 65
            height: 60
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: prefRightLabel
                text: qsTr("Right Eye")
                color:"white"
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                id: prefRightEyeImg
                sourceSize.width: 45
                sourceSize.height: 45
                fillMode: Image.PreserveAspectFit
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                source: "../imgs/eye-right.png"
                enabled: false
                z:1

                ColorOverlay {
                    id: rightEyeDisabledOverlay
                    anchors.fill: prefRightEyeImg
                    source: prefRightEyeImg
                    color: "#555555"
                    opacity: 1
                }

                ColorOverlay {
                    id: rightEyeOverlayImg
                    anchors.fill: prefRightEyeImg
                    source: prefRightEyeImg
                    color: "white"
                    opacity: 0
                }

                MouseArea {
                    id: prefRighttEyeBtn
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onEntered: {
                        rightEyeOverlayImg.opacity = 1
                    }
                    onExited: {
                        rightEyeOverlayImg.opacity = 0
                    }
                    onClicked: {
                        update_comboboxes(rightEyePrefDropdown, rightEyeCam);
                        activate_dropdown(rightEyePrefDropdown, scenePrefDropdown, leftEyePrefDropdown);
                    }
                }
                Dropdown {
                    id:rightEyePrefDropdown
                    x: -143
                    y: 49
                    enabled: false;
                    opacity: 0;
                    comboFrameRate.onActivated: {
                        rightEyeCam.set_mode(comboFrameRate.currentText, comboResolution.currentText);
                        update_comboboxes(rightEyePrefDropdown, rightEyeCam);
                    }
                    comboResolution.onActivated: {
                        rightEyeCam.set_mode(comboFrameRate.currentText, comboResolution.currentText);
                        update_comboboxes(rightEyePrefDropdown, rightEyeCam);
                    }
                    dialGamma.onMoved: {
                        rightEyeCam.set_gamma(dialGamma.value);
                    }
                    switchColor.onToggled: {
                        rightEyeCam.set_color(switchColor.position);
                    }
                    switchFlip.onToggled: {
                        leftEyeCam.flip_image(switchFlip.position);
                    }
                }
            }
        }
    }

    //CALIBRATION SETTINGS
    //--------------------
    GroupBox {
        id: calibrationSettings
        x: 30
        y: 16
        width: 460
        height: 110
        label: Text {
            color:"gray"
            text:"Calibration Settings"
        }
        ColumnLayout {
            y:0
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: calibrationLabel
                text: qsTr("Calibrate")
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                id: calibration
                sourceSize.width: 50
                sourceSize.height: 50
                fillMode: Image.PreserveAspectFit
                Layout.preferredHeight: 50
                Layout.preferredWidth: 50
                source: "../imgs/calibration.png"
                enabled: false
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
                    onClicked: {
                        //calibScreen.showFullScreen();
                        if (calibrationModeBox.currentText == "Screen") {
                            console.log("initializing on-screen calibration");
                            calibScreen.showNormal();
                        }
                        else if (calibrationModeBox.currentText == "HMD") {
                            dropdownHMD.enabled = true;
                            dropdownHMD.opacity = 1;
                            calibHMDitem.focus = true;
                        }
                    }
                }
                DropdownHMD {
                    id: dropdownHMD
                    x: 34
                    y: 50
                    enabled: false
                    opacity: 0
                }
            }
        }

        ColumnLayout {
            x: 67
            y: 0
            Text {
                id: estimationLabel
                color: "#ffffff"
                text: qsTr("Estimation")
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Image {
                id: estimation
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 50
                sourceSize.width: 50
                z: 1
                source: "../imgs/estimation.png"
                Layout.preferredHeight: 50
                sourceSize.height: 50
                enabled: false

                signal enableEstimation();

                Component.onCompleted: {
                    calibControl.enable_estimation.connect(enableEstimation);
                }

                onEnableEstimation: {
                    estimation.enabled = true;
                    estimationDisabledOverlay.opacity = 0;
                }

                ColorOverlay {
                    id: estimationDisabledOverlay
                    color: "#555555"
                    opacity: 1
                    source: estimation
                    anchors.fill: estimation
                }

                ColorOverlay {
                    id: estimationOverlay
                    color: "#ffffff"
                    opacity: 0
                    source: estimation
                    anchors.fill: estimation
                }

                MouseArea {
                    id: estimationBtn
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    anchors.fill: parent
                    onEntered: {
                        estimationOverlay.opacity = 1
                    }
                    onExited: {
                        estimationOverlay.opacity = 0
                    }
                    onClicked: {
                        if (!dropdownEstimation.enabled) {
                            dropdownEstimation.enabled = true;
                            dropdownEstimation.opacity = 1;
                            calibControl.show_estimation();
                        } else {
                            dropdownEstimation.enabled = false;
                            dropdownEstimation.opacity = 0;
                        }
                    }
                }
                DropdownEstimation {
                    id: dropdownEstimation
                    x: 34
                    y: 50
                    z: 2
                    enabled: false
                    opacity: 0;
                }
            }
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillHeight: false
        }

        ColumnLayout {
            x: 145
            y:0
            width: 140
            height: 60
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: calibrationModeLabel
                text: qsTr("Mode")
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            ComboBox {
                id: calibrationModeBox
                width: 140
                height: 28
                currentIndex: 0
                z: 1
                font.pointSize: 10
                model: ["Screen", "HMD"]
                onActivated:  {
                    console.log("selected:", index);
                }
            }
        }
        ColumnLayout {
            x: 290
            y:0
            width: 60
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: calibrationStoreLabel
                text: qsTr("Store Data")
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            Switch {
                id: switchStore
                width: 50
                height: 40
                checked: false
                font.pointSize: 8
                onCheckedChanged: {
                    calibControl.toggle_storage();
                }
            }
        }

        //3D management
        //-------------
        ColumnLayout {
            x: 370
            y:0
            width: 60
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            Text {
                id: calibration3DLabel
                text: qsTr("3D Model")
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            Switch {
                id: switch3DModel
                width: 50
                height: 40
                checked: false
                font.pointSize: 8
                onCheckedChanged: {
                    camManager.toggle_3D();
                    calibControl.toggle_3D();
                    calibHMD.toggle_3D();
                    if (switch3DModel.checked) {
                        leftEyeGroup.leftIcon3d.opacity  = 1;
                        rightEyeGroup.rightIcon3d.opacity = 1;
                    } else {
                        leftEyeGroup.leftIcon3d.opacity  = 0;
                        rightEyeGroup.rightIcon3d.opacity = 0;
                    }
                }
            }
        }

    }

    /*CALIBRATION SCREEN
      ------------------*/
    CalibScreen {
        id: calibScreen
        visible: false
        height: 720
        width: 1280
    }

    /*CALIBRATION HMD
      -----------------*/
    CalibHMD {
        id: calibHMDitem
        visible: false
        width: mainWindow.width
        height: mainWindow.height
    }
}
