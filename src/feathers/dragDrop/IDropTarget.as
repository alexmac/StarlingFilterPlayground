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
package feathers.dragDrop
{
	import starling.events.Event;

	/**
	 * Dispatched when the touch enters the drop target's bounds. Call
	 * <code>acceptDrag()</code> on the drag and drop manager to allow
	 * the drag to the be dropped on the target.
	 *
	 * @eventType = feathers.events.DragDropEvent.DRAG_ENTER
	 */
	[Event(name="dragEnter",type="feathers.events.DragDropEvent")]

	/**
	 * Dispatched when the touch moves within the drop target's bounds.
	 *
	 * @eventType = feathers.events.DragDropEvent.DRAG_MOVE
	 */
	[Event(name="dragMove",type="feathers.events.DragDropEvent")]

	/**
	 * Dispatched when the touch exits the drop target's bounds or when
	 * the drag is cancelled while the touch is within the drop target's
	 * bounds. Will <em>not</em> be dispatched if the drop target hasn't
	 * accepted the drag.
	 *
	 * @eventType = feathers.events.DragDropEvent.DRAG_EXIT
	 */
	[Event(name="dragExit",type="feathers.events.DragDropEvent")]

	/**
	 * Dispatched when an accepted drag is dropped on the target. Will
	 * <em>not</em> be dispatched if the drop target hasn't accepted the
	 * drag.
	 *
	 * @eventType = feathers.events.DragDropEvent.DRAG_DROP
	 */
	[Event(name="dragDrop",type="feathers.events.DragDropEvent")]

	/**
	 * A display object that can accept data dropped by the drag and drop
	 * manager.
	 *
	 * @see DragDropManager
	 */
	public interface IDropTarget
	{
		function dispatchEvent(event:Event):void;
		function dispatchEventWith(type:String, bubbles:Boolean = false, data:Object = null):void;
	}
}
