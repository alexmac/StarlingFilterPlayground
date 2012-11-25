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
package feathers.core
{
	import flash.errors.IllegalOperationError;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	/**
	 * Dispatched when the selection changes.
	 *
	 * @eventType starling.events.Event.CHANGE
	 */
	[Event(name="change",type="starling.events.Event")]

	/**
	 * Controls the selection of two or more IToggle instances where only one
	 * may be selected at a time.
	 * 
	 * @see IToggle
	 */
	public class ToggleGroup extends EventDispatcher
	{
		/**
		 * Constructor.
		 */
		public function ToggleGroup()
		{
		}

		/**
		 * @private
		 */
		protected var _items:Vector.<IToggle> = new Vector.<IToggle>;

		/**
		 * @private
		 */
		protected var _ignoreChanges:Boolean = false;

		/**
		 * @private
		 */
		protected var _isSelectionRequired:Boolean = true;

		/**
		 * Determines if the user can deselect the currently selected item or
		 * not. The selection may always be cleared programmatically by setting
		 * the selected index to <code>-1</code> or the selected item to
		 * <code>null</code>.
		 *
		 * <p>If <code>isSelectionRequired</code> is set to <code>true</code>
		 * and the toggle group has items that were added previously, and there
		 * is no currently selected item, the item at index <code>0</code> will
		 * be selected automatically.</p>
		 */
		public function get isSelectionRequired():Boolean
		{
			return this._isSelectionRequired;
		}

		/**
		 * @private
		 */
		public function set isSelectionRequired(value:Boolean):void
		{
			if(this._isSelectionRequired == value)
			{
				return;
			}
			this._isSelectionRequired = value;
			if(this._isSelectionRequired && this._selectedIndex < 0 && this._items.length > 0)
			{
				this.selectedIndex = 0;
			}
		}
		
		/**
		 * The currently selected toggle.
		 */
		public function get selectedItem():IToggle
		{
			if(this._selectedIndex < 0)
			{
				return null;
			}
			return this._items[this._selectedIndex];
		}
		
		/**
		 * @private
		 */
		public function set selectedItem(value:IToggle):void
		{
			this.selectedIndex = this._items.indexOf(value);
		}
		
		/**
		 * @private
		 */
		protected var _selectedIndex:int = -1;
		
		/**
		 * The index of the currently selected toggle.
		 */
		public function get selectedIndex():int
		{
			return this._selectedIndex;
		}
		
		/**
		 * @private
		 */
		public function set selectedIndex(value:int):void
		{
			const itemCount:int = this._items.length;
			if(value < -1 || value >= itemCount)
			{
				throw new RangeError("Index " + value + " is out of range " + itemCount + " for ToggleGroup.");
			}
			const hasChanged:Boolean = this._selectedIndex != value;
			this._selectedIndex = value;

			//refresh all the items
			this._ignoreChanges = true;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:IToggle = this._items[i];
				item.isSelected = i == value;
			}
			this._ignoreChanges = false;
			if(hasChanged)
			{
				//only dispatch if there's been a change. we didn't return
				//early because this setter could be called if an item is
				//unselected. if selection is required, we need to reselect the
				//item (happens below in the item's onChange listener).
				this.dispatchEventWith(Event.CHANGE);
			}
		}
		
		/**
		 * Adds a toggle to the group. If it is the first item added to the
		 * group, and <code>isSelectionRequired</code> is <code>true</code>, it
		 * will be selected automatically.
		 */
		public function addItem(item:IToggle):void
		{
			if(!item)
			{
				throw new ArgumentError("IToggle passed to ToggleGroup addItem() must not be null.");
			}
			
			const index:int = this._items.indexOf(item);
			if(index >= 0)
			{
				throw new IllegalOperationError("Cannot add an item to a ToggleGroup more than once.");
			}
			this._items.push(item);
			if(this._selectedIndex < 0 && this._isSelectionRequired)
			{
				this.selectedItem = item;
			}
			else
			{
				item.isSelected = false;
			}
			item.addEventListener(Event.CHANGE, item_changeHandler);

			if(item is IGroupedToggle)
			{
				IGroupedToggle(item).toggleGroup = this;
			}
		}
		
		/**
		 * Removes a toggle from the group. If the item being removed is
		 * selected and <code>isSelectionRequired</code> is <code>true</code>,
		 * the final item will be selected. If <code>isSelectionRequired</code>
		 * is <code>false</code> instead, no item will be selected.
		 */
		public function removeItem(item:IToggle):void
		{
			const index:int = this._items.indexOf(item);
			if(index < 0)
			{
				return;
			}
			this._items.splice(index, 1);
			item.removeEventListener(Event.CHANGE, item_changeHandler);
			if(item is IGroupedToggle)
			{
				IGroupedToggle(item).toggleGroup = null;
			}
			if(this._selectedIndex >= this._items.length)
			{
				if(this._isSelectionRequired)
				{
					this.selectedIndex = this._items.length - 1;
				}
				else
				{
					this.selectedIndex = -1;
				}
			}
		}

		/**
		 * Removes all toggles from the group. No item will be selected.
		 */
		public function removeAllItems():void
		{
			const itemCount:int = this._items.length;
			for(var i:int = 0; i < itemCount; i++)
			{
				var item:IToggle = this._items.shift();
				item.removeEventListener(Event.CHANGE, item_changeHandler);
				if(item is IGroupedToggle)
				{
					IGroupedToggle(item).toggleGroup = null;
				}
			}
			this.selectedIndex = -1;
		}

		/**
		 * Determines if the group includes the specified item.
		 */
		public function hasItem(item:IToggle):Boolean
		{
			const index:int = this._items.indexOf(item);
			return index >= 0;
		}
		
		/**
		 * @private
		 */
		protected function item_changeHandler(event:Event):void
		{
			if(this._ignoreChanges)
			{
				return;
			}

			const item:IToggle = IToggle(event.currentTarget);
			const index:int = this._items.indexOf(item);
			if(item.isSelected || (this._isSelectionRequired && this._selectedIndex == index))
			{
				//don't let it deselect the item
				this.selectedIndex = index;
			}
			else if(!item.isSelected)
			{
				this.selectedIndex = -1;
			}
		}
		
	}
}