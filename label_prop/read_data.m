
% Reads the result.dat file
function [X] = read_data(infile)
    %h = fopen('data.dat', 'rb');
    h = fopen([infile '.dat'], 'rb');
	row = fread(h, 1, 'integer*4');
	col = fread(h, 1, 'integer*4');
    ch = fread(h, 1, 'integer*4');
	X = fread(h, row * col * ch, 'double');
    X = reshape(X, [row col ch]);
	fclose(h);
end