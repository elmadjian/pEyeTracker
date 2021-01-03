import QtQuick 2.9
import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.0

Window {
    id: calibWindow
    height: 720
    width: 1280
    color: "white"
    property var recording: false
    property var counter: 0

    signal moveOn()

    // @disable-check M16
    onClosing: {
        console.log("closing calib window");
        markerCenter.opacity = 0;
        calibTarget.visible = false;
        calibTargetOverlay.opacity = 0;
        reset();
    }

    Component.onCompleted: {
        calibControl.move_on.connect(moveOn);
    }
    onMoveOn: {
        recording = false;
        nextStep();
    }

    function reset() {
        calibWindow.visible = false;
        estimationMessage.opacity = 0;
        startMessage.opacity = 1;
    }


    function nextStep() {
        if (startMessage.opacity == 1) {
            startMessage.opacity = 0;
            calibTarget.visible = true;
            calibTargetOverlay.visible = true;
            markerCenter.opacity = 1
            calibTargetOverlay.opacity = 1
            calibControl.start_calibration();
        }
        if (calibTarget.visible) {

            //target was being collected: move to next position
            if (calibTargetOverlay.opacity == 1) {

                //recording, don't do nothing until it's finished
                if (recording) {
                    console.log("Wait, recording data...");
                    return
                }

                calibControl.next_target();
                var target = calibControl.target;

                //calibration ended
                if (target[0] === -1 && target[1] === -1) {
                    markerCenter.opacity = 0;
                    calibTarget.visible = false;
                    calibTargetOverlay.opacity = 0;
                    estimationMessage.opacity = 1;
                    calibControl.perform_estimation();
                    reset();
                }
                calibTargetOverlay.opacity = 0;
                calibTarget.x = target[0] * calibWindow.width - calibTarget.width/2;
                calibTarget.y = target[1] * calibWindow.height - calibTarget.height/2;
            }

            //record data
            else {
                calibTargetOverlay.opacity = 1;
                recording = true;
                var freq_scene = sceneCam.current_fps;
                var freq_leye  = leftEyeCam.current_fps;
                var freq_reye  = rightEyeCam.current_fps;
                var max_freq   = Math.max(freq_scene, freq_leye, freq_reye);
                var min_freq   = Math.min(freq_scene, freq_leye, freq_reye);
                calibControl.collect_data(min_freq, max_freq);
            }
        }
    }

    Item {
        id: keyListener
        focus: true
        anchors.fill: parent
        Keys.onPressed: {
            if (event.key === Qt.Key_Space) {
                event.accepted = true;
                nextStep();
            }
        }
    }
    MouseArea {
        id: mouseListener
        focus: true
        anchors.fill: parent
        onDoubleClicked: {
            nextStep();
        }
    }

    Image {
        visible: false
        id: calibTarget
        source:"../imgs/aruco.png"
        sourceSize.width: calibWindow.width/12
        sourceSize.height: calibWindow.height/6.75
    }

    ColorOverlay {
        visible: false
        id: calibTargetOverlay
        anchors.fill: calibTarget
        source: calibTarget
        color: "#752b26"
        opacity: 1
    }

    Rectangle {
        id: markerCenter
        width: calibTarget.width/18
        height: calibTarget.height/18
        color: "green";
        radius: width*0.5
        x: calibTarget.x + calibTarget.width/2 - markerCenter.width/2
        y: calibTarget.y + calibTarget.height/2 - markerCenter.height/2
        opacity: 0

//        signal showMarkerCenter(var showMarker)

//        Component.onCompleted: {
//            sceneCam.show_marker_center.connect(showMarkerCenter);
//        }
//        onShowMarkerCenter:  {
//            if (showMarker) {
//                console.log("update this exposing a QT Property in Python. Can't make changes from another process call!");
//            } else {
//                console.log("update this exposing a QT Property in Python. Can't make changes from another process call!");
//            }
//        }
    }

    Rectangle {
        id: startMessage
        radius: 20
        border.width: 0
        height: 200
        color: "#f0dbc1"
        width: 350
        opacity: 1
        z:2
        anchors.centerIn: parent

        Text {
            width: 271
            height: 54
            anchors.centerIn: parent
            text: qsTr("Press SPACE key or MIDDLE_BTN to start."
                      +" Use the same input to trigger recording"
                      +" for each target.")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pointSize: 12
        }
    }
    Rectangle {
        id: estimationMessage
        radius: 20
        border.width: 0
        height: 200
        color: "#f0dbc1"
        width: 350
        opacity: 0
        z:2
        anchors.centerIn: parent

        Text {
            width: 271
            height: 54
            anchors.centerIn: parent
            text: qsTr("Performing gaze estimation. Please wait.")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pointSize: 12
        }
    }
}

