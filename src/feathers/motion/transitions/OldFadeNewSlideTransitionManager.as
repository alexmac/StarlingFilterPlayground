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
package feathers.motion.transitions
{
	import feathers.controls.IScreen;
	import feathers.controls.ScreenNavigator;

	import flash.utils.getQualifiedClassName;

	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;

	/**
	 * A transition for <code>ScreenNavigator</code> that fades out the old
	 * screen and slides in the new screen from an edge. The slide starts from
	 * the right or left, depending on if the manager determines that the
	 * transition is a push or a pop.
	 *
	 * <p>Whether a screen change is supposed to be a push or a pop is
	 * determined automatically. The manager generates an identifier from the
	 * fully-qualified class name of the screen, and if present, the
	 * <code>screenID</code> defined by <code>IScreen</code> instances. If the
	 * generated identifier is present on the stack, a screen change is
	 * considered a pop. If the token is not present, it's a push. Screen IDs
	 * should be tailored to this behavior to avoid false positives.</p>
	 *
	 * <p>If your navigation structure requires explicit pushing and popping, a
	 * custom transition manager is probably better.</p>
	 *
	 * @see feathers.controls.ScreenNavigator
	 */
	public class OldFadeNewSlideTransitionManager
	{
		/**
		 * Constructor.
		 */
		public function OldFadeNewSlideTransitionManager(navigator:ScreenNavigator, quickStack:Class = null)
		{
			if(!navigator)
			{
				throw new ArgumentError("ScreenNavigator cannot be null.");
			}
			this.navigator = navigator;
			if(quickStack)
			{
				this._stack.push(quickStack);
			}
			this.navigator.transition = this.onTransition;
		}

		/**
		 * The <code>ScreenNavigator</code> being managed.
		 */
		protected var navigator:ScreenNavigator;

		/**
		 * @private
		 */
		protected var _stack:Vector.<String> = new <String>[];

		/**
		 * @private
		 */
		protected var _activeTransition:Tween;

		/**
		 * @private
		 */
		protected var _savedCompleteHandler:Function;

		/**
		 * @private
		 */
		protected var _savedOtherTarget:DisplayObject;
		
		/**
		 * The duration of the transition.
		 */
		public var duration:Number = 0.25;

		/**
		 * A delay before the transition starts, measured in seconds. This may
		 * be required on low-end systems that will slow down for a short time
		 * after heavy texture uploads.
		 */
		public var delay:Number = 0.1;
		
		/**
		 * The easing function to use.
		 */
		public var ease:Object = Transitions.EASE_OUT;
		
		/**
		 * Removes all saved classes from the stack that are used to determine
		 * which side of the <code>ScreenNavigator</code> the new screen will
		 * slide in from.
		 */
		public function clearStack():void
		{
			this._stack.length = 0;
		}
		
		/**
		 * The function passed to the <code>transition</code> property of the
		 * <code>ScreenNavigator</code>.
		 */
		protected function onTransition(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function):void
		{
			if(!oldScreen)
			{
				if(newScreen)
				{
					newScreen.x = 0;
				}
				onComplete();
				return;
			}
			
			if(this._activeTransition)
			{
				Starling.juggler.remove(this._activeTransition);
				this._activeTransition = null;
				this._savedOtherTarget = null;
			}
			
			this._savedCompleteHandler = onComplete;
			
			if(!newScreen)
			{
				oldScreen.x = 0;
				this._activeTransition = new Tween(oldScreen, this.duration, this.ease);
				this._activeTransition.fadeTo(0);
				this._activeTransition.delay = this.delay;
				this._activeTransition.onComplete = activeTransition_onComplete;
				Starling.juggler.add(this._activeTransition);
				return;
			}
			var newScreenClassAndID:String = getQualifiedClassName(newScreen);
			if(newScreen is IScreen)
			{
				newScreenClassAndID += "~" + IScreen(newScreen).screenID;
			}
			var stackIndex:int = this._stack.indexOf(newScreenClassAndID);
			if(stackIndex < 0)
			{
				var oldScreenClassAndID:String = getQualifiedClassName(oldScreen);
				if(oldScreen is IScreen)
				{
					oldScreenClassAndID += "~" + IScreen(oldScreen).screenID;
				}
				this._stack.push(oldScreenClassAndID);
				oldScreen.x = 0;
				newScreen.x = this.navigator.width;
			}
			else
			{
				this._stack.length = stackIndex;
				oldScreen.x = 0;
				newScreen.x = -this.navigator.width;
			}
			newScreen.alpha = 1;
			this._savedOtherTarget = oldScreen;
			this._activeTransition = new Tween(newScreen, this.duration, this.ease);
			this._activeTransition.animate("x", 0);
			this._activeTransition.delay = this.delay;
			this._activeTransition.onUpdate = activeTransition_onUpdate;
			this._activeTransition.onComplete = activeTransition_onComplete;
			Starling.juggler.add(this._activeTransition);
		}
		
		/**
		 * @private
		 */
		protected function activeTransition_onUpdate():void
		{
			if(this._savedOtherTarget)
			{
				this._savedOtherTarget.alpha = 1 - this._activeTransition.currentTime / this._activeTransition.totalTime;
			}
		}
		
		/**
		 * @private
		 */
		protected function activeTransition_onComplete():void
		{
			this._activeTransition = null;
			this._savedOtherTarget = null;
			if(this._savedCompleteHandler != null)
			{
				this._savedCompleteHandler();
			}
		}
	}
}