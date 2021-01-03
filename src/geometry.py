import numpy as np 

"""
Python code based on the one provided by Yiu Yuk Hoi, Seyed-Ahmad Ahmadi, and Moustafa Aboulatta
(https://github.com/pydsgz/DeepVOG)

"""

class Geometry():

    def __init__(self, focal_length, eye_z):
        self.focal_length = focal_length
        self.eye_z = eye_z
        
    
    def convert_ellipse_to_general(self, xc, yc, w, h, radian):
        A = (w**2)*(np.sin(radian)**2) + (h**2) * (np.cos(radian)**2)
        B = 2 * (h**2 - w**2) * np.sin(radian) * np.cos(radian)
        C = (w**2)*(np.cos(radian)**2) + (h**2)*(np.sin(radian)**2)
        D = -2*A*xc - B*yc
        E = -B*xc - 2*C*yc
        F = A*(xc**2) + B*xc*yc + C*(yc**2) - (w**2)*(h**2)
        return (A,B,C,D,E,F)


    def unproject_gaze(self, vertex, ell_co, radius=None):
        a,b,c,_,f,g,h,u,v,w = self.__gen_cone_co(vertex, ell_co)
        #Discriminating cubic equation coefficients
        lamb_co1 = 1
        lamb_co2 = -(a+b+c)
        lamb_co3 = (b*c + c*a + a*b - f**2 - g**2 - h**2)
        lamb_co4 = -(a*b*c + 2*f*g*h - a*f**2 - b*g**2 - c*h**2)
        #Discriminating cubic solution
        lamb1, lamb2, lamb3 = np.roots([lamb_co1,lamb_co2,lamb_co3,lamb_co4])
        l,m,n = self.__gen_lmn(lamb1, lamb2, lamb3)
        norm_cano_pos = np.array([l[0],m[0],n[0],1]).reshape(4,1)
        norm_cano_neg = np.array([l[1],m[1],n[1],1]).reshape(4,1)
        
        #Calculating T1
        l1, m1, n1 = self.__get_rotmat_co(lamb1, a,b,g,f,h)
        l2, m2, n2 = self.__get_rotmat_co(lamb2, a,b,g,f,h)
        l3, m3, n3 = self.__get_rotmat_co(lamb3, a,b,g,f,h)
        T1 = np.array([[l1,l2,l3,0],
                       [m1,m2,m3,0],
                       [n1,n2,n3,0],
                       [0, 0, 0, 1]])
        li, mi, ni = T1[0,0:3], T1[1,0:3], T1[2,0:3]
        norm_cam_pos = np.dot(T1, norm_cano_pos)
        norm_cam_neg = np.dot(T1, norm_cano_neg)

        #Calculating T2
        T2 = np.eye(4)
        T2[0:3,3] = -(u*li+v*mi+w*ni)/np.array([lamb1, lamb2, lamb3])

        #Calculating T3
        T3_pos = self.__calc_T3(l[0], m[0], n[0])
        T3_neg = self.__calc_T3(l[1], m[1], n[1])

        A_pos,B_pos,C_pos,D_pos = self.__calc_ABCD(T3_pos,lamb1,lamb2,lamb3)
        A_neg,B_neg,C_neg,D_neg = self.__calc_ABCD(T3_neg,lamb1,lamb2,lamb3)

        T0 = np.eye(4)
        T0[2,3] = -vertex[2]
        center_pos = self.__calc_XYZ_frame(A_pos,B_pos,C_pos,D_pos,radius)
        center_neg = self.__calc_XYZ_frame(A_neg,B_neg,C_neg,D_neg,radius)
        true_center_pos, true_center_neg = self.__get_true_centers(T0, T1, T2, 
            [T3_pos, T3_neg], [center_pos, center_neg])
        #fix for direction inconsistency
        if h < 0:
            norm_cam_pos, norm_cam_neg, true_center_pos, true_center_neg =\
                norm_cam_neg, norm_cam_pos, true_center_neg, true_center_pos
        return norm_cam_pos[0:3], norm_cam_neg[0:3],\
            true_center_pos[0:3], true_center_neg[0:3]


    def reproject(self, vec3d):
        return (self.focal_length * vec3d[0:2]) / vec3d[2]

    def reverse_reproject(self, vec2d):
        vec2d_scaled = (vec2d*self.eye_z)/self.focal_length
        return vec2d_scaled


    def line_sphere_intersect(self, c,r,o,l):
        '''
        c -> eyeball center
        r -> eyeball radius
        o -> line origin
        l -> direction unit vector
        '''
        l = l/np.linalg.norm(l)
        delta = np.square(np.dot(l.T, (o-c))) - np.dot((o-c).T,(o-c))\
            + np.square(r)
        if delta < 0:
            raise Exception
        else:
            d1 = -np.dot(l.T,(o-c)) + np.sqrt(delta)
            d2 = -np.dot(l.T,(o-c)) - np.sqrt(delta)
        return [d1,d2]


    def fit_ransac(self, a, n, max_iters=2000, samples=20, min_distance=2000):
        num_lines = a.shape[0]
        best_model = None
        best_distance = min_distance
        for _ in range(max_iters):
            samp_idx = np.random.choice(num_lines, size=samples, replace=False)
            a_sampled = a[samp_idx, :]
            n_sampled = n[samp_idx, :]
            model_sampled = self.intersect(a_sampled, n_sampled)
            sampled_distance = self.__calc_distance(a,n,model_sampled)
            if sampled_distance > min_distance:
                continue
            else:
                if sampled_distance < best_distance:
                    best_model = model_sampled
                    best_distance = sampled_distance
        return best_model


    def intersect(self, a, n):
        '''
        a -> vector coordinates
        n -> vector orientation
        ''' 
        n = n/np.linalg.norm(n, axis=1, keepdims=True)
        num_lines = a.shape[0]
        dim = a.shape[1]
        I = np.eye(dim)
        R_sum, q_sum = 0, 0
        for i in range(num_lines):
            R = I - np.matmul(n[i].reshape(dim,1), n[i].reshape(1,dim))
            q = np.matmul(R, a[i].reshape(dim, 1))
            q_sum = q_sum + q
            R_sum = R_sum + R
        p = np.matmul(np.linalg.inv(R_sum), q_sum)
        return p


    def convert_vec2angle31(self, n1):
        """
        Inputs:
            n1 = numpy array with shape (3,1)
        """
        assert n1.shape == (3,1)
        n1 = n1/np.linalg.norm(n1)
        n1_x, n1_y, n1_z_abs = n1[0,0], n1[1,0], np.abs(n1[2,0])
        # x-angulation            
        if n1_x > 0:
            x_angle = np.arctan(n1_z_abs/n1_x)
        else:
            x_angle = np.pi - np.arctan(n1_z_abs/np.abs(n1_x))
        # y-angulation
        if n1_y > 0:
            y_angle = np.arctan(n1_z_abs/n1_y)
        else:
            y_angle = np.pi - np.arctan(n1_z_abs/np.abs(n1_y))
        x_angle = np.rad2deg(x_angle)
        y_angle = np.rad2deg(y_angle)
        return [x_angle, y_angle]
        

    def __calc_distance(self, a, n, p):
        num_lines = a.shape[0]
        dim = a.shape[1]
        I = np.eye(dim)
        D_sum = 0
        for i in range(num_lines):
            D_1 = (a[i].reshape(dim,1) - p.reshape(dim,1)).T
            D_2 = I - np.matmul(n[i].reshape(dim,1), n[i].reshape(1,dim))
            D_3 = D_1.T 
            D   = np.matmul(np.matmul(D_1, D_2), D_3)
            D_sum += D
        D_sum /= num_lines
        return D_sum


    def __get_true_centers(self, T0, T1, T2, T3, centers):
        T3_pos, T3_neg = T3[0], T3[1]
        center_pos, center_neg = centers[0], centers[1]
        true_center_pos = np.matmul(T0, np.matmul(T1, np.matmul(
            T2, np.matmul(T3_pos, center_pos))))
        if true_center_pos[2] < 0:
            center_pos[0:3] = -center_pos[0:3]
            true_center_pos = np.matmul(T0, np.matmul(T1, np.matmul(
                T2, np.matmul(T3_pos, center_pos))))
        true_center_neg = np.matmul(T0, np.matmul(T1, np.matmul(
            T2, np.matmul(T3_neg, center_neg))))
        if true_center_neg[2] < 0:
            center_neg[0:3] = -center_neg[0:3]
            true_center_neg = np.matmul(T0, np.matmul(T1, np.matmul(
                T2, np.matmul(T3_neg, center_neg))))
        return true_center_pos, true_center_neg

    def __calc_XYZ_frame(self, A,B,C,D,r):
        Z = (A*r)/np.sqrt((B**2)+(C**2)-A*D)
        X = (-B/A)*Z
        Y = (-C/A)*Z
        center = np.array([X,Y,Z,1]).reshape(4,1)
        return center

    
    def __calc_ABCD(self, T3, lamb1, lamb2, lamb3):
        li, mi, ni = T3[0:3,0], T3[0:3,1], T3[0:3,2]
        lamb_array = np.array([lamb1, lamb2, lamb3])
        A = np.dot(np.power(li,2), lamb_array)
        B = np.sum(li*ni*lamb_array)
        C = np.sum(mi*ni*lamb_array)
        D = np.dot(np.power(ni,2), lamb_array)
        return A,B,C,D


    def __calc_T3(self, l, m ,n ):
        lm_sqrt = np.sqrt((l**2)+(m**2))
        T3 = np.array([-m/lm_sqrt, -(l*n)/lm_sqrt, l, 0,
                        l/lm_sqrt, -(m*n)/lm_sqrt, m, 0,
                        0, lm_sqrt, n, 0,
                        0, 0, 0, 1]).reshape(4,4)
        return T3

    
    def __get_rotmat_co(self, lamb, a, b, g, f, h):
        t1 = (b-lamb)*g - f*h
        t2 = (a - lamb)*f - g*h
        t3 = -(a-lamb)*(t1/t2)/g - (h/g)
        m = 1/(np.sqrt(1 + (t1/t2)**2 + t3**2))
        l = (t1/t2)*m
        n = t3*m
        return l, m, n


    def __gen_cone_co(self, vertex, ell_co):
        A,B,C,D,E,F = ell_co
        alpha, beta, gamma = vertex
        a_prime, h_prime, b_prime = A, B/2, C
        g_prime, f_prime, d_prime = D/2, E/2, F
        gamma_square = gamma**2
        a = gamma_square * a_prime
        b = gamma_square * b_prime
        c = a_prime * alpha**2 + 2 * h_prime * alpha * beta\
            + b_prime * beta**2 + 2 * g_prime * alpha + 2\
            * f_prime * beta + d_prime
        d = gamma_square * d_prime
        f = -gamma * (b_prime * beta + h_prime * alpha +f_prime)
        g = -gamma * (h_prime * beta + a_prime * alpha + g_prime)
        h = gamma_square * h_prime
        u = gamma_square * g_prime
        v = gamma_square * f_prime
        w = -gamma * (f_prime * beta + g_prime * alpha + d_prime)
        return (a,b,c,d,f,g,h,u,v,w)


    def __gen_lmn(self, lamb1, lamb2, lamb3):
        if lamb1 > 0 and lamb2 > 0 and lamb3 < 0:
            if lamb2 > lamb1:
                m_pos = np.sqrt((lamb2-lamb1)/(lamb2-lamb3))
                m_neg = -m_pos
                n = np.sqrt((lamb1-lamb3)/(lamb2/lamb3))
                return [0,0], [m_pos,m_neg], [n,n]
            if lamb1 > lamb2:
                l_pos = np.sqrt((lamb1-lamb2)/(lamb1-lamb3))
                l_neg = -l_pos
                n = np.sqrt((lamb2-lamb3)/(lamb1-lamb3))
                return [l_pos,l_neg], [0,0], [n,n]
            elif lamb1 == lamb2:
                return [0,0], [0,0], [1,1]
        return None, None, None

    
