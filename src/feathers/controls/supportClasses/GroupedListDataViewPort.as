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
package feathers.controls.supportClasses
{
	import feathers.controls.GroupedList;
	import feathers.controls.Scroller;
	import feathers.controls.renderers.IGroupedListHeaderOrFooterRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.core.FeathersControl;
	import feathers.core.IFeathersControl;
	import feathers.core.PropertyProxy;
	import feathers.data.HierarchicalCollection;
	import feathers.events.CollectionEventType;
	import feathers.events.FeathersEventType;
	import feathers.layout.ILayout;
	import feathers.layout.IVariableVirtualLayout;
	import feathers.layout.IVirtualLayout;
	import feathers.layout.LayoutBoundsResult;
	import feathers.layout.ViewPortBounds;

	import flash.geom.Point;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	/**
	 * @private
	 * Used internally by GroupedList. Not meant to be used on its own.
	 */
	public final class GroupedListDataViewPort extends FeathersControl implements IViewPort
	{
		private static const INVALIDATION_FLAG_ITEM_RENDERER_FACTORY:String = "itemRendererFactory";

		private static const HELPER_POINT:Point = new Point();
		private static const HELPER_BOUNDS:ViewPortBounds = new ViewPortBounds();
		private static const HELPER_LAYOUT_RESULT:LayoutBoundsResult = new LayoutBoundsResult();
		private static const HELPER_VECTOR:Vector.<int> = new <int>[];

		public function GroupedListDataViewPort()
		{
			super();
			this.addEventListener(TouchEvent.TOUCH, touchHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		}

		private var touchPointID:int = -1;

		private var _minVisibleWidth:Number = 0;

		public function get minVisibleWidth():Number
		{
			return this._minVisibleWidth;
		}

		public function set minVisibleWidth(value:Number):void
		{
			if(this._minVisibleWidth == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("minVisibleWidth cannot be NaN");
			}
			this._minVisibleWidth = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var _maxVisibleWidth:Number = Number.POSITIVE_INFINITY;

		public function get maxVisibleWidth():Number
		{
			return this._maxVisibleWidth;
		}

		public function set maxVisibleWidth(value:Number):void
		{
			if(this._maxVisibleWidth == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("maxVisibleWidth cannot be NaN");
			}
			this._maxVisibleWidth = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var actualVisibleWidth:Number = NaN;

		private var explicitVisibleWidth:Number = NaN;

		public function get visibleWidth():Number
		{
			return this.actualVisibleWidth;
		}

		public function set visibleWidth(value:Number):void
		{
			if(this.explicitVisibleWidth == value || (isNaN(value) && isNaN(this.explicitVisibleWidth)))
			{
				return;
			}
			this.explicitVisibleWidth = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var _minVisibleHeight:Number = 0;

		public function get minVisibleHeight():Number
		{
			return this._minVisibleHeight;
		}

		public function set minVisibleHeight(value:Number):void
		{
			if(this._minVisibleHeight == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("minVisibleHeight cannot be NaN");
			}
			this._minVisibleHeight = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var _maxVisibleHeight:Number = Number.POSITIVE_INFINITY;

		public function get maxVisibleHeight():Number
		{
			return this._maxVisibleHeight;
		}

		public function set maxVisibleHeight(value:Number):void
		{
			if(this._maxVisibleHeight == value)
			{
				return;
			}
			if(isNaN(value))
			{
				throw new ArgumentError("maxVisibleHeight cannot be NaN");
			}
			this._maxVisibleHeight = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		private var actualVisibleHeight:Number;

		private var explicitVisibleHeight:Number = NaN;

		public function get visibleHeight():Number
		{
			return this.actualVisibleHeight;
		}

		public function set visibleHeight(value:Number):void
		{
			if(this.explicitVisibleHeight == value || (isNaN(value) && isNaN(this.explicitVisibleHeight)))
			{
				return;
			}
			this.explicitVisibleHeight = value;
			this.invalidate(INVALIDATION_FLAG_SIZE);
		}

		public function get horizontalScrollStep():Number
		{
			return this._typicalItemWidth;
		}

		public function get verticalScrollStep():Number
		{
			return this._typicalItemHeight;
		}

		private var _typicalItemWidth:Number = NaN;

		public function get typicalItemWidth():Number
		{
			return this._typicalItemWidth;
		}

		private var _typicalItemHeight:Number = NaN;

		public function get typicalItemHeight():Number
		{
			return this._typicalItemHeight;
		}

		private var _typicalHeaderWidth:Number = NaN;

		public function get typicalHeaderWidth():Number
		{
			return this._typicalHeaderWidth;
		}

		private var _typicalHeaderHeight:Number = NaN;

		public function get typicalHeaderHeight():Number
		{
			return this._typicalHeaderHeight;
		}

		private var _typicalFooterWidth:Number = NaN;

		public function get typicalFooterWidth():Number
		{
			return this._typicalFooterWidth;
		}

		private var _typicalFooterHeight:Number = NaN;

		public function get typicalFooterHeight():Number
		{
			return this._typicalFooterHeight;
		}

		private var _layoutItems:Vector.<DisplayObject> = new <DisplayObject>[];

		private var _unrenderedItems:Vector.<int> = new <int>[];
		private var _inactiveItemRenderers:Vector.<IGroupedListItemRenderer> = new <IGroupedListItemRenderer>[];
		private var _activeItemRenderers:Vector.<IGroupedListItemRenderer> = new <IGroupedListItemRenderer>[];
		private var _itemRendererMap:Dictionary = new Dictionary(true);

		private var _unrenderedFirstItems:Vector.<int>;
		private var _inactiveFirstItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _activeFirstItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _firstItemRendererMap:Dictionary = new Dictionary(true);

		private var _unrenderedLastItems:Vector.<int>;
		private var _inactiveLastItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _activeLastItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _lastItemRendererMap:Dictionary;

		private var _unrenderedSingleItems:Vector.<int>;
		private var _inactiveSingleItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _activeSingleItemRenderers:Vector.<IGroupedListItemRenderer>;
		private var _singleItemRendererMap:Dictionary;

		private var _unrenderedHeaders:Vector.<int> = new <int>[];
		private var _inactiveHeaderRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _activeHeaderRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _headerRendererMap:Dictionary = new Dictionary(true);

		private var _unrenderedFooters:Vector.<int> = new <int>[];
		private var _inactiveFooterRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _activeFooterRenderers:Vector.<IGroupedListHeaderOrFooterRenderer> = new <IGroupedListHeaderOrFooterRenderer>[];
		private var _footerRendererMap:Dictionary = new Dictionary(true);

		private var _headerIndices:Vector.<int> = new <int>[];
		private var _footerIndices:Vector.<int> = new <int>[];

		private var _isScrolling:Boolean = false;

		private var _owner:GroupedList;

		public function get owner():GroupedList
		{
			return this._owner;
		}

		public function set owner(value:GroupedList):void
		{
			if(this._owner == value)
			{
				return;
			}
			if(this._owner)
			{
				this._owner.removeEventListener(Event.SCROLL, owner_scrollHandler);
			}
			this._owner = value;
			if(this._owner)
			{
				this._owner.addEventListener(Event.SCROLL, owner_scrollHandler);
			}
		}

		private var _dataProvider:HierarchicalCollection;

		public function get dataProvider():HierarchicalCollection
		{
			return this._dataProvider;
		}

		public function set dataProvider(value:HierarchicalCollection):void
		{
			if(this._dataProvider == value)
			{
				return;
			}
			if(this._dataProvider)
			{
				this._dataProvider.removeEventListener(Event.CHANGE, dataProvider_changeHandler);
				this._dataProvider.removeEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
			}
			this._dataProvider = value;
			if(this._dataProvider)
			{
				this._dataProvider.addEventListener(Event.CHANGE, dataProvider_changeHandler);
				this._dataProvider.addEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
			}
			this.invalidate(INVALIDATION_FLAG_DATA);
		}

		private var _isSelectable:Boolean = true;

		public function get isSelectable():Boolean
		{
			return this._isSelectable;
		}

		public function set isSelectable(value:Boolean):void
		{
			if(this._isSelectable == value)
			{
				return;
			}
			this._isSelectable = value;
			if(!this._isSelectable)
			{
				this.setSelectedLocation(-1, -1);
			}
			this.invalidate(INVALIDATION_FLAG_SELECTED);
		}

		private var _selectedGroupIndex:int = -1;

		public function get selectedGroupIndex():int
		{
			return this._selectedGroupIndex;
		}

		private var _selectedItemIndex:int = -1;

		public function get selectedItemIndex():int
		{
			return this._selectedItemIndex;
		}

		private var _itemRendererType:Class;

		public function get itemRendererType():Class
		{
			return this._itemRendererType;
		}

		public function set itemRendererType(value:Class):void
		{
			if(this._itemRendererType == value)
			{
				return;
			}

			this._itemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _itemRendererFactory:Function;

		public function get itemRendererFactory():Function
		{
			return this._itemRendererFactory;
		}

		public function set itemRendererFactory(value:Function):void
		{
			if(this._itemRendererFactory === value)
			{
				return;
			}

			this._itemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _itemRendererName:String;

		public function get itemRendererName():String
		{
			return this._itemRendererName;
		}

		public function set itemRendererName(value:String):void
		{
			if(this._itemRendererName == value)
			{
				return;
			}
			this._itemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _typicalItem:Object = null;

		public function get typicalItem():Object
		{
			return this._typicalItem;
		}

		public function set typicalItem(value:Object):void
		{
			if(this._typicalItem == value)
			{
				return;
			}
			this._typicalItem = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _itemRendererProperties:PropertyProxy;

		public function get itemRendererProperties():PropertyProxy
		{
			return this._itemRendererProperties;
		}

		public function set itemRendererProperties(value:PropertyProxy):void
		{
			if(this._itemRendererProperties == value)
			{
				return;
			}
			if(this._itemRendererProperties)
			{
				this._itemRendererProperties.removeOnChangeCallback(childProperties_onChange);
			}
			this._itemRendererProperties = PropertyProxy(value);
			if(this._itemRendererProperties)
			{
				this._itemRendererProperties.addOnChangeCallback(childProperties_onChange);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _firstItemRendererType:Class;

		public function get firstItemRendererType():Class
		{
			return this._firstItemRendererType;
		}

		public function set firstItemRendererType(value:Class):void
		{
			if(this._firstItemRendererType == value)
			{
				return;
			}

			this._firstItemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _firstItemRendererFactory:Function;

		public function get firstItemRendererFactory():Function
		{
			return this._firstItemRendererFactory;
		}

		public function set firstItemRendererFactory(value:Function):void
		{
			if(this._firstItemRendererFactory === value)
			{
				return;
			}

			this._firstItemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _firstItemRendererName:String;

		public function get firstItemRendererName():String
		{
			return this._firstItemRendererName;
		}

		public function set firstItemRendererName(value:String):void
		{
			if(this._firstItemRendererName == value)
			{
				return;
			}
			this._firstItemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _lastItemRendererType:Class;

		public function get lastItemRendererType():Class
		{
			return this._lastItemRendererType;
		}

		public function set lastItemRendererType(value:Class):void
		{
			if(this._lastItemRendererType == value)
			{
				return;
			}

			this._lastItemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _lastItemRendererFactory:Function;

		public function get lastItemRendererFactory():Function
		{
			return this._lastItemRendererFactory;
		}

		public function set lastItemRendererFactory(value:Function):void
		{
			if(this._lastItemRendererFactory === value)
			{
				return;
			}

			this._lastItemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _lastItemRendererName:String;

		public function get lastItemRendererName():String
		{
			return this._lastItemRendererName;
		}

		public function set lastItemRendererName(value:String):void
		{
			if(this._lastItemRendererName == value)
			{
				return;
			}
			this._lastItemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _singleItemRendererType:Class;

		public function get singleItemRendererType():Class
		{
			return this._singleItemRendererType;
		}

		public function set singleItemRendererType(value:Class):void
		{
			if(this._singleItemRendererType == value)
			{
				return;
			}

			this._singleItemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _singleItemRendererFactory:Function;

		public function get singleItemRendererFactory():Function
		{
			return this._singleItemRendererFactory;
		}

		public function set singleItemRendererFactory(value:Function):void
		{
			if(this._singleItemRendererFactory === value)
			{
				return;
			}

			this._singleItemRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _singleItemRendererName:String;

		public function get singleItemRendererName():String
		{
			return this._singleItemRendererName;
		}

		public function set singleItemRendererName(value:String):void
		{
			if(this._singleItemRendererName == value)
			{
				return;
			}
			this._singleItemRendererName = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _headerRendererType:Class;

		public function get headerRendererType():Class
		{
			return this._headerRendererType;
		}

		public function set headerRendererType(value:Class):void
		{
			if(this._headerRendererType == value)
			{
				return;
			}

			this._headerRendererType = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _headerRendererFactory:Function;

		public function get headerRendererFactory():Function
		{
			return this._headerRendererFactory;
		}

		public function set headerRendererFactory(value:Function):void
		{
			if(this._headerRendererFactory === value)
			{
				return;
			}

			this._headerRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _headerRendererName:String;

		public function get headerRendererName():String
		{
			return this._headerRendererName;
		}

		public function set headerRendererName(value:String):void
		{
			if(this._headerRendererName == value)
			{
				return;
			}
			this._headerRendererName = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _typicalHeader:Object = null;

		public function get typicalHeader():Object
		{
			return this._typicalHeader;
		}

		public function set typicalHeader(value:Object):void
		{
			if(this._typicalHeader == value)
			{
				return;
			}
			this._typicalHeader = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _headerRendererProperties:PropertyProxy;

		public function get headerRendererProperties():PropertyProxy
		{
			return this._headerRendererProperties;
		}

		public function set headerRendererProperties(value:PropertyProxy):void
		{
			if(this._headerRendererProperties == value)
			{
				return;
			}
			if(this._headerRendererProperties)
			{
				this._headerRendererProperties.removeOnChangeCallback(childProperties_onChange);
			}
			this._headerRendererProperties = PropertyProxy(value);
			if(this._headerRendererProperties)
			{
				this._headerRendererProperties.addOnChangeCallback(childProperties_onChange);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _footerRendererType:Class;

		public function get footerRendererType():Class
		{
			return this._footerRendererType;
		}

		public function set footerRendererType(value:Class):void
		{
			if(this._footerRendererType == value)
			{
				return;
			}

			this._footerRendererType = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _footerRendererFactory:Function;

		public function get footerRendererFactory():Function
		{
			return this._footerRendererFactory;
		}

		public function set footerRendererFactory(value:Function):void
		{
			if(this._footerRendererFactory === value)
			{
				return;
			}

			this._footerRendererFactory = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _footerRendererName:String;

		public function get footerRendererName():String
		{
			return this._footerRendererName;
		}

		public function set footerRendererName(value:String):void
		{
			if(this._footerRendererName == value)
			{
				return;
			}
			this._footerRendererName = value;
			this.invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		}

		private var _typicalFooter:Object = null;

		public function get typicalFooter():Object
		{
			return this._typicalFooter;
		}

		public function set typicalFooter(value:Object):void
		{
			if(this._typicalFooter == value)
			{
				return;
			}
			this._typicalFooter = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _footerRendererProperties:PropertyProxy;

		public function get footerRendererProperties():PropertyProxy
		{
			return this._footerRendererProperties;
		}

		public function set footerRendererProperties(value:PropertyProxy):void
		{
			if(this._footerRendererProperties == value)
			{
				return;
			}
			if(this._footerRendererProperties)
			{
				this._footerRendererProperties.removeOnChangeCallback(childProperties_onChange);
			}
			this._footerRendererProperties = PropertyProxy(value);
			if(this._footerRendererProperties)
			{
				this._footerRendererProperties.addOnChangeCallback(childProperties_onChange);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		private var _ignoreLayoutChanges:Boolean = false;
		private var _ignoreRendererResizing:Boolean = false;

		private var _layout:ILayout;

		public function get layout():ILayout
		{
			return this._layout;
		}

		public function set layout(value:ILayout):void
		{
			if(this._layout == value)
			{
				return;
			}
			if(this._layout)
			{
				EventDispatcher(this._layout).removeEventListener(Event.CHANGE, layout_changeHandler);
			}
			this._layout = value;
			if(this._layout)
			{
				if(this._layout is IVariableVirtualLayout)
				{
					IVariableVirtualLayout(this._layout).hasVariableItemDimensions = true;
				}
				EventDispatcher(this._layout).addEventListener(Event.CHANGE, layout_changeHandler);
			}
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _horizontalScrollPosition:Number = 0;

		public function get horizontalScrollPosition():Number
		{
			return this._horizontalScrollPosition;
		}

		public function set horizontalScrollPosition(value:Number):void
		{
			if(this._horizontalScrollPosition == value)
			{
				return;
			}
			this._horizontalScrollPosition = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _verticalScrollPosition:Number = 0;

		public function get verticalScrollPosition():Number
		{
			return this._verticalScrollPosition;
		}

		public function set verticalScrollPosition(value:Number):void
		{
			if(this._verticalScrollPosition == value)
			{
				return;
			}
			this._verticalScrollPosition = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private var _minimumItemCount:int;
		private var _minimumHeaderCount:int;
		private var _minimumFooterCount:int;
		private var _minimumFirstAndLastItemCount:int;
		private var _minimumSingleItemCount:int;

		private var _ignoreSelectionChanges:Boolean = false;

		public function setSelectedLocation(groupIndex:int, itemIndex:int):void
		{
			if(this._selectedGroupIndex == groupIndex && this._selectedItemIndex == itemIndex)
			{
				return;
			}
			if((groupIndex < 0 && itemIndex >= 0) || (groupIndex >= 0 && itemIndex < 0))
			{
				throw new ArgumentError("To deselect items, group index and item index must both be < 0.");
			}
			this._selectedGroupIndex = groupIndex;
			this._selectedItemIndex = itemIndex;

			this.invalidate(INVALIDATION_FLAG_SELECTED);
			this.dispatchEventWith(Event.CHANGE);
		}

		public function getScrollPositionForIndex(groupIndex:int, itemIndex:int, result:Point = null):Point
		{
			if(!result)
			{
				result = new Point();
			}

			const displayIndex:int = this.locationToDisplayIndex(groupIndex, itemIndex);
			return this._layout.getScrollPositionForIndex(displayIndex, this._layoutItems, 0, 0, this.actualVisibleWidth, this.actualVisibleHeight, result);
		}

		override protected function draw():void
		{
			const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
			const scrollInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SCROLL);
			const sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
			const selectionInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SELECTED);
			const itemRendererInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);

			if(stylesInvalid || dataInvalid || itemRendererInvalid)
			{
				if(this._layout is IVariableVirtualLayout)
				{
					IVariableVirtualLayout(this._layout).resetVariableVirtualCache();
				}
				this.calculateTypicalValues();
			}

			if(scrollInvalid || sizeInvalid || dataInvalid || itemRendererInvalid)
			{
				this.refreshRenderers(itemRendererInvalid);
			}
			if(scrollInvalid || sizeInvalid || dataInvalid || stylesInvalid || itemRendererInvalid)
			{
				this.refreshHeaderRendererStyles();
				this.refreshFooterRendererStyles();
				this.refreshItemRendererStyles();
			}
			if(scrollInvalid || selectionInvalid || sizeInvalid || dataInvalid || itemRendererInvalid)
			{
				this.refreshSelection();
			}

			if(scrollInvalid || stateInvalid || sizeInvalid || dataInvalid || itemRendererInvalid)
			{
				this.refreshEnabled();
			}

			this.validateRenderers();
			if(scrollInvalid || dataInvalid || itemRendererInvalid || sizeInvalid)
			{
				this._ignoreRendererResizing = true;
				this._layout.layout(this._layoutItems, HELPER_BOUNDS, HELPER_LAYOUT_RESULT);
				this._ignoreRendererResizing = false;
				this.setSizeInternal(HELPER_LAYOUT_RESULT.contentWidth, HELPER_LAYOUT_RESULT.contentHeight, false);
				this.actualVisibleWidth = HELPER_LAYOUT_RESULT.viewPortWidth;
				this.actualVisibleHeight = HELPER_LAYOUT_RESULT.viewPortHeight;
			}
		}

		private function refreshEnabled():void
		{
			var rendererCount:int = this._activeItemRenderers.length;
			for(var i:int = 0; i < rendererCount; i++)
			{
				var renderer:DisplayObject = DisplayObject(this._activeItemRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).isEnabled = this._isEnabled;
				}
			}
			if(this._activeFirstItemRenderers)
			{
				rendererCount = this._activeFirstItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(this._activeFirstItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).isEnabled = this._isEnabled;
					}
				}
			}
			if(this._activeLastItemRenderers)
			{
				rendererCount = this._activeLastItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(this._activeLastItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).isEnabled = this._isEnabled;
					}
				}
			}
			if(this._activeSingleItemRenderers)
			{
				rendererCount = this._activeSingleItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(this._activeSingleItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).isEnabled = this._isEnabled;
					}
				}
			}
			rendererCount = this._activeHeaderRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				renderer = DisplayObject(this._activeHeaderRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).isEnabled = this._isEnabled;
				}
			}
			rendererCount = this._activeFooterRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				renderer = DisplayObject(this._activeFooterRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).isEnabled = this._isEnabled;
				}
			}
		}

		private function validateRenderers():void
		{
			var rendererCount:int = this._activeItemRenderers.length;
			for(var i:int = 0; i < rendererCount; i++)
			{
				var renderer:DisplayObject = DisplayObject(this._activeItemRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).validate();
				}
			}
			if(this._activeFirstItemRenderers)
			{
				rendererCount = this._activeFirstItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(this._activeFirstItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).validate();
					}
				}
			}
			if(this._activeLastItemRenderers)
			{
				rendererCount = this._activeLastItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(this._activeLastItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).validate();
					}
				}
			}
			if(this._activeSingleItemRenderers)
			{
				rendererCount = this._activeSingleItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					renderer = DisplayObject(this._activeSingleItemRenderers[i]);
					if(renderer is FeathersControl)
					{
						FeathersControl(renderer).validate();
					}
				}
			}
			rendererCount = this._activeHeaderRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				renderer = DisplayObject(this._activeHeaderRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).validate();
				}
			}
			rendererCount = this._activeFooterRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				renderer = DisplayObject(this._activeFooterRenderers[i]);
				if(renderer is FeathersControl)
				{
					FeathersControl(renderer).validate();
				}
			}
		}
		
		private function invalidateParent():void
		{
			Scroller(this.parent.parent).invalidate(INVALIDATION_FLAG_DATA);
		}

		private function calculateTypicalValues():void
		{
			var typicalHeader:Object = this._typicalHeader;
			var typicalFooter:Object = this._typicalFooter;
			if(!typicalHeader || !typicalFooter)
			{
				if(this._dataProvider && this._dataProvider.getLength() > 0)
				{
					var group:Object = this._dataProvider.getItemAt(0);
					if(!typicalHeader)
					{
						typicalHeader = this._owner.groupToHeaderData(group);
					}
					if(!typicalFooter)
					{
						typicalFooter = this._owner.groupToFooterData(group);
					}
				}
				else
				{
					this._typicalHeaderWidth = 0;
					this._typicalFooterWidth = 0;
					this._typicalFooterHeight= 0;
					this._typicalHeaderHeight = 0;
				}
			}

			//headers are optional
			if(typicalHeader)
			{
				const typicalHeaderRenderer:IGroupedListHeaderOrFooterRenderer = this.createHeaderRenderer(typicalHeader, 0, 0, true);
				this.refreshOneHeaderRendererStyles(typicalHeaderRenderer);
				if(typicalHeaderRenderer is FeathersControl)
				{
					FeathersControl(typicalHeaderRenderer).validate();
				}
				var displayRenderer:DisplayObject = DisplayObject(typicalHeaderRenderer);
				this._typicalHeaderWidth = displayRenderer.width;
				this._typicalHeaderHeight = displayRenderer.height;
				this.destroyHeaderRenderer(typicalHeaderRenderer);
			}

			//footers are optional
			if(typicalFooter)
			{
				const typicalFooterRenderer:IGroupedListHeaderOrFooterRenderer = this.createFooterRenderer(typicalFooter, 0, 0, true);
				this.refreshOneFooterRendererStyles(typicalFooterRenderer);
				if(typicalFooterRenderer is FeathersControl)
				{
					FeathersControl(typicalFooterRenderer).validate();
				}
				displayRenderer = DisplayObject(typicalFooterRenderer);
				this._typicalFooterWidth = displayRenderer.width;
				this._typicalFooterHeight = displayRenderer.height;
				this.destroyFooterRenderer(typicalFooterRenderer);
			}

			var typicalItem:Object = this._typicalItem;
			if(!typicalItem)
			{
				if(this._dataProvider && this._dataProvider.getLength() > 0)
				{
					typicalItem = this._dataProvider.getItemAt(0);
				}
				else
				{
					this._typicalItemWidth = 0;
					this._typicalItemHeight = 0;
					return;
				}
			}

			const typicalItemRenderer:IGroupedListItemRenderer = this.createItemRenderer(this._inactiveItemRenderers,
				this._activeItemRenderers, this._itemRendererMap, this._itemRendererType, this._itemRendererFactory,
				this._itemRendererName, typicalItem, 0, 0, 0, true);
			this.refreshOneItemRendererStyles(typicalItemRenderer);
			if(typicalItemRenderer is FeathersControl)
			{
				FeathersControl(typicalItemRenderer).validate();
			}
			displayRenderer = DisplayObject(typicalItemRenderer);
			this._typicalItemWidth = displayRenderer.width;
			this._typicalItemHeight = displayRenderer.height;
			this.destroyItemRenderer(typicalItemRenderer);
		}

		private function refreshItemRendererStyles():void
		{
			for each(var renderer:IGroupedListItemRenderer in this._activeItemRenderers)
			{
				this.refreshOneItemRendererStyles(renderer);
			}
			for each(renderer in this._activeFirstItemRenderers)
			{
				this.refreshOneItemRendererStyles(renderer);
			}
			for each(renderer in this._activeLastItemRenderers)
			{
				this.refreshOneItemRendererStyles(renderer);
			}
			for each(renderer in this._activeSingleItemRenderers)
			{
				this.refreshOneItemRendererStyles(renderer);
			}
		}

		private function refreshHeaderRendererStyles():void
		{
			for each(var renderer:IGroupedListHeaderOrFooterRenderer in this._activeHeaderRenderers)
			{
				this.refreshOneHeaderRendererStyles(renderer);
			}
		}

		private function refreshFooterRendererStyles():void
		{
			for each(var renderer:IGroupedListHeaderOrFooterRenderer in this._activeFooterRenderers)
			{
				this.refreshOneFooterRendererStyles(renderer);
			}
		}

		private function refreshOneItemRendererStyles(renderer:IGroupedListItemRenderer):void
		{
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			for(var propertyName:String in this._itemRendererProperties)
			{
				if(displayRenderer.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._itemRendererProperties[propertyName];
					displayRenderer[propertyName] = propertyValue;
				}
			}
		}

		private function refreshOneHeaderRendererStyles(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			for(var propertyName:String in this._headerRendererProperties)
			{
				if(displayRenderer.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._headerRendererProperties[propertyName];
					displayRenderer[propertyName] = propertyValue;
				}
			}
		}

		private function refreshOneFooterRendererStyles(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			for(var propertyName:String in this._footerRendererProperties)
			{
				if(displayRenderer.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._footerRendererProperties[propertyName];
					displayRenderer[propertyName] = propertyValue;
				}
			}
		}

		private function refreshSelection():void
		{
			this._ignoreSelectionChanges = true;
			for each(var renderer:IGroupedListItemRenderer in this._activeItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == this._selectedGroupIndex &&
					renderer.itemIndex == this._selectedItemIndex;
			}
			for each(renderer in this._activeFirstItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == this._selectedGroupIndex &&
					renderer.itemIndex == this._selectedItemIndex;
			}
			for each(renderer in this._activeLastItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == this._selectedGroupIndex &&
					renderer.itemIndex == this._selectedItemIndex;
			}
			for each(renderer in this._activeSingleItemRenderers)
			{
				renderer.isSelected = renderer.groupIndex == this._selectedGroupIndex &&
					renderer.itemIndex == this._selectedItemIndex;
			}
			this._ignoreSelectionChanges = false;
		}

		private function refreshRenderers(itemRendererTypeIsInvalid:Boolean):void
		{
			var temp:Vector.<IGroupedListItemRenderer> = this._inactiveItemRenderers;
			this._inactiveItemRenderers = this._activeItemRenderers;
			this._activeItemRenderers = temp;
			this._activeItemRenderers.length = 0;
			if(this._inactiveFirstItemRenderers)
			{
				temp = this._inactiveFirstItemRenderers;
				this._inactiveFirstItemRenderers = this._activeFirstItemRenderers;
				this._activeFirstItemRenderers = temp;
				this._activeFirstItemRenderers.length = 0;
			}
			if(this._inactiveLastItemRenderers)
			{
				temp = this._inactiveLastItemRenderers;
				this._inactiveLastItemRenderers = this._activeLastItemRenderers;
				this._activeLastItemRenderers = temp;
				this._activeLastItemRenderers.length = 0;
			}
			if(this._inactiveSingleItemRenderers)
			{
				temp = this._inactiveSingleItemRenderers;
				this._inactiveSingleItemRenderers = this._activeSingleItemRenderers;
				this._activeSingleItemRenderers = temp;
				this._activeSingleItemRenderers.length = 0;
			}
			var temp2:Vector.<IGroupedListHeaderOrFooterRenderer> = this._inactiveHeaderRenderers;
			this._inactiveHeaderRenderers = this._activeHeaderRenderers;
			this._activeHeaderRenderers = temp2;
			this._activeHeaderRenderers.length = 0;
			temp2 = this._inactiveFooterRenderers;
			this._inactiveFooterRenderers = this._activeFooterRenderers;
			this._activeFooterRenderers = temp2;
			this._activeFooterRenderers.length = 0;
			if(itemRendererTypeIsInvalid)
			{
				this.recoverInactiveRenderers();
				this.freeInactiveRenderers();
			}
			this._headerIndices.length = 0;
			this._footerIndices.length = 0;

			HELPER_BOUNDS.x = HELPER_BOUNDS.y = 0;
			HELPER_BOUNDS.explicitWidth = this.explicitVisibleWidth;
			HELPER_BOUNDS.explicitHeight = this.explicitVisibleHeight;
			HELPER_BOUNDS.minWidth = this._minVisibleWidth;
			HELPER_BOUNDS.minHeight = this._minVisibleHeight;
			HELPER_BOUNDS.maxWidth = this._maxVisibleWidth;
			HELPER_BOUNDS.maxHeight = this._maxVisibleHeight;

			this.findUnrenderedData();
			this.recoverInactiveRenderers();
			this.renderUnrenderedData();
			this.freeInactiveRenderers();
		}

		private function findUnrenderedData():void
		{
			const hasCustomFirstItemRenderer:Boolean = this._firstItemRendererType || this._firstItemRendererFactory != null || this._firstItemRendererName;
			const hasCustomLastItemRenderer:Boolean = this._lastItemRendererType || this._lastItemRendererFactory != null || this._lastItemRendererName;
			const hasCustomSingleItemRenderer:Boolean = this._singleItemRendererType || this._singleItemRendererFactory != null || this._singleItemRendererName;

			if(hasCustomFirstItemRenderer)
			{
				if(!this._firstItemRendererMap)
				{
					this._firstItemRendererMap = new Dictionary(true);
				}
				if(!this._inactiveFirstItemRenderers)
				{
					this._inactiveFirstItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!this._activeFirstItemRenderers)
				{
					this._activeFirstItemRenderers = new <IGroupedListItemRenderer>[]
				}
				if(!this._unrenderedFirstItems)
				{
					this._unrenderedFirstItems = new <int>[];
				}
			}
			else
			{
				this._firstItemRendererMap = null;
				this._inactiveFirstItemRenderers = null;
				this._activeFirstItemRenderers = null;
				this._unrenderedFirstItems = null;
			}
			if(hasCustomLastItemRenderer)
			{
				if(!this._lastItemRendererMap)
				{
					this._lastItemRendererMap = new Dictionary(true);
				}
				if(!this._inactiveLastItemRenderers)
				{
					this._inactiveLastItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!this._activeLastItemRenderers)
				{
					this._activeLastItemRenderers = new <IGroupedListItemRenderer>[]
				}
				if(!this._unrenderedLastItems)
				{
					this._unrenderedLastItems = new <int>[];
				}
			}
			else
			{
				this._lastItemRendererMap = null;
				this._inactiveLastItemRenderers = null;
				this._activeLastItemRenderers = null;
				this._unrenderedLastItems = null;
			}
			if(hasCustomSingleItemRenderer)
			{
				if(!this._singleItemRendererMap)
				{
					this._singleItemRendererMap = new Dictionary(true);
				}
				if(!this._inactiveSingleItemRenderers)
				{
					this._inactiveSingleItemRenderers = new <IGroupedListItemRenderer>[];
				}
				if(!this._activeSingleItemRenderers)
				{
					this._activeSingleItemRenderers = new <IGroupedListItemRenderer>[]
				}
				if(!this._unrenderedSingleItems)
				{
					this._unrenderedSingleItems = new <int>[];
				}
			}
			else
			{
				this._singleItemRendererMap = null;
				this._inactiveSingleItemRenderers = null;
				this._activeSingleItemRenderers = null;
				this._unrenderedSingleItems = null;
			}

			const groupCount:int = this._dataProvider ? this._dataProvider.getLength() : 0;
			var totalLayoutCount:int = 0;
			var totalHeaderCount:int = 0;
			var totalFooterCount:int = 0;
			var totalSingleItemCount:int = 0;
			var averageItemsPerGroup:int = 0;
			for(var i:int = 0; i < groupCount; i++)
			{
				var group:Object = this._dataProvider.getItemAt(i);
				if(this._owner.groupToHeaderData(group) !== null)
				{
					this._headerIndices.push(totalLayoutCount);
					totalLayoutCount++;
					totalHeaderCount++;
				}
				var currentItemCount:int = this._dataProvider.getLength(i);
				totalLayoutCount += currentItemCount;
				averageItemsPerGroup += currentItemCount;
				if(currentItemCount == 0)
				{
					totalSingleItemCount++;
				}
				if(this._owner.groupToFooterData(group) !== null)
				{
					this._footerIndices.push(totalLayoutCount);
					totalLayoutCount++;
					totalFooterCount++;
				}
			}
			this._layoutItems.length = totalLayoutCount;
			const virtualLayout:IVirtualLayout = this._layout as IVirtualLayout;
			const useVirtualLayout:Boolean = virtualLayout && virtualLayout.useVirtualLayout;
			if(useVirtualLayout)
			{
				this._ignoreLayoutChanges = true;
				virtualLayout.typicalItemWidth = this._typicalItemWidth;
				virtualLayout.typicalItemHeight = this._typicalItemHeight;
				this._ignoreLayoutChanges = false;
				virtualLayout.measureViewPort(totalLayoutCount, HELPER_BOUNDS, HELPER_POINT);
				virtualLayout.getVisibleIndicesAtScrollPosition(this._horizontalScrollPosition, this._verticalScrollPosition, HELPER_POINT.x, HELPER_POINT.y, totalLayoutCount, HELPER_VECTOR);

				averageItemsPerGroup /= groupCount;
				this._minimumFirstAndLastItemCount = this._minimumSingleItemCount = this._minimumHeaderCount = this._minimumFooterCount = Math.ceil(HELPER_POINT.y / (this._typicalItemHeight * averageItemsPerGroup));
				this._minimumHeaderCount = Math.min(this._minimumHeaderCount, totalHeaderCount);
				this._minimumFooterCount = Math.min(this._minimumFooterCount, totalFooterCount);
				this._minimumSingleItemCount = Math.min(this._minimumSingleItemCount, totalSingleItemCount);

				//assumes that zero headers/footers might be visible
				this._minimumItemCount = Math.ceil(HELPER_POINT.y / this._typicalItemHeight) + 1;
			}
			var currentIndex:int = 0;
			for(i = 0; i < groupCount; i++)
			{
				group = this._dataProvider.getItemAt(i);
				var header:Object = this._owner.groupToHeaderData(group);
				if(header !== null)
				{
					//the end index is included in the visible items
					if(useVirtualLayout && HELPER_VECTOR.indexOf(currentIndex) < 0)
					{
						this._layoutItems[currentIndex] = null;
					}
					else
					{
						var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(this._headerRendererMap[header]);
						if(headerOrFooterRenderer)
						{
							headerOrFooterRenderer.layoutIndex = currentIndex;
							headerOrFooterRenderer.groupIndex = i;
							this._activeHeaderRenderers.push(headerOrFooterRenderer);
							this._inactiveHeaderRenderers.splice(this._inactiveHeaderRenderers.indexOf(headerOrFooterRenderer), 1);
							var displayRenderer:DisplayObject = DisplayObject(headerOrFooterRenderer);
							displayRenderer.visible = true;
							this._layoutItems[currentIndex] = displayRenderer;
						}
						else
						{
							this._unrenderedHeaders.push(i);
							this._unrenderedHeaders.push(currentIndex);
						}
					}
					currentIndex++;
				}
				currentItemCount = this._dataProvider.getLength(i);
				var currentGroupLastIndex:int = currentItemCount - 1;
				for(var j:int = 0; j < currentItemCount; j++)
				{
					if(useVirtualLayout && HELPER_VECTOR.indexOf(currentIndex) < 0)
					{
						this._layoutItems[currentIndex] = null;
					}
					else
					{
						var item:Object = this._dataProvider.getItemAt(i, j);
						if(hasCustomSingleItemRenderer && j == 0 && j == currentGroupLastIndex)
						{
							this.findRendererForItem(item, i, j, currentIndex, this._singleItemRendererMap, this._inactiveSingleItemRenderers,
								this._activeSingleItemRenderers, this._unrenderedSingleItems);
						}
						else if(hasCustomFirstItemRenderer && j == 0)
						{
							this.findRendererForItem(item, i, j, currentIndex, this._firstItemRendererMap, this._inactiveFirstItemRenderers,
								this._activeFirstItemRenderers, this._unrenderedFirstItems);
						}
						else if(hasCustomLastItemRenderer && j == currentGroupLastIndex)
						{
							this.findRendererForItem(item, i, j, currentIndex, this._lastItemRendererMap, this._inactiveLastItemRenderers,
								this._activeLastItemRenderers, this._unrenderedLastItems);
						}
						else
						{
							this.findRendererForItem(item, i, j, currentIndex, this._itemRendererMap, this._inactiveItemRenderers,
								this._activeItemRenderers, this._unrenderedItems);
						}
					}
					currentIndex++;
				}
				var footer:Object = this._owner.groupToFooterData(group);
				if(footer !== null)
				{
					if(useVirtualLayout && HELPER_VECTOR.indexOf(currentIndex) < 0)
					{
						this._layoutItems[currentIndex] = null;
					}
					else
					{
						headerOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(this._footerRendererMap[footer]);
						if(headerOrFooterRenderer)
						{
							headerOrFooterRenderer.groupIndex = i;
							headerOrFooterRenderer.layoutIndex = currentIndex;
							this._activeFooterRenderers.push(headerOrFooterRenderer);
							this._inactiveFooterRenderers.splice(this._inactiveFooterRenderers.indexOf(headerOrFooterRenderer), 1);
							displayRenderer = DisplayObject(headerOrFooterRenderer);
							displayRenderer.visible = true;
							this._layoutItems[currentIndex] = displayRenderer;
						}
						else
						{
							this._unrenderedFooters.push(i);
							this._unrenderedFooters.push(currentIndex);
						}
					}
					currentIndex++;
				}
			}
		}

		private function findRendererForItem(item:Object, groupIndex:int, itemIndex:int, layoutIndex:int,
			rendererMap:Dictionary, inactiveRenderers:Vector.<IGroupedListItemRenderer>,
			activeRenderers:Vector.<IGroupedListItemRenderer>, unrenderedItems:Vector.<int>):void
		{
			var itemRenderer:IGroupedListItemRenderer = IGroupedListItemRenderer(rendererMap[item]);
			if(itemRenderer)
			{
				itemRenderer.groupIndex = groupIndex;
				itemRenderer.itemIndex = itemIndex;
				itemRenderer.layoutIndex = layoutIndex;
				activeRenderers.push(itemRenderer);
				inactiveRenderers.splice(inactiveRenderers.indexOf(itemRenderer), 1);
				var displayRenderer:DisplayObject = DisplayObject(itemRenderer);
				displayRenderer.visible = true;
				this._layoutItems[layoutIndex] = displayRenderer;
			}
			else
			{
				unrenderedItems.push(groupIndex);
				unrenderedItems.push(itemIndex);
				unrenderedItems.push(layoutIndex);
			}
		}

		private function renderUnrenderedData():void
		{
			var rendererCount:int = this._unrenderedItems.length;
			for(var i:int = 0; i < rendererCount; i += 3)
			{
				var groupIndex:int = this._unrenderedItems.shift();
				var itemIndex:int = this._unrenderedItems.shift();
				var layoutIndex:int = this._unrenderedItems.shift();
				var item:Object = this._dataProvider.getItemAt(groupIndex, itemIndex);
				var itemRenderer:IGroupedListItemRenderer = this.createItemRenderer(this._inactiveItemRenderers,
					this._activeItemRenderers, this._itemRendererMap, this._itemRendererType, this._itemRendererFactory,
					this._itemRendererName, item, groupIndex, itemIndex, layoutIndex, false);
				this._layoutItems[layoutIndex] = DisplayObject(itemRenderer);
			}

			if(this._unrenderedFirstItems)
			{
				rendererCount = this._unrenderedFirstItems.length;
				for(i = 0; i < rendererCount; i += 3)
				{
					groupIndex = this._unrenderedFirstItems.shift();
					itemIndex = this._unrenderedFirstItems.shift();
					layoutIndex = this._unrenderedFirstItems.shift();
					item = this._dataProvider.getItemAt(groupIndex, itemIndex);
					var type:Class = this._firstItemRendererType ? this._firstItemRendererType : this._itemRendererType;
					var factory:Function = this._firstItemRendererFactory != null ? this._firstItemRendererFactory : this._itemRendererFactory;
					var name:String = this._firstItemRendererName ? this._firstItemRendererName : this._itemRendererName;
					itemRenderer = this.createItemRenderer(this._inactiveFirstItemRenderers, this._activeFirstItemRenderers,
						this._firstItemRendererMap, type, factory, name, item, groupIndex, itemIndex, layoutIndex, false);
					this._layoutItems[layoutIndex] = DisplayObject(itemRenderer);
				}
			}

			if(this._unrenderedLastItems)
			{
				rendererCount = this._unrenderedLastItems.length;
				for(i = 0; i < rendererCount; i += 3)
				{
					groupIndex = this._unrenderedLastItems.shift();
					itemIndex = this._unrenderedLastItems.shift();
					layoutIndex = this._unrenderedLastItems.shift();
					item = this._dataProvider.getItemAt(groupIndex, itemIndex);
					type = this._lastItemRendererType ? this._lastItemRendererType : this._itemRendererType;
					factory = this._lastItemRendererFactory != null ? this._lastItemRendererFactory : this._itemRendererFactory;
					name = this._lastItemRendererName ? this._lastItemRendererName : this._itemRendererName;
					itemRenderer = this.createItemRenderer(this._inactiveLastItemRenderers, this._activeLastItemRenderers,
						this._lastItemRendererMap, type,  factory,  name, item, groupIndex, itemIndex, layoutIndex, false);
					this._layoutItems[layoutIndex] = DisplayObject(itemRenderer);
				}
			}

			if(this._unrenderedSingleItems)
			{
				rendererCount = this._unrenderedSingleItems.length;
				for(i = 0; i < rendererCount; i += 3)
				{
					groupIndex = this._unrenderedSingleItems.shift();
					itemIndex = this._unrenderedSingleItems.shift();
					layoutIndex = this._unrenderedSingleItems.shift();
					item = this._dataProvider.getItemAt(groupIndex, itemIndex);
					type = this._singleItemRendererType ? this._singleItemRendererType : this._itemRendererType;
					factory = this._singleItemRendererFactory != null ? this._singleItemRendererFactory : this._itemRendererFactory;
					name = this._singleItemRendererName ? this._singleItemRendererName : this._itemRendererName;
					itemRenderer = this.createItemRenderer(this._inactiveSingleItemRenderers, this._activeSingleItemRenderers,
						this._singleItemRendererMap, type,  factory,  name, item, groupIndex, itemIndex, layoutIndex, false);
					this._layoutItems[layoutIndex] = DisplayObject(itemRenderer);
				}
			}

			rendererCount = this._unrenderedHeaders.length;
			for(i = 0; i < rendererCount; i += 2)
			{
				groupIndex = this._unrenderedHeaders.shift();
				layoutIndex = this._unrenderedHeaders.shift();
				item = this._dataProvider.getItemAt(groupIndex);
				item = this._owner.groupToHeaderData(item);
				var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = this.createHeaderRenderer(item, groupIndex, layoutIndex, false);
				this._layoutItems[layoutIndex] = DisplayObject(headerOrFooterRenderer);
			}

			rendererCount = this._unrenderedFooters.length;
			for(i = 0; i < rendererCount; i += 2)
			{
				groupIndex = this._unrenderedFooters.shift();
				layoutIndex = this._unrenderedFooters.shift();
				item = this._dataProvider.getItemAt(groupIndex);
				item = this._owner.groupToFooterData(item);
				headerOrFooterRenderer = this.createFooterRenderer(item, groupIndex, layoutIndex, false);
				this._layoutItems[layoutIndex] = DisplayObject(headerOrFooterRenderer);
			}
		}

		private function recoverInactiveRenderers():void
		{
			var rendererCount:int = this._inactiveItemRenderers.length;
			for(var i:int = 0; i < rendererCount; i++)
			{
				var itemRenderer:IGroupedListItemRenderer = this._inactiveItemRenderers[i];
				delete this._itemRendererMap[itemRenderer.data];
			}

			if(this._inactiveFirstItemRenderers)
			{
				rendererCount = this._inactiveFirstItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = this._inactiveFirstItemRenderers[i];
					delete this._firstItemRendererMap[itemRenderer.data];
				}
			}

			if(this._inactiveLastItemRenderers)
			{
				rendererCount = this._inactiveLastItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = this._inactiveLastItemRenderers[i];
					delete this._lastItemRendererMap[itemRenderer.data];
				}
			}

			if(this._inactiveSingleItemRenderers)
			{
				rendererCount = this._inactiveSingleItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = this._inactiveSingleItemRenderers[i];
					delete this._singleItemRendererMap[itemRenderer.data];
				}
			}

			rendererCount = this._inactiveHeaderRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = this._inactiveHeaderRenderers[i];
				delete this._headerRendererMap[headerOrFooterRenderer.data];
			}

			rendererCount = this._inactiveFooterRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				headerOrFooterRenderer = this._inactiveFooterRenderers[i];
				delete this._footerRendererMap[headerOrFooterRenderer.data];
			}
		}

		private function freeInactiveRenderers():void
		{
			//we may keep around some extra renderers to avoid too much
			//allocation and garbage collection. they'll be hidden.
			var keepCount:int = Math.min(this._minimumItemCount - this._activeItemRenderers.length, this._inactiveItemRenderers.length);
			for(var i:int = 0; i < keepCount; i++)
			{
				var itemRenderer:IGroupedListItemRenderer = this._inactiveItemRenderers.shift();
				DisplayObject(itemRenderer).visible = false;
				this._activeItemRenderers.push(itemRenderer);
			}
			var rendererCount:int = this._inactiveItemRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				itemRenderer = this._inactiveItemRenderers.shift();
				this.destroyItemRenderer(itemRenderer);
			}

			if(this._activeFirstItemRenderers)
			{
				keepCount = Math.min(this._minimumFirstAndLastItemCount - this._activeFirstItemRenderers.length, this._inactiveFirstItemRenderers.length);
				for(i = 0; i < keepCount; i++)
				{
					itemRenderer = this._inactiveFirstItemRenderers.shift();
					DisplayObject(itemRenderer).visible = false;
					this._activeFirstItemRenderers.push(itemRenderer);
				}
				rendererCount = this._inactiveFirstItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = this._inactiveFirstItemRenderers.shift();
					this.destroyItemRenderer(itemRenderer);
				}
			}

			if(this._activeLastItemRenderers)
			{
				keepCount = Math.min(this._minimumFirstAndLastItemCount - this._activeLastItemRenderers.length, this._inactiveLastItemRenderers.length);
				for(i = 0; i < keepCount; i++)
				{
					itemRenderer = this._inactiveLastItemRenderers.shift();
					DisplayObject(itemRenderer).visible = false;
					this._activeLastItemRenderers.push(itemRenderer);
				}
				rendererCount = this._inactiveLastItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = this._inactiveLastItemRenderers.shift();
					this.destroyItemRenderer(itemRenderer);
				}
			}

			if(this._activeSingleItemRenderers)
			{
				keepCount = Math.min(this._minimumSingleItemCount - this._activeSingleItemRenderers.length, this._inactiveSingleItemRenderers.length);
				for(i = 0; i < keepCount; i++)
				{
					itemRenderer = this._inactiveSingleItemRenderers.shift();
					DisplayObject(itemRenderer).visible = false;
					this._activeSingleItemRenderers.push(itemRenderer);
				}
				rendererCount = this._inactiveSingleItemRenderers.length;
				for(i = 0; i < rendererCount; i++)
				{
					itemRenderer = this._inactiveSingleItemRenderers.shift();
					this.destroyItemRenderer(itemRenderer);
				}
			}

			keepCount = Math.min(this._minimumHeaderCount - this._activeHeaderRenderers.length, this._inactiveHeaderRenderers.length);
			for(i = 0; i < keepCount; i++)
			{
				var headerOrFooterRenderer:IGroupedListHeaderOrFooterRenderer = this._inactiveHeaderRenderers.shift();
				DisplayObject(headerOrFooterRenderer).visible = false;
				this._activeHeaderRenderers.push(headerOrFooterRenderer);
			}
			rendererCount = this._inactiveHeaderRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				headerOrFooterRenderer = this._inactiveHeaderRenderers.shift();
				this.destroyHeaderRenderer(headerOrFooterRenderer);
			}

			keepCount = Math.min(this._minimumFooterCount - this._activeFooterRenderers.length, this._inactiveFooterRenderers.length);
			for(i = 0; i < keepCount; i++)
			{
				headerOrFooterRenderer = this._inactiveFooterRenderers.shift();
				DisplayObject(headerOrFooterRenderer).visible = false;
				this._activeFooterRenderers.push(headerOrFooterRenderer);
			}
			rendererCount = this._inactiveFooterRenderers.length;
			for(i = 0; i < rendererCount; i++)
			{
				headerOrFooterRenderer = this._inactiveFooterRenderers.shift();
				this.destroyFooterRenderer(headerOrFooterRenderer);
			}
		}

		private function createItemRenderer(inactiveRenderers:Vector.<IGroupedListItemRenderer>,
			activeRenderers:Vector.<IGroupedListItemRenderer>, rendererMap:Dictionary,
			type:Class, factory:Function, name:String, item:Object, groupIndex:int, itemIndex:int,
			layoutIndex:int, isTemporary:Boolean = false):IGroupedListItemRenderer
		{
			if(isTemporary || inactiveRenderers.length == 0)
			{
				var renderer:IGroupedListItemRenderer;
				if(factory != null)
				{
					renderer = IGroupedListItemRenderer(factory());
				}
				else
				{
					renderer = new type();
				}
				var uiRenderer:IFeathersControl = IFeathersControl(renderer);
				if(name && name.length > 0)
				{
					uiRenderer.nameList.add(name);
				}
				this.addChild(DisplayObject(renderer));
			}
			else
			{
				renderer = inactiveRenderers.shift();
			}
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			renderer.data = item;
			renderer.groupIndex = groupIndex;
			renderer.itemIndex = itemIndex;
			renderer.layoutIndex = layoutIndex;
			renderer.owner = this._owner;
			displayRenderer.visible = true;

			if(!isTemporary)
			{
				rendererMap[item] = renderer;
				activeRenderers.push(renderer);
				displayRenderer.addEventListener(Event.CHANGE, renderer_changeHandler);
				displayRenderer.addEventListener(FeathersEventType.RESIZE, itemRenderer_resizeHandler);
			}

			return renderer;
		}

		private function createHeaderRenderer(header:Object, groupIndex:int, layoutIndex:int, isTemporary:Boolean = false):IGroupedListHeaderOrFooterRenderer
		{
			if(isTemporary || this._inactiveHeaderRenderers.length == 0)
			{
				var renderer:IGroupedListHeaderOrFooterRenderer;
				if(this._headerRendererFactory != null)
				{
					renderer = IGroupedListHeaderOrFooterRenderer(this._headerRendererFactory());
				}
				else
				{
					renderer = new this._headerRendererType();
				}
				var uiRenderer:IFeathersControl = IFeathersControl(renderer);
				if(this._headerRendererName && this._headerRendererName.length > 0)
				{
					uiRenderer.nameList.add(this._headerRendererName);
				}
				this.addChild(DisplayObject(renderer));
			}
			else
			{
				renderer = this._inactiveHeaderRenderers.shift();
			}
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			renderer.data = header;
			renderer.groupIndex = groupIndex;
			renderer.layoutIndex = layoutIndex;
			renderer.owner = this._owner;
			displayRenderer.visible = true;

			if(!isTemporary)
			{
				this._headerRendererMap[header] = renderer;
				this._activeHeaderRenderers.push(renderer);
				displayRenderer.addEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
			}

			return renderer;
		}

		private function createFooterRenderer(footer:Object, groupIndex:int, layoutIndex:int, isTemporary:Boolean = false):IGroupedListHeaderOrFooterRenderer
		{
			if(isTemporary || this._inactiveFooterRenderers.length == 0)
			{
				var renderer:IGroupedListHeaderOrFooterRenderer;
				if(this._footerRendererFactory != null)
				{
					renderer = IGroupedListHeaderOrFooterRenderer(this._footerRendererFactory());
				}
				else
				{
					renderer = new this._footerRendererType();
				}
				var uiRenderer:IFeathersControl = IFeathersControl(renderer);
				if(this._footerRendererName && this._footerRendererName.length > 0)
				{
					uiRenderer.nameList.add(this._footerRendererName);
				}
				this.addChild(DisplayObject(renderer));
			}
			else
			{
				renderer = this._inactiveFooterRenderers.shift();
			}
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			renderer.data = footer;
			renderer.groupIndex = groupIndex;
			renderer.layoutIndex = layoutIndex;
			renderer.owner = this._owner;
			displayRenderer.visible = true;

			if(!isTemporary)
			{
				this._footerRendererMap[footer] = renderer;
				this._activeFooterRenderers.push(renderer);
				displayRenderer.addEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
			}

			return renderer;
		}

		private function destroyItemRenderer(renderer:IGroupedListItemRenderer):void
		{
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			displayRenderer.removeEventListener(Event.CHANGE, renderer_changeHandler);
			displayRenderer.removeEventListener(FeathersEventType.RESIZE, itemRenderer_resizeHandler);
			this.removeChild(displayRenderer, true);
		}

		private function destroyHeaderRenderer(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			displayRenderer.removeEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
			this.removeChild(displayRenderer, true);
		}

		private function destroyFooterRenderer(renderer:IGroupedListHeaderOrFooterRenderer):void
		{
			const displayRenderer:DisplayObject = DisplayObject(renderer);
			displayRenderer.removeEventListener(FeathersEventType.RESIZE, headerOrFooterRenderer_resizeHandler);
			this.removeChild(displayRenderer, true);
		}

		private function locationToDisplayIndex(groupIndex:int, itemIndex:int):int
		{
			var displayIndex:int = 0;
			const groupCount:int = this._dataProvider.getLength();
			for(var i:int = 0; i < groupCount; i++)
			{
				var group:Object = this._dataProvider.getItemAt(i);
				var header:Object = this._owner.groupToHeaderData(group);
				if(header)
				{
					displayIndex++;
				}
				var groupLength:int = this._dataProvider.getLength(i);
				for(var j:int = 0; j < groupLength; j++)
				{
					if(groupIndex == i && itemIndex == j)
					{
						return displayIndex;
					}
					displayIndex++;
				}
				var footer:Object = this._owner.groupToFooterData(group);
				if(footer)
				{
					displayIndex++;
				}
			}
			return -1;
		}

		private function childProperties_onChange(proxy:PropertyProxy, name:String):void
		{
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		private function owner_scrollHandler(event:Event):void
		{
			this._isScrolling = true;
		}

		private function dataProvider_changeHandler(event:Event):void
		{
			this.invalidate(INVALIDATION_FLAG_DATA);
			this.invalidateParent();
		}

		private function dataProvider_updateItemHandler(event:Event, indices:Array):void
		{
			const groupIndex:int = indices[0];
			const itemIndex:int = indices[1];
			const item:Object = this._dataProvider.getItemAt(groupIndex, itemIndex);
			var renderer:IGroupedListItemRenderer = IGroupedListItemRenderer(this._itemRendererMap[item]);
			if(!renderer)
			{
				renderer = IGroupedListItemRenderer(this._firstItemRendererMap[item]);
				if(!renderer)
				{
					renderer = IGroupedListItemRenderer(this._lastItemRendererMap[item]);
					if(!renderer)
					{
						return;
					}
				}
			}
			renderer.data = null;
			renderer.data = item;
		}

		private function layout_changeHandler(event:Event):void
		{
			if(this._ignoreLayoutChanges)
			{
				return;
			}
			this.invalidate(INVALIDATION_FLAG_SCROLL);
			this.invalidateParent();
		}

		private function itemRenderer_resizeHandler(event:Event):void
		{
			if(this._ignoreRendererResizing)
			{
				return;
			}
			const layout:IVariableVirtualLayout = this._layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			const renderer:IGroupedListItemRenderer = IGroupedListItemRenderer(event.currentTarget);
			layout.resetVariableVirtualCacheAtIndex(renderer.layoutIndex, DisplayObject(renderer));
			this.invalidate(INVALIDATION_FLAG_SCROLL);
			this.invalidateParent();
		}

		private function headerOrFooterRenderer_resizeHandler(event:Event):void
		{
			if(this._ignoreRendererResizing)
			{
				return;
			}
			const layout:IVariableVirtualLayout = this._layout as IVariableVirtualLayout;
			if(!layout || !layout.hasVariableItemDimensions)
			{
				return;
			}
			const renderer:IGroupedListHeaderOrFooterRenderer = IGroupedListHeaderOrFooterRenderer(event.currentTarget);
			layout.resetVariableVirtualCacheAtIndex(renderer.layoutIndex, DisplayObject(renderer));
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		private function renderer_changeHandler(event:Event):void
		{
			if(this._ignoreSelectionChanges)
			{
				return;
			}
			const renderer:IGroupedListItemRenderer = IGroupedListItemRenderer(event.currentTarget);
			const isAlreadySelected:Boolean = this._selectedGroupIndex == renderer.groupIndex &&
				this._selectedItemIndex == renderer.itemIndex;
			if(!this._isSelectable || this._isScrolling || isAlreadySelected)
			{
				//reset to the old value
				renderer.isSelected = isAlreadySelected;
				return;
			}
			this.setSelectedLocation(renderer.groupIndex, renderer.itemIndex);
		}

		private function removedFromStageHandler(event:Event):void
		{
			this.touchPointID = -1;
		}

		private function touchHandler(event:TouchEvent):void
		{
			if(!this._isEnabled)
			{
				this.touchPointID = -1;
				return;
			}

			const touches:Vector.<Touch> = event.getTouches(this);
			if(touches.length == 0)
			{
				return;
			}
			if(this.touchPointID >= 0)
			{
				var touch:Touch;
				for each(var currentTouch:Touch in touches)
				{
					if(currentTouch.id == this.touchPointID)
					{
						touch = currentTouch;
						break;
					}
				}
				if(!touch)
				{
					return;
				}
				if(touch.phase == TouchPhase.ENDED)
				{
					this.touchPointID = -1;
					return;
				}
			}
			else
			{
				for each(touch in touches)
				{
					if(touch.phase == TouchPhase.BEGAN)
					{
						this.touchPointID = touch.id;
						this._isScrolling = false;
						return;
					}
				}
			}
		}
	}
}
