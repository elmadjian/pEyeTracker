import numpy as np

'''
Python code based on the one provided by Yiu Yuk Hoi, Seyed-Ahmad Ahmadi, and Moustafa Aboulatta
(https://github.com/pydsgz/DeepVOG)
'''

class Ellipse():

    def __init__(self, data):
        '''
        creates an Ellipse object and fits an ellipse to data input

        data should be a list of the form [[x1,...,xn],[y1,...,yn]]
        '''
        a1, a2 = self.__fit(data)
        self.coef = np.vstack([a1, a2])
        c, w, h, phi = self.__create_parameters()
        self.center = c
        self.width  = w
        self.height = h
        self.radian = phi


    def __fit(self, data):
        x,y = np.asarray(data, dtype=float)
        D1 = np.mat(np.vstack([x**2, x*y, y**2])).T
        D2 = np.mat(np.vstack([x, y, np.ones(len(x))])).T
        S1 = D1.T*D1
        S2 = D1.T*D2
        S3 = D2.T*D2
        C1 = np.mat([[0.,0.,2.],[0.,-1.,0.],[2.,0.,0.]])
        M  = C1.I * (S1 - S2 * S3.I * S2.T)
        _, eig_vec = np.linalg.eig(M)
        cond = 4*np.multiply(eig_vec[0,:], eig_vec[2,:])-np.power(eig_vec[1,:],2)
        a1 = eig_vec[:,np.nonzero(cond.A > 0)[1]]
        a2 = -S3.I * S2.T * a1
        return a1, a2

    def __create_parameters(self):
        a = self.coef[0,0]
        b = self.coef[1,0]/2.
        c = self.coef[2,0]
        d = self.coef[3,0]/2.
        f = self.coef[4,0]/2.
        g = self.coef[5,0]
        x0 = (c*d-b*f)/(b**2.-a*c)
        y0 = (a*f-b*d)/(b**2.-a*c)
        numerator = 2*(a*f*f+c*d*d+g*b*b-2*b*d*f-a*c*g)
        denominator1 = (b*b-a*c)*( (c-a)*np.sqrt(1+4*b*b/((a-c)*(a-c)))-(c+a))
        denominator2 = (b*b-a*c)*( (a-c)*np.sqrt(1+4*b*b/((a-c)*(a-c)))-(c+a))
        width  = np.sqrt(numerator/denominator1)
        height = np.sqrt(numerator/denominator2)
        phi = 0.5*np.arctan((2*b)/(a-c))
        return [x0,y0], width, height, phi

    def get_parameters(self):
        return self.center, [self.width, self.height], self.radian