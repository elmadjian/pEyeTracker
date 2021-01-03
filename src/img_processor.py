import uvc
from multiprocessing import Process, Pipe, Array
import traceback
import cv2
import sys
import time
import numpy as np
import ctypes


class ImageProcessor(Process):

    '''
    It provides generic image processing functionality for
    specialized image processing classes, such as gamma
    adjusment, B&W convertion, etc.
    '''

    def __init__(self, source, mode, pipe, array, cap, pos=None):
        Process.__init__(self)
        self.eye_cam = False
        self.source = source
        self.mode = mode
        self.pipe = pipe
        self.shared_array = array
        self.shared_pos = pos
        self.capturing = cap
    
    def get_shared_np_array(self, img):
        nparray = np.frombuffer(self.shared_array, dtype=ctypes.c_uint8) 
        return nparray.reshape(img.shape)

    def adjust_gamma(self, img, gamma):
        lut = np.empty((1,256), np.uint8)
        for i in range(256):
            lut[0,i] = np.clip(pow(i/255.0, gamma) * 255.0, 0, 255)
        return cv2.LUT(img, lut)

    def cvtBlackWhite(self, img, color):
        if color:
            return img
        return cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    def flip_img(self, img, flip):
        if flip:
            return cv2.flip(img, -1)
        return img

    def reset_mode(self, cap):
        print("resetting...")
        mode = cap.frame_mode
        cap.close()
        time.sleep(0.5)
        dev_list = uvc.device_list()
        cap2 = uvc.Capture(dev_list[self.source]['uid'])
        print("Trying mode:", mode)
        cap2.frame_mode = mode
        cap2.bandwidth_factor = 1.3
        return cap2


    def process_msg(self, gamma, color, mode_3D=None, flip=None):  
        loop = True
        if self.pipe.poll():
            msg = self.pipe.recv()
            if msg == "stop": 
                loop = False
            elif msg == "pause":
                while msg != "play":
                    msg = self.pipe.recv()
            elif msg == "mode_3D":
                mode_3D = not mode_3D
            elif msg == "gamma":
                gamma = self.pipe.recv()
            elif msg == "color":
                color = self.pipe.recv()
            elif msg == "flip":
                flip = self.pipe.recv()
        return loop, gamma, color, mode_3D, flip
            

    def run(self):
        return

    def run_vid(self):
        return
   
