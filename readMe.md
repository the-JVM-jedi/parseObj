# Wavefront OBJ File Parser for MATLAB

This MATLAB function parses Wavefront OBJ files, extracting mesh vertices, texture coordinates, normal coordinates, face definitions, and material properties. It also supports material assignments from associated MTL files.

## Features
- Reads vertices (`v`), texture coordinates (`vt`), and normals (`vn`) from OBJ files.
- Parses face definitions (`f`) with support for vertex, texture, and normal indices.
- Extracts material properties from associated MTL files.
- Maps materials to faces using `faceMaterialName`.

## Usage

### Syntax
```matlab
obj = readObj(fname);

### Input

-   `fname`: Full path to the  `.obj`  file.
    

### Output

The function returns a struct  `obj`  with the following fields:

-   `obj.v`: Mesh vertices (Nx3 matrix).
    
-   `obj.vt`: Texture coordinates (Mx2 or Mx3 matrix).
    
-   `obj.vn`: Normal coordinates (Px3 matrix).
    
-   `obj.f`: Face definitions (struct with fields  `v`,  `vt`,  `vn`).
    
-   `obj.faceMaterialName`: Material names for each face (cell array).
    
-   `obj.materials`: Material properties (struct array).
    

### Example

matlab

Copy

% Load an OBJ file
obj = readObj('example.obj');

% Access vertices
vertices = obj.v;

% Access faces
faces = obj.f.v;

% Access material for the first face
materialName = obj.faceMaterialName{1};
material = obj.materials(strcmp({obj.materials.name}, materialName));

## Requirements

-   MATLAB R2016b or later.
    

## Installation

1.  Download the  `parseObj.m`  file.
    
2.  Add the file to your MATLAB path or the working directory.
    

## File Structure

-   `readObj.m`: Main function to parse OBJ files.
    
## License

This project is licensed under the MIT License. See the  [LICENSE](https://license/)  file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Acknowledgments

-   Original code by Bernard Abayowa, Tec^Edge.
    
-   Modified by Benjamin Kipkoech.
