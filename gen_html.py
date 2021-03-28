import numpy as np
import matplotlib.pyplot as plt 
import os
import glob


scenes = ['Home_004_1', 'Home_006_1', 'Home_010_1', 'Home_011_1', 'Home_016_1']


f = open('temp_github.html', 'w')

for scene in scenes:
	img_folder = '{}/selected_images'.format(scene)
	label_folder = '{}/vis_anno'.format(scene)
	img_files = [os.path.basename(x) for x in glob.glob('{}/*.jpg'.format(img_folder))]

	for img_file in img_files:
		img_id = img_file[:-4]
		f.write('<h5>{}/selected_images/{}_.jpg</h5>'.format(scene, img_id))
		f.write('<img src=\"https://github.com/GMU-vision-robotics/AVD_annotation/blob/main/{}/{}.jpg\" width=\"512px\" style=\"margin: 0px 10px\" />'.format(img_folder, img_id))
		f.write('<img src=\"https://github.com/GMU-vision-robotics/AVD_annotation/blob/main/{}/{}_anno.jpg\" width=\"512px\" style=\"margin: 0px 10px\" />'.format(label_folder, img_id))
		f.write('</br>')

f.close()