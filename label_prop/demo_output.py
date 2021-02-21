# this script shows the predicted image along with ground truth

import numpy as np

scene_names = ['Home_001_1', 'Home_005_1', 'Home_002_1', 'Home_003_1', \
	'Home_004_1', 'Home_006_1', 'Home_007_1', 'Home_010_1', \
	'Home_011_1', 'Home_016_1']
idx_start = 9
idx_end = 9

for i in range(idx_start, idx_end+1):
	current_scene = scene_names[i]
	files = open('{}/input.txt'.format(current_scene), 'r').readlines()
	f = open('{}/index.html'.format(current_scene), 'w')
	f.write('<table style="text-align:center;">')
	f.write('<tr><td></td><td>Image with Bounding Box #</td><td>Label (cropped)</td><td>Depth</td></tr>')
	for curFile in files:
		suffix = curFile[13:-1]		
		curFile = curFile[0:13]
		f.write('<tr>')
		s = '<td>' + curFile + suffix[0:-3] + '</td>'
		f.write(s)
		s = '<td><img src="jpg_rgb/' +  curFile   + '01.jpg" height="200" width="400"/></td>'
		f.write(s)
		s = '<td><img src="label_pred_geom_only_85_with_smoothness_0.5/figure_cropped/' + curFile + suffix +  '" height="200" width="400"/></td>'
		f.write(s)
		s = '<td><img src="high_res_depth/' +  curFile   + '03.png" height="200" width="400"/></td>'
		f.write(s)
		#s = '<td><img src="label_pred_geom_only_51_with_smoothness_0.5/figure/' + curFile + suffix +  '" height="200" width="400"/></td>'
		#f.write(s)
		f.write('</tr>' + '\n')

	f.write('</table>')
	f.close()
	

'''
io.output(paths.concat(opt.results_dir,opt.netG_name .. '_' .. opt.phase, 'index.html'))

io.write('<table style="text-align:center;">')

io.write('<tr><td>Image #</td><td>Input</td><td>Output</td><td>Ground Truth</td></tr>')
for i=1, #filepaths do
    io.write('<tr>')
    io.write('<td>' .. filepaths[i] .. '</td>')
    io.write('<td><img src="./images/input/' .. filepaths[i] .. '"/></td>')
    io.write('<td><img src="./images/output/' .. filepaths[i] .. '"/></td>')
    io.write('<td><img src="./images/target/' .. filepaths[i] .. '"/></td>')
    io.write('</tr>')
end

io.write('</table>')
'''

