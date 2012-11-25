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
package feathers.display
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.textures.Texture;
	import starling.utils.MatrixUtil;

	/**
	 * Adds capabilities to Starling's <code>Image</code> class, including
	 * <code>scrollRect</code> and pixel snapping.
	 */
	public class Image extends starling.display.Image implements IDisplayObjectWithScrollRect
	{
		private static const HELPER_POINT:Point = new Point();
		private static const HELPER_MATRIX:Matrix = new Matrix();
		private static const HELPER_RECTANGLE:Rectangle = new Rectangle();
		
		/**
		 * Constructor.
		 */
		public function Image(texture:Texture)
		{
			super(texture);
		}

		/**
		 * @private
		 */
		override public function set width(value:Number):void
		{
			var actualWidth:Number = super.getBounds(this, HELPER_RECTANGLE).width;
			super.width = value;
			//we need to override the default scaleX modification here because
			//the "actual" width is modified by the scroll rect.
			if(actualWidth != 0.0)
			{
				this.scaleX = value / actualWidth;
			}
			else
			{
				this.scaleX = 1.0;
			}
		}

		/**
		 * @private
		 */
		override public function set height(value:Number):void
		{
			var actualHeight:Number = super.getBounds(this, HELPER_RECTANGLE).height;
			super.height = value;
			if(actualHeight != 0.0)
			{
				this.scaleY = value / actualHeight;
			}
			else
			{
				this.scaleY = 1.0;
			}
		}
		
		/**
		 * @private
		 */
		private var _scrollRect:Rectangle;
		
		/**
		 * @inheritDoc
		 */
		public function get scrollRect():Rectangle
		{
			return this._scrollRect;
		}
		
		/**
		 * @private
		 */
		public function set scrollRect(value:Rectangle):void
		{
			this._scrollRect = value;
			if(this._scrollRect)
			{
				if(!this._scaledScrollRectXY)
				{
					this._scaledScrollRectXY = new Point();
				}
				if(!this._scissorRect)
				{
					this._scissorRect = new Rectangle();
				}
			}
			else
			{
				this._scaledScrollRectXY = null;
				this._scissorRect = null;
			}
		}
		
		private var _scaledScrollRectXY:Point = new Point();
		private var _scissorRect:Rectangle = new Rectangle();

		/**
		 * @private
		 */
		private var _snapToPixels:Boolean = false;

		/**
		 * Determines if the image should be snapped to the nearest global whole
		 * pixel when rendered.
		 */
		public function get snapToPixels():Boolean
		{
			return _snapToPixels;
		}

		/**
		 * @private
		 */
		public function set snapToPixels(value:Boolean):void
		{
			if(this._snapToPixels == value)
			{
				return;
			}
			this._snapToPixels = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			if(this._scrollRect)
			{
				if(!resultRect)
				{
					resultRect = new Rectangle();
				}
				if(targetSpace == this)
				{
					resultRect.x = 0;
					resultRect.y = 0;
					resultRect.width = this._scrollRect.width;
					resultRect.height = this._scrollRect.height;
				}
				else
				{
					this.getTransformationMatrix(targetSpace, HELPER_MATRIX);
					MatrixUtil.transformCoords(HELPER_MATRIX, 0, 0, HELPER_POINT);
					resultRect.x = HELPER_POINT.x;
					resultRect.y = HELPER_POINT.y;
					resultRect.width = HELPER_MATRIX.a * this._scrollRect.width + HELPER_MATRIX.c * this._scrollRect.height;
					resultRect.height = HELPER_MATRIX.d * this._scrollRect.height + HELPER_MATRIX.b * this._scrollRect.width;
				}
				return resultRect;
			}
			return super.getBounds(targetSpace, resultRect);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			if(this._scrollRect)
			{
				const scale:Number = Starling.contentScaleFactor;
				this.getBounds(this.stage, this._scissorRect);
				this._scissorRect.x *= scale;
				this._scissorRect.y *= scale;
				this._scissorRect.width *= scale;
				this._scissorRect.height *= scale;
				
				this.getTransformationMatrix(this.stage, HELPER_MATRIX);
				this._scaledScrollRectXY.x = this._scrollRect.x * HELPER_MATRIX.a;
				this._scaledScrollRectXY.y = this._scrollRect.y * HELPER_MATRIX.d;
				
				const oldRect:Rectangle = ScrollRectManager.currentScissorRect;
				if(oldRect)
				{
					this._scissorRect.x += ScrollRectManager.scrollRectOffsetX * scale;
					this._scissorRect.y += ScrollRectManager.scrollRectOffsetY * scale;
					this._scissorRect = this._scissorRect.intersection(oldRect);
				}
				this._scissorRect.x = Math.round(this._scissorRect.x);
				this._scissorRect.y = Math.round(this._scissorRect.y);
				const viewPort:Rectangle = Starling.current.viewPort;
				//isEmpty() && <= 0 don't work here for some reason
				if(this._scissorRect.width < 1 || this._scissorRect.height < 1 ||
					this._scissorRect.x >= viewPort.width ||
					this._scissorRect.y >= viewPort.height ||
					(this._scissorRect.x + this._scissorRect.width) <= 0 ||
					(this._scissorRect.y + this._scissorRect.height) <= 0)
				{
					return;
				}
				support.finishQuadBatch();
				Starling.context.setScissorRectangle(this._scissorRect);
				ScrollRectManager.currentScissorRect = this._scissorRect;
				ScrollRectManager.scrollRectOffsetX -= this._scaledScrollRectXY.x;
				ScrollRectManager.scrollRectOffsetY -= this._scaledScrollRectXY.y;
				support.translateMatrix(-this._scrollRect.x, -this._scrollRect.y);
			}
			if(this._snapToPixels)
			{
				this.getTransformationMatrix(this.stage, HELPER_MATRIX);
				support.translateMatrix(Math.round(HELPER_MATRIX.tx) - HELPER_MATRIX.tx, Math.round(HELPER_MATRIX.ty) - HELPER_MATRIX.ty);
			}
			super.render(support, alpha);
			if(this._scrollRect)
			{
				support.finishQuadBatch();
			}
			if(this._snapToPixels)
			{
				support.translateMatrix(-(Math.round(HELPER_MATRIX.tx) - HELPER_MATRIX.tx), -(Math.round(HELPER_MATRIX.ty) - HELPER_MATRIX.ty));
			}
			if(this._scrollRect)
			{
				support.translateMatrix(this._scrollRect.x, this._scrollRect.y);
				ScrollRectManager.scrollRectOffsetX += this._scaledScrollRectXY.x;
				ScrollRectManager.scrollRectOffsetY += this._scaledScrollRectXY.y;
				ScrollRectManager.currentScissorRect = oldRect;
				Starling.context.setScissorRectangle(oldRect);
			}
		}
	}
}