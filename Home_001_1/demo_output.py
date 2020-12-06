# this script shows the predicted image along with ground truth

import numpy as np

files = open('input.txt', 'r').readlines()
f = open('index.html', 'w')
f.write('<table style="text-align:center;">')
f.write('<tr><td></td><td>Image with Bounding Box #</td><td>Label (cropped)</td><td>Depth</td></tr>')
for curFile in files:
	suffix = curFile[13:-1]		
	curFile = curFile[0:13]
	f.write('<tr>')
	s = '<td>' + curFile + suffix[0:-3] + '</td>'
	f.write(s)
	s = '<td><img src="bboxes/' +  curFile   + '01.jpg" height="200" width="400"/></td>'
	f.write(s)
	s = '<td><img src="label_pred_geom_only_51_with_smoothness_0.5/figure_cropped/' + curFile + suffix +  '" height="200" width="400"/></td>'
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

