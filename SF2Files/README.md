# SF2Files

This project holds all of the embedded SF2 files included with the released app and AUv3 component. Additional
files can be added by the user, but they start out with these.

Because of its size, the `FluidR3_GM.sf2` file is split up into 3 smaller chunks and then combined into the one file during a custom build 
process. A reference to the `FluidR3_GM.sf2` generated file is found in the (red) `DerivedSources` folder. The folder points to a spot in the 
`DerivedData` project folder for intermediate build products. The folder and the file links will always be red, but they do point to proper
locations. Furthermore, they resolve to valid locations in both "Build" and "Archive" actions.
