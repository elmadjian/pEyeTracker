import sys
from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, Property, Signal, QObject, Slot
import eye
import scene
import videoio_uvc
import calibration
import calibration_hmd
import cv2
import time
import numpy as np
import multiprocessing as mp


if __name__=='__main__':
    #mp.set_start_method('spawn')
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    videoio   = videoio_uvc.VideoIO_UVC()
    calib_ctl = calibration.Calibrator(3, 3, 30, 5)
    calib_hmd = calibration_hmd.HMDCalibrator(3, 3, 60, 4) 

    scene_cam = scene.SceneCamera('scene')
    le_cam    = eye.EyeCamera('left')
    re_cam    = eye.EyeCamera('right')
    videoio.set_active_cameras(scene_cam, le_cam, re_cam)
    calib_ctl.set_sources(scene_cam, le_cam, re_cam)
    calib_hmd.set_sources(le_cam, re_cam)

    engine.rootContext().setContextProperty("camManager", videoio)
    engine.rootContext().setContextProperty("sceneCam", scene_cam)
    engine.rootContext().setContextProperty("leftEyeCam", le_cam)
    engine.rootContext().setContextProperty("rightEyeCam", re_cam)
    engine.rootContext().setContextProperty("calibControl", calib_ctl)
    engine.rootContext().setContextProperty("calibHMD", calib_hmd)
    engine.addImageProvider('sceneimg', scene_cam)
    engine.addImageProvider('leyeimg', le_cam)
    engine.addImageProvider('reyeimg', re_cam)
    engine.load(QUrl("../ui/src/main.qml"))


    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec_())