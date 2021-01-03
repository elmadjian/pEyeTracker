from PySide2.QtGui import QImage, QPixmap
from PySide2 .QtCore import QObject, Signal, Slot, Property, QBasicTimer, QPoint
from PySide2.QtQuick import QQuickPaintedItem, QQuickImageProvider
from threading import Thread, Lock
from multiprocessing import Process, Pipe, Value, Condition, Array
import cv2
import numpy as np
import time
import uvc
import sys
import traceback
import ctypes
import os

class Camera(QQuickImageProvider, QObject):

    update_image = Signal()

    def __init__(self, name=None):
        QQuickImageProvider.__init__(self, QQuickImageProvider.Pixmap)
        QObject.__init__(self)
        self.__image = self.to_QPixmap(cv2.imread("../ui/test.jpg"))
        self.__np_img = None
        self.name = name
        self.capturing = Value('i', 0)
        self.dev_list = uvc.device_list()
        self.fps_res = {}
        self.modes = {}
        self.mode = None         # --> subclassed property
        self.shared_array = None # --> subclassed property
        self.shared_pos = None   # --> subclassed property
        self.source = None
        self.cap = None
        self.pipe, self.child = Pipe()
        self.cam_process = None
        self.vid_process = None
        self.cam_thread = None
        self.paused = False
        self.gamma = 1.0
        self.color = True
        self.flip = False
        

    def thread_loop(self):
        while self.capturing.value:
            time.sleep(0.005)
            try:
                img = self.__get_shared_np_array()
                img = self.process(img)
                self.__np_img = img
                qimage = self.to_QPixmap(img)
                if qimage is not None:
                    self.__image = qimage
                    self.update_image.emit()
            except Exception as e:
                print(">>> Exception:", e)

    def __get_shared_np_array(self):
        nparray = np.frombuffer(self.shared_array, dtype=ctypes.c_uint8)
        w, h = self.mode[0], self.mode[1]
        return nparray.reshape((h,w,3))

    def create_shared_array(self, mode):
        w = mode[0]
        h = mode[1]
        return Array(ctypes.c_uint8, h*w*3, lock=False)

    def requestImage(self, id, size, requestedSize):
        return self.__image

    def requestPixmap(self, id, size, requestImage):
        return self.__image

    def get_np_image(self):
        return self.__np_img

    def get_processed_data(self):
        nparray = np.frombuffer(self.shared_pos, dtype=ctypes.c_float)
        return nparray

    def init_process(self, source, pipe, array, pos, mode, cap): #abstract
        return 

    def init_vid_process(self, source, pipe, array, pos, mode, cap): #abstract
        return

    def process(self, img):
        return img

    def join_process(self): #abstract
        return

    def join_vid_process(self): # abstract
        return 

    def reset_model(self): #abstract
        return

    def get_processed_data(self): #abstract
        return

    def stop(self, video_file=False):
        if self.capturing.value:
            if self.paused:
                self.pipe.send("play")
            self.pipe.send("stop")
            if video_file:
                self.join_vid_process()
                if self.vid_process.is_alive():
                    self.vid_process.terminate()
            else:
                self.join_process()
                if self.cam_process.is_alive():
                    self.cam_process.terminate()
            self.cam_thread.join(1)

    def play(self, is_video):
        if is_video:
            if not self.capturing.value:
                self.play_video_file()
            else:
                self.pipe.send("play")
                self.paused = False

    def pause(self, is_video):
        if is_video:
            self.pipe.send("pause")
            self.paused = True

    def get_source(self):
        return self.source
    
    def is_cam_active(self):
        if self.cam_thread is not None:
            if self.cam_thread.is_alive():
                return True
        return False

    def set_source(self, source):
        print('setting camera source to', source)
        self.source = source
        self.load_state()
        self.__set_fps_modes()
        self.shared_array = self.create_shared_array(self.mode)
        self.capturing.value = 1
        self.init_process(source, self.child, self.shared_array, 
                          self.shared_pos, self.mode, self.capturing)
        self.cam_thread = Thread(target=self.thread_loop, args=())
        self.save_state()
        self.cam_thread.start()
        

    def set_video_file(self, filename):
        cap = cv2.VideoCapture(filename)
        w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
        h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
        f = cap.get(cv2.CAP_PROP_FPS)
        self.source = filename
        self.mode = (int(w),int(h),int(f)) 
        self.modes = {}
        self.shared_array = self.create_shared_array(self.mode)
        ret, frame = cap.read()
        if ret:
            qimage = self.to_QPixmap(frame)
            if qimage is not None:
                self.__image = qimage
                self.update_image.emit()
        cap.release()

    def play_video_file(self):
        self.capturing.value = 1
        self.init_vid_process(self.source, self.child, self.shared_array, 
                    self.shared_pos, self.mode, self.capturing)
        self.cam_thread = Thread(target=self.thread_loop, args=())
        self.cam_thread.start()

    def __set_fps_modes(self):
        self.fps_res, self.modes = {}, {}
        dev_list = uvc.device_list()
        cap = uvc.Capture(dev_list[self.source]['uid'])
        for i in range(len(cap.avaible_modes)):
            mode = cap.avaible_modes[i]
            fps  = mode[2]
            if fps not in self.fps_res.keys():
                self.fps_res[fps] = []
                self.modes[fps]   = []
            resolution = str(mode[0]) + " x " + str(mode[1])
            self.modes[fps].append(mode)
            self.fps_res[fps].append(resolution)
        if self.mode not in cap.avaible_modes:
            self.mode = sorted(cap.avaible_modes)[0]
        cap.close()

    @Property('QVariantList')
    def fps_list(self):
        return sorted(list(self.fps_res.keys()))

    @Property('QVariantList')
    def modes_list(self):
        curr_fps = self.mode[2]
        return self.fps_res[curr_fps]

    @Property(int)
    def current_fps_index(self):
        curr_fps = self.mode[2]
        fps_list = sorted(list(self.fps_res.keys()))
        return fps_list.index(curr_fps)

    @Property(int)
    def current_fps(self):
        curr_fps = self.mode[2]
        return curr_fps

    @Property(int)
    def current_res_index(self):
        w,h,fps  = self.mode
        curr_res = str(w) + " x " + str(h)
        res_list = self.fps_res[fps]
        return res_list.index(curr_res)

    @Slot(str, str)
    def set_mode(self, fps, resolution):
        self.stop()
        res  = resolution.split('x')
        self.mode = (int(res[0]), int(res[1]), int(fps))
        self.__set_fps_modes()
        print("setting mode:", self.mode)
        if resolution not in self.fps_res[int(fps)]:
            print("setting mode:", self.modes[int(fps)][0])
            self.mode = self.modes[int(fps)][0]
        self.shared_array = self.create_shared_array(self.mode)
        self.pipe, self.child = Pipe()
        self.capturing.value = 1
        self.init_process(self.source, self.child, self.shared_array, 
                          self.shared_pos, self.mode, self.capturing)
        self.cam_thread = Thread(target=self.thread_loop, args=())
        self.save_state()
        self.cam_thread.start()

    @Slot(float)
    def set_gamma(self, value):
        self.gamma = value
        self.pipe.send("gamma")
        self.pipe.send(value)

    @Slot(float)
    def set_color(self, value):
        self.color = value
        self.pipe.send("color")
        self.pipe.send(bool(value))

    @Slot(float)
    def flip_image(self, value):
        self.flip = value
        self.pipe.send("flip")
        self.pipe.send(bool(value))

    @Slot()
    def reset(self):
        self.reset_model()

    def to_QPixmap(self, img):
        if img is None:
            return
        if len(img.shape) == 3:
            h,w,_ = img.shape
            rgbimg = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            #flipimg = cv2.flip(rgbimg,1)
            qimg = QImage(rgbimg.data, w, h, QImage.Format_RGB888)
            pixmap = QPixmap.fromImage(qimg)
            return pixmap

    def save_state(self):
        with open('config/'+self.name+'config.txt', 'w') as f:
            data =  str(self.mode[0]) + ':'
            data += str(self.mode[1]) + ':'
            data += str(self.mode[2]) #+ ':'
            #data += str(self.gamma)   + ':'
            #data += str(int(self.color)) 
            f.write(data)

    def load_state(self):
        if os.path.isfile('config/'+self.name+'config.txt'):
            with open('config/'+self.name+'config.txt', 'r') as f:
                d = f.readline().split(':')
                self.mode = (int(d[0]), int(d[1]), int(d[2]))

    


if __name__=="__main__":
    cam = Camera()
    cam.set_source(0)
    cam.start()
    # dev_list = uvc.device_list()
    # cap = uvc.Capture(dev_list[2]['uid'])
    # print(cap.avaible_modes)


