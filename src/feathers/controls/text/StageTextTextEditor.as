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
package feathers.controls.text
{
	import feathers.core.FeathersControl;
	import feathers.core.ITextEditor;
	import feathers.display.Image;
	import feathers.display.ScrollRectManager;
	import feathers.events.FeathersEventType;
	import feathers.text.StageTextField;

	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.engine.FontPosture;
	import flash.text.engine.FontWeight;
	import flash.ui.Keyboard;
	import flash.utils.getDefinitionByName;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.events.Event;
	import starling.textures.ConcreteTexture;
	import starling.textures.Texture;
	import starling.utils.MatrixUtil;

	/**
	 * Dispatched when the text property changes.
	 */
	[Event(name="change",type="starling.events.Event")]

	/**
	 * Dispatched when the user presses the Enter key while the editor has focus.
	 *
	 * @eventType feathers.events.FeathersEventType.ENTER
	 */
	[Event(name="enter",type="starling.events.Event")]

	/**
	 * Dispatched when the text editor receives focus.
	 *
	 * @eventType feathers.events.FeathersEventType.FOCUS_IN
	 */
	[Event(name="focusIn",type="starling.events.Event")]

	/**
	 * Dispatched when the text editor loses focus.
	 *
	 * @eventType feathers.events.FeathersEventType.FOCUS_OUT
	 */
	[Event(name="focusOut",type="starling.events.Event")]

	/**
	 * A Feathers text editor that uses the native <code>StageText</code> class
	 * in AIR, and the custom <code>StageTextField</code> class (that simulates
	 * <code>StageText</code>) in Flash Player.
	 *
	 * @see http://wiki.starling-framework.org/feathers/text-editors
	 * @see flash.text.StageText
	 * @see feathers.text.StageTextField
	 */
	public class StageTextTextEditor extends FeathersControl implements ITextEditor
	{
		/**
		 * @private
		 */
		private static const HELPER_MATRIX:Matrix = new Matrix();

		/**
		 * @private
		 */
		private static const HELPER_POINT:Point = new Point();

		/**
		 * @private
		 */
		protected static const INVALIDATION_FLAG_POSITION:String = "position";

		/**
		 * Constructor.
		 */
		public function StageTextTextEditor()
		{
			this.isQuickHitAreaEnabled = true;
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStageHandler);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}

		/**
		 * @private
		 */
		override public function set x(value:Number):void
		{
			super.x = value;
			//we need to know when the position changes to change the position
			//of the StageText instance.
			this.invalidate(INVALIDATION_FLAG_POSITION);
		}

		/**
		 * @private
		 */
		override public function set y(value:Number):void
		{
			super.y = value;
			this.invalidate(INVALIDATION_FLAG_POSITION);
		}

		/**
		 * The StageText instance. It's typed Object so that a replacement class
		 * can be used in browser-based Flash Player.
		 */
		protected var stageText:Object;

		/**
		 * An image that displays a snapshot of the native <code>StageText</code>
		 * in the Starling display list when the editor doesn't have focus.
		 */
		protected var textSnapshot:Image;

		/**
		 * @private
		 */
		protected var _text:String = "";

		/**
		 * The text displayed by the input.
		 */
		public function get text():String
		{
			return this._text;
		}

		/**
		 * @private
		 */
		public function set text(value:String):void
		{
			if(!value)
			{
				//don't allow null or undefined
				value = "";
			}
			if(this._text == value)
			{
				return;
			}
			this._text = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
			this.dispatchEventWith(starling.events.Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _measureTextField:TextField;

		/**
		 * @private
		 */
		protected var _stageTextHasFocus:Boolean = false;

		/**
		 * @private
		 */
		protected var _isWaitingToSetFocus:Boolean = false;

		/**
		 * @private
		 */
		protected var _pendingSelectionStartIndex:int = -1;

		/**
		 * @private
		 */
		protected var _pendingSelectionEndIndex:int = -1;

		/**
		 * @private
		 */
		protected var _stageTextIsComplete:Boolean = false;

		/**
		 * @private
		 * Stores the snapshot of the StageText to display when the StageText
		 * isn't visible.
		 */
		protected var textSnapshotBitmapData:BitmapData;

		/**
		 * @private
		 */
		protected var _oldGlobalX:Number = 0;

		/**
		 * @private
		 */
		protected var _oldGlobalY:Number = 0;

		/**
		 * @private
		 */
		protected var _savedSelectionIndex:int = -1;

		/**
		 * @private
		 */
		protected var _autoCapitalize:String = "none";

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get autoCapitalize():String
		{
			return this._autoCapitalize;
		}

		/**
		 * @private
		 */
		public function set autoCapitalize(value:String):void
		{
			if(this._autoCapitalize == value)
			{
				return;
			}
			this._autoCapitalize = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _autoCorrect:Boolean = false;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get autoCorrect():Boolean
		{
			return this._autoCorrect;
		}

		/**
		 * @private
		 */
		public function set autoCorrect(value:Boolean):void
		{
			if(this._autoCorrect == value)
			{
				return;
			}
			this._autoCorrect = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _color:uint = 0x000000;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get color():uint
		{
			return this._color as uint;
		}

		/**
		 * @private
		 */
		public function set color(value:uint):void
		{
			if(this._color == value)
			{
				return;
			}
			this._color = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _displayAsPassword:Boolean = false;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get displayAsPassword():Boolean
		{
			return this._displayAsPassword;
		}

		/**
		 * @private
		 */
		public function set displayAsPassword(value:Boolean):void
		{
			if(this._displayAsPassword == value)
			{
				return;
			}
			this._displayAsPassword = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _editable:Boolean = true;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get editable():Boolean
		{
			return this._editable;
		}

		/**
		 * @private
		 */
		public function set editable(value:Boolean):void
		{
			if(this._editable == value)
			{
				return;
			}
			this._editable = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _fontFamily:String = null;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get fontFamily():String
		{
			return this._fontFamily;
		}

		/**
		 * @private
		 */
		public function set fontFamily(value:String):void
		{
			if(this._fontFamily == value)
			{
				return;
			}
			this._fontFamily = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _fontPosture:String = FontPosture.NORMAL;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get fontPosture():String
		{
			return this._fontPosture;
		}

		/**
		 * @private
		 */
		public function set fontPosture(value:String):void
		{
			if(this._fontPosture == value)
			{
				return;
			}
			this._fontPosture = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _fontSize:int = 12;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get fontSize():int
		{
			return this._fontSize;
		}

		/**
		 * @private
		 */
		public function set fontSize(value:int):void
		{
			if(this._fontSize == value)
			{
				return;
			}
			this._fontSize = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _fontWeight:String = FontWeight.NORMAL;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get fontWeight():String
		{
			return this._fontWeight;
		}

		/**
		 * @private
		 */
		public function set fontWeight(value:String):void
		{
			if(this._fontWeight == value)
			{
				return;
			}
			this._fontWeight = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _locale:String = "en";

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get locale():String
		{
			return this._locale;
		}

		/**
		 * @private
		 */
		public function set locale(value:String):void
		{
			if(this._locale == value)
			{
				return;
			}
			this._locale = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _maxChars:int = int.MAX_VALUE;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get maxChars():int
		{
			return this._maxChars;
		}

		/**
		 * @private
		 */
		public function set maxChars(value:int):void
		{
			if(this._maxChars == value)
			{
				return;
			}
			this._maxChars = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _restrict:String;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get restrict():String
		{
			return this._restrict;
		}

		/**
		 * @private
		 */
		public function set restrict(value:String):void
		{
			if(this._restrict == value)
			{
				return;
			}
			this._restrict = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _returnKeyLabel:String = "default";

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get returnKeyLabel():String
		{
			return this._returnKeyLabel;
		}

		/**
		 * @private
		 */
		public function set returnKeyLabel(value:String):void
		{
			if(this._returnKeyLabel == value)
			{
				return;
			}
			this._returnKeyLabel = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _softKeyboardType:String = "default";

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get softKeyboardType():String
		{
			return this._softKeyboardType;
		}

		/**
		 * @private
		 */
		public function set softKeyboardType(value:String):void
		{
			if(this._softKeyboardType == value)
			{
				return;
			}
			this._softKeyboardType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _textAlign:String = TextFormatAlign.START;

		/**
		 * Same as the <code>StageText</code> property with the same name.
		 */
		public function get textAlign():String
		{
			return this._textAlign;
		}

		/**
		 * @private
		 */
		public function set textAlign(value:String):void
		{
			if(this._textAlign == value)
			{
				return;
			}
			this._textAlign = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		override public function dispose():void
		{
			if(this.textSnapshotBitmapData)
			{
				this.textSnapshotBitmapData.dispose();
				this.textSnapshotBitmapData = null;
			}

			if(this.stageText)
			{
				this.disposeStageText();
			}

			if(this._measureTextField)
			{
				Starling.current.nativeStage.removeChild(this._measureTextField);
				this._measureTextField = null;
			}

			super.dispose();
		}

		/**
		 * @private
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			HELPER_POINT.x = HELPER_POINT.y = 0;
			this.getTransformationMatrix(this.stage, HELPER_MATRIX);
			MatrixUtil.transformCoords(HELPER_MATRIX, 0, 0, HELPER_POINT);
			ScrollRectManager.toStageCoordinates(HELPER_POINT, this);
			if(HELPER_POINT.x != this._oldGlobalX || HELPER_POINT.y != this._oldGlobalY)
			{
				this._oldGlobalX = HELPER_POINT.x;
				this._oldGlobalY = HELPER_POINT.y;
				const starlingViewPort:Rectangle = Starling.current.viewPort;
				var stageTextViewPort:Rectangle = this.stageText.viewPort;
				if(!stageTextViewPort)
				{
					stageTextViewPort = new Rectangle();
				}
				stageTextViewPort.x = Math.round(starlingViewPort.x + (HELPER_POINT.x * Starling.contentScaleFactor));
				stageTextViewPort.y = Math.round(starlingViewPort.y + (HELPER_POINT.y * Starling.contentScaleFactor));
				this.stageText.viewPort = stageTextViewPort;
			}

			if(this.textSnapshot)
			{
				this.textSnapshot.x = Math.round(HELPER_MATRIX.tx) - HELPER_MATRIX.tx;
				this.textSnapshot.y = Math.round(HELPER_MATRIX.ty) - HELPER_MATRIX.ty;
			}

			//theoretically, this will ensure that the StageText is set visible
			//or invisible immediately after the snapshot changes visibility in
			//the rendered graphics. the OS might take longer to do the change,
			//though.
			this.stageText.visible = this.textSnapshot ? !this.textSnapshot.visible : this._stageTextHasFocus;
			super.render(support, alpha);
		}

		/**
		 * @inheritDoc
		 */
		public function setFocus(position:Point = null):void
		{
			if(this.stageText && this._stageTextIsComplete)
			{
				if(position)
				{
					if(position.x < 0)
					{
						this._savedSelectionIndex = 0;
					}
					else
					{
						this._savedSelectionIndex = this._measureTextField.getCharIndexAtPoint(position.x, position.y);
						const bounds:Rectangle = this._measureTextField.getCharBoundaries(this._savedSelectionIndex);
						if(bounds && (bounds.x + bounds.width - position.x) < (position.x - bounds.x))
						{
							this._savedSelectionIndex++;
						}
					}
				}
				else
				{
					this._savedSelectionIndex = -1;
				}
				this.stageText.assignFocus();
			}
			else
			{
				this._isWaitingToSetFocus = true;
			}
		}

		/**
		 * @inheritDoc
		 */
		public function selectRange(startIndex:int, endIndex:int):void
		{
			if(this._stageTextIsComplete && this.stageText)
			{
				this.stageText.selectRange(startIndex, endIndex);
			}
			else
			{
				this._pendingSelectionStartIndex = startIndex;
				this._pendingSelectionEndIndex = endIndex;
			}
		}

		/**
		 * @private
		 */
		override protected function draw():void
		{
			const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const positionInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_POSITION);
			const skinInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SKIN);
			var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);

			if(stylesInvalid)
			{
				this.refreshStageTextProperties();
			}

			if(dataInvalid)
			{
				if(this.stageText.text != this._text)
				{
					this.stageText.text = this._text;
				}
				this._measureTextField.text = this.stageText.text;
			}

			if(stateInvalid)
			{
				this.stageText.editable = this._isEnabled;
			}

			if(positionInvalid || sizeInvalid || stylesInvalid || skinInvalid || stateInvalid)
			{
				this.refreshViewPort();
			}

			if(stylesInvalid || dataInvalid || sizeInvalid)
			{
				if(!this._stageTextHasFocus)
				{
					const hasText:Boolean = this._text.length > 0;
					if(hasText)
					{
						this.refreshSnapshot(sizeInvalid || !this.textSnapshotBitmapData);
					}
					if(this.textSnapshot)
					{
						this.textSnapshot.visible = hasText;
					}
				}
			}

			this.doPendingActions();
		}

		/**
		 * @private
		 */
		protected function refreshStageTextProperties():void
		{
			this.stageText.autoCapitalize = this._autoCapitalize;
			this.stageText.autoCorrect = this._autoCorrect;
			this.stageText.color = this._color;
			this.stageText.displayAsPassword = this._displayAsPassword
			this.stageText.editable = this._editable;
			this.stageText.fontFamily = this._fontFamily;
			this.stageText.fontPosture = this._fontPosture;
			this.stageText.fontSize = this._fontSize;
			this.stageText.fontWeight = this._fontWeight;
			this.stageText.locale = this._locale;
			this.stageText.maxChars = this._maxChars;
			this.stageText.restrict = this._restrict;
			this.stageText.returnKeyLabel = this._returnKeyLabel;
			this.stageText.softKeyboardType = this._softKeyboardType;
			this.stageText.textAlign = this._textAlign;

			this._measureTextField.displayAsPassword = this._displayAsPassword;
			this._measureTextField.maxChars = this._maxChars;
			this._measureTextField.restrict = this._restrict;

			const format:TextFormat = this._measureTextField.defaultTextFormat;
			format.color = this._color;
			format.font = this._fontFamily;
			format.italic = this._fontPosture == FontPosture.ITALIC;
			format.size = this._fontSize / Starling.contentScaleFactor;
			format.bold = this._fontWeight == FontWeight.BOLD;
			var alignValue:String = this._textAlign;
			if(alignValue == TextFormatAlign.START)
			{
				alignValue = TextFormatAlign.LEFT;
			}
			else if(alignValue == TextFormatAlign.END)
			{
				alignValue = TextFormatAlign.RIGHT;
			}
			format.align = alignValue;
			this._measureTextField.defaultTextFormat = format;
			this._measureTextField.setTextFormat(format);
		}

		/**
		 * @private
		 */
		protected function doPendingActions():void
		{
			if(this._isWaitingToSetFocus)
			{
				this._isWaitingToSetFocus = false;
				this.setFocus();
			}
			if(this._pendingSelectionStartIndex >= 0)
			{
				const startIndex:int = this._pendingSelectionStartIndex;
				const endIndex:int = this._pendingSelectionEndIndex;
				this._pendingSelectionStartIndex = -1;
				this._pendingSelectionEndIndex = -1;
				this.selectRange(startIndex, endIndex);
			}
		}

		/**
		 * @private
		 */
		protected function refreshSnapshot(needsNewBitmap:Boolean):void
		{
			if(needsNewBitmap)
			{
				const viewPort:Rectangle = this.stageText.viewPort;
				if(viewPort.width == 0 || viewPort.height == 0)
				{
					return;
				}
				if(!this.textSnapshotBitmapData || this.textSnapshotBitmapData.width != viewPort.width || this.textSnapshotBitmapData.height != viewPort.height)
				{
					if(this.textSnapshotBitmapData)
					{
						this.textSnapshotBitmapData.dispose();
					}
					this.textSnapshotBitmapData = new BitmapData(viewPort.width, viewPort.height, true, 0x00ff00ff);
				}
			}

			if(!this.textSnapshotBitmapData)
			{
				return;
			}
			this.textSnapshotBitmapData.fillRect(this.textSnapshotBitmapData.rect, 0x00ff00ff);
			this.stageText.drawViewPortToBitmapData(this.textSnapshotBitmapData);
			if(!this.textSnapshot)
			{
				this.textSnapshot = new Image(starling.textures.Texture.fromBitmapData(this.textSnapshotBitmapData, false, false, Starling.contentScaleFactor));
				this.addChild(this.textSnapshot);
			}
			else
			{
				if(needsNewBitmap)
				{
					this.textSnapshot.texture.dispose();
					this.textSnapshot.texture = starling.textures.Texture.fromBitmapData(this.textSnapshotBitmapData, false, false, Starling.contentScaleFactor);
					this.textSnapshot.readjustSize();
				}
				else
				{
					//this is faster, so use it if we haven't resized the
					//bitmapdata
					const texture:starling.textures.Texture = this.textSnapshot.texture;
					if(Starling.handleLostContext && texture is ConcreteTexture)
					{
						ConcreteTexture(texture).restoreOnLostContext(this.textSnapshotBitmapData);
					}
					flash.display3D.textures.Texture(texture.base).uploadFromBitmapData(this.textSnapshotBitmapData);
				}
			}

			this.getTransformationMatrix(this.stage, HELPER_MATRIX);
			this.textSnapshot.x = Math.round(HELPER_MATRIX.tx) - HELPER_MATRIX.tx;
			this.textSnapshot.y = Math.round(HELPER_MATRIX.ty) - HELPER_MATRIX.ty;
		}

		/**
		 * @private
		 */
		protected function refreshViewPort():void
		{
			const starlingViewPort:Rectangle = Starling.current.viewPort;
			var stageTextViewPort:Rectangle = this.stageText.viewPort;
			if(!stageTextViewPort)
			{
				stageTextViewPort = new Rectangle();
			}
			if(!this.stageText.stage)
			{
				this.stageText.stage = Starling.current.nativeStage;
			}

			HELPER_POINT.x = HELPER_POINT.y = 0;
			this.getTransformationMatrix(this.stage, HELPER_MATRIX);
			MatrixUtil.transformCoords(HELPER_MATRIX, 0, 0, HELPER_POINT);
			ScrollRectManager.toStageCoordinates(HELPER_POINT, this);
			this._oldGlobalX = HELPER_POINT.x;
			this._oldGlobalY = HELPER_POINT.y;
			stageTextViewPort.x = Math.round(starlingViewPort.x + HELPER_POINT.x * Starling.contentScaleFactor);
			stageTextViewPort.y = Math.round(starlingViewPort.y + HELPER_POINT.y * Starling.contentScaleFactor);
			stageTextViewPort.width = Math.round(Math.max(1, this.actualWidth * Starling.contentScaleFactor * this.scaleX));
			//we're ignoring padding bottom here to keep the descent from being cut off
			stageTextViewPort.height = Math.round(Math.max(1, this.actualHeight * Starling.contentScaleFactor * this.scaleY));
			if(isNaN(stageTextViewPort.width) || isNaN(stageTextViewPort.height))
			{
				stageTextViewPort.width = 1;
				stageTextViewPort.height = 1;
			}
			this.stageText.viewPort = stageTextViewPort;
		}

		/**
		 * @private
		 */
		protected function disposeStageText():void
		{
			this.stageText.removeEventListener(flash.events.Event.CHANGE, stageText_changeHandler);
			this.stageText.removeEventListener(KeyboardEvent.KEY_DOWN, stageText_keyDownHandler);
			this.stageText.removeEventListener(FocusEvent.FOCUS_IN, stageText_focusInHandler);
			this.stageText.removeEventListener(FocusEvent.FOCUS_OUT, stageText_focusOutHandler);
			this.stageText.removeEventListener(flash.events.Event.COMPLETE, stageText_completeHandler);
			this.stageText.stage = null;
			this.stageText.dispose();
			this.stageText = null;
		}

		/**
		 * @private
		 */
		protected function addedToStageHandler(event:starling.events.Event):void
		{
			if(this._measureTextField && !this._measureTextField.parent)
			{
				Starling.current.nativeStage.addChild(this._measureTextField);
			}
			else if(!this._measureTextField)
			{
				this._measureTextField = new TextField();
				this._measureTextField.visible = false;
				this._measureTextField.mouseEnabled = this._measureTextField.mouseWheelEnabled = false;
				this._measureTextField.autoSize = TextFieldAutoSize.LEFT;
				this._measureTextField.multiline = false;
				this._measureTextField.wordWrap = false;
				this._measureTextField.embedFonts = false;
				this._measureTextField.defaultTextFormat = new TextFormat(null, 11, 0x000000, false, false, false);
				Starling.current.nativeStage.addChild(this._measureTextField);
			}

			this._stageTextIsComplete = false;
			var StageTextType:Class;
			var initOptions:Object;
			try
			{
				StageTextType = Class(getDefinitionByName("flash.text.StageText"));
				const StageTextInitOptionsType:Class = Class(getDefinitionByName("flash.text.StageTextInitOptions"));
				initOptions = new StageTextInitOptionsType(false);
			}
			catch(error:Error)
			{
				StageTextType = StageTextField;
				initOptions = { multiline: false };
			}
			this.stageText = new StageTextType(initOptions);
			this.stageText.visible = false;
			this.stageText.addEventListener(flash.events.Event.CHANGE, stageText_changeHandler);
			this.stageText.addEventListener(KeyboardEvent.KEY_DOWN, stageText_keyDownHandler);
			this.stageText.addEventListener(FocusEvent.FOCUS_IN, stageText_focusInHandler);
			this.stageText.addEventListener(FocusEvent.FOCUS_OUT, stageText_focusOutHandler);
			this.stageText.addEventListener(flash.events.Event.COMPLETE, stageText_completeHandler);
		}

		/**
		 * @private
		 */
		protected function removedFromStageHandler(event:starling.events.Event):void
		{
			Starling.current.nativeStage.removeChild(this._measureTextField);
			this._measureTextField = null;

			this.disposeStageText();
		}

		/**
		 * @private
		 */
		protected function stageText_changeHandler(event:flash.events.Event):void
		{
			this.text = this.stageText.text;
		}

		/**
		 * @private
		 */
		protected function stageText_completeHandler(event:flash.events.Event):void
		{
			this.stageText.removeEventListener(flash.events.Event.COMPLETE, stageText_completeHandler);
			this.invalidate();

			this._stageTextIsComplete = true;
		}

		/**
		 * @private
		 */
		protected function stageText_focusInHandler(event:FocusEvent):void
		{
			this._stageTextHasFocus = true;
			if(this.textSnapshot)
			{
				this.textSnapshot.visible = false;
			}
			if(this._savedSelectionIndex >= 0)
			{
				const selectionIndex:int = this._savedSelectionIndex;
				this._savedSelectionIndex = -1;
				this.selectRange(selectionIndex, selectionIndex)
			}
			this.invalidate(INVALIDATION_FLAG_SKIN);
			this.dispatchEventWith(FeathersEventType.FOCUS_IN);
		}

		/**
		 * @private
		 */
		protected function stageText_focusOutHandler(event:FocusEvent):void
		{
			this._stageTextHasFocus = false;
			//since StageText doesn't expose its scroll position, we need to
			//set the selection back to the beginning to scroll there. it's a
			//hack, but so is everything about StageText.
			//in other news, why won't 0,0 work here?
			this.stageText.selectRange(1, 1);

			this.invalidate(INVALIDATION_FLAG_DATA);
			this.invalidate(INVALIDATION_FLAG_SKIN);
			this.dispatchEventWith(FeathersEventType.FOCUS_OUT);
		}

		/**
		 * @private
		 */
		protected function stageText_keyDownHandler(event:KeyboardEvent):void
		{
			if(event.keyCode == Keyboard.ENTER)
			{
				this.dispatchEventWith(FeathersEventType.ENTER);
			}
			else if(event.keyCode == Keyboard.BACK)
			{
				//even a listener on the stage won't detect the back key press that
				//will close the application if the StageText has focus, so we
				//always need to prevent it here
				event.preventDefault();
				Starling.current.nativeStage.focus = Starling.current.nativeStage;
			}
		}
	}
}
