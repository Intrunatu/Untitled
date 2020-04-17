%% Republie tout les fichiers
filelist = dir("pbl*.m");
[~,repoPath] = system('git rev-parse --show-toplevel');
xslPath = fullfile(repoPath(1:end-1),'mxdom2simplehtml.xsl');
delete('html/*')


for i =1:length(filelist)
    publish(filelist(i).name, 'stylesheet', xslPath );
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





% <!------------------------------------------------------------------------------------->
% <script>
% function hide_all(){
%   list = document.getElementsByClassName('codeinput');
%   for (let i = 0; i < list.length; i++) {
%     list[i].style.display = 'none';
%   }
%   document.getElementById("toggleCode").onclick = show_all; 
% }
% 
% function show_all(){
%   list = document.getElementsByClassName('codeinput');
%   for (let i = 0; i < list.length; i++) {
%     list[i].style.display = 'block';
%   }
%   document.getElementById("toggleCode").onclick = hide_all; 
% }
% 
% window.onload = hide_all;  
% </script>
% 
% <p><a id="toggleCode" onclick = "hide_all()">Afficher / Masquer le code</a></p>
% <!------------------------------------------------------------------------------------->