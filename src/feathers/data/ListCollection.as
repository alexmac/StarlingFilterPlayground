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
package feathers.data
{
	import feathers.events.CollectionEventType;

	import starling.events.Event;

	import starling.events.EventDispatcher;

	/**
	 * Dispatched when the underlying data source changes and the ui will
	 * need to redraw the data.
	 *
	 * @eventType starling.events.Event.CHANGE
	 */
	[Event(name="change",type="starling.events.Event")]

	/**
	 * Dispatched when the collection has changed drastically, such as when
	 * the underlying data source is replaced completely.
	 *
	 * @eventType feathers.events.CollectionEventType.RESET
	 */
	[Event(name="reset",type="starling.events.Event")]

	/**
	 * Dispatched when an item is added to the collection.
	 *
	 * <p>The <code>data</code> property of the event is the index of the
	 * item that has been updated. It is of type <code>int</code>.</p>
	 *
	 * @eventType feathers.events.CollectionEventType.ADD_ITEM
	 */
	[Event(name="addItem",type="starling.events.Event")]

	/**
	 * Dispatched when an item is removed from the collection.
	 *
	 * <p>The <code>data</code> property of the event is the index of the
	 * item that has been updated. It is of type <code>int</code>.</p>
	 *
	 * @eventType feathers.events.CollectionEventType.REMOVE_ITEM
	 */
	[Event(name="removeItem",type="starling.events.Event")]

	/**
	 * Dispatched when an item is replaced in the collection.
	 *
	 * <p>The <code>data</code> property of the event is the index of the
	 * item that has been updated. It is of type <code>int</code>.</p>
	 *
	 * @eventType feathers.events.CollectionEventType.REPLACE_ITEM
	 */
	[Event(name="replaceItem",type="starling.events.Event")]

	/**
	 * Dispatched when a property of an item in the collection has changed
	 * and the item doesn't have its own change event or signal. This signal
	 * is only dispatched when the <code>updateItemAt()</code> function is
	 * called on the <code>HierarchicalCollection</code>.
	 *
	 * <p>In general, it's better for the items themselves to dispatch events
	 * or signals when their properties change.</p>
	 *
	 * <p>The <code>data</code> property of the event is the index of the
	 * item that has been updated. It is of type <code>int</code>.</p>
	 *
	 * @eventType feathers.events.CollectionEventType.UPDATE_ITEM
	 */
	[Event(name="updateItem",type="starling.events.Event")]

	[DefaultProperty("data")]
	/**
	 * Wraps a data source with a common API for use with UI controls, like
	 * lists, that support one dimensional collections of data. Supports custom
	 * "data descriptors" so that unexpected data sources may be used. Supports
	 * Arrays, Vectors, and XMLLists automatically.
	 * 
	 * @see ArrayListCollectionDataDescriptor
	 * @see VectorListCollectionDataDescriptor
	 * @see XMLListListCollectionDataDescriptor
	 */
	public final class ListCollection extends EventDispatcher
	{
		/**
		 * Constructor
		 */
		public function ListCollection(data:Object = null)
		{
			if(!data)
			{
				//default to an array if no data is provided
				data = [];
			}
			this.data = data;
		}
		
		/**
		 * @private
		 */
		private var _data:Object;
		
		/**
		 * The data source for this collection. May be any type of data, but a
		 * <code>dataDescriptor</code> needs to be provided to translate from
		 * the data source's APIs to something that can be understood by
		 * <code>ListCollection</code>.
		 * 
		 * <p>Data sources of type Array, Vector, and XMLList are automatically
		 * detected, and no <code>dataDescriptor</code> needs to be set if the
		 * <code>ListCollection</code> uses one of these types.</p>
		 */
		public function get data():Object
		{
			return _data;
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
			//we'll automatically detect an array, vector, or xmllist for convenience
			if(this._data is Array && !(this._dataDescriptor is ArrayListCollectionDataDescriptor))
			{
				this.dataDescriptor = new ArrayListCollectionDataDescriptor();
			}
			else if(this._data is Vector.<Number> && !(this._dataDescriptor is VectorNumberListCollectionDataDescriptor))
			{
				this.dataDescriptor = new VectorNumberListCollectionDataDescriptor();
			}
			else if(this._data is Vector.<int> && !(this._dataDescriptor is VectorIntListCollectionDataDescriptor))
			{
				this.dataDescriptor = new VectorIntListCollectionDataDescriptor();
			}
			else if(this._data is Vector.<uint> && !(this._dataDescriptor is VectorUintListCollectionDataDescriptor))
			{
				this.dataDescriptor = new VectorUintListCollectionDataDescriptor();
			}
			else if(this._data is Vector.<*> && !(this._dataDescriptor is VectorListCollectionDataDescriptor))
			{
				this.dataDescriptor = new VectorListCollectionDataDescriptor();
			}
			else if(this._data is XMLList && !(this._dataDescriptor is XMLListListCollectionDataDescriptor))
			{
				this.dataDescriptor = new XMLListListCollectionDataDescriptor();
			}
			this.dispatchEventWith(CollectionEventType.RESET);
			this.dispatchEventWith(Event.CHANGE);
		}
		
		/**
		 * @private
		 */
		private var _dataDescriptor:IListCollectionDataDescriptor;

		/**
		 * Describes the underlying data source by translating APIs.
		 * 
		 * @see IListCollectionDataDescriptor
		 */
		public function get dataDescriptor():IListCollectionDataDescriptor
		{
			return this._dataDescriptor;
		}
		
		/**
		 * @private
		 */
		public function set dataDescriptor(value:IListCollectionDataDescriptor):void
		{
			if(this._dataDescriptor == value)
			{
				return;
			}
			this._dataDescriptor = value;
			this.dispatchEventWith(CollectionEventType.RESET);
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * The number of items in the collection.
		 */
		public function get length():int
		{
			return this._dataDescriptor.getLength(this._data);
		}

		/**
		 * If an item doesn't dispatch an event or signal to indicate that it
		 * has changed, you can manually tell the collection about the change,
		 * and the collection will dispatch the <code>onItemUpdate</code> signal
		 * to manually notify the component that renders the data.
		 */
		public function updateItemAt(index:int):void
		{
			this.dispatchEventWith(CollectionEventType.UPDATE_ITEM, false, index);
		}
		
		/**
		 * Returns the item at the specified index in the collection.
		 */
		public function getItemAt(index:int):Object
		{
			return this._dataDescriptor.getItemAt(this._data, index);
		}
		
		/**
		 * Determines which index the item appears at within the collection. If
		 * the item isn't in the collection, returns <code>-1</code>.
		 */
		public function getItemIndex(item:Object):int
		{
			return this._dataDescriptor.getItemIndex(this._data, item);
		}
		
		/**
		 * Adds an item to the collection, at the specified index.
		 */
		public function addItemAt(item:Object, index:int):void
		{
			this._dataDescriptor.addItemAt(this._data, item, index);
			this.dispatchEventWith(Event.CHANGE);
			this.dispatchEventWith(CollectionEventType.ADD_ITEM, false, index);
		}
		
		/**
		 * Removes the item at the specified index from the collection and
		 * returns it.
		 */
		public function removeItemAt(index:int):Object
		{
			const item:Object = this._dataDescriptor.removeItemAt(this._data, index);
			this.dispatchEventWith(Event.CHANGE);
			this.dispatchEventWith(CollectionEventType.REMOVE_ITEM, false, index);
			return item;
		}
		
		/**
		 * Removes a specific item from the collection.
		 */
		public function removeItem(item:Object):void
		{
			const index:int = this.getItemIndex(item);
			if(index >= 0)
			{
				this.removeItemAt(index);
			}
		}
		
		/**
		 * Replaces the item at the specified index with a new item.
		 */
		public function setItemAt(item:Object, index:int):void
		{
			this._dataDescriptor.setItemAt(this._data, item, index);
			this.dispatchEventWith(Event.CHANGE);
			this.dispatchEventWith(CollectionEventType.REPLACE_ITEM, false, index);
		}
		
		/**
		 * Adds an item to the end of the collection.
		 */
		public function push(item:Object):void
		{
			this.addItemAt(item, this.length);
		}
		
		/**
		 * Removes the item from the end of the collection and returns it.
		 */
		public function pop():Object
		{
			return this.removeItemAt(this.length - 1);
		}
		
		/**
		 * Adds an item to the beginning of the collection.
		 */
		public function unshift(item:Object):void
		{
			this.addItemAt(item, 0);
		}
		
		/**
		 * Removed the item from the beginning of the collection and returns it. 
		 */
		public function shift():Object
		{
			return this.removeItemAt(0);
		}
	}
}