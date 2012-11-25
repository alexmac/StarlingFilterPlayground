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
package feathers.layout
{
	import flash.geom.Point;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	/**
	 * @inheritDoc
	 */
	[Event(name="change",type="starling.events.Event")]

	/**
	 * Positions items as tiles (equal width and height) from top to bottom
	 * in multiple columns. Constrained to the suggested height, the tiled
	 * columns layout will change in width as the number of items increases or
	 * decreases.
	 */
	public class TiledColumnsLayout extends EventDispatcher implements IVirtualLayout
	{
		/**
		 * @private
		 */
		private static const HELPER_VECTOR:Vector.<DisplayObject> = new <DisplayObject>[];
		
		/**
		 * If the total item height is smaller than the height of the bounds,
		 * the items will be aligned to the top.
		 */
		public static const VERTICAL_ALIGN_TOP:String = "top";

		/**
		 * If the total item height is smaller than the height of the bounds,
		 * the items will be aligned to the middle.
		 */
		public static const VERTICAL_ALIGN_MIDDLE:String = "middle";

		/**
		 * If the total item height is smaller than the height of the bounds,
		 * the items will be aligned to the bottom.
		 */
		public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";

		/**
		 * If the total item width is smaller than the width of the bounds, the
		 * items will be aligned to the left.
		 */
		public static const HORIZONTAL_ALIGN_LEFT:String = "left";

		/**
		 * If the total item width is smaller than the width of the bounds, the
		 * items will be aligned to the center.
		 */
		public static const HORIZONTAL_ALIGN_CENTER:String = "center";

		/**
		 * If the total item width is smaller than the width of the bounds, the
		 * items will be aligned to the right.
		 */
		public static const HORIZONTAL_ALIGN_RIGHT:String = "right";

		/**
		 * If an item height is smaller than the height of a tile, the item will
		 * be aligned to the top edge of the tile.
		 */
		public static const TILE_VERTICAL_ALIGN_TOP:String = "top";

		/**
		 * If an item height is smaller than the height of a tile, the item will
		 * be aligned to the middle of the tile.
		 */
		public static const TILE_VERTICAL_ALIGN_MIDDLE:String = "middle";

		/**
		 * If an item height is smaller than the height of a tile, the item will
		 * be aligned to the bottom edge of the tile.
		 */
		public static const TILE_VERTICAL_ALIGN_BOTTOM:String = "bottom";

		/**
		 * The item will be resized to fit the height of the tile.
		 */
		public static const TILE_VERTICAL_ALIGN_JUSTIFY:String = "justify";

		/**
		 * If an item width is smaller than the width of a tile, the item will
		 * be aligned to the left edge of the tile.
		 */
		public static const TILE_HORIZONTAL_ALIGN_LEFT:String = "left";

		/**
		 * If an item width is smaller than the width of a tile, the item will
		 * be aligned to the center of the tile.
		 */
		public static const TILE_HORIZONTAL_ALIGN_CENTER:String = "center";

		/**
		 * If an item width is smaller than the width of a tile, the item will
		 * be aligned to the right edge of the tile.
		 */
		public static const TILE_HORIZONTAL_ALIGN_RIGHT:String = "right";

		/**
		 * The item will be resized to fit the width of the tile.
		 */
		public static const TILE_HORIZONTAL_ALIGN_JUSTIFY:String = "justify";

		/**
		 * The items will be positioned in pages horizontally from left to right.
		 */
		public static const PAGING_HORIZONTAL:String = "horizontal";

		/**
		 * The items will be positioned in pages vertically from top to bottom.
		 */
		public static const PAGING_VERTICAL:String = "vertical";

		/**
		 * The items will not be paged. In other words, they will be positioned
		 * in a continuous set of columns without gaps.
		 */
		public static const PAGING_NONE:String = "none";

		/**
		 * Constructor.
		 */
		public function TiledColumnsLayout()
		{
		}

		/**
		 * @private
		 */
		protected var _gap:Number = 0;

		/**
		 * The space, in pixels, between tiles.
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
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _paddingTop:Number = 0;

		/**
		 * The space, in pixels, above of items.
		 */
		public function get paddingTop():Number
		{
			return this._paddingTop;
		}

		/**
		 * @private
		 */
		public function set paddingTop(value:Number):void
		{
			if(this._paddingTop == value)
			{
				return;
			}
			this._paddingTop = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _paddingRight:Number = 0;

		/**
		 * The space, in pixels, to the right of the items.
		 */
		public function get paddingRight():Number
		{
			return this._paddingRight;
		}

		/**
		 * @private
		 */
		public function set paddingRight(value:Number):void
		{
			if(this._paddingRight == value)
			{
				return;
			}
			this._paddingRight = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _paddingBottom:Number = 0;

		/**
		 * The space, in pixels, below the items.
		 */
		public function get paddingBottom():Number
		{
			return this._paddingBottom;
		}

		/**
		 * @private
		 */
		public function set paddingBottom(value:Number):void
		{
			if(this._paddingBottom == value)
			{
				return;
			}
			this._paddingBottom = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _paddingLeft:Number = 0;

		/**
		 * The space, in pixels, to the left of the items.
		 */
		public function get paddingLeft():Number
		{
			return this._paddingLeft;
		}

		/**
		 * @private
		 */
		public function set paddingLeft(value:Number):void
		{
			if(this._paddingLeft == value)
			{
				return;
			}
			this._paddingLeft = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _verticalAlign:String = VERTICAL_ALIGN_TOP;

		[Inspectable(type="String",enumeration="top,middle,bottom")]
		/**
		 * If the total column height is less than the bounds, the items in the
		 * column can be aligned vertically.
		 */
		public function get verticalAlign():String
		{
			return this._verticalAlign;
		}

		/**
		 * @private
		 */
		public function set verticalAlign(value:String):void
		{
			if(this._verticalAlign == value)
			{
				return;
			}
			this._verticalAlign = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _horizontalAlign:String = HORIZONTAL_ALIGN_CENTER;

		[Inspectable(type="String",enumeration="left,center,right")]
		/**
		 * If the total row width is less than the bounds, the items in the row
		 * can be aligned horizontally.
		 */
		public function get horizontalAlign():String
		{
			return this._horizontalAlign;
		}

		/**
		 * @private
		 */
		public function set horizontalAlign(value:String):void
		{
			if(this._horizontalAlign == value)
			{
				return;
			}
			this._horizontalAlign = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _tileVerticalAlign:String = TILE_VERTICAL_ALIGN_MIDDLE;

		[Inspectable(type="String",enumeration="top,middle,bottom,justify")]
		/**
		 * If an item's height is less than the tile bounds, the position of the
		 * item can be aligned vertically.
		 */
		public function get tileVerticalAlign():String
		{
			return this._tileVerticalAlign;
		}

		/**
		 * @private
		 */
		public function set tileVerticalAlign(value:String):void
		{
			if(this._tileVerticalAlign == value)
			{
				return;
			}
			this._tileVerticalAlign = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _tileHorizontalAlign:String = TILE_HORIZONTAL_ALIGN_CENTER;

		[Inspectable(type="String",enumeration="left,center,right,justify")]
		/**
		 * If the item's width is less than the tile bounds, the position of the
		 * item can be aligned horizontally.
		 */
		public function get tileHorizontalAlign():String
		{
			return this._tileHorizontalAlign;
		}

		/**
		 * @private
		 */
		public function set tileHorizontalAlign(value:String):void
		{
			if(this._tileHorizontalAlign == value)
			{
				return;
			}
			this._tileHorizontalAlign = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _paging:String = PAGING_NONE;

		/**
		 * If the total combined width of the columns is larger than the width
		 * of the view port, the layout will be split into pages where each
		 * page is filled with the maximum number of columns that may be
		 * displayed without cutting off any items.
		 */
		public function get paging():String
		{
			return this._paging;
		}

		/**
		 * @private
		 */
		public function set paging(value:String):void
		{
			if(this._paging == value)
			{
				return;
			}
			this._paging = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _useSquareTiles:Boolean = true;

		/**
		 * Determines if the tiles must be square or if their width and height
		 * may have different values.
		 */
		public function get useSquareTiles():Boolean
		{
			return this._useSquareTiles;
		}

		/**
		 * @private
		 */
		public function set useSquareTiles(value:Boolean):void
		{
			if(this._useSquareTiles == value)
			{
				return;
			}
			this._useSquareTiles = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _useVirtualLayout:Boolean = true;

		/**
		 * @inheritDoc
		 */
		public function get useVirtualLayout():Boolean
		{
			return this._useVirtualLayout;
		}

		/**
		 * @private
		 */
		public function set useVirtualLayout(value:Boolean):void
		{
			if(this._useVirtualLayout == value)
			{
				return;
			}
			this._useVirtualLayout = value;
			this.dispatchEventWith(Event.CHANGE);
		}

		/**
		 * @private
		 */
		protected var _typicalItemWidth:Number = 0;

		/**
		 * @inheritDoc
		 */
		public function get typicalItemWidth():Number
		{
			return this._typicalItemWidth;
		}

		/**
		 * @private
		 */
		public function set typicalItemWidth(value:Number):void
		{
			if(this._typicalItemWidth == value)
			{
				return;
			}
			this._typicalItemWidth = value;
		}

		/**
		 * @private
		 */
		protected var _typicalItemHeight:Number = 0;

		/**
		 * @inheritDoc
		 */
		public function get typicalItemHeight():Number
		{
			return this._typicalItemHeight;
		}

		/**
		 * @private
		 */
		public function set typicalItemHeight(value:Number):void
		{
			if(this._typicalItemHeight == value)
			{
				return;
			}
			this._typicalItemHeight = value;
		}

		/**
		 * @inheritDoc
		 */
		public function layout(items:Vector.<DisplayObject>, viewPortBounds:ViewPortBounds = null, result:LayoutBoundsResult = null):LayoutBoundsResult
		{
			const boundsX:Number = viewPortBounds ? viewPortBounds.x : 0;
			const boundsY:Number = viewPortBounds ? viewPortBounds.y : 0;
			const minWidth:Number = viewPortBounds ? viewPortBounds.minWidth : 0;
			const minHeight:Number = viewPortBounds ? viewPortBounds.minHeight : 0;
			const maxWidth:Number = viewPortBounds ? viewPortBounds.maxWidth : Number.POSITIVE_INFINITY;
			const maxHeight:Number = viewPortBounds ? viewPortBounds.maxHeight : Number.POSITIVE_INFINITY;
			const explicitWidth:Number = viewPortBounds ? viewPortBounds.explicitWidth : NaN;
			const explicitHeight:Number = viewPortBounds ? viewPortBounds.explicitHeight : NaN;
			
			HELPER_VECTOR.length = 0;
			const itemCount:int = items.length;
			var tileWidth:Number = this._useSquareTiles ? Math.max(0, this._typicalItemWidth, this._typicalItemHeight) : this._typicalItemWidth;
			var tileHeight:Number = this._useSquareTiles ? tileWidth : this._typicalItemHeight;
			//a virtual layout assumes that all items are the same size as
			//the typical item, so we don't need to measure every item in
			//that case
			if(!this._useVirtualLayout)
			{
				for(var i:int = 0; i < itemCount; i++)
				{
					var item:DisplayObject = items[i];
					if(!item)
					{
						continue;
					}
					tileWidth = this._useSquareTiles ? Math.max(tileWidth, item.width, item.height) : Math.max(tileWidth, item.width);
					tileHeight = this._useSquareTiles ? Math.max(tileWidth, tileHeight) : Math.max(tileHeight, item.height);
				}
			}

			var availableWidth:Number = NaN;
			var availableHeight:Number = NaN;

			var horizontalTileCount:int = 1;
			if(!isNaN(explicitWidth))
			{
				availableWidth = explicitWidth;
				horizontalTileCount = Math.max(1, (explicitWidth - this._paddingLeft - this._paddingRight + this._gap) / (tileWidth + this._gap));
			}
			else if(!isNaN(maxWidth))
			{
				availableWidth = maxWidth;
				horizontalTileCount = Math.max(1, (maxWidth - this._paddingLeft - this._paddingRight + this._gap) / (tileWidth + this._gap));
			}
			var verticalTileCount:int = Math.max(1, itemCount);
			if(!isNaN(explicitHeight))
			{
				availableHeight = explicitHeight;
				verticalTileCount = Math.max(1, (explicitHeight - this._paddingTop - this._paddingBottom + this._gap) / (tileHeight + this._gap));
			}
			else if(!isNaN(maxHeight))
			{
				availableHeight = maxHeight;
				verticalTileCount = Math.max(1, (maxHeight - this._paddingTop - this._paddingBottom + this._gap) / (tileHeight + this._gap));
			}

			const totalPageWidth:Number = horizontalTileCount * (tileWidth + this._gap) - this._gap + this._paddingLeft + this._paddingRight;
			const totalPageHeight:Number = verticalTileCount * (tileHeight + this._gap) - this._gap + this._paddingTop + this._paddingBottom;
			const availablePageWidth:Number = isNaN(availableWidth) ? totalPageWidth : availableWidth;
			const availablePageHeight:Number = isNaN(availableHeight) ? totalPageHeight : availableHeight;

			const startX:Number = boundsX + this._paddingLeft;
			const startY:Number = boundsY + this._paddingTop;

			const perPage:int = horizontalTileCount * verticalTileCount;
			var pageIndex:int = 0;
			var nextPageStartIndex:int = perPage;
			var pageStartY:Number = startY;
			var positionX:Number = startX;
			var positionY:Number = startY;
			for(i = 0; i < itemCount; i++)
			{
				item = items[i];
				if(i != 0 && i % verticalTileCount == 0)
				{
					positionX += tileWidth + this._gap;
					positionY = pageStartY;
				}
				if(i == nextPageStartIndex)
				{
					//we're starting a new page, so handle alignment of the
					//items on the current page and update the positions
					if(this._paging != PAGING_NONE)
					{
						var discoveredItems:Vector.<DisplayObject> = this._useVirtualLayout ? HELPER_VECTOR : items;
						var discoveredItemsFirstIndex:int = this._useVirtualLayout ? 0 : (i - perPage);
						var discoveredItemsLastIndex:int = this._useVirtualLayout ? (HELPER_VECTOR.length - 1) : (i - 1);
						this.applyHorizontalAlign(discoveredItems, discoveredItemsFirstIndex, discoveredItemsLastIndex, totalPageWidth, availablePageWidth);
						this.applyVerticalAlign(discoveredItems, discoveredItemsFirstIndex, discoveredItemsLastIndex, totalPageHeight, availablePageHeight);
						HELPER_VECTOR.length = 0;
					}
					pageIndex++;
					nextPageStartIndex += perPage;

					//we can use availableWidth and availableHeight here without
					//checking if they're NaN because we will never reach a
					//new page without them already being calculated.
					if(this._paging == PAGING_HORIZONTAL)
					{
						positionX = startX + availableWidth * pageIndex;
					}
					else if(this._paging == PAGING_VERTICAL)
					{
						positionX = startX;
						positionY = pageStartY = startY + availableHeight * pageIndex;
					}
				}
				if(item)
				{
					switch(this._tileHorizontalAlign)
					{
						case TILE_HORIZONTAL_ALIGN_JUSTIFY:
						{
							item.x = positionX;
							item.width = tileWidth;
							break;
						}
						case TILE_HORIZONTAL_ALIGN_LEFT:
						{
							item.x = positionX;
							break;
						}
						case TILE_HORIZONTAL_ALIGN_RIGHT:
						{
							item.x = positionX + tileWidth - item.width;
							break;
						}
						default: //center or unknown
						{
							item.x = positionX + (tileWidth - item.width) / 2;
						}
					}
					switch(this._tileVerticalAlign)
					{
						case TILE_VERTICAL_ALIGN_JUSTIFY:
						{
							item.y = positionY;
							item.height = tileHeight;
							break;
						}
						case TILE_VERTICAL_ALIGN_TOP:
						{
							item.y = positionY;
							break;
						}
						case TILE_VERTICAL_ALIGN_BOTTOM:
						{
							item.y = positionY + tileHeight - item.height;
							break;
						}
						default: //middle or unknown
						{
							item.y = positionY + (tileHeight - item.height) / 2;
						}
					}
					if(this._useVirtualLayout)
					{
						HELPER_VECTOR.push(item);
					}
				}
				positionY += tileHeight + this._gap;
			}
			//align the last page
			if(this._paging != PAGING_NONE)
			{
				discoveredItems = this._useVirtualLayout ? HELPER_VECTOR : items;
				discoveredItemsFirstIndex = this._useVirtualLayout ? 0 : (nextPageStartIndex - perPage);
				discoveredItemsLastIndex = this._useVirtualLayout ? (HELPER_VECTOR.length - 1) : (i - 1);
				this.applyHorizontalAlign(discoveredItems, discoveredItemsFirstIndex, discoveredItemsLastIndex, totalPageWidth, availablePageWidth);
				this.applyVerticalAlign(discoveredItems, discoveredItemsFirstIndex, discoveredItemsLastIndex, totalPageHeight, availablePageHeight);
			}

			var totalWidth:Number = positionX + tileWidth + this._paddingRight;
			if(!isNaN(availableWidth))
			{
				if(this._paging == PAGING_VERTICAL)
				{
					totalWidth = availableWidth;
				}
				else if(this._paging == PAGING_HORIZONTAL)
				{
					totalWidth = Math.ceil(itemCount / perPage) * availableWidth;
				}
			}
			var totalHeight:Number = totalPageHeight;
			if(!isNaN(availableHeight) && this._paging == PAGING_VERTICAL)
			{
				totalHeight = Math.ceil(itemCount / perPage) * availableHeight;
			}

			if(isNaN(availableWidth))
			{
				availableWidth = totalWidth;
			}
			if(isNaN(availableHeight))
			{
				availableHeight = totalHeight;
			}
			availableWidth = Math.max(minWidth, availableWidth);
			availableHeight = Math.max(minHeight, availableHeight);

			if(this._paging == PAGING_NONE)
			{
				discoveredItems = this._useVirtualLayout ? HELPER_VECTOR : items;
				discoveredItemsLastIndex = discoveredItems.length - 1;
				this.applyHorizontalAlign(discoveredItems, 0, discoveredItemsLastIndex, totalWidth, availableWidth);
				this.applyVerticalAlign(discoveredItems, 0, discoveredItemsLastIndex, totalHeight, availableHeight);
			}
			HELPER_VECTOR.length = 0;

			if(!result)
			{
				result = new LayoutBoundsResult();
			}
			result.contentWidth = totalWidth;
			result.contentHeight = totalHeight;
			result.viewPortWidth = availableWidth;
			result.viewPortHeight = availableHeight;

			return result;
		}

		/**
		 * @inheritDoc
		 */
		public function measureViewPort(itemCount:int, viewPortBounds:ViewPortBounds = null, result:Point = null):Point
		{
			if(!result)
			{
				result = new Point();
			}
			const explicitWidth:Number = viewPortBounds ? viewPortBounds.explicitWidth : NaN;
			const explicitHeight:Number = viewPortBounds ? viewPortBounds.explicitHeight : NaN;
			const needsWidth:Boolean = isNaN(explicitWidth);
			const needsHeight:Boolean = isNaN(explicitHeight);
			if(!needsWidth && !needsHeight)
			{
				result.x = explicitWidth;
				result.y = explicitHeight;
				return result;
			}

			const boundsX:Number = viewPortBounds ? viewPortBounds.x : 0;
			const boundsY:Number = viewPortBounds ? viewPortBounds.y : 0;
			const minWidth:Number = viewPortBounds ? viewPortBounds.minWidth : 0;
			const minHeight:Number = viewPortBounds ? viewPortBounds.minHeight : 0;
			const maxWidth:Number = viewPortBounds ? viewPortBounds.maxWidth : Number.POSITIVE_INFINITY;
			const maxHeight:Number = viewPortBounds ? viewPortBounds.maxHeight : Number.POSITIVE_INFINITY;

			const tileWidth:Number = this._useSquareTiles ? Math.max(0, this._typicalItemWidth, this._typicalItemHeight) : this._typicalItemWidth;
			const tileHeight:Number = this._useSquareTiles ? tileWidth : this._typicalItemHeight;
			var availableWidth:Number = NaN;
			var availableHeight:Number = NaN;
			var horizontalTileCount:int = 1;
			if(!isNaN(explicitWidth))
			{
				availableWidth = explicitWidth;
				horizontalTileCount = Math.max(1, (explicitWidth - this._paddingLeft - this._paddingRight + this._gap) / (tileWidth + this._gap));
			}
			else if(!isNaN(maxWidth))
			{
				availableWidth = maxWidth;
				horizontalTileCount = Math.max(1, (maxWidth - this._paddingLeft - this._paddingRight + this._gap) / (tileWidth + this._gap));
			}
			var verticalTileCount:int = Math.max(1, itemCount);
			if(!isNaN(explicitHeight))
			{
				availableHeight = explicitHeight;
				verticalTileCount = Math.max(1, (explicitHeight - this._paddingTop - this._paddingBottom + this._gap) / (tileHeight + this._gap));
			}
			else if(!isNaN(maxHeight))
			{
				availableHeight = maxHeight;
				verticalTileCount = Math.max(1, (maxHeight - this._paddingTop - this._paddingBottom + this._gap) / (tileHeight + this._gap));
			}

			const totalPageWidth:Number = horizontalTileCount * (tileWidth + this._gap) - this._gap + this._paddingLeft + this._paddingRight;
			const totalPageHeight:Number = verticalTileCount * (tileHeight + this._gap) - this._gap + this._paddingTop + this._paddingBottom;
			const availablePageWidth:Number = isNaN(availableWidth) ? totalPageWidth : availableWidth;
			const availablePageHeight:Number = isNaN(availableHeight) ? totalPageHeight : availableHeight;

			const startX:Number = boundsX + this._paddingLeft;

			const perPage:int = horizontalTileCount * verticalTileCount;

			var pageIndex:int = 0;
			var nextPageStartIndex:int = perPage;
			var positionX:Number = startX;
			for(var i:int = 0; i < itemCount; i++)
			{
				if(i != 0 && i % verticalTileCount == 0)
				{
					positionX += tileWidth + this._gap;
				}
				if(i == nextPageStartIndex)
				{
					pageIndex++;
					nextPageStartIndex += perPage;

					//we can use availableWidth and availableHeight here without
					//checking if they're NaN because we will never reach a
					//new page without them already being calculated.
					if(this._paging == PAGING_HORIZONTAL)
					{
						positionX = startX + availableWidth * pageIndex;
					}
					else if(this._paging == PAGING_VERTICAL)
					{
						positionX = startX;
					}
				}
			}

			var totalWidth:Number = positionX + tileWidth + this._paddingRight;
			if(!isNaN(availableWidth))
			{
				if(this._paging == PAGING_VERTICAL)
				{
					totalWidth = availableWidth;
				}
				else if(this._paging == PAGING_HORIZONTAL)
				{
					totalWidth = Math.ceil(itemCount / perPage) * availableWidth;
				}
			}
			var totalHeight:Number = totalPageHeight;
			if(!isNaN(availableHeight) && this._paging == PAGING_VERTICAL)
			{
				totalHeight = Math.ceil(itemCount / perPage) * availableHeight;
			}
			result.x = needsWidth ? Math.max(minWidth, totalWidth) : explicitWidth;
			result.y = needsHeight ? Math.max(minHeight, totalHeight) : explicitHeight;
			return result;
		}

		/**
		 * @inheritDoc
		 */
		public function getVisibleIndicesAtScrollPosition(scrollX:Number, scrollY:Number, width:Number, height:Number, itemCount:int, result:Vector.<int> = null):Vector.<int>
		{
			if(!result)
			{
				result = new <int>[];
			}
			result.length = 0;
			const tileWidth:Number = this._useSquareTiles ? Math.max(0, this._typicalItemWidth, this._typicalItemHeight) : this._typicalItemWidth;
			const tileHeight:Number = this._useSquareTiles ? tileWidth : this._typicalItemHeight;
			const verticalTileCount:int = Math.max(1, (height - this._paddingTop - this._paddingBottom + this._gap) / (tileHeight + this._gap));
			if(this._paging != PAGING_NONE)
			{
				var horizontalTileCount:int = Math.max(1, (width - this._paddingLeft - this._paddingRight + this._gap) / (tileWidth + this._gap));
				const perPage:Number = horizontalTileCount * verticalTileCount;
				if(this._paging == PAGING_HORIZONTAL)
				{
					var startPageIndex:int = Math.round(scrollX / width);
					var minimum:int = startPageIndex * perPage;
					if(minimum > 0)
					{
						var pageStartPosition:Number = startPageIndex * width;
						var partialPageSize:Number = scrollX - pageStartPosition;
						if(partialPageSize < 0)
						{
							minimum -= verticalTileCount * Math.ceil((-partialPageSize - this._paddingRight) / (tileWidth + this._gap));
						}
						else if(partialPageSize > 0)
						{
							minimum += verticalTileCount * Math.floor((partialPageSize - this._paddingLeft) / (tileWidth + this._gap));
						}
					}
					var maximum:int = minimum + perPage + 2 * verticalTileCount - 1;
					for(var i:int = minimum; i <= maximum; i++)
					{
						result.push(i);
					}
					return result;
				}
				else
				{
					startPageIndex = Math.round(scrollY / height);
					minimum = startPageIndex * perPage;
					var totalColumnHeight:Number = verticalTileCount * (tileHeight + this._gap) - this._gap;
					var topSideOffset:Number = 0;
					var bottomSideOffset:Number = 0;
					if(totalColumnHeight < height)
					{
						if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
						{
							topSideOffset = height - this._paddingTop - this._paddingBottom - totalColumnHeight;
							bottomSideOffset = 0;
						}
						else if(this._verticalAlign == VERTICAL_ALIGN_MIDDLE)
						{
							topSideOffset = bottomSideOffset = (height - this._paddingTop - this._paddingBottom - totalColumnHeight) / 2;
						}
						else if(this._verticalAlign == VERTICAL_ALIGN_TOP)
						{
							topSideOffset = 0;
							bottomSideOffset = height - this._paddingTop - this._paddingBottom - totalColumnHeight;
						}
					}
					var rowOffset:int = 0;
					pageStartPosition = startPageIndex * height;
					partialPageSize = scrollY - pageStartPosition;
					if(partialPageSize < 0)
					{
						partialPageSize = Math.max(0, -partialPageSize - this._paddingBottom - bottomSideOffset);
						rowOffset = -Math.floor(partialPageSize / (tileHeight + this._gap)) - 1;
						minimum += -perPage + verticalTileCount + rowOffset;
					}
					else if(partialPageSize > 0)
					{
						partialPageSize = Math.max(0, partialPageSize - this._paddingTop - topSideOffset);
						rowOffset = Math.floor(partialPageSize / (tileHeight + this._gap));
						minimum += rowOffset;
					}
					if(minimum < 0)
					{
						minimum = 0;
						rowOffset = 0;
					}
					var rowIndex:int = (verticalTileCount + rowOffset) % verticalTileCount;
					var columnIndex:int = 0;
					var maxRowIndex:int = rowIndex + verticalTileCount + 2;
					var pageStart:int = int(minimum / perPage) * perPage;
					i = minimum;
					do
					{
						result.push(i);
						columnIndex++;
						if(columnIndex == horizontalTileCount)
						{
							columnIndex = 0;
							rowIndex++;
							if(rowIndex == verticalTileCount)
							{
								rowIndex = 0;
								pageStart += perPage;
								maxRowIndex -= verticalTileCount;
							}
							i = pageStart + rowIndex - verticalTileCount;
						}
						i += verticalTileCount;
					}
					while(rowIndex != maxRowIndex)
					return result;
				}
			}
			else
			{
				var columnIndexOffset:int = 0;
				const totalColumnWidth:Number = Math.ceil(itemCount / verticalTileCount) * (tileWidth + this._gap) - this._gap;
				if(totalColumnWidth < width)
				{
					if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
					{
						columnIndexOffset = Math.ceil((width - totalColumnWidth) / (tileWidth + this._gap));
					}
					else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
					{
						columnIndexOffset = Math.ceil((width - totalColumnWidth) / (tileWidth + this._gap) / 2);
					}
				}
				columnIndex = -columnIndexOffset + Math.floor((scrollX - this._paddingLeft + this._gap) / (tileWidth + this._gap));
				horizontalTileCount = Math.ceil((width - this._paddingLeft + this._gap) / (tileWidth + this._gap)) + 1;
				minimum = columnIndex * verticalTileCount;
				maximum = minimum + verticalTileCount * horizontalTileCount;
				for(i = minimum; i <= maximum; i++)
				{
					result.push(i);
				}
			}
			return result;
		}

		/**
		 * @inheritDoc
		 */
		public function getScrollPositionForIndex(index:int, items:Vector.<DisplayObject>, x:Number, y:Number, width:Number, height:Number, result:Point = null):Point
		{
			if(!result)
			{
				result = new Point();
			}

			const itemCount:int = items.length;
			var tileWidth:Number = this._useSquareTiles ? Math.max(0, this._typicalItemWidth, this._typicalItemHeight) : this._typicalItemWidth;
			var tileHeight:Number = this._useSquareTiles ? tileWidth : this._typicalItemHeight;
			//a virtual layout assumes that all items are the same size as
			//the typical item, so we don't need to measure every item in
			//that case
			if(!this._useVirtualLayout)
			{
				for(var i:int = 0; i < itemCount; i++)
				{
					var item:DisplayObject = items[i];
					if(!item)
					{
						continue;
					}
					tileWidth = this._useSquareTiles ? Math.max(tileWidth, item.width, item.height) : Math.max(tileWidth, item.width);
					tileHeight = this._useSquareTiles ? Math.max(tileWidth, tileHeight) : Math.max(tileHeight, item.height);
				}
			}
			const verticalTileCount:int = Math.max(1, (height - this._paddingTop - this._paddingBottom + this._gap) / (tileHeight + this._gap));
			if(this._paging != PAGING_NONE)
			{
				const horizontalTileCount:int = Math.max(1, (width - this._paddingLeft - this._paddingRight + this._gap) / (tileWidth + this._gap));
				const perPage:Number = horizontalTileCount * verticalTileCount;
				const pageIndex:int = index / perPage;
				if(this._paging == PAGING_HORIZONTAL)
				{
					result.x = pageIndex * width;
					result.y = 0;
				}
				else
				{
					result.x = 0;
					result.y = pageIndex * height;
				}
			}
			else
			{
				result.x = this._paddingLeft + ((tileWidth + this._gap) * index / verticalTileCount) + (width - tileWidth) / 2;
				result.y = 0;
			}
			return result;
		}

		/**
		 * @private
		 */
		protected function applyHorizontalAlign(items:Vector.<DisplayObject>, startIndex:int, endIndex:int, totalItemWidth:Number, availableWidth:Number):void
		{
			if(totalItemWidth >= availableWidth)
			{
				return;
			}
			var horizontalAlignOffsetX:Number = 0;
			if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
			{
				horizontalAlignOffsetX = availableWidth - totalItemWidth;
			}
			else if(this._horizontalAlign != HORIZONTAL_ALIGN_LEFT)
			{
				//we're going to default to center if we encounter an
				//unknown value
				horizontalAlignOffsetX = (availableWidth - totalItemWidth) / 2;
			}
			if(horizontalAlignOffsetX != 0)
			{
				for(var i:int = startIndex; i <= endIndex; i++)
				{
					var item:DisplayObject = items[i];
					item.x += horizontalAlignOffsetX;
				}
			}
		}

		/**
		 * @private
		 */
		protected function applyVerticalAlign(items:Vector.<DisplayObject>, startIndex:int, endIndex:int, totalItemHeight:Number, availableHeight:Number):void
		{
			if(totalItemHeight >= availableHeight)
			{
				return;
			}
			var verticalAlignOffsetY:Number = 0;
			if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
			{
				verticalAlignOffsetY = availableHeight - totalItemHeight;
			}
			else if(this._verticalAlign == VERTICAL_ALIGN_MIDDLE)
			{
				verticalAlignOffsetY = (availableHeight - totalItemHeight) / 2;
			}
			if(verticalAlignOffsetY != 0)
			{
				for(var i:int = startIndex; i <= endIndex; i++)
				{
					var item:DisplayObject = items[i];
					item.y += verticalAlignOffsetY;
				}
			}
		}
	}
}
