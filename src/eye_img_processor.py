import cv2
import numpy as np
import img_processor as imp
import time
import sys
import uvc

class EyeImageProcessor(imp.ImageProcessor):

    '''
    It runs specialized image processing tasks for eye cameras
    as a separate process
    '''

    def __init__(self, source, mode, pipe, array, cap):
        super().__init__(source, mode, pipe, array, cap)

    def _setup_eye_cam(self, cap):
        if self.eye_cam:
            try:
                controls_dict = dict([(c.display_name, c) for c in cap.controls])
                controls_dict['Auto Exposure Mode'].value = 1
                controls_dict['Gamma'].value = 200
            except:
                print("Exposure settings not available for this camera.")

    def run_vid(self):
        self.capturing.value = 1
        cap = cv2.VideoCapture(self.source)
        gamma, color, delay, mode_3D = 1, True, 1/self.mode[2], False
        loop, flip = True, False
        while cap.isOpened() and loop:
            ret, frame = cap.read()
            if ret:
                img = self.adjust_gamma(frame, gamma)
                img = self.cvtBlackWhite(img, color)
                img = self.flip_img(img, flip) 
                if img is not None:
                    shared_img = self.get_shared_np_array(img)
                    np.copyto(shared_img, img)
                time.sleep(delay)
            loop,gamma,color,mode_3D,flip = self.process_msg(gamma,color,mode_3D,flip)
        cap.release()
        self.capturing.value = 0


    def run(self):
        self.capturing.value = 1
        dev_list = uvc.device_list()
        cap = uvc.Capture(dev_list[self.source]['uid'])
        self._setup_eye_cam(cap)
        cap.frame_mode = self.mode
        attempt, attempts, loop = 0, 5, True
        gamma, color, mode_3D, flip = 1, True, False, False
        while attempt < attempts and loop:     
            try:
                frame = cap.get_frame(2.0)
                img   = self.adjust_gamma(frame.bgr, gamma)
                img   = self.cvtBlackWhite(img, color)
                img   = self.flip_img(img, flip)       
                if img is not None:
                    attempt = 0
                    shared_img = self.get_shared_np_array(img)
                    np.copyto(shared_img, img)
            except Exception as e:
                print("error:", e)
                cap = self.reset_mode(cap)
                attempt += 1 
            loop,gamma,color,mode_3D,flip = self.process_msg(gamma,color,mode_3D,flip)      
        self.capturing.value = 0
        print("eye camera closed [source: {}]".format(self.source))