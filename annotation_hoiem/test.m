
while (1)
    f = figure;
    [a, b, key] = ginput(1);
    disp(['key is ' num2str(key)]);
    key = get(f,'CurrentCharacter');
    disp(['keyboard is ' num2str(key)]);
    
    
end