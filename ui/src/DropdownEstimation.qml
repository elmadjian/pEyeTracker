import QtQuick 2.9
//import QtQuick.Window 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.0
import QtQuick.Controls.Universal 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: dropdownEstimation
    height: 472
    width: 839
    color: "white"
    Universal.theme: Universal.Dark
    Universal.accent: Universal.Lime
    z: 2

    signal drawEstimation(var tgt, var le, var re, var leErr, var reErr);
    property var targetList: [];
    property var leftEyeList;
    property var rightEyeList;

    Component.onCompleted: {
        calibControl.draw_estimation.connect(drawEstimation);
    }

    onDrawEstimation: {
        targetList = tgt;
        leftEyeList = le;
        rightEyeList = re;
        leftEyeError.text = "Left eye error = <b>" + leErr + "</b>";
        rightEyeError.text = "Right eye error = <b>" + reErr + "</b>";
        canvasArea.requestPaint();
    }

    function drawCrossHair(coord, ctx, color, width, size) {
        var c = denormalize(coord);
        var x = c[0];
        var y = c[1];
        ctx.beginPath();
        ctx.lineWidth = width;
        ctx.strokeStyle = color;
        ctx.moveTo(x,y-size);
        ctx.lineTo(x,y+size);
        ctx.moveTo(x-size,y);
        ctx.lineTo(x+size,y);
        ctx.stroke();
    }

    function denormalize(coord) {
        var newX = coord[0] * dropdownEstimation.width;
        var newY = coord[1] * dropdownEstimation.height;
        var x = Math.floor(newX)+0.5;
        var y = Math.floor(newY)+0.5;
        return [x, y];
    }


    Canvas {
        id: canvasArea
        anchors.fill: parent
        onPaint: {
            console.log("painting now");
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, canvasArea.width, canvasArea.height);
            for (var i = 0; i < targetList.length; i++) {
                drawCrossHair(targetList[i], ctx, "black", 2, 10);
                drawCrossHair(leftEyeList[i], ctx, "red", 1, 7);
                drawCrossHair(rightEyeList[i], ctx, "green", 1, 7);
            }

        }
    }

    Rectangle {
        id: caption
        width: parent.width
        height: 50
        color: "#CCCCCC"
        y: 475

        Item {
            x: 5
            y: 10
            Rectangle {
                width: 18
                height: 18
                color: "black"
            }
            Text {
                id: targetCaption
                x: 22
                y: 2
                text: qsTr("target")
            }
        }

        Item {
            x: 85
            y: 10
            Rectangle {
                width: 18
                height: 18
                color: "red"
            }
            Text {
                id: leftEyeCaption
                x: 22
                y: 2
                text: qsTr("left eye")
            }
        }

        Item {
            x: 165
            y: 10
            Rectangle {
                width: 18
                height: 18
                color: "green"
            }
            Text {
                id: rightEyeCaption
                x: 22
                y: 2
                text: qsTr("right eye")
            }
        }

        Text {
            id: leftEyeError
            x: 400
            y: 10
            text: qsTr("")
        }

        Text {
            id: rightEyeError
            x: 600
            y: 10
            text: qsTr("")
        }


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
                dropdownEstimation.enabled = false;
                dropdownEstimation.opacity = 0;
            }
        }
    }
}
