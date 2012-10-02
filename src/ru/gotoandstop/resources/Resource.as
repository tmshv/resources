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
		
		private var _id:String;
		public function get id():String{
			return this._id;
		}
		
		private var _bytes:ByteArray;
		public function get bytes():ByteArray{
			return this._bytes;
		}
		
		private var _data:Object;
		public function get data():Object{
			return this._data;
		}
		
		private var _loader:ResourceLoader;
		public function get loader():ResourceLoader{
			return this._loader;
		}
		public function set loader(value:ResourceLoader):void{
			this._loader = value;
		}

        public var dataCallback:Function;

		public function Resource(id:String, url:String, callback:Function){
			super();
			_id = id;
			_url = url;
            dataCallback = callback;
		}
		
		public function push():void{
            if(loader) {
                loader.add(this);
            }
		}
		
		public function setData(bytes:ByteArray, data:Object=null):void{
			this._bytes = bytes;
			this._data = data;
            dataCallback(this);
		}
		
		public override function toString():String{
			return "[Resource id]".replace("id", id);
		}
	}
}