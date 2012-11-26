// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters
{
    import flash.display3D.Program3D;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.utils.getTimer;
    
    import starling.core.Starling;
    import starling.textures.Texture;
    import starling.filters.FragmentFilter;

    import com.adobe.glsl2agal.CModule;
    import com.adobe.glsl2agal.compileShader;

    public class GLSLFilter extends FragmentFilter
    {
        private static var glsl2agalInitialized:Boolean = false;
        private var mShaderProgram:Program3D;
        private var vs:String, fs:String
        private var timeIdx:int = -1

        public function GLSLFilter()
        {
            super();

            if(!glsl2agalInitialized) {
                CModule.startAsync()
                glsl2agalInitialized = true
            }
        }
        
        public override function dispose():void
        {
            if (mShaderProgram) mShaderProgram.dispose();
            super.dispose();
        }
        
        protected override function createPrograms():void
        {
            if(vs && fs) {
                try {
                    var compiledVertexShader:Object = JSON.parse(com.adobe.glsl2agal.compileShader(vs, 0, true));
                    trace(JSON.stringify(compiledVertexShader))

                    mMVPConstantID = compiledVertexShader.varnames["gl_ModelViewProjectionMatrix"].slice(2)
                    mVertexAttributeID = compiledVertexShader.varnames["gl_Vertex"].slice(2)
                    mTextureAttributeID = compiledVertexShader.varnames["gl_MultiTexCoord0"].slice(2)

                    var compiledFragmentShader:Object = JSON.parse(com.adobe.glsl2agal.compileShader(fs, 1, true));
                    trace(JSON.stringify(compiledFragmentShader))

                    mBaseTextureID = compiledFragmentShader.varnames["baseTexture"].slice(2)

                    mShaderProgram = assembleAgal(compiledFragmentShader.agalasm, compiledVertexShader.agalasm);

                    try {
                        timeIdx = compiledFragmentShader.varnames["time"].slice(2)
                    } catch(e:*) {
                        timeIdx = -1;
                    }
                    
                    var c:String
                    var constval:Array
                    
                    for(c in compiledFragmentShader.consts) {
                        constval = compiledFragmentShader.consts[c];
                        Starling.context.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, int(c.slice(2)), Vector.<Number>([constval[0], constval[1], constval[2], constval[3]]) )
                    }
                    
                    for(c in compiledVertexShader.consts) {
                        constval = compiledVertexShader.consts[c];
                        Starling.context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, int(c.slice(2)), Vector.<Number>([constval[0], constval[1], constval[2], constval[3]]) )
                    }

                    return;
                } catch(e:Error) {
                    trace("Failed to compile shader...");
                    trace(e);
                }

            }

            // Reset to the Identity filter
            trace("Switching to the Identity Shader...")
            mMVPConstantID = 0
            mVertexAttributeID = 0
            mTextureAttributeID = 1
            mBaseTextureID = 0
            timeIdx = -1;

            mShaderProgram = assembleAgal();
        }

        public function update(_vs:String, _fs:String):void
        {
            trace("update...");
            this.vs = _vs;
            this.fs = _fs;
            createPrograms();
        }

        private var tmpVec:Vector.<Number> = new Vector.<Number>(4);
        
        protected override function activate(pass:int, context:Context3D, texture:Texture):void
        {
            // already set by super class:
            // 
            // vertex constants 0-3: mvpMatrix (3D)
            // vertex attribute 0:   vertex position (FLOAT_2)
            // vertex attribute 1:   texture coordinates (FLOAT_2)
            // texture 0:            input texture
            if(timeIdx != -1) {
                tmpVec[0] = getTimer() / 10000;
                Starling.context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, timeIdx , tmpVec);
            }
            context.setProgram(mShaderProgram);
        }
    }
}