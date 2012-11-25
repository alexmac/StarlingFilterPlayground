StarlingFilterPlayground
========================

Interactively create Starling filters using GLSL (compiled with the GLSL2AGAL project).

Clicking the "Display Source" button will show the fragment and vertex shader source being applied to the starling MovieClip currently on the stage. Editing the GLSL source will cause the filter to update in real time (assuming the shader compiled successfully).

More work is needed on the UI to make it more user-friendly, maybe you want to contribute?

TODO
----

- Make the text areas look better + add scroll bars
- display shader compilation errors somewhere
- add the ability to export the AGAL asm in a form suitable for use in a starling app