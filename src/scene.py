import cv2
import numpy as np
import time
import sys
import camera_proc as camera
from scene_img_processor import SceneImageProcessor
from multiprocessing import Array, Process
import ctypes
import uvc


class SceneCamera(camera.Camera):

    '''
    This is the specialized scene camera extention of the Camera class.
    It is responsible for:
    - starting / stoping scene image processing independent tasks
    - tracking ARUCO markers on screen
    - providing marker position information to other objects
    '''

    def __init__(self, name=None, mode=(640,480,30)):
        super().__init__(name)
        self.mode = mode
        self.cam_process = None
        self.vid_process = None
        self.shared_array = self.create_shared_array(mode)
        self.shared_pos = self.create_shared_pos()

    def init_process(self, source, pipe, array, pos, mode, cap):
        mode = self.check_mode_availability(source, mode)
        self.cam_process = SceneImageProcessor(source, mode, pipe, 
                                               array, cap, pos)
        self.cam_process.start()  

    def init_vid_process(self, source, pipe, array, pos, mode, cap):
        mode = self.check_mode_availability(source, mode)
        self.cam_process = SceneImageProcessor(source, mode, pipe,
                                             array, cap, pos)
        self.vid_process = Process(target=self.cam_process.run_vid, args=())
        self.vid_process.start()    

    def join_process(self):
        self.cam_process.join(10)

    def join_vid_process(self):
        self.vid_process.join(3)

    def create_shared_array(self, mode):
        w = mode[0]
        h = mode[1]
        return Array(ctypes.c_uint8, h*w*3, lock=False)

    def create_shared_pos(self):
        return Array(ctypes.c_float, 3, lock=False)

    def check_mode_availability(self, source, mode):
        dev_list = uvc.device_list()
        cap = uvc.Capture(dev_list[source]['uid'])
        # m = (mode[1], mode[0], mode[2])
        if mode not in cap.avaible_modes:
            m = cap.avaible_modes[0]
            mode = (m[1], m[0], m[2])
            self.shared_array = self.create_shared_array(mode)
            self.mode = mode
        return mode
        


