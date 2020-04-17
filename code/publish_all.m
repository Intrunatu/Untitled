%% Republie tout les fichiers
filelist = dir("pbl*.m");
for i =1:length(filelist)
    publish(filelist(i).name);
end


%% Creation de l'index
filelist = dir("pbl*.m");
fileID = fopen('index.m','w');
fprintf(fileID,"%%%% Index\r\n");
for i =1:length(filelist)
    [~, fname] = fileparts(filelist(i).name);
    fprintf(fileID, '%% * <%s.html %s>\r\n', fname, fname);
end
fclose(fileID);
publish('index');
delete('index.m');
zip('html','html/*');