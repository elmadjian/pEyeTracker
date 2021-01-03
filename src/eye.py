import cv2
import time
import numpy as np
import camera_proc as camera
import sys 
import ctypes
import uvc
from matplotlib import pyplot as plt
from eye_img_processor import EyeImageProcessor
#from img_processor import ImageProcessor
from multiprocessing import Array, Process
from pupil_detectors import Detector3D, Detector2D



class EyeCamera(camera.Camera):

    def __init__(self, name=None, mode=(640,480,30)):
        super().__init__(name)
        self.mode = mode
        self.cam_process = None
        self.vid_process = None
        self.shared_array = self.create_shared_array(mode)
        self.shared_pos = self.create_shared_pos()
        self.mode_3D = False
        self.detector_2D = Detector2D()
        self.detector_3D = Detector3D()
        self.detector_2D.update_properties({'2d':{'pupil_size_max':250}})
        self.detector_3D.update_properties({'2d':{'pupil_size_max':250}})
        self.countdown = 5

    def init_process(self, source, pipe, array, pos, mode, cap):
        mode = self.check_mode_availability(source, mode)
        self.cam_process = EyeImageProcessor(source, mode, pipe, array, cap)
        self.cam_process.start()
        if self.mode_3D:
            self.pipe.send("mode_3D")    

    def init_vid_process(self, source, pipe, array, pos, mode, cap):
        mode = self.check_mode_availability(source, mode)
        self.cam_process = EyeImageProcessor(source, mode, pipe, array, cap)
        self.vid_process = Process(target=self.cam_process.run_vid, args=())
        self.vid_process.start()
        if self.mode_3D:
            self.pipe.send("mode_3D")

    def join_process(self):
        self.cam_process.join(10)

    def join_vid_process(self):
        self.vid_process.join(3)

    def toggle_3D(self):
        self.mode_3D = not self.mode_3D
        self.pipe.send("mode_3D")

    def create_shared_array(self, mode):
        w = mode[0]
        h = mode[1]
        return Array(ctypes.c_uint8, h*w*3, lock=False)

    def create_shared_pos(self):
        return Array(ctypes.c_float, 4, lock=False)

    def check_mode_availability(self, source, mode):
        dev_list = uvc.device_list()
        cap = uvc.Capture(dev_list[source]['uid'])
        if mode not in cap.avaible_modes:
            m = cap.avaible_modes[0]
            mode = (m[1], m[0], m[2])
            self.shared_array = self.create_shared_array(mode)
            self.mode = mode
        return mode

        '''
        {'ellipse': {'center': (134.35316467285156, 149.26513671875), 
                    'axes': (51.67513656616211, 61.95164489746094), 
                    'angle': 151.75175476074222}, 
                    'diameter': 61.95164489746094, 
                    'location': (134.35316467285156, 149.26513671875), 
                    'confidence': 0.6857050061225891
        '''
    def process(self, img):
        if img is None:
            return
        height, width = img.shape[0], img.shape[1]
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        timestamp = uvc.get_time_monotonic()
        if self.mode_3D:
            result = self.detector_3D.detect(gray, timestamp)
        else:
            result = self.detector_2D.detect(gray)
        if result["confidence"] > 0.6:
            if self.mode_3D:
                n = np.array(result['circle_3d']['normal'])
                center = np.array(result['circle_3d']['center'])     
                self.pos = np.array([n[0], n[1], n[2], time.monotonic()])
            else:
                c = np.array(result['ellipse']['center'])
                self.pos = np.array([c[0]/width, c[1]/height, time.monotonic()])
            self.__draw_tracking_info(result, img)
            self.countdown = 5
        else:
            self.countdown -= 1
            if self.countdown <= 0:
                self.pos = None
        return img
 
    def __draw_tracking_info(self, result, img, color=(255,120,120)):
        ellipse = result["ellipse"]
        center = tuple(int(v) for v in ellipse["center"])
        cv2.drawMarker(img, center, (0,255,0), cv2.MARKER_CROSS, 12, 1)
        self.__draw_ellipse(ellipse, img, (0,0,255))
        if self.mode_3D:
            sphere = result["projected_sphere"]
            normal = result["circle_3d"]["normal"]
            dest_pos = (int(center[0]+normal[0]*60), int(center[1]+normal[1]*60))
            cv2.line(img, center, dest_pos, (85,175,20),2)
            if result['model_confidence'] > 0.6:
                self.__draw_ellipse(sphere, img, (255, 204, 51), 1)


    def __draw_ellipse(self, ellipse, img, color, thickness=2):
        center = tuple(int(v) for v in ellipse["center"])
        axes = tuple(int(v/2) for v in ellipse["axes"])
        rad = ellipse["angle"]
        cv2.ellipse(img, center, axes, rad, 0, 360, color, 2)

    
    def reset_model(self):
        if self.mode_3D:
            self.detector_3D.reset_model()
        else:
            self.detector_2D.reset_model()


    def get_processed_data(self):
        return self.pos




            

