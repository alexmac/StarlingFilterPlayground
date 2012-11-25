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
package feathers.controls
{
	import feathers.core.FeathersControl;
	import feathers.core.PropertyProxy;
	import feathers.data.ListCollection;

	import starling.events.Event;

	[DefaultProperty("dataProvider")]
	/**
	 * A set of related buttons with layout, customized using a data provider.
	 *
	 * @see http://wiki.starling-framework.org/feathers/button-group
	 */
	public class ButtonGroup extends FeathersControl
	{
		/**
		 * @private
		 */
		protected static const INVALIDATION_FLAG_BUTTON_FACTORY:String = "buttonFactory";

		/**
		 * @private
		 */
		private static const DEFAULT_BUTTON_FIELDS:Vector.<String> = new <String>
		[
			"defaultIcon",
			"upIcon",
			"downIcon",
			"hoverIcon",
			"disabledIcon",
			"defaultSelectedIcon",
			"selectedUpIcon",
			"selectedDownIcon",
			"selectedHoverIcon",
			"selectedDisabledIcon",
			"isSelected",
			"isToggle",
		];

		/**
		 * @private
		 */
		private static const DEFAULT_BUTTON_EVENTS:Vector.<String> = new <String>
		[
			Event.TRIGGERED,
			Event.CHANGE,
		];

		/**
		 * The buttons are displayed in order from left to right.
		 */
		public static const DIRECTION_HORIZONTAL:String = "horizontal";

		/**
		 * The buttons are displayed in order from top to bottom.
		 */
		public static const DIRECTION_VERTICAL:String = "vertical";

		/**
		 * The default value added to the <code>nameList</code> of the buttons.
		 */
		public static const DEFAULT_CHILD_NAME_BUTTON:String = "feathers-button-group-button";

		/**
		 * @private
		 */
		protected static function defaultButtonFactory():Button
		{
			return new Button();
		}

		/**
		 * Constructor.
		 */
		public function ButtonGroup()
		{
		}

		/**
		 * The value added to the <code>nameList</code> of the buttons.
		 */
		protected var buttonName:String = DEFAULT_CHILD_NAME_BUTTON;

		/**
		 * The value added to the <code>nameList</code> of the first button.
		 */
		protected var firstButtonName:String = DEFAULT_CHILD_NAME_BUTTON;

		/**
		 * The value added to the <code>nameList</code> of the last button.
		 */
		protected var lastButtonName:String = DEFAULT_CHILD_NAME_BUTTON;

		/**
		 * @private
		 */
		protected var activeFirstButton:Button;

		/**
		 * @private
		 */
		protected var inactiveFirstButton:Button;

		/**
		 * @private
		 */
		protected var activeLastButton:Button;

		/**
		 * @private
		 */
		protected var inactiveLastButton:Button;

		/**
		 * @private
		 */
		protected var activeButtons:Vector.<Button> = new <Button>[];

		/**
		 * @private
		 */
		protected var inactiveButtons:Vector.<Button> = new <Button>[];

		/**
		 * @private
		 */
		protected var _dataProvider:ListCollection;

		/**
		 * The collection of data to be displayed with buttons.
		 *
		 * @see #buttonInitializer
		 */
		public function get dataProvider():ListCollection
		{
			return this._dataProvider;
		}

		/**
		 * @private
		 */
		public function set dataProvider(value:ListCollection):void
		{
			if(this._dataProvider == value)
			{
				return;
			}
			if(this._dataProvider)
			{
				this._dataProvider.removeEventListener(Event.CHANGE, dataProvider_changeHandler);
			}
			this._dataProvider = value;
			if(this._dataProvider)
			{
				this._dataProvider.addEventListener(Event.CHANGE, dataProvider_changeHandler);
			}
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _direction:String = DIRECTION_VERTICAL;

		[Inspectable(type="String",enumeration="horizontal,vertical")]
		/**
		 * The button group layout is either vertical or horizontal.
		 */
		public function get direction():String
		{
			return _direction;
		}

		/**
		 * @private
		 */
		public function set direction(value:String):void
		{
			if(this._direction == value)
			{
				return;
			}
			this._direction = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _gap:Number = 0;

		/**
		 * Space, in pixels, between buttons.
		 */
		public function get gap():Number
		{
			return this._gap;
		}

		/**
		 * @private
		 */
		public function set gap(value:Number):void
		{
			if(this._gap == value)
			{
				return;
			}
			this._gap = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _firstGap:Number = NaN;

		/**
		 * Space, in pixels, between the first two buttons. If NaN, the standard
		 * gap will be used.
		 *
		 * @see #gap
		 * @see #lastGap
		 */
		public function get firstGap():Number
		{
			return this._firstGap;
		}

		/**
		 * @private
		 */
		public function set firstGap(value:Number):void
		{
			if(this._firstGap == value)
			{
				return;
			}
			this._firstGap = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _lastGap:Number = NaN;

		/**
		 * Space, in pixels, between the last two buttons. If NaN, the standard
		 * gap will be used.
		 *
		 * @see #gap
		 * @see #firstGap
		 */
		public function get lastGap():Number
		{
			return this._lastGap;
		}

		/**
		 * @private
		 */
		public function set lastGap(value:Number):void
		{
			if(this._lastGap == value)
			{
				return;
			}
			this._lastGap = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _buttonFactory:Function = defaultButtonFactory;

		/**
		 * Creates a new button.
		 *
		 * <p>This function is expected to have the following signature:</p>
		 *
		 * <pre>function():Button</pre>
		 *
		 * @see #firstButtonFactory
		 * @see #lastButtonFactory
		 */
		public function get buttonFactory():Function
		{
			return this._buttonFactory;
		}

		/**
		 * @private
		 */
		public function set buttonFactory(value:Function):void
		{
			if(this._buttonFactory == value)
			{
				return;
			}
			this._buttonFactory = value;
			this.invalidate(INVALIDATION_FLAG_BUTTON_FACTORY);
		}

		/**
		 * @private
		 */
		protected var _firstButtonFactory:Function;

		/**
		 * Creates a new first button. If the firstButtonFactory is null, then the
		 * ButtonGroup will use the buttonFactory.
		 *
		 * <p>This function is expected to have the following signature:</p>
		 *
		 * <pre>function():Button</pre>
		 *
		 * @see #buttonFactory
		 * @see #lastButtonFactory
		 */
		public function get firstButtonFactory():Function
		{
			return this._firstButtonFactory;
		}

		/**
		 * @private
		 */
		public function set firstButtonFactory(value:Function):void
		{
			if(this._firstButtonFactory == value)
			{
				return;
			}
			this._firstButtonFactory = value;
			this.invalidate(INVALIDATION_FLAG_BUTTON_FACTORY);
		}

		/**
		 * @private
		 */
		protected var _lastButtonFactory:Function;

		/**
		 * Creates a new last button. If the lastButtonFactory is null, then the
		 * ButtonGroup will use the buttonFactory.
		 *
		 * <p>This function is expected to have the following signature:</p>
		 *
		 * <pre>function():Button</pre>
		 *
		 * @see #buttonFactory
		 * @see #firstButtonFactory
		 */
		public function get lastButtonFactory():Function
		{
			return this._lastButtonFactory;
		}

		/**
		 * @private
		 */
		public function set lastButtonFactory(value:Function):void
		{
			if(this._lastButtonFactory == value)
			{
				return;
			}
			this._lastButtonFactory = value;
			this.invalidate(INVALIDATION_FLAG_BUTTON_FACTORY);
		}

		/**
		 * @private
		 */
		protected var _buttonInitializer:Function = defaultButtonInitializer;

		/**
		 * Modifies a button, perhaps by changing its label and icons, based on the
		 * item from the data provider that the button is meant to represent. The
		 * default buttonInitializer function can set the button's label and icons if
		 * <code>label</code> and/or any of the <code>Button</code> icon fields
		 * (<code>defaultIcon</code>, <code>upIcon</code>, etc.) are present in
		 * the item. onPress and onRelease events can also be listened to by
		 * passing in functions for each.
		 */
		public function get buttonInitializer():Function
		{
			return this._buttonInitializer;
		}

		/**
		 * @private
		 */
		public function set buttonInitializer(value:Function):void
		{
			if(this._buttonInitializer == value)
			{
				return;
			}
			this._buttonInitializer = value;
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		/**
		 * @private
		 */
		protected var _customButtonName:String;

		/**
		 * A name to add to all buttons in this button group. Typically used by
		 * a theme to provide different skins to different button groups.
		 *
		 * @see feathers.core.FeathersControl#nameList
		 */
		public function get customButtonName():String
		{
			return this._customButtonName;
		}

		/**
		 * @private
		 */
		public function set customButtonName(value:String):void
		{
			if(this._customButtonName == value)
			{
				return;
			}
			if(this._customButtonName)
			{
				for each(var button:Button in this.activeButtons)
				{
					button.nameList.remove(this._customButtonName);
				}
			}
			this._customButtonName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _customFirstButtonName:String;

		/**
		 * A name to add to the first button in this button group. Typically
		 * used by a theme to provide different skins to the first button.
		 *
		 * @see feathers.core.FeathersControl#nameList
		 */
		public function get customFirstButtonName():String
		{
			return this._customFirstButtonName;
		}

		/**
		 * @private
		 */
		public function set customFirstButtonName(value:String):void
		{
			if(this._customFirstButtonName == value)
			{
				return;
			}
			if(this._customFirstButtonName && this.activeFirstButton)
			{
				this.activeFirstButton.nameList.remove(this._customButtonName);
				this.activeFirstButton.nameList.remove(this._customFirstButtonName);
			}
			this._customFirstButtonName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _customLastButtonName:String;

		/**
		 * A name to add to the last button in this button group. Typically used
		 * by a theme to provide different skins to the last button.
		 *
		 * @see feathers.core.FeathersControl#nameList
		 */
		public function get customLastButtonName():String
		{
			return this._customLastButtonName;
		}

		/**
		 * @private
		 */
		public function set customLastButtonName(value:String):void
		{
			if(this._customLastButtonName == value)
			{
				return;
			}
			if(this._customLastButtonName && this.activeLastButton)
			{
				this.activeLastButton.nameList.remove(this._customButtonName);
				this.activeLastButton.nameList.remove(this._customLastButtonName);
			}
			this._customLastButtonName = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _buttonProperties:PropertyProxy;

		/**
		 * A set of key/value pairs to be passed down to all of the button
		 * group's buttons. These values are shared by each button, so values
		 * that cannot be shared (such as display objects that need to be added
		 * to the display list) should be passed to buttons in another way (such
		 * as with an <code>AddedWatcher</code>).
		 *
		 * <p>If the subcomponent has its own subcomponents, their properties
		 * can be set too, using attribute <code>&#64;</code> notation. For example,
		 * to set the skin on the thumb of a <code>SimpleScrollBar</code>
		 * which is in a <code>Scroller</code> which is in a <code>List</code>,
		 * you can use the following syntax:</p>
		 * <pre>list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);</pre>
		 *
		 * @see AddedWatcher
		 */
		public function get buttonProperties():Object
		{
			if(!this._buttonProperties)
			{
				this._buttonProperties = new PropertyProxy(childProperties_onChange);
			}
			return this._buttonProperties;
		}

		/**
		 * @private
		 */
		public function set buttonProperties(value:Object):void
		{
			if(this._buttonProperties == value)
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
			if(this._buttonProperties)
			{
				this._buttonProperties.removeOnChangeCallback(childProperties_onChange);
			}
			this._buttonProperties = PropertyProxy(value);
			if(this._buttonProperties)
			{
				this._buttonProperties.addOnChangeCallback(childProperties_onChange);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
			const buttonFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_BUTTON_FACTORY);
			var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);

			if(dataInvalid || buttonFactoryInvalid)
			{
				this.refreshButtons(buttonFactoryInvalid);
			}

			if(dataInvalid || buttonFactoryInvalid || stylesInvalid)
			{
				this.refreshButtonStyles();
			}

			if(dataInvalid || buttonFactoryInvalid || stateInvalid)
			{
				this.commitEnabled();
			}

			sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

			if(sizeInvalid || dataInvalid || buttonFactoryInvalid || stylesInvalid)
			{
				this.layoutButtons();
			}
		}

		/**
		 * @private
		 */
		protected function commitEnabled():void
		{
			for each(var button:Button in this.activeButtons)
			{
				button.isEnabled = this._isEnabled;
			}
		}

		/**
		 * @private
		 */
		protected function refreshButtonStyles():void
		{
			for each(var button:Button in this.activeButtons)
			{
				for(var propertyName:String in this._buttonProperties)
				{
					var propertyValue:Object = this._buttonProperties[propertyName];
					if(button.hasOwnProperty(propertyName))
					{
						button[propertyName] = propertyValue;
					}
				}

				if(button == this.activeFirstButton && this._customFirstButtonName)
				{
					if(!button.nameList.contains(this._customFirstButtonName))
					{
						button.nameList.add(this._customFirstButtonName);
					}
				}
				else if(button == this.activeLastButton && this._customLastButtonName)
				{
					if(!button.nameList.contains(this._customLastButtonName))
					{
						button.nameList.add(this._customLastButtonName);
					}
				}
				else if(this._customButtonName && !button.nameList.contains(this._customButtonName))
				{
					button.nameList.add(this._customButtonName);
				}
			}
		}

		/**
		 * @private
		 */
		protected function defaultButtonInitializer(button:Button, item:Object):void
		{
			if(item is Object)
			{
				if(item.hasOwnProperty("label"))
				{
					button.label = item.label;
				}
				else
				{
					button.label = item.toString();
				}
				for each(var field:String in DEFAULT_BUTTON_FIELDS)
				{
					if(item.hasOwnProperty(field))
					{
						button[field] = item[field];
					}
				}
				for each(field in DEFAULT_BUTTON_EVENTS)
				{
					if(item.hasOwnProperty(field))
					{
						button.addEventListener(field, item[field] as Function);
					}
				}
			}
			else
			{
				button.label = "";
			}

		}

		/**
		 * @private
		 */
		protected function refreshButtons(isFactoryInvalid:Boolean):void
		{
			var temp:Vector.<Button> = this.inactiveButtons;
			this.inactiveButtons = this.activeButtons;
			this.activeButtons = temp;
			this.activeButtons.length = 0;
			temp = null;
			if(isFactoryInvalid)
			{
				this.clearInactiveButtons();
			}
			else
			{
				if(this.activeFirstButton)
				{
					this.inactiveButtons.shift();
				}
				this.inactiveFirstButton = this.activeFirstButton;

				if(this.activeLastButton)
				{
					this.inactiveButtons.pop();
				}
				this.inactiveLastButton = this.activeLastButton;
			}
			this.activeFirstButton = null;
			this.activeLastButton = null;

			const itemCount:int = this._dataProvider ? this._dataProvider.length : 0;
			const lastItemIndex:int = itemCount - 1;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:Object = this._dataProvider.getItemAt(i);
				if(i == 0)
				{
					var button:Button = this.activeFirstButton = this.createFirstButton(item);
				}
				else if(i == lastItemIndex)
				{
					button = this.activeLastButton = this.createLastButton(item);
				}
				else
				{
					button = this.createButton(item);
				}
				this.activeButtons.push(button);
			}
			this.clearInactiveButtons();
		}

		/**
		 * @private
		 */
		protected function clearInactiveButtons():void
		{
			const itemCount:int = this.inactiveButtons.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var button:Button = this.inactiveButtons.shift();
				this.destroyButton(button);
			}

			if(this.inactiveFirstButton)
			{
				this.destroyButton(this.inactiveFirstButton);
				this.inactiveFirstButton = null;
			}

			if(this.inactiveLastButton)
			{
				this.destroyButton(this.inactiveLastButton);
				this.inactiveLastButton = null;
			}
		}

		/**
		 * @private
		 */
		protected function createFirstButton(item:Object):Button
		{
			if(this.inactiveFirstButton)
			{
				var button:Button = this.inactiveFirstButton;
				this.inactiveFirstButton = null;
			}
			else
			{
				const factory:Function = this._firstButtonFactory != null ? this._firstButtonFactory : this._buttonFactory;
				button = Button(factory());
				if(this._customFirstButtonName)
				{
					button.nameList.add(this._customFirstButtonName);
				}
				else
				{
					button.nameList.add(this.firstButtonName);
				}
				this.addChild(button);
			}
			this._buttonInitializer(button, item);
			return button;
		}

		/**
		 * @private
		 */
		protected function createLastButton(item:Object):Button
		{
			if(this.inactiveLastButton)
			{
				var button:Button = this.inactiveLastButton;
				this.inactiveLastButton = null;
			}
			else
			{
				const factory:Function = this._lastButtonFactory != null ? this._lastButtonFactory : this._buttonFactory;
				button = Button(factory());
				if(this._customLastButtonName)
				{
					button.nameList.add(this._customLastButtonName);
				}
				else
				{
					button.nameList.add(this.lastButtonName);
				}
				this.addChild(button);
			}
			this._buttonInitializer(button, item);
			return button;
		}

		/**
		 * @private
		 */
		protected function createButton(item:Object):Button
		{
			if(this.inactiveButtons.length == 0)
			{
				var button:Button = this._buttonFactory();
				if(this._customButtonName)
				{
					button.nameList.add(this._customButtonName);
				}
				else
				{
					button.nameList.add(this.buttonName);
				}
				this.addChild(button);
			}
			else
			{
				button = this.inactiveButtons.shift();
			}
			this._buttonInitializer(button, item);
			return button;
		}

		/**
		 * @private
		 */
		protected function destroyButton(button:Button):void
		{
			this.removeChild(button, true);
		}

		/**
		 * @private
		 */
		protected function autoSizeIfNeeded():Boolean
		{
			const needsWidth:Boolean = isNaN(this.explicitWidth);
			const needsHeight:Boolean = isNaN(this.explicitHeight);
			if(!needsWidth && !needsHeight)
			{
				return false;
			}

			var newWidth:Number = this.explicitWidth;
			var newHeight:Number = this.explicitHeight;
			if(needsWidth)
			{
				newWidth = 0;
				for each(var button:Button in this.activeButtons)
				{
					button.validate();
					newWidth = Math.max(button.width, newWidth);
				}
				if(this._direction == DIRECTION_HORIZONTAL)
				{
					var buttonCount:int = this.activeButtons.length;
					newWidth = buttonCount * (newWidth + this._gap) - this._gap;
					if(!isNaN(this._firstGap) && buttonCount > 1)
					{
						newWidth -= this._gap;
						newWidth += this._firstGap;
					}
					if(!isNaN(this._lastGap) && buttonCount > 2)
					{
						newWidth -= this._gap;
						newWidth += this._lastGap;
					}
				}
			}

			if(needsHeight)
			{
				newHeight = 0;
				for each(button in this.activeButtons)
				{
					button.validate();
					newHeight = Math.max(button.height, newHeight);
				}
				if(this._direction != DIRECTION_HORIZONTAL)
				{
					buttonCount = this.activeButtons.length;
					newHeight = buttonCount * (newHeight + this._gap) - this._gap;
					if(!isNaN(this._firstGap) && buttonCount > 1)
					{
						newHeight -= this._gap;
						newHeight += this._firstGap;
					}
					if(!isNaN(this._lastGap) && buttonCount > 2)
					{
						newHeight -= this._gap;
						newHeight += this._lastGap;
					}
				}
			}
			return this.setSizeInternal(newWidth, newHeight, false);
		}

		/**
		 * @private
		 */
		protected function layoutButtons():void
		{
			const hasFirstGap:Boolean = !isNaN(this._firstGap);
			const hasLastGap:Boolean = !isNaN(this._lastGap);
			const buttonCount:int = this.activeButtons.length;
			const secondToLastIndex:int = buttonCount - 2;
			const totalSize:Number = this._direction == DIRECTION_VERTICAL ? this.actualHeight : this.actualWidth;
			var totalButtonSize:Number = totalSize - (this._gap * (buttonCount - 1));
			if(hasFirstGap)
			{
				totalButtonSize += this._gap - this._firstGap;
			}
			if(hasLastGap)
			{
				totalButtonSize += this._gap - this._lastGap;
			}
			const buttonSize:Number = totalButtonSize / buttonCount;
			var position:Number = 0;
			for(var i:int = 0; i < buttonCount; i++)
			{
				var button:Button = this.activeButtons[i];
				if(this._direction == DIRECTION_VERTICAL)
				{
					button.width = this.actualWidth;
					button.height = buttonSize;
					button.x = 0;
					button.y = position;
					position += button.height;
				}
				else //horizontal
				{
					button.width = buttonSize;
					button.height = this.actualHeight;
					button.x = position;
					button.y = 0;
					position += button.width;
				}

				if(hasFirstGap && i == 0)
				{
					position += this._firstGap;
				}
				else if(hasLastGap && i == secondToLastIndex)
				{
					position += this._lastGap;
				}
				else
				{
					position += this._gap;
				}
			}
		}

		/**
		 * @private
		 */
		protected function childProperties_onChange(proxy:PropertyProxy, name:String):void
		{
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected function dataProvider_changeHandler(event:Event):void
		{
			this.invalidate(INVALIDATION_FLAG_DATA);
		}
	}
}
