package com.vimeo.events
{
	import flash.events.Event;
	
	/**
	 * @author Tilman Griesel <tilman.griesel@dozeo.com>
	 */
	public class VimeoPlayerEvent extends Event
	{
		public static const COMPLETE : String       = 'complete';
		public static const ERROR : String          = 'error';
		public static const FINISH : String         = 'finish';
		public static const LOAD_PROGRESS : String  = 'loadProgress';
		public static const PAUSE : String          = 'pause';
		public static const PLAY : String           = 'play';
		public static const PLAY_PROGRESS : String  = 'playProgress';
		public static const READY : String          = 'ready';
		public static const SEEK : String           = 'seek';
		
		public function VimeoPlayerEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false):void 
		{ 
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event 
		{ 
			return new VimeoPlayerEvent(this.type, this.bubbles, this.cancelable);
		} 
		
		override public function toString():String 
		{ 
			return formatToString("VimeoPlayerEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
	}
}