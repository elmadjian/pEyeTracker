import cv2

aruco_dict = cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_4X4_50)
img = cv2.aruco.drawMarker(aruco_dict, 0, 800)
cv2.imshow('test', img)
cv2.waitKey(0)
cv2.imwrite('aruco.png', img)