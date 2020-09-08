# this script shows the predicted image along with ground truth

import numpy as np

files = open('input.txt', 'r').readlines()
f = open('index.html', 'w')
f.write('<table style="text-align:center;">')
f.write('<tr><td>Image #</td><td>Input</td><td>Annotated Image</td></tr>')
for curf in files:
	curf = curf[:-1];
	f.write('<tr>')
	s = '<td>' + curf + '</td>'
	f.write(s)
	s = '<td><img src="../selected_images/' + curf + '" height="400" width="400"/></td>'
	f.write(s)
	s = '<td><img src="./' +  curf  + '" height="400" width="400"/></td>'
	f.write(s)
	f.write('</tr>')
f.write('</table>')
	
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

