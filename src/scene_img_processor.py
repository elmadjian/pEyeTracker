import cv2
import numpy as np
import img_processor as imp
import time
import uvc
import ctypes

class SceneImageProcessor(imp.ImageProcessor):

    def __init__(self, source, mode, pipe, array, cap, pos):
        super().__init__(source, mode, pipe, array, cap, pos)

    
    def run_vid(self):
        self.capturing.value = 1
        cap = cv2.VideoCapture(self.source)
        gamma, color, delay, loop = 1, True, 1/self.mode[2], True
        while cap.isOpened() and loop:
            ret, frame = cap.read()
            if ret:
                img = self.adjust_gamma(frame, gamma)
                img = self.cvtBlackWhite(img, color)
                img, pos = self.process(img)
                if img is not None:
                    shared_img = self.get_shared_np_array(img)
                    shared_pos = np.frombuffer(self.shared_pos,
                                               dtype=ctypes.c_float)
                    np.copyto(shared_img, img)
                    if pos is not None:
                        np.copyto(shared_pos, pos)
                time.sleep(delay)
            loop, gamma, color, _, _ = self.process_msg(gamma, color)
        cap.release()
        self.capturing.value = 0

    
    def run(self):
        self.capturing.value = 1
        dev_list = uvc.device_list()
        cap = uvc.Capture(dev_list[self.source]['uid'])
        cap.frame_mode = self.mode
        attempt, attempts, loop = 0, 4, True
        gamma, color = 1, True
        while attempt < attempts and loop:     
            try:
                frame    = cap.get_frame(2.0)
                img      = self.adjust_gamma(frame.bgr, gamma)
                img      = self.cvtBlackWhite(img, color)  
                img, pos = self.process(img)   
                if img is not None:
                    attempt = 0
                    shared_img = self.get_shared_np_array(img)
                    shared_pos = np.frombuffer(self.shared_pos, 
                                               dtype=ctypes.c_float)
                    np.copyto(shared_img, img)
                    if pos is not None:
                        np.copyto(shared_pos, pos)
            except Exception as e:
                print("error:", e)
                cap = self.reset_mode(cap)
                attempt += 1           
            loop, gamma, color, _, _ = self.process_msg(gamma, color)
        self.capturing.value = 0
        print("scene camera closed [source: {}]".format(self.source))
        

    def process(self, img):
        height, width = img.shape[0], img.shape[1]
        dict4 = cv2.aruco.DICT_4X4_50
        aruco_dict = cv2.aruco.getPredefinedDictionary(dict4)
        corners, ids,_ = cv2.aruco.detectMarkers(img, aruco_dict)
        target_pos = None
        if ids is not None:
            cv2.aruco.drawDetectedMarkers(img, corners, ids)
            mean = np.mean(corners[0][0], axis=0)
            x = mean[0]/width
            y = mean[1]/height
            target_pos = np.array([x,y,time.monotonic()],dtype='float32')
        return img, target_pos