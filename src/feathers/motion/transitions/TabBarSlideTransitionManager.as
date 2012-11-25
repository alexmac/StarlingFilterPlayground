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
	import feathers.controls.ScreenNavigator;
	import feathers.controls.TabBar;

	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;

	/**
	 * Slides new screens from the left or right depending on the old and new
	 * selected index values of a TabBar control.
	 *
	 * @see feathers.controls.ScreenNavigator
	 * @see feathers.controls.TabBar
	 */
	public class TabBarSlideTransitionManager
	{
		/**
		 * Constructor.
		 */
		public function TabBarSlideTransitionManager(navigator:ScreenNavigator, tabBar:TabBar)
		{
			if(!navigator)
			{
				throw new ArgumentError("ScreenNavigator cannot be null.");
			}
			this.navigator = navigator;
			this.tabBar = tabBar;
			this._oldIndex = tabBar.selectedIndex;
			this.tabBar.addEventListener(Event.CHANGE, tabBar_changeHandler);
			this.navigator.transition = this.onTransition;
		}

		/**
		 * The <code>ScreenNavigator</code> being managed.
		 */
		protected var navigator:ScreenNavigator;

		/**
		 * The <code>TabBar</code> that controls the navigation.
		 */
		protected var tabBar:TabBar;

		/**
		 * @private
		 */
		protected var _activeTransition:Tween;

		/**
		 * @private
		 */
		protected var _savedOtherTarget:DisplayObject;

		/**
		 * @private
		 */
		protected var _savedCompleteHandler:Function;

		/**
		 * @private
		 */
		protected var _oldScreen:DisplayObject;

		/**
		 * @private
		 */
		protected var _newScreen:DisplayObject;

		/**
		 * @private
		 */
		protected var _oldIndex:int;

		/**
		 * @private
		 */
		protected var _isFromRight:Boolean = true;

		/**
		 * @private
		 */
		protected var _isWaitingOnTabBarChange:Boolean = true;

		/**
		 * @private
		 */
		protected var _isWaitingOnTransitionChange:Boolean = true;

		/**
		 * The duration of the transition, measured in seconds.
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
		 * The function passed to the <code>transition</code> property of the
		 * <code>ScreenNavigator</code>.
		 */
		protected function onTransition(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function):void
		{
			this._oldScreen = oldScreen;
			this._newScreen = newScreen;
			this._savedCompleteHandler = onComplete;

			if(!this._isWaitingOnTabBarChange)
			{
				this.transitionNow();
			}
			else
			{
				this._isWaitingOnTransitionChange = false;
			}
		}

		/**
		 * @private
		 */
		protected function transitionNow():void
		{
			if(this._activeTransition)
			{
				this._savedOtherTarget  = null;
				Starling.juggler.remove(this._activeTransition);
				this._activeTransition = null;
			}

			if(!this._oldScreen || !this._newScreen)
			{
				if(this._newScreen)
				{
					this._newScreen.x = 0;
				}
				if(this._oldScreen)
				{
					this._oldScreen.x = 0;
				}
				if(this._savedCompleteHandler != null)
				{
					this._savedCompleteHandler();
				}
				return;
			}

			this._oldScreen.x = 0;
			var activeTransition_onUpdate:Function;
			if(this._isFromRight)
			{
				this._newScreen.x = this.navigator.width;
				activeTransition_onUpdate = this.activeTransitionFromRight_onUpdate;
			}
			else
			{
				this._newScreen.x = -this.navigator.width;
				activeTransition_onUpdate = this.activeTransitionFromLeft_onUpdate;
			}
			this._savedOtherTarget = this._oldScreen;
			this._activeTransition = new Tween(this._newScreen, this.duration, this.ease);
			this._activeTransition.animate("x", 0);
			this._activeTransition.delay = this.delay;
			this._activeTransition.onUpdate = activeTransition_onUpdate;
			this._activeTransition.onComplete = activeTransition_onComplete;
			Starling.juggler.add(this._activeTransition);

			this._oldScreen = null;
			this._newScreen = null;
			this._isWaitingOnTabBarChange = true;
			this._isWaitingOnTransitionChange = true;
		}

		/**
		 * @private
		 */
		protected function activeTransitionFromRight_onUpdate():void
		{
			if(this._savedOtherTarget)
			{
				const newScreen:DisplayObject = DisplayObject(this._activeTransition.target);
				this._savedOtherTarget.x = newScreen.x - this.navigator.width;
			}
		}

		/**
		 * @private
		 */
		protected function activeTransitionFromLeft_onUpdate():void
		{
			if(this._savedOtherTarget)
			{
				const newScreen:DisplayObject = DisplayObject(this._activeTransition.target);
				this._savedOtherTarget.x = newScreen.x + this.navigator.width;
			}
		}

		/**
		 * @private
		 */
		protected function activeTransition_onComplete():void
		{
			this._savedOtherTarget = null;
			this._activeTransition = null;
			if(this._savedCompleteHandler != null)
			{
				this._savedCompleteHandler();
			}
		}

		/**
		 * @private
		 */
		protected function tabBar_changeHandler(event:Event):void
		{
			var newIndex:int = this.tabBar.selectedIndex;
			this._isFromRight = newIndex > this._oldIndex;
			this._oldIndex = newIndex;

			if(!this._isWaitingOnTransitionChange)
			{
				this.transitionNow();
			}
			else
			{
				this._isWaitingOnTabBarChange = false;
			}
		}
	}
}