FLEX=/path/to/flexsdk

all:
	"$(FLEX)/bin/mxmlc" \
		-debug=false -strict \
		-compiler.omit-trace-statements=false \
		-static-link-runtime-shared-libraries \
		-library-path+=starling.swc \
		-library-path+=glsl2agal.swc \
		-swf-version=18 \
		src/StarlingFilterPlayground.as -o demo/StarlingFilterPlayground.swf
