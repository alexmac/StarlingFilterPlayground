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
	import starling.animation.IAnimatable;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;

	[ExcludeClass]
	public final class ValidationQueue implements IAnimatable
	{
		/**
		 * Constructor.
		 */
		public function ValidationQueue()
		{
		}

		private var _starling:Starling;

		private var _isValidating:Boolean = false;

		/**
		 * If true, the queue is currently validating.
		 */
		public function get isValidating():Boolean
		{
			return this._isValidating;
		}

		private var _delayedQueue:Vector.<IFeathersControl> = new <IFeathersControl>[];
		private var _queue:Vector.<IFeathersControl> = new <IFeathersControl>[];

		/**
		 * @private
		 * Adds a control to the queue.
		 */
		public function addControl(control:IFeathersControl, delayIfValidating:Boolean):void
		{
			const currentStarling:Starling = Starling.current;
			if(currentStarling && this._starling != currentStarling)
			{
				this._starling = currentStarling;
				currentStarling.juggler.add(this);
			}
			const currentQueue:Vector.<IFeathersControl> = (this._isValidating && delayIfValidating) ? this._delayedQueue : this._queue;
			const queueLength:int = currentQueue.length;
			const containerControl:DisplayObjectContainer = control as DisplayObjectContainer;
			for(var i:int = 0; i < queueLength; i++)
			{
				var item:DisplayObject = DisplayObject(currentQueue[i]);
				if(control == item && currentQueue == this._queue)
				{
					//already queued
					return;
				}
				if(containerControl && containerControl.contains(item))
				{
					break;
				}
			}
			currentQueue.splice(i, 0, control);
		}

		/**
		 * @private
		 */
		public function advanceTime(time:Number):void
		{
			this._isValidating = true;
			while(this._queue.length > 0)
			{
				var item:IFeathersControl = this._queue.shift();
				item.validate();
			}
			const temp:Vector.<IFeathersControl> = this._queue;
			this._queue = this._delayedQueue;
			this._delayedQueue = temp;
			this._isValidating = false;
		}
	}
}
