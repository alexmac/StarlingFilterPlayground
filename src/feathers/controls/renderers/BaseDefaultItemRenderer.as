/*
 Copyright (c) 2012 Josh Tynjala

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
package feathers.controls.renderers
{
	import feathers.controls.Button;
	import feathers.controls.text.BitmapFontTextRenderer;
	import feathers.core.FeathersControl;
	import feathers.core.IFeathersControl;
	import feathers.core.ITextRenderer;
	import feathers.core.PropertyProxy;

	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;

	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.events.TouchEvent;
	import starling.textures.Texture;

	/**
	 * An abstract class for item renderer implementations.
	 */
	public class BaseDefaultItemRenderer extends Button
	{
		/**
		 * The default value added to the <code>nameList</code> of the accessory
		 * label.
		 */
		public static const DEFAULT_CHILD_NAME_ACCESSORY_LABEL:String = "feathers-item-renderer-accessory-label";

		/**
		 * @private
		 */
		private static const HELPER_POINT:Point = new Point();

		/**
		 * @private
		 */
		protected static var DOWN_STATE_DELAY_MS:int = 250;

		/**
		 * @private
		 */
		protected static function defaultImageFactory(texture:Texture):Image
		{
			return new Image(texture);
		}

		/**
		 * Constructor.
		 */
		public function BaseDefaultItemRenderer()
		{
			super();
			this.isQuickHitAreaEnabled = false;
		}

		/**
		 * The value added to the <code>nameList</code> of the accessory label.
		 */
		protected var accessoryLabelName:String = DEFAULT_CHILD_NAME_ACCESSORY_LABEL;

		/**
		 * @private
		 */
		protected var iconImage:Image;

		/**
		 * @private
		 */
		protected var accessoryImage:Image;

		/**
		 * @private
		 */
		protected var accessoryLabel:ITextRenderer;

		/**
		 * @private
		 */
		protected var accessory:DisplayObject;

		/**
		 * @private
		 */
		protected var _data:Object;

		/**
		 * The item displayed by this renderer.
		 */
		public function get data():Object
		{
			return this._data;
		}

		/**
		 * @private
		 */
		public function set data(value:Object):void
		{
			if(this._data == value)
			{
				return;
			}
			this._data = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _owner:IFeathersControl;

		/**
		 * @private
		 */
		protected var _delayedCurrentState:String;

		/**
		 * @private
		 */
		protected var _stateDelayTimer:Timer;

		/**
		 * @private
		 */
		protected var _useStateDelayTimer:Boolean = true;

		/**
		 * If true, the down state (and subsequent state changes) will be
		 * delayed to make scrolling look nicer.
		 */
		public function get useStateDelayTimer():Boolean
		{
			return this._useStateDelayTimer;
		}

		/**
		 * @private
		 */
		public function set useStateDelayTimer(value:Boolean):void
		{
			this._useStateDelayTimer = value;
		}

		/**
		 * @private
		 */
		protected var _itemHasLabel:Boolean = true;

		/**
		 * If true, the label will come from the renderer's item using the
		 * appropriate field or function for the label. If false, the label may
		 * be set externally.
		 */
		public function get itemHasLabel():Boolean
		{
			return this._itemHasLabel;
		}

		/**
		 * @private
		 */
		public function set itemHasLabel(value:Boolean):void
		{
			this._itemHasLabel = value;
		}

		/**
		 * @private
		 */
		protected var _itemHasIcon:Boolean = true;

		/**
		 * If true, the icon will come from the renderer's item using the
		 * appropriate field or function for the icon. If false, the icon may
		 * be skinned for each state externally.
		 */
		public function get itemHasIcon():Boolean
		{
			return this._itemHasIcon;
		}

		/**
		 * @private
		 */
		public function set itemHasIcon(value:Boolean):void
		{
			this._itemHasIcon = value;
		}

		/**
		 * @private
		 */
		override protected function set currentState(value:String):void
		{
			if(!this._isToggle)
			{
				value = STATE_UP;
			}
			if(this._useStateDelayTimer)
			{
				if(this._stateDelayTimer && this._stateDelayTimer.running)
				{
					this._delayedCurrentState = value;
					return;
				}

				if(value == Button.STATE_DOWN)
				{
					if(this._currentState == value)
					{
						return;
					}
					this._delayedCurrentState = value;
					if(this._stateDelayTimer)
					{
						this._stateDelayTimer.reset();
					}
					else
					{
						this._stateDelayTimer = new Timer(DOWN_STATE_DELAY_MS, 1);
						this._stateDelayTimer.addEventListener(TimerEvent.TIMER_COMPLETE, stateDelayTimer_timerCompleteHandler);
					}
					this._stateDelayTimer.start();
					return;
				}
			}
			super.currentState = value;
		}

		/**
		 * @private
		 */
		protected var _labelField:String = "label";

		/**
		 * The field in the item that contains the label text to be displayed by
		 * the renderer. If the item does not have this field, and a
		 * <code>labelFunction</code> is not defined, then the renderer will
		 * default to calling <code>toString()</code> on the item. To omit the
		 * label completely, either provide a custom item renderer without a
		 * label or define a <code>labelFunction</code> that returns an empty
		 * string.
		 *
		 * <p>All of the label fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>labelFunction</code></li>
		 *     <li><code>labelField</code></li>
		 * </ol>
		 *
		 * @see #labelFunction
		 */
		public function get labelField():String
		{
			return this._labelField;
		}

		/**
		 * @private
		 */
		public function set labelField(value:String):void
		{
			if(this._labelField == value)
			{
				return;
			}
			this._labelField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _labelFunction:Function;

		/**
		 * A function used to generate label text for a specific item. If this
		 * function is not null, then the <code>labelField</code> will be
		 * ignored.
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function( item:Object ):String</pre>
		 *
		 * <p>All of the label fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>labelFunction</code></li>
		 *     <li><code>labelField</code></li>
		 * </ol>
		 *
		 * @see #labelField
		 */
		public function get labelFunction():Function
		{
			return this._labelFunction;
		}

		/**
		 * @private
		 */
		public function set labelFunction(value:Function):void
		{
			if(this._labelFunction == value)
			{
				return;
			}
			this._labelFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _iconField:String = "icon";

		/**
		 * The field in the item that contains a display object to be displayed
		 * as an icon or other graphic next to the label in the renderer.
		 *
		 * <p>All of the icon fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>iconTextureFunction</code></li>
		 *     <li><code>iconTextureField</code></li>
		 *     <li><code>iconFunction</code></li>
		 *     <li><code>iconField</code></li>
		 * </ol>
		 *
		 * @see #iconFunction
		 * @see #iconTextureField
		 * @see #iconTextureFunction
		 */
		public function get iconField():String
		{
			return this._iconField;
		}

		/**
		 * @private
		 */
		public function set iconField(value:String):void
		{
			if(this._iconField == value)
			{
				return;
			}
			this._iconField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _iconFunction:Function;

		/**
		 * A function used to generate an icon for a specific item.
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function( item:Object ):DisplayObject</pre>
		 *
		 * <p>All of the icon fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>iconTextureFunction</code></li>
		 *     <li><code>iconTextureField</code></li>
		 *     <li><code>iconFunction</code></li>
		 *     <li><code>iconField</code></li>
		 * </ol>
		 *
		 * @see #iconField
		 * @see #iconTextureField
		 * @see #iconTextureFunction
		 */
		public function get iconFunction():Function
		{
			return this._iconFunction;
		}

		/**
		 * @private
		 */
		public function set iconFunction(value:Function):void
		{
			if(this._iconFunction == value)
			{
				return;
			}
			this._iconFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _iconTextureField:String = "iconTexture";

		/**
		 * The field in the item that contains a texture to be used for the
		 * renderer's icon. The renderer will automatically manage and reuse an
		 * internal <code>Image</code>. This <code>Image</code> may be
		 * customized by changing the <code>iconImageFactory</code>.
		 *
		 * <p>All of the icon fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>iconTextureFunction</code></li>
		 *     <li><code>iconTextureField</code></li>
		 *     <li><code>iconFunction</code></li>
		 *     <li><code>iconField</code></li>
		 * </ol>
		 *
		 * @see #iconImageFactory
		 * @see #iconTextureFunction
		 * @see #iconField
		 * @see #iconFunction
		 * @see starling.textures.Texture
		 */
		public function get iconTextureField():String
		{
			return this._iconTextureField;
		}

		/**
		 * @private
		 */
		public function set iconTextureField(value:String):void
		{
			if(this._iconTextureField == value)
			{
				return;
			}
			this._iconTextureField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _iconTextureFunction:Function;

		/**
		 * A function used to generate a texture to be used for the renderer's
		 * icon. The renderer will automatically manage and reuse an internal
		 * <code>Image</code> and swap the texture when the renderer's data
		 * changes. This <code>Image</code> may be customized by changing the
		 * <code>iconImageFactory</code>.
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function( item:Object ):Texture</pre>
		 *
		 * <p>All of the icon fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>iconTextureFunction</code></li>
		 *     <li><code>iconTextureField</code></li>
		 *     <li><code>iconFunction</code></li>
		 *     <li><code>iconField</code></li>
		 * </ol>
		 *
		 * @see #iconImageFactory
		 * @see #iconTextureField
		 * @see #iconField
		 * @see #iconFunction
		 * @see starling.textures.Texture
		 */
		public function get iconTextureFunction():Function
		{
			return this._iconTextureFunction;
		}

		/**
		 * @private
		 */
		public function set iconTextureFunction(value:Function):void
		{
			if(this._iconTextureFunction == value)
			{
				return;
			}
			this._iconTextureFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _accessoryField:String = "accessory";

		/**
		 * The field in the item that contains a display object to be positioned
		 * in the accessory position of the renderer. If you wish to display an
		 * <code>Image</code> in the accessory position, it's better for
		 * performance to use <code>accessoryTextureField</code> instead.
		 *
		 * <p>All of the accessory fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>accessoryTextureFunction</code></li>
		 *     <li><code>accessoryTextureField</code></li>
		 *     <li><code>accessoryLabelFunction</code></li>
		 *     <li><code>accessoryLabelField</code></li>
		 *     <li><code>accessoryFunction</code></li>
		 *     <li><code>accessoryField</code></li>
		 * </ol>
		 *
		 * @see #accessoryTextureField
		 * @see #accessoryFunction
		 * @see #accessoryTextureFunction
		 * @see #accessoryLabelField
		 * @see #accessoryLabelFunction
		 */
		public function get accessoryField():String
		{
			return this._accessoryField;
		}

		/**
		 * @private
		 */
		public function set accessoryField(value:String):void
		{
			if(this._accessoryField == value)
			{
				return;
			}
			this._accessoryField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _accessoryFunction:Function;

		/**
		 * A function that returns a display object to be positioned in the
		 * accessory position of the renderer. If you wish to display an
		 * <code>Image</code> in the accessory position, it's better for
		 * performance to use <code>accessoryTextureFunction</code> instead.
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function( item:Object ):DisplayObject</pre>
		 *
		 * <p>All of the accessory fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>accessoryTextureFunction</code></li>
		 *     <li><code>accessoryTextureField</code></li>
		 *     <li><code>accessoryLabelFunction</code></li>
		 *     <li><code>accessoryLabelField</code></li>
		 *     <li><code>accessoryFunction</code></li>
		 *     <li><code>accessoryField</code></li>
		 * </ol>
		 *
		 * @see #accessoryField
		 * @see #accessoryTextureField
		 * @see #accessoryTextureFunction
		 * @see #accessoryLabelField
		 * @see #accessoryLabelFunction
		 */
		public function get accessoryFunction():Function
		{
			return this._accessoryFunction;
		}

		/**
		 * @private
		 */
		public function set accessoryFunction(value:Function):void
		{
			if(this._accessoryFunction == value)
			{
				return;
			}
			this._accessoryFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _accessoryTextureField:String = "accessoryTexture";

		/**
		 * The field in the item that contains a texture to be displayed in a
		 * renderer-managed <code>Image</code> in the accessory position of the
		 * renderer. The renderer will automatically reuse an internal
		 * <code>Image</code> and swap the texture when the renderer's data
		 * changes. This <code>Image</code> may be customized by
		 * changing the <code>accessoryImageFactory</code>.
		 *
		 * <p>Using an accessory texture will result in better performance than
		 * passing in an <code>Image</code> through a <code>accessoryField</code>
		 * or <code>accessoryFunction</code> because the renderer can avoid
		 * costly display list manipulation.</p>
		 *
		 * <p>All of the accessory fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>accessoryTextureFunction</code></li>
		 *     <li><code>accessoryTextureField</code></li>
		 *     <li><code>accessoryLabelFunction</code></li>
		 *     <li><code>accessoryLabelField</code></li>
		 *     <li><code>accessoryFunction</code></li>
		 *     <li><code>accessoryField</code></li>
		 * </ol>
		 *
		 * @see #accessoryImageFactory
		 * @see #accessoryTextureFunction
		 * @see #accessoryField
		 * @see #accessoryFunction
		 * @see #accessoryLabelField
		 * @see #accessoryLabelFunction
		 */
		public function get accessoryTextureField():String
		{
			return this._accessoryTextureField;
		}

		/**
		 * @private
		 */
		public function set accessoryTextureField(value:String):void
		{
			if(this._accessoryTextureField == value)
			{
				return;
			}
			this._accessoryTextureField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _accessoryTextureFunction:Function;

		/**
		 * A function that returns a texture to be displayed in a
		 * renderer-managed <code>Image</code> in the accessory position of the
		 * renderer. The renderer will automatically reuse an internal
		 * <code>Image</code> and swap the texture when the renderer's data
		 * changes. This <code>Image</code> may be customized by
		 * changing the <code>accessoryImageFactory</code>.
		 *
		 * <p>Using an accessory texture will result in better performance than
		 * passing in an <code>Image</code> through a <code>accessoryField</code>
		 * or <code>accessoryFunction</code> because the renderer can avoid
		 * costly display list manipulation.</p>
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function( item:Object ):Texture</pre>
		 *
		 * <p>All of the accessory fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>accessoryTextureFunction</code></li>
		 *     <li><code>accessoryTextureField</code></li>
		 *     <li><code>accessoryLabelFunction</code></li>
		 *     <li><code>accessoryLabelField</code></li>
		 *     <li><code>accessoryFunction</code></li>
		 *     <li><code>accessoryField</code></li>
		 * </ol>
		 *
		 * @see #accessoryImageFactory
		 * @see #accessoryTextureField
		 * @see #accessoryField
		 * @see #accessoryFunction
		 * @see #accessoryLabelField
		 * @see #accessoryLabelFunction
		 */
		public function get accessoryTextureFunction():Function
		{
			return this._accessoryTextureFunction;
		}

		/**
		 * @private
		 */
		public function set accessoryTextureFunction(value:Function):void
		{
			if(this.accessoryTextureFunction == value)
			{
				return;
			}
			this._accessoryTextureFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _accessoryLabelField:String = "accessoryLabel";

		/**
		 * The field in the item that contains a string to be displayed in a
		 * renderer-managed <code>Label</code> in the accessory position of the
		 * renderer. The renderer will automatically reuse an internal
		 * <code>Label</code> and swap the text when the data changes. This
		 * <code>Label</code> may be skinned by changing the
		 * <code>accessoryLabelFactory</code>.
		 *
		 * <p>Using an accessory label will result in better performance than
		 * passing in a <code>Label</code> through a <code>accessoryField</code>
		 * or <code>accessoryFunction</code> because the renderer can avoid
		 * costly display list manipulation.</p>
		 *
		 * <p>All of the accessory fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>accessoryTextureFunction</code></li>
		 *     <li><code>accessoryTextureField</code></li>
		 *     <li><code>accessoryLabelFunction</code></li>
		 *     <li><code>accessoryLabelField</code></li>
		 *     <li><code>accessoryFunction</code></li>
		 *     <li><code>accessoryField</code></li>
		 * </ol>
		 *
		 * @see #accessoryLabelFactory
		 * @see #accessoryLabelFunction
		 * @see #accessoryField
		 * @see #accessoryFunction
		 * @see #accessoryTextureField
		 * @see #accessoryTextureFunction
		 */
		public function get accessoryLabelField():String
		{
			return this._accessoryLabelField;
		}

		/**
		 * @private
		 */
		public function set accessoryLabelField(value:String):void
		{
			if(this._accessoryLabelField == value)
			{
				return;
			}
			this._accessoryLabelField = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _accessoryLabelFunction:Function;

		/**
		 * A function that returns a string to be displayed in a
		 * renderer-managed <code>Label</code> in the accessory position of the
		 * renderer. The renderer will automatically reuse an internal
		 * <code>Label</code> and swap the text when the data changes. This
		 * <code>Label</code> may be skinned by changing the
		 * <code>accessoryLabelFactory</code>.
		 *
		 * <p>Using an accessory label will result in better performance than
		 * passing in a <code>Label</code> through a <code>accessoryField</code>
		 * or <code>accessoryFunction</code> because the renderer can avoid
		 * costly display list manipulation.</p>
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function( item:Object ):String</pre>
		 *
		 * <p>All of the accessory fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>accessoryTextureFunction</code></li>
		 *     <li><code>accessoryTextureField</code></li>
		 *     <li><code>accessoryLabelFunction</code></li>
		 *     <li><code>accessoryLabelField</code></li>
		 *     <li><code>accessoryFunction</code></li>
		 *     <li><code>accessoryField</code></li>
		 * </ol>
		 *
		 * @see #accessoryLabelFactory
		 * @see #accessoryLabelField
		 * @see #accessoryField
		 * @see #accessoryFunction
		 * @see #accessoryTextureField
		 * @see #accessoryTextureFunction
		 */
		public function get accessoryLabelFunction():Function
		{
			return this._accessoryLabelFunction;
		}

		/**
		 * @private
		 */
		public function set accessoryLabelFunction(value:Function):void
		{
			if(this._accessoryLabelFunction == value)
			{
				return;
			}
			this._accessoryLabelFunction = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _iconImageFactory:Function = defaultImageFactory;

		/**
		 * A function that generates an <code>Image</code> that uses the result
		 * of <code>iconTextureField</code> or <code>iconTextureFunction</code>.
		 * Useful for transforming the <code>Image</code> in some way. For
		 * example, you might want to scale it for current DPI.
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function():Image</pre>
		 *
		 * @see #iconTextureField;
		 * @see #iconTextureFunction;
		 */
		public function get iconImageFactory():Function
		{
			return this._iconImageFactory;
		}

		/**
		 * @private
		 */
		public function set iconImageFactory(value:Function):void
		{
			if(this._iconImageFactory == value)
			{
				return;
			}
			this._iconImageFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _accessoryImageFactory:Function = defaultImageFactory;

		/**
		 * A function that generates an <code>Image</code> that uses the result
		 * of <code>accessoryTextureField</code> or <code>accessoryTextureFunction</code>.
		 * Useful for transforming the <code>Image</code> in some way. For
		 * example, you might want to scale it for current DPI.
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function():Image</pre>
		 *
		 * @see #accessoryTextureField;
		 * @see #accessoryTextureFunction;
		 */
		public function get accessoryImageFactory():Function
		{
			return this._accessoryImageFactory;
		}

		/**
		 * @private
		 */
		public function set accessoryImageFactory(value:Function):void
		{
			if(this._accessoryImageFactory == value)
			{
				return;
			}
			this._accessoryImageFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _accessoryLabelFactory:Function;

		/**
		 * A function that generates <code>ITextRenderer</code> that uses the result
		 * of <code>accessoryLabelField</code> or <code>accessoryLabelFunction</code>.
		 * Useful for skinning the <code>ITextRenderer</code>.
		 *
		 * <p>The function is expected to have the following signature:</p>
		 * <pre>function():ITextRenderer</pre>
		 *
		 * @see #accessoryLabelField;
		 * @see #accessoryLabelFunction;
		 */
		public function get accessoryLabelFactory():Function
		{
			return this._accessoryLabelFactory;
		}

		/**
		 * @private
		 */
		public function set accessoryLabelFactory(value:Function):void
		{
			if(this._accessoryLabelFactory == value)
			{
				return;
			}
			this._accessoryLabelFactory = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _accessoryLabelProperties:PropertyProxy;

		/**
		 * A set of key/value pairs to be passed down to a label accessory.
		 *
		 * <p>If the subcomponent has its own subcomponents, their properties
		 * can be set too, using attribute <code>&#64;</code> notation. For example,
		 * to set the skin on the thumb of a <code>SimpleScrollBar</code>
		 * which is in a <code>Scroller</code> which is in a <code>List</code>,
		 * you can use the following syntax:</p>
		 * <pre>list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
		 *
		 * @see #accessoryLabelField
		 * @see #accessoryLabelFunction
		 */
		public function get accessoryLabelProperties():Object
		{
			if(!this._accessoryLabelProperties)
			{
				this._accessoryLabelProperties = new PropertyProxy(accessoryLabelProperties_onChange);
			}
			return this._accessoryLabelProperties;
		}

		/**
		 * @private
		 */
		public function set accessoryLabelProperties(value:Object):void
		{
			if(this._accessoryLabelProperties == value)
			{
				return;
			}
			if(!value)
			{
				value = new PropertyProxy();
			}
			if(!(value is PropertyProxy))
			{
				const newValue:PropertyProxy = new PropertyProxy();
				for(var propertyName:String in value)
				{
					newValue[propertyName] = value[propertyName];
				}
				value = newValue;
			}
			if(this._accessoryLabelProperties)
			{
				this._accessoryLabelProperties.removeOnChangeCallback(accessoryLabelProperties_onChange);
			}
			this._accessoryLabelProperties = PropertyProxy(value);
			if(this._accessoryLabelProperties)
			{
				this._accessoryLabelProperties.addOnChangeCallback(accessoryLabelProperties_onChange);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		override public function dispose():void
		{
			if(this.iconImage)
			{
				this.iconImage.removeFromParent(true);
			}

			//the accessory may have come from outside of this class. it's up
			//to that code to dispose of the accessory. in fact, if we disposed
			//of it here, we might screw something up!
			if(this.accessory)
			{
				this.accessory.removeFromParent();
			}

			//however, we need to dispose these, if they exist, since we made
			//them here.
			if(this.accessoryImage)
			{
				this.accessoryImage.dispose();
				this.accessoryImage = null;
			}
			if(this.accessoryLabel)
			{
				DisplayObject(this.accessoryLabel).dispose();
				this.accessoryLabel = null;
			}
			super.dispose();
		}

		/**
		 * Using <code>labelField</code> and <code>labelFunction</code>,
		 * generates a label from the item.
		 *
		 * <p>All of the label fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>labelFunction</code></li>
		 *     <li><code>labelField</code></li>
		 * </ol>
		 */
		public function itemToLabel(item:Object):String
		{
			if(this._labelFunction != null)
			{
				return this._labelFunction(item) as String;
			}
			else if(this._labelField != null && item && item.hasOwnProperty(this._labelField))
			{
				return item[this._labelField] as String;
			}
			else if(item is Object)
			{
				return item.toString();
			}
			return "";
		}

		/**
		 * Uses the icon fields and functions to generate an icon for a specific
		 * item.
		 *
		 * <p>All of the icon fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>iconTextureFunction</code></li>
		 *     <li><code>iconTextureField</code></li>
		 *     <li><code>iconFunction</code></li>
		 *     <li><code>iconField</code></li>
		 * </ol>
		 */
		protected function itemToIcon(item:Object):DisplayObject
		{
			if(this._iconTextureFunction != null)
			{
				var texture:Texture = this._iconTextureFunction(item) as Texture;
				this.refreshIconTexture(texture);
				return this.iconImage;
			}
			else if(this._iconTextureField != null && item && item.hasOwnProperty(this._iconTextureField))
			{
				texture = item[this._iconTextureField] as Texture;
				this.refreshIconTexture(texture);
				return this.iconImage;
			}
			else if(this._iconFunction != null)
			{
				return this._iconFunction(item) as DisplayObject;
			}
			else if(this._iconField != null && item && item.hasOwnProperty(this._iconField))
			{
				return item[this._iconField] as DisplayObject;
			}

			return null;
		}

		/**
		 * Uses the accessory fields and functions to generate an accessory for
		 * a specific item.
		 *
		 * <p>All of the accessory fields and functions, ordered by priority:</p>
		 * <ol>
		 *     <li><code>accessoryTextureFunction</code></li>
		 *     <li><code>accessoryTextureField</code></li>
		 *     <li><code>accessoryLabelFunction</code></li>
		 *     <li><code>accessoryLabelField</code></li>
		 *     <li><code>accessoryFunction</code></li>
		 *     <li><code>accessoryField</code></li>
		 * </ol>
		 */
		protected function itemToAccessory(item:Object):DisplayObject
		{
			if(this._accessoryTextureFunction != null)
			{
				var texture:Texture = this._accessoryTextureFunction(item) as Texture;
				this.refreshAccessoryTexture(texture);
				return this.accessoryImage;
			}
			else if(this._accessoryTextureField != null && item && item.hasOwnProperty(this._accessoryTextureField))
			{
				texture = item[this._accessoryTextureField] as Texture;
				this.refreshAccessoryTexture(texture);
				return this.accessoryImage;
			}
			else if(this._accessoryLabelFunction != null)
			{
				var label:String = this._accessoryLabelFunction(item) as String;
				this.refreshAccessoryLabel(label);
				return DisplayObject(this.accessoryLabel);
			}
			else if(this._accessoryLabelField != null && item && item.hasOwnProperty(this._accessoryLabelField))
			{
				label = item[this._accessoryLabelField] as String;
				this.refreshAccessoryLabel(label);
				return DisplayObject(this.accessoryLabel);
			}
			else if(this._accessoryFunction != null)
			{
				return this._accessoryFunction(item) as DisplayObject;
			}
			else if(this._accessoryField != null && item && item.hasOwnProperty(this._accessoryField))
			{
				return item[this._accessoryField] as DisplayObject;
			}

			return null;
		}

		/**
		 * @private
		 */
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			if(dataInvalid)
			{
				this.commitData();
			}
			if(dataInvalid || stylesInvalid)
			{
				this.refreshAccessoryLabelStyles();
			}
			super.draw();
		}

		/**
		 * @private
		 */
		override protected function autoSizeIfNeeded():Boolean
		{
			const needsWidth:Boolean = isNaN(this.explicitWidth);
			const needsHeight:Boolean = isNaN(this.explicitHeight);
			if(!needsWidth && !needsHeight)
			{
				return false;
			}
			this.labelTextRenderer.measureText(HELPER_POINT);
			if(this.accessory is IFeathersControl)
			{
				IFeathersControl(this.accessory).validate();
			}
			var newWidth:Number = this.explicitWidth;
			if(needsWidth)
			{
				if(this.currentIcon && this.label)
				{
					if(this._iconPosition != ICON_POSITION_TOP && this._iconPosition != ICON_POSITION_BOTTOM)
					{
						var adjustedGap:Number = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingLeft, this._paddingRight) : this._gap;
						newWidth = this.currentIcon.width + adjustedGap + HELPER_POINT.x;
					}
					else
					{
						newWidth = Math.max(this.currentIcon.width, HELPER_POINT.x);
					}
				}
				else if(this.currentIcon)
				{
					newWidth = this.currentIcon.width;
				}
				else if(this.label)
				{
					newWidth = HELPER_POINT.x;
				}
				if(this.accessory)
				{
					newWidth += this.accessory.width
				}
				newWidth += this._paddingLeft + this._paddingRight;
				if(isNaN(newWidth))
				{
					newWidth = this._originalSkinWidth;
				}
				else if(!isNaN(this._originalSkinWidth))
				{
					newWidth = Math.max(newWidth, this._originalSkinWidth);
				}
			}

			var newHeight:Number = this.explicitHeight;
			if(needsHeight)
			{
				if(this.currentIcon && this.label)
				{
					if(this._iconPosition == ICON_POSITION_TOP || this._iconPosition == ICON_POSITION_BOTTOM)
					{
						adjustedGap = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingTop, this._paddingBottom) : this._gap;
						newHeight = this.currentIcon.height + adjustedGap + HELPER_POINT.y;
					}
					else
					{
						newHeight = Math.max(this.currentIcon.height, HELPER_POINT.y);
					}
				}
				else if(this.currentIcon)
				{
					newHeight = this.currentIcon.height;
				}
				else if(this.label)
				{
					newHeight = HELPER_POINT.y;
				}
				if(this.accessory)
				{
					newHeight = Math.max(newHeight, this.accessory.height);
				}
				newHeight += this._paddingTop + this._paddingBottom;
				if(isNaN(newHeight))
				{
					newHeight = this._originalSkinHeight;
				}
				else if(!isNaN(this._originalSkinHeight))
				{
					newHeight = Math.max(newHeight, this._originalSkinHeight);
				}
			}

			return this.setSizeInternal(newWidth, newHeight, false);
		}

		/**
		 * @private
		 */
		protected function commitData():void
		{
			if(this._owner)
			{
				if(this._itemHasLabel)
				{
					this._label = this.itemToLabel(this._data);
				}
				if(this._itemHasIcon)
				{
					this.defaultIcon = this.itemToIcon(this._data);
				}
				const newAccessory:DisplayObject = this.itemToAccessory(this._data);
				if(newAccessory != this.accessory)
				{
					if(this.accessory)
					{
						this.accessory.removeEventListener(TouchEvent.TOUCH, accessory_touchHandler);
						this.accessory.removeFromParent();
					}
					this.accessory = newAccessory;
					if(this.accessory)
					{
						if(this.accessory is IFeathersControl && !(this.accessory is BitmapFontTextRenderer))
						{
							this.accessory.addEventListener(TouchEvent.TOUCH, accessory_touchHandler);
						}
						this.addChild(this.accessory);
					}
				}
			}
			else
			{
				if(this._itemHasLabel)
				{
					this._label = "";
				}
				if(this._itemHasIcon)
				{
					this.defaultIcon = null;
				}
				if(this.accessory)
				{
					this.accessory.removeFromParent();
					this.accessory = null;
				}
			}
		}

		/**
		 * @private
		 */
		protected function refreshAccessoryLabelStyles():void
		{
			if(!this.accessoryLabel)
			{
				return;
			}
			const displayAccessoryLabel:DisplayObject = DisplayObject(this.accessoryLabel);
			for(var propertyName:String in this._accessoryLabelProperties)
			{
				if(displayAccessoryLabel.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._accessoryLabelProperties[propertyName];
					displayAccessoryLabel[propertyName] = propertyValue;
				}
			}
		}

		/**
		 * @private
		 */
		protected function refreshIconTexture(texture:Texture):void
		{
			if(texture)
			{
				if(!this.iconImage)
				{
					this.iconImage = this._iconImageFactory(texture);
				}
				else
				{
					this.iconImage.texture = texture;
					this.iconImage.readjustSize();
				}
			}
			else if(this.iconImage)
			{
				this.iconImage.removeFromParent(true);
				this.iconImage = null;
			}
		}

		/**
		 * @private
		 */
		protected function refreshAccessoryTexture(texture:Texture):void
		{
			if(texture)
			{
				if(!this.accessoryImage)
				{
					this.accessoryImage = this._accessoryImageFactory(texture);
				}
				else
				{
					this.accessoryImage.texture = texture;
					this.accessoryImage.readjustSize();
				}
			}
			else if(this.accessoryImage)
			{
				this.accessoryImage.removeFromParent(true);
				this.accessoryImage = null;
			}
		}

		/**
		 * @private
		 */
		protected function refreshAccessoryLabel(label:String):void
		{
			if(label !== null)
			{
				if(!this.accessoryLabel)
				{
					const factory:Function = this._accessoryLabelFactory != null ? this._accessoryLabelFactory : FeathersControl.defaultTextRendererFactory;
					this.accessoryLabel = ITextRenderer(factory());
					this.accessoryLabel.nameList.add(this.accessoryLabelName);
				}
				this.accessoryLabel.text = label;
			}
			else if(this.accessoryLabel)
			{
				DisplayObject(this.accessoryLabel).removeFromParent(true);
				this.accessoryLabel = null;
			}
		}

		/**
		 * @private
		 */
		override protected function layoutContent():void
		{
			if(this.accessory is IFeathersControl)
			{
				IFeathersControl(this.accessory).validate();
			}
			var labelMaxWidth:Number = this.actualWidth - this._paddingLeft - this._paddingRight;
			var adjustedGap:Number = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingLeft, this._paddingRight) : this._gap;
			if(this.currentIcon && (this._iconPosition == ICON_POSITION_LEFT || this._iconPosition == ICON_POSITION_LEFT_BASELINE ||
				this._iconPosition == ICON_POSITION_RIGHT || this._iconPosition == ICON_POSITION_RIGHT_BASELINE))
			{
				labelMaxWidth -= (this.currentIcon.width + adjustedGap);
			}
			if(this.accessory)
			{
				labelMaxWidth -= (this.accessory.width + adjustedGap);
			}

			this.labelTextRenderer.maxWidth = labelMaxWidth;
			this.labelTextRenderer.validate();

			if(this.label)
			{
				this.positionLabelOrIcon(DisplayObject(this.labelTextRenderer));
				if(this.accessory)
				{
					if(this._horizontalAlign == Button.HORIZONTAL_ALIGN_RIGHT)
					{
						this.labelTextRenderer.x -= (this.accessory.width + adjustedGap);
					}
					else if(this._horizontalAlign == Button.HORIZONTAL_ALIGN_CENTER)
					{
						this.labelTextRenderer.x -= (this.accessory.width + adjustedGap) / 2;
					}
				}
				if(this.currentIcon)
				{
					this.positionLabelAndIcon();
				}
			}
			else if(this.currentIcon)
			{
				this.positionLabelOrIcon(this.currentIcon);
				if(this.accessory)
				{
					if(this._horizontalAlign == Button.HORIZONTAL_ALIGN_RIGHT)
					{
						this.currentIcon.x -= (this.accessory.width + adjustedGap);
					}
					else if(this._horizontalAlign == Button.HORIZONTAL_ALIGN_CENTER)
					{
						this.currentIcon.x -= (this.accessory.width + adjustedGap) / 2;
					}
				}
			}

			if(!this.accessory)
			{
				return;
			}
			this.accessory.x = this.actualWidth - this._paddingRight - this.accessory.width;
			this.accessory.y = (this.actualHeight - this.accessory.height) / 2;
		}

		/**
		 * @private
		 */
		protected function handleOwnerScroll():void
		{
			this._touchPointID = -1;
			if(this._stateDelayTimer && this._stateDelayTimer.running)
			{
				this._stateDelayTimer.stop();
			}
			this._delayedCurrentState = null;
			if(this._currentState != Button.STATE_UP)
			{
				super.currentState = Button.STATE_UP;
			}
		}

		/**
		 * @private
		 */
		protected function accessoryLabelProperties_onChange(proxy:PropertyProxy, name:String):void
		{
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected function stateDelayTimer_timerCompleteHandler(event:TimerEvent):void
		{
			super.currentState = this._delayedCurrentState;
			this._delayedCurrentState = null;
		}

		/**
		 * @private
		 */
		protected function accessory_touchHandler(event:TouchEvent):void
		{
			if(this.accessory == this.accessoryLabel ||
				this.accessory == this.accessoryImage)
			{
				//do nothing
				return;
			}
			event.stopPropagation();
		}
	}
}