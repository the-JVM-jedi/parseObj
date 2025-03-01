function obj = readObj(fname)
%
% obj = readObj(fname)
%
% This function parses wavefront object data from a .obj file.
% It reads the mesh vertices, texture coordinates, normal coordinates,
% face definitions (grouped by number of vertices), and material assignments.
%
% INPUT: 
%   fname - Full path to the wavefront object file (.obj).
%
% OUTPUT: 
%   obj.v - Mesh vertices (Nx3 matrix, where N is the number of vertices).
%   obj.vt - Texture coordinates (Mx2 or Mx3 matrix, where M is the number of texture coordinates).
%   obj.vn - Normal coordinates (Px3 matrix, where P is the number of normals).
%   obj.f - Face definitions. A struct with fields:
%       - f.v: Vertex indices for faces (Qx3 matrix for triangular faces).
%       - f.vt: Texture coordinate indices for faces (Qx3 matrix).
%       - f.vn: Normal indices for faces (Qx3 matrix).
%   obj.faceMaterialName - A cell array of size equal to the number of faces (Qx1).
%       Each cell contains the name of the material used for that face.
%   obj.materials - A struct array containing parsed material properties from the .mtl file.
%       Each struct has fields: 'name', 'Kd', 'Ka', 'Ks', 'Ns', 'd'.
%
% Bernard Abayowa, Tec^Edge
% 11/8/07
% Modified By: Benjamin Kipkoech
% 3/1/25

% Initialize variables to store vertices, texture coordinates, normals, and faces.
v = []; % Mesh vertices
vt = []; % Texture coordinates
vn = []; % Normal coordinates
f.v = []; % Vertex indices for faces
f.vt = []; % Texture coordinate indices for faces
f.vn = []; % Normal indices for faces
faceMaterialName = {}; % Material names for each face
currentName = ''; % Current material name being used for faces

% Initialize a struct to store material properties.
materials = struct('name', {}, 'Kd', {}, 'Ka', {}, 'Ks', {}, 'Ns', {}, 'd', {});

% Open the .obj file for reading.
fid = fopen(fname);
if fid == -1
    error('Could not open the file: %s. Please check the file path and permissions.', fname);
end

% Parse the .obj file line by line.
while 1    
    tline = fgetl(fid); % Read the next line from the file.
    if ~ischar(tline), break, end % Exit the loop if end of file is reached.
    
    ln = sscanf(tline, '%s', 1); % Extract the first token (line type).
    
    % Process the line based on its type.
    switch ln
        case 'v' % Mesh vertices (e.g., "v 1.0 2.0 3.0")
            v = [v; sscanf(tline(2:end), '%f')']; % Append vertex coordinates.
            
        case 'vt' % Texture coordinates (e.g., "vt 0.5 0.5")
            vt = [vt; sscanf(tline(3:end), '%f')']; % Append texture coordinates.
            
        case 'vn' % Normal coordinates (e.g., "vn 0.0 0.0 1.0")
            vn = [vn; sscanf(tline(3:end), '%f')']; % Append normal coordinates.
            
        case 'f' % Face definition (e.g., "f 1/2/3 4/5/6 7/8/9")
            fv = []; fvt = []; fvn = []; % Initialize face vertex, texture, and normal indices.
            str = textscan(tline(2:end), '%s'); str = str{1}; % Split the face definition into tokens.
            
            nf = length(findstr(str{1}, '/')); % Count the number of slashes to determine format.
            
            % Extract vertex indices.
            [tok, str] = strtok(str, '//'); % Tokenize based on slashes.
            for k = 1:length(tok)
                fv = [fv, str2num(tok{k})]; % Append vertex indices.
            end
            
            % Extract texture coordinates if present.
            if (nf > 0) 
                [tok, str] = strtok(str, '//');
                for k = 1:length(tok)
                    fvt = [fvt, str2num(tok{k})]; % Append texture indices.
                end
            end
            
            % Extract normal coordinates if present.
            if (nf > 1) 
                [tok, str] = strtok(str, '//');
                for k = 1:length(tok)
                    fvn = [fvn, str2num(tok{k})]; % Append normal indices.
                end
            end
            
            % Append face data to the respective arrays.
            f.v = [f.v; fv]; 
            f.vt = [f.vt; fvt]; 
            f.vn = [f.vn; fvn]; 
            faceMaterialName = [faceMaterialName; {currentName}]; % Assign the current material name to this face.
            
        case 'usemtl' % Material assignment for subsequent faces (e.g., "usemtl Material1")
            currentName = strtrim(tline(8:end)); % Update the current material name.
            
        case 'mtllib' % MTL file reference (e.g., "mtllib example.mtl")
            mtlFile = strtrim(tline(7:end)); % Extract the MTL file name.
            [filepath, ~, ~] = fileparts(fname); % Get the directory of the .obj file.
            mtlFilePath = fullfile(filepath, mtlFile); % Construct the full path to the MTL file.
            
            % Check if the MTL file exists and parse it.
            if exist(mtlFilePath, 'file')
                materials = parseMTLFile(mtlFilePath); % Parse the MTL file.
            else
                warning('MTL file not found: %s', mtlFilePath); % Issue a warning if the MTL file is missing.
            end
    end
end
fclose(fid); % Close the .obj file.

% Store the parsed data in the output struct.
obj.v = v; 
obj.vt = vt; 
obj.vn = vn; 
obj.f = f; 
obj.faceMaterialName = faceMaterialName; 
obj.materials = materials;
end

% MTL file parser
function materials = parseMTLFile(mtlFilePath)
% Function to parse an MTL file and extract material properties into a struct.
%
% Inputs:
%   mtlFilePath - Full path to the .mtl file.
%
% Output:
%   materials - A struct array containing parsed material properties.
%       Each struct has fields: 'name', 'Kd', 'Ka', 'Ks', 'Ns', 'd'.

    % Open the MTL file for reading.
    fid = fopen(mtlFilePath, 'r');
    if fid == -1
        error('Could not open the file: %s', mtlFilePath);
    end
    
    % Initialize variables.
    currentMaterial = []; % Temporary storage for the current material being parsed.
    materials = struct('name', {}, 'Kd', {}, 'Ka', {}, 'Ks', {}, 'Ns', {}, 'd', {}); % Output struct.
    
    % Read the MTL file line by line.
    while ~feof(fid)
        line = strtrim(fgetl(fid)); % Read the next line and remove leading/trailing whitespace.
        
        % Skip empty lines or comments.
        if isempty(line) || line(1) == '#'
            continue; 
        end
        
        % Split the line into tokens.
        tokens = strsplit(line);
        
        % Process the line based on its type.
        if strcmp(tokens{1}, 'newmtl') % New material definition (e.g., "newmtl Material1")
            if ~isempty(currentMaterial) % Save the previous material if it exists.
                materials(end+1) = currentMaterial;
            end
            % Initialize a new material struct.
            currentMaterial = struct('name', tokens{2}, 'Kd', [0, 0, 0], 'Ka', [0, 0, 0], ...
                                     'Ks', [0, 0, 0], 'Ns', 0, 'd', 1);
        elseif strcmp(tokens{1}, 'Kd') % Diffuse color (e.g., "Kd 0.8 0.8 0.8")
            currentMaterial.Kd = str2double(tokens(2:4)); % Parse RGB values.
        elseif strcmp(tokens{1}, 'Ka') % Ambient color (e.g., "Ka 0.2 0.2 0.2")
            currentMaterial.Ka = str2double(tokens(2:4)); % Parse RGB values.
        elseif strcmp(tokens{1}, 'Ks') % Specular color (e.g., "Ks 1.0 1.0 1.0")
            currentMaterial.Ks = str2double(tokens(2:4)); % Parse RGB values.
        elseif strcmp(tokens{1}, 'Ns') % Shininess (e.g., "Ns 200")
            currentMaterial.Ns = str2double(tokens{2}); % Parse the value.
        elseif strcmp(tokens{1}, 'd') % Transparency (e.g., "d 1.0")
            currentMaterial.d = str2double(tokens{2}); % Parse the value.
        end
    end
    
    % Add the last material if it exists.
    if ~isempty(currentMaterial)
        materials(end+1) = currentMaterial;
    end
    
    % Close the MTL file.
    fclose(fid);
end