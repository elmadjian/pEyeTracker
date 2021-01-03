import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.0


Item {
    id: calibHMDitem
    visible: false
    width: mainWindow.width
    height: mainWindow.height
    property alias keyListenerHMD: keyListenerHMD
    property bool recording: false
    property bool stalling: false
    signal moveOn()
    signal connStatus(var connectionStatus)

    Component.onCompleted: {
        calibHMD.move_on.connect(moveOn);
        calibHMD.conn_status.connect(connStatus);
    }

    onMoveOn: {
        recording = false;
        checkStateAndNextStep();
    }

    onConnStatus: {
        if (connectionStatus)
            calibHMDText.state = "success";
        else {
            calibHMDText.state = "failed";
        }
    }

    function reset() {
        calibHMDitem.visible = false;
        calibHMDText.state = "connecting";
    }

    //Calibration routine for a 2D procedure
    //--------------------------------------
    function nextCalibStep() {
        if (calibHMDText.state == "success") {
            calibHMDText.state = "calibrating";
            stalling = true;
        }

        if (stalling) {
            //recording, don't do nothing until it's finished
            if (recording) {
                console.log("Wait, recording data...");
                return
            }
            calibHMD.next_target();
            var target = calibHMD.target;

            //calibration ended
            if (target[0] === -9 && target[1] === -9) {
                console.log("calibration ended");
                calibHMD.perform_estimation();
                calibHMDText.state = "calib_finished";
                //reset();
            }
            stalling = false;

        }
        //record data
        else {
            stalling = true;
            recording = true;
            var freq_leye = leftEyeCam.current_fps;
            var freq_reye = rightEyeCam.current_fps;
            var max_freq  = Math.max(freq_leye, freq_reye);
            var min_freq  = Math.min(freq_leye, freq_reye);
            calibHMD.collect_data(min_freq, max_freq);
        }
    }

    // Calibration routine for gaze depth estimation
    //----------------------------------------------
    function nextDepthStep() {
        if (calibHMDText.state == "calib_finished") {
            calibHMDText.state = "depth_calib";
            calibHMD.start_depth_calibration();
            stalling = true;
        }
        if (stalling) {
            if (recording) {
                console.log("Wait, recording data...");
                return
            }
            calibHMD.next_depth_target();
            var target = calibHMD.depth_target;

            //calibration ended
            if (target[0] === -9 && target[1] === -9) {
                console.log("depth calibration ended");
                calibHMD.perform_depth_estimation();
                reset();
            }
            stalling = false;
        }
        //record data
        else {
            stalling = true;
            recording = true;
            var freq_leye = leftEyeCam.current_fps;
            var freq_reye = rightEyeCam.current_fps;
            var max_freq  = Math.max(freq_leye, freq_reye);
            var min_freq  = Math.min(freq_leye, freq_reye);
            calibHMD.collect_depth_data(min_freq, max_freq);
        }
    }

    function checkStateAndNextStep() {
        if (calibHMDText.state == "success" || 
        calibHMDText.state == "calibrating") {
            nextCalibStep();
        }
        else if (calibHMDText.state == "calib_finished" ||
        calibHMDText.state == "depth_calib") {
            nextDepthStep();
        }
    }

    Rectangle {
        id: calibHMDmode
        width: parent.width
        height: parent.height
        anchors.fill: parent
        opacity: 0.5
        color: "black"
        z:3
    }

    Rectangle {
        id: calibHMDmessage
        radius: 20
        border.width: 0
        height: 200
        color: "#f0dbc1"
        width: 350
        opacity: 1
        z:4
        anchors.centerIn: parent
        Component.onCompleted: {
            calibHMDText.state = "connecting";
        }

        Text {
            id: calibHMDText
            width: 271
            height: 54
            anchors.centerIn: parent
            text: qsTr("")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            font.pointSize: 12

            onVisibleChanged: {
                if (visible) {
                    console.log("connecting");
                    calibHMD.connect();
                }
            }

            Button {
                id: closeHMDbtn
                x: 86
                y: 62
                visible: false
                text: "OK"
                onClicked: {
                    calibHMDitem.visible = false;
                    closeHMDbtn.visible = false;
                    calibHMDText.state = "connecting";
                }
            }

            states: [
                State {
                    name: "connecting"
                    PropertyChanges {
                        target: calibHMDText
                        text: qsTr("Searching for HMD...")
                    }
                },
                State {
                    name: "failed"
                    PropertyChanges {
                        target: calibHMDText
                        text: qsTr("Could not find an HMD with current network settings")
                    }
                    PropertyChanges {
                        target: closeHMDbtn
                        visible: true
                    }
                },
                State {
                    name: "success"
                    PropertyChanges {
                        target: calibHMDText
                        text: qsTr("HMD found!\n"+
                                   "Press SPACE or DOUBLE_CLICK to "+
                                   "start gaze calibration")
                    }
                },
                State {
                    name: "calibrating"
                    PropertyChanges {
                        target: calibHMDText
                        text: qsTr("Calibration in progress...")

                    }
                },
                State{
                    name: "calib_finished"
                    PropertyChanges {
                        target: calibHMDText
                        text: qsTr("Gaze calibration finished!\n"+
                                   "Press SPACE or DOUBLE_CLICK to "+
                                   "start depth calibration")
                    }
                },
                State {
                    name: "depth_calib"
                    PropertyChanges {
                        target: calibHMDText
                        text: qsTr("Calibrating gaze depth...")
                    }
                }
            ]
        }
    }
    Item {
        id: keyListenerHMD
        focus: true
        anchors.fill: parent
        Keys.onPressed: {
            if (event.key === Qt.Key_Space) {
                event.accepted = true;
                checkStateAndNextStep();
            }
        }
    }
    MouseArea {
        id: mouseListenerHMD
        focus: true
        anchors.fill: parent
        onDoubleClicked: {
            checkStateAndNextStep();
        }
    }
}

