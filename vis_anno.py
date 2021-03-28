import numpy as np
import matplotlib.pyplot as plt 
import os
import glob
import scipy.io as sio
import cv2

colors =	[(0.6, 0.0, 0.0),
  			 (0.0, 0.0, 0.0),
			 (0.7, 0.0, 0.0), 
			 (0.0, 0.0, 0.5), 
			 (0.0, 0.0, 0.0), 
			 (0.2, 0.2, 0.2), 
			 (0.0, 0.0, 0.0), 
			 (0.2, 1.2, 0.2), 
			 (0.0, 0.0, 0.0), 
			 (0.0, 0.0, 0.0), 
			 (0.4, 0.4, 0.4), 
			 (0.0, 0.0, 1.0), 
			 (1.0, 0.7, 0.4), 
			 (0.0, 0.0, 0.0), 
			 (0.6, 1.0, 1.0), 
			 (0.0, 1.0, 1.0), 
			 (1.0, 0.6, 0.6), 
			 (1.0, 0.0, 0.0),
			 (0.0, 0.0, 0.0),
			 (0.7, 0.7, 0.0),
			 (1.0, 0.4, 0.7),
			 (0.0, 0.0, 0.0),
			 (0.0, 0.0, 0.0), 
			 (0.0, 0.0, 0.0), 
			 (0.6, 0.8, 1.0),
			 (1.0, 0.6, 0.7), 
			 (0.0, 0.0, 0.0),
			 (0.0, 0.0, 0.0),
			 (0.9, 0.0, 0.0),
			 (0.0, 0.0, 0.0),
			 (0.0, 0.0, 0.0),
			 (0.0, 0.0, 0.0),
			 (0.0, 0.6, 0.0),
			 (0.0, 0.9, 0.3), 
			 (0.0, 0.7, 0.0),
			 (0.5, 1.0, 0.5),
			 (0.0, 0.7, 0.7),
			 (0.0, 0.0, 7.0),
			 (1.0, 1.0, 0.7),
			 (0.9, 0.0, 0.9),
			 (0.0, 0.5, 1.0),
			 (1.0, 0.3, 0.3),
			 (0.7, 0.0, 0.0),
			 (0.9, 0.9, 0.0),
			 (1.0, 0.7, 1.0),
			 (0.9, 1.0, 1.0),
			 (0.5, 0.5, 0.0),
			 (0.5, 0.5, 0.5),
			 (0.0, 0.0, 0.4),
			 (0.7, 0.7, 0.7),
			 (0.3, 0.0, 0.0),
			 (0.0, 0.3, 0.0),
			 (0.0, 0.9, 0.3),
			 (0.0, 0.7, 0.0),
			 (0.5, 1.0, 0.5),
			 (0.0, 0.7, 0.7),
			 (0.0, 0.0, 7.0),
			 (1.0, 1.0, 0.7),
			 (0.9, 0.0, 0.9),
			 (0.0, 0.5, 1.0),
			 (1.0, 0.3, 0.3),
			 (0.7, 0.0, 0.0),
			 (0.9, 0.9, 0.0),
			 (1.0, 0.7, 1.0),
			 (0.9, 1.0, 1.0), 
			 (0.5, 0.5, 0.0), 
			 (0.5, 0.5, 0.5), 
			 (0.0, 0.0, 0.4), 
			 (0.7, 0.7, 0.7), 
			 (0.3, 0.0, 0.0), 
			 (0.0, 0.3, 0.0),
			 (0.0, 0.9, 0.3), 
			 (0.0, 0.7, 0.0), 
			 (0.5, 1.0, 0.5),
			 (0.0, 0.7, 0.7),  
			 (0.0, 0.0, 7.0),
			 (1.0, 1.0, 0.7), 
			 (0.9, 0.0, 0.9), 
			 (0.0, 0.5, 1.0), 
			 (1.0, 0.3, 0.3), 
			 (0.7, 0.0, 0.0), 
			 (0.9, 0.9, 0.0), 
			 (1.0, 0.7, 1.0), 
			 (0.9, 1.0, 1.0), 
			 (0.3, 0.0, 0.0), 
			 (0.0, 0.3, 0.0)]

def apply_color_map(image_array):
	color_array = np.zeros((image_array.shape[0], image_array.shape[1], 3), dtype=np.uint8)
	for label_id, color in enumerate(colors):
		a, b, c = color
		a, b, c = int(a*255), int(b*255), int(c*255)
		color_array[image_array == label_id] = (a,b,c)
	return color_array

scene = 'Home_016_1'

img_folder = '{}/selected_images'.format(scene)
label_folder = '{}/final_label'.format(scene)
img_files = [os.path.basename(x) for x in glob.glob('{}/*.jpg'.format(img_folder))]

if not os.path.exists('{}/vis_anno'.format(scene)): 
	os.mkdir('{}/vis_anno'.format(scene))

for img_file in img_files:
	print('img_file = {}'.format(img_file))
	img_id = img_file[:-4]
	img = cv2.imread('{}/{}.jpg'.format(img_folder, img_id), 1)[:, :, ::-1]
	anno = sio.loadmat('{}/{}.mat'.format(label_folder, img_id))['mapLabel']
	color_anno = apply_color_map(anno)

	cv2.imwrite('{}/vis_anno/{}_anno.jpg'.format(scene, img_id), color_anno[:,:,::-1])

	#assert 1==2