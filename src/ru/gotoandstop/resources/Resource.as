package ru.gotoandstop.resources{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.utils.ByteArray;
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="open", type="flash.events.Event")]
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]
	
	/**
	*
	* @author Roman Timashev (roman@tmshv.ru)
	*/
	public class Resource extends EventDispatcher{
		private var _url:String;
		public function get url():String{
			return this._url;
		}
		
		private var _key:String;
		public function get key():String{
			return this._key;
		}
		
		private var _bytes:ByteArray;
		public function get bytes():ByteArray{
			return this._bytes;
		}
		
		private var _data:*;
		public function get data():*{
			return this._data;
		}
		
		private var _loaded:Boolean;
		public function get loaded():Boolean{
			return this._loaded;
		}
		
		private var __loader:ResourceLoader;
		internal function get loader():ResourceLoader{
			return this.__loader;
		}
		internal function set loader(value:ResourceLoader):void{
			this.__loader = value;
		}

        public var completeCallback:Function;

		public function Resource(key:String, url:String){
			super();
			this._key = key;
			this._url = url;
		}
		
		public function reload():void{
			//this.__loader.addResource(this);
		}
		
		/**
		 * Над экземпляром класса <code>Resource</code> нельзя вызвать метод <code>dispatchEvent</code>
		 * @param event
		 * @return 
		 * 
		 */
		public override function dispatchEvent(event:Event):Boolean{
			throw new IllegalOperationError();
		}
		
		/**
		 * События диспетчит по просьбе <code>ResourceLoader</code>
		 * @param event
		 * @return 
		 * 
		 */
		internal function dispatchEvent2(event:Event):Boolean{
            if(event.type==Event.COMPLETE){
                if(completeCallback != null) {
                    completeCallback(this);
                }
            }
			return super.dispatchEvent(event);
		}
		
		internal function setData(bytes:ByteArray, data:*=null):void{
			this._bytes = bytes;
			this._data = data;
		}
		
		public override function toString():String{
			var message:String = '[Resource key:<key>]';
			return message.replace(/<key>/, this._key);
		}
	}
}