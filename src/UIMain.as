package
{
	import feathers.controls.Header;
	import feathers.controls.List;
	import feathers.controls.Label;
	import feathers.controls.Check;
	import feathers.controls.Screen;
	import feathers.controls.Callout;
	import feathers.data.ListCollection;
	import feathers.skins.StandardIcons;
	import feathers.themes.MetalWorksMobileTheme;
	import starling.core.Starling;
	import starling.display.MovieClip;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.filters.GLSLFilter;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.events.TextEvent;

	[Event(name="complete",type="starling.events.Event")]

	public class UIMain extends Screen
	{
		private var _header:Header;
		private var _theme:MetalWorksMobileTheme;

		private var vertexSource:TextField;
		private var fragmentSource:TextField;

		// Texture Atlas
        
        [Embed(source="assets/bird_atlas.xml", mimeType="application/octet-stream")]
        public static const AtlasXml:Class;
        
        [Embed(source="assets/bird_atlas.png")]
        public static const AtlasTexture:Class;

        private static var sTextureAtlas:TextureAtlas;

        private var mMovie:MovieClip;

        private var sourceCheck:Check;

        private var glslfilter:GLSLFilter = new GLSLFilter()

        public static function getTextureAtlas():TextureAtlas
        {
            if (sTextureAtlas == null)
            {
                var texture:Texture = Texture.fromBitmap(new AtlasTexture(), true, false, 1);
                var xml:XML = XML(new AtlasXml());
                sTextureAtlas = new TextureAtlas(texture, xml);
            }
            
            return sTextureAtlas;
        }

		public function UIMain()
		{
			super();
		}

		override protected function initialize():void
		{
			_theme = new MetalWorksMobileTheme(stage);
			_header = new Header();
			_header.title = "Starling Filter Playground";
			addChild(_header);

			sourceCheck = new Check();
			sourceCheck.label = "Display Source";
			sourceCheck.addEventListener(Event.TRIGGERED, sourceCheck_triggeredHandler);
			addChild(sourceCheck);

			var frames:Vector.<Texture> = getTextureAtlas().getTextures("flight");
            mMovie = new MovieClip(frames, 15);

			mMovie.x = (stage.stageWidth/2) - int(mMovie.width / 2);
			mMovie.y = (stage.stageHeight/2) - int(mMovie.height / 2);
			addChild(mMovie);

			mMovie.filter = glslfilter;

			Starling.juggler.add(mMovie);


			vertexSource = new TextField();
			Starling.current.nativeOverlay.addChild(vertexSource);
			
			vertexSource.visible = false;
			vertexSource.wordWrap = true; 
			vertexSource.multiline = true;
			vertexSource.type = TextFieldType.INPUT;
			vertexSource.addEventListener(Event.CHANGE, vertexSourceChanged);

			fragmentSource = new TextField();
			Starling.current.nativeOverlay.addChild(fragmentSource);
			fragmentSource.visible = false;
			fragmentSource.wordWrap = true; 
			fragmentSource.multiline = true;
			fragmentSource.type = TextFieldType.INPUT;
			fragmentSource.addEventListener(Event.CHANGE, fragmentSourceChanged);

			vertexSource.text = <![CDATA[
				varying vec2 TexCoords;
				
				void main()
				{
					TexCoords = gl_MultiTexCoord0.xy;
					gl_Position = gl_ModelViewProjectionMatrix * vec4(gl_Vertex.xy, 0, 0);
				}
			]]>;

			fragmentSource.text =  <![CDATA[
				varying vec2 TexCoords;
				
				uniform sampler2D baseTexture;
				uniform float time;
				
				vec2 wobbleTexCoords(in vec2 tc)
				{
					tc.x += (sin(tc.x*10.0 + time*10.0)*0.05);
					tc.y -= (cos(tc.y*10.0 + time*10.0)*0.05); 
					return tc;
				}
				
				void main()
				{
					vec2 tc = wobbleTexCoords(TexCoords);
					vec4 oc = texture2D(baseTexture, tc);
					gl_FragColor = oc;
				}		
			]]>;

			recompile();
        }

        private function recompile():void
        {
			glslfilter.update(vertexSource.text, fragmentSource.text);
        }

        private function sourceCheck_triggeredHandler(event:Event):void
		{
			vertexSource.visible = !vertexSource.visible;
			fragmentSource.visible = !fragmentSource.visible;
		}

		private function vertexSourceChanged(e:*):void
		{
			recompile();
		}

		private function fragmentSourceChanged(e:*):void
		{
			recompile();
		}
		
		override protected function draw():void
		{
			_header.width = actualWidth;
			_header.validate();

			sourceCheck.y = _header.height + 5
			sourceCheck.validate();

			vertexSource.y = sourceCheck.y + sourceCheck.height + 5;

			var h:int = stage.stageHeight - vertexSource.y;

			vertexSource.width = stage.stageWidth/2;
			vertexSource.height = h/2;

			fragmentSource.y = vertexSource.y + (h/2);
			fragmentSource.width = stage.stageWidth/2;
			fragmentSource.height = h/2;
		}
	}
}