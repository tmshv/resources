package ru.gotoandstop.resources{
	import flash.events.Event;
	
	/*
	*
	* @author Timashev Roman
	*/
	public class ResourceLoaderEvent extends Event{
		public static const COMPLETE:String = '';
		public static const QUEUE_COMPLETE:String = 'queueComplete';
		//public static const PROGRESSS:String;
		
		private var _alias:String;
		public function get alias():String{
			return this._alias;
		}
		
		public function ResourceLoaderEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
	}
}