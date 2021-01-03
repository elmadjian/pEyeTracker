import subprocess
import re
import uvc
from PySide2.QtCore import QObject, Signal, Slot, Property

class VideoIO_UVC(QObject):

    '''
    This class manages camera I/O.
    It is also the main I/O interface used by the UI, which
    means that it allows:
    - to switch one camera spot to ther other in the UI
    - start / stop a stream through the UI
    - toggle the 3D model 
    - load videos instead of opening cam streams
    '''

    def __init__(self):
        QObject.__init__(self)
        self.cameras = {}
        self.read_inputs()
        self.scene = None
        self.leye  = None
        self.reye  = None

    
    def read_inputs(self):
        self.cameras = {}
        dev_list = uvc.device_list()
        for i in range(len(dev_list)):
            name = dev_list[i]['name']
            self.cameras[i] = name


    @Property('QVariantList')
    def camera_list(self):
        self.read_inputs()
        cameras = ["{}: {}".format(i,self.cameras[i]) for i in self.cameras.keys()]
        opts = ['No feed', 'File...']
        return opts + cameras


    def get_camera_name(self, source):
        return self.cameras[source]

    
    def set_active_cameras(self, scene, leye, reye):
        self.scene = scene
        self.leye  = leye
        self.reye  = reye

    @Slot()
    def toggle_3D(self):
        self.leye.toggle_3D()
        self.reye.toggle_3D()

    @Slot(bool)
    def stop_scene_cam(self, video_file):
        self.scene.stop(video_file)

    @Slot(bool)
    def stop_leye_cam(self, video_file):
        self.leye.stop(video_file)

    @Slot(bool)
    def stop_reye_cam(self, video_file):
        self.reye.stop(video_file)

    @Slot(bool)
    def stop_cameras(self, video_file):
        print(">>> Closing video feed...")
        self.scene.stop(video_file)
        self.leye.stop(video_file)
        self.reye.stop(video_file)
        print(">>> Finished!")

    @Slot(bool, bool, bool)
    def play_cams(self, scene_t, leye_t, reye_t):
        self.scene.play(scene_t)
        self.leye.play(leye_t)
        self.reye.play(reye_t)

    @Slot(bool, bool, bool)
    def pause_cams(self, scene_t, leye_t, reye_t):
        self.scene.pause(scene_t)
        self.leye.pause(leye_t)
        self.reye.pause(reye_t)

    @Slot(str, str)
    def load_video(self, cam_id, filename):
        if cam_id.startswith("Scene"):
            self.scene.stop(video_file=True)
            self.scene.set_video_file(filename)
        elif cam_id.startswith("Left"):
            self.leye.stop(video_file=True)
            self.leye.set_video_file(filename)
        else:
            self.reye.stop(video_file=True)
            self.reye.set_video_file(filename)


    @Slot(str, str)
    def set_camera_source(self, cam_id, cam_name):
        source = int(cam_name.split(':')[0])
        if cam_id.startswith("Scene"):
            self._change_cameras(self.scene, self.leye, self.reye, source)
        elif cam_id.startswith("Left"):
            self._change_cameras(self.leye, self.scene, self.reye, source)
        else:
            self._change_cameras(self.reye, self.scene, self.leye, source)

    @Slot()
    def save_session_config(self):
        print('>>> Saving session configuration...')
        
        

    def _change_cameras(self, cam1, cam2, cam3, source):
        '''
        cam1: camera to be changed
        cam2 and cam3: non-selected cameras that might also have to change
        value: camera source 
        '''
        cam1.stop()
        prev_source = cam1.get_source()
        if source == cam2.get_source():
            cam2.stop()
            cam2.set_source(prev_source)
        elif source == cam3.get_source():
            cam3.stop()
            cam3.set_source(prev_source)
        cam1.set_source(source)



if __name__=="__main__":
    v = VideoIO_UVC()
    print(v.get_cameras())