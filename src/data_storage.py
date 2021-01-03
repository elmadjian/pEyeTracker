import numpy as np 
import os
import time

class Storer():
    '''
    Important:
    ---------
    -> 2D: x, y, time, 0, 0, 0, 0
    -> 3D: x_p, y_p, z_p, x_n, y_n, z_n, time
    '''

    def __init__(self, target_list, hmd=False):
        self.target_list = target_list
        self.targets, self.l_centers, self.r_centers = None, None, None
        self.depth_t, self.dist = None, None
        self.t_imgs, self.l_imgs, self.r_imgs = None, None, None
        self.l_sess, self.r_sess, self.l_raw, self.r_raw = [],[],[],[]
        self.hmd = hmd
        self.scene, self.leye, self.reye = None, None, None
        self.uid = time.ctime().replace(':', '_')
   
    def initialize_storage(self, ntargets):
        self.targets = {i:np.empty((0,2), dtype='float32') for i in range(ntargets)}
        if self.hmd:
            self.targets = {i:np.empty((0,3), dtype='float32') for i in range(ntargets)}
        self.l_centers = {i:np.empty((0,3), dtype='float32') for i in range(ntargets)}
        self.r_centers = {i:np.empty((0,3), dtype='float32') for i in range(ntargets)}
        self.t_imgs = {i:[] for i in range(ntargets)}
        self.l_imgs = {i:[] for i in range(ntargets)}
        self.r_imgs = {i:[] for i in range(ntargets)}
    
    def initialize_depth_storage(self, ntargets):
        self.depth_t = {i:np.empty((0,1), dtype='float32') for i in range(ntargets)}
        self.dist = {i:np.empty((0,1), dtype='float32') for i in range(ntargets)}

    def set_sources(self, scene, leye, reye):
        self.scene = scene
        self.leye  = leye
        self.reye  = reye

    def set_target_list(self, target_list):
        self.target_list = target_list

    def collect_depth_data(self, idx, dist, mode3D, minfreq):
        le = self.leye.get_processed_data()
        re = self.reye.get_processed_data()
        if self.__check_data_n_timestamp(None, le, re, mode3D, 1/minfreq):
            self.__add_depth_data(dist, idx)

    def collect_data(self, idx, mode3D, minfreq):
        sc, sc_img = None, None
        if self.scene is not None:
            sc = self.scene.get_processed_data() 
            sc_img = self.scene.get_np_image()
        le = self.leye.get_processed_data()
        re = self.reye.get_processed_data()
        le_img = self.leye.get_np_image()
        re_img = self.reye.get_np_image()
        if self.__check_data_n_timestamp(sc, le, re, mode3D, 1/minfreq):
            self.__add_data(sc, le, re, idx)
            self.__add_imgs(sc_img, le_img, re_img, idx)
    
    def __add_data(self, sc, le, re, idx):
        scd = np.array(self.target_list[idx])
        if sc is not None and self.scene.is_cam_active():
            scd = np.array([sc[0], sc[1]], dtype='float32')
        self.targets[idx] = np.vstack((self.targets[idx], scd))
        if self.leye.is_cam_active():
            led = np.array([le[0],le[1],le[2]])#,le[3],le[4],le[5]])
            self.l_centers[idx] = np.vstack((self.l_centers[idx], led))
        if self.reye.is_cam_active():
            red = np.array([re[0],re[1],re[2]])#,le[3],le[4],le[5]])
            self.r_centers[idx] = np.vstack((self.r_centers[idx], red))

    def __add_imgs(self, sc, le, re, idx):
        if sc is not None and self.scene.is_cam_active():
            self.t_imgs[idx].append(sc)
        if self.leye.is_cam_active():
            self.l_imgs[idx].append(le)
        if self.reye.is_cam_active():
            self.r_imgs[idx].append(re)

    def __add_depth_data(self, dist, idx):
        scd = np.array(self.target_list[idx][2])
        self.depth_t[idx] = np.vstack((self.depth_t[idx], scd))
        if self.leye.is_cam_active() and self.reye.is_cam_active():
            d = np.array([dist])
            self.dist[idx] = np.vstack((self.dist[idx], d))
   
    def __check_data_n_timestamp(self, sc, le, re, mode3D, thresh):
        if le is None and self.leye.is_cam_active():
            return False
        if re is None and self.reye.is_cam_active():
            return False
        if sc is None:
            return True
        sc_t, le_t, re_t = sc[2], le[2], re[2]
        if mode3D:
            #le_t, re_t = le[6], re[6]
            le_t, re_t = le[3], re[3]
        if sc.any(): #check for zeros since Windows compat update
            if le.any() and re.any():
                if abs(sc_t - le_t) < thresh:
                    if abs(sc_t - re_t) < thresh:
                        return True
            if le.any() and not re.any():
                if abs(sc_t - le_t) < thresh:
                    return True
            if not le.any() and re.any():
                if abs(sc_t - re_t) < thresh:
                    return True
        return False

    def __dict_to_list(self, dic):
        new_list = np.empty((0,dic[0].shape[1]), dtype='float32')
        for t in dic.keys():
            new_list = np.vstack((new_list, dic[t]))
        return new_list

    def get_targets_list(self):
        return self.__dict_to_list(self.targets)

    def get_depth_t_list(self):
        return self.__dict_to_list(self.depth_t)

    def get_dist_list(self):
        return self.__dict_to_list(self.dist)

    def get_l_centers_list(self, mode_3D):
        data = self.__dict_to_list(self.l_centers)
        if not mode_3D:
            data = np.array(data[:,:2])
        return data

    def get_r_centers_list(self, mode_3D):
        data = self.__dict_to_list(self.r_centers)
        if not mode_3D:
            data = np.array(data[:,:2])
        return data

    def get_random_test_samples(self, nsamples, ntargets):
        s_target = {i:np.empty((0,3), dtype='float32') for i in range(ntargets)}
        s_left   = {i:np.empty((0,3), dtype='float32') for i in range(ntargets)}
        s_right  = {i:np.empty((0,3), dtype='float32') for i in range(ntargets)}
        distribution = [i for i in range(nsamples)]
        candidates = np.random.choice(distribution, 5, False)
        for t in self.targets.keys():
            s_target[t] = np.take(self.targets[t], candidates, axis=0)
            if len(self.l_centers[t]) > 0:
                s_left[t] = np.take(self.l_centers[t], candidates, axis=0)
                self.l_centers[t] = np.delete(self.l_centers[t], candidates, axis=0)
            if len(self.r_centers[t]) > 0:
                s_right[t] = np.take(self.r_centers[t], candidates, axis=0)
                self.r_centers[t] = np.delete(self.r_centers[t], candidates, axis=0)
            self.targets[t] = np.delete(self.targets[t], candidates, axis=0)
        return s_target, s_left, s_right            


    def append_session_data(self, l_gaze, r_gaze, l_raw, r_raw):
        self.l_sess.append(l_gaze)
        self.r_sess.append(r_gaze)
        self.l_raw.append(l_raw)
        self.r_raw.append(r_raw)

    
    def store_calibration(self):
        print(">>> Storing calibration data, please wait...")
        path = self.__check_or_create_path('calibration')
        for k in self.targets.keys():
            perc = int(k/len(self.targets.keys()) * 100)
            print(">>> {}%...".format(perc), end="\r", flush=True)
            c1, c2 = self.target_list[k]
            prefix = str(c1) + "_" + str(c2) + "_"
            # np.savez_compressed(path+prefix+ "img_scene", self.t_imgs[k])
            # np.savez_compressed(path+prefix+ "img_leye", self.l_imgs[k])
            # np.savez_compressed(path+prefix+ "img_reye", self.r_imgs[k])
            np.savez_compressed(path+prefix+ "tgt", self.targets[k])
            if len(self.l_centers[k]) > 0:
                np.savez_compressed(path+prefix+"leye", self.l_centers[k])
            if len(self.r_centers[k]) > 0:
                np.savez_compressed(path+prefix+"reye", self.r_centers[k])
        print(">>> Calibration data saved.")

    def store_session(self):
        if len(self.l_sess) > 0:        
            print(">>> Saving session...")
            path = self.__check_or_create_path('session')
            np.savez_compressed(path+'_left_gaze', self.l_sess)
            np.savez_compressed(path+'_right_gaze', self.r_sess)
            np.savez_compressed(path+'_left_eye', self.l_raw)
            np.savez_compressed(path+'_right_eye', self.r_raw)
            print('>>> Session saved.')


    def __check_or_create_path(self, spec):
        '''
        spec -> either 'calibration' or 'session'
        '''
        path = os.getcwd() + "/data/"+self.uid+"/"+spec+"/"
        os.makedirs(path)
        return path