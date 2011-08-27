package ru.gotoandstop.resources{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.ByteArray;
	
	/**
	 *
	 * @author Timashev Roman
	 */
	public class ResourceLibrary extends EventDispatcher{
		private static var createForLoader:Boolean;
		internal static function createWithLoader(loader:ResourceLoader):ResourceLibrary{
			var lib:ResourceLibrary = new ResourceLibrary();
			lib.init(loader);
			return lib;
		}
		
		private var _loader:ResourceLoader;
		public function get loader():ResourceLoader{
			return this._loader;
		}
		
		private var storage:Object;
		
		public function ResourceLibrary(loaderStreamNumber:uint=1){
			super();
			this.init(
				ResourceLoader.createWithLibrary(loaderStreamNumber, this)
			);
		}
		
		private function init(loader:ResourceLoader):void{
			this._loader = loader;
			this.storage = new Object();
		}
		
		internal function add(resource:Resource):Resource{
			this.storage[resource.key] = resource;
			return resource;
		}
		
//		public function addAsBytes(bytes:ByteArray, key:String):Resource{
//			
//		}
		
//		public function addAsImage(bitmapData:BitmapData, key:String):Resource{
//			
//		}
		
//		public function addAsSWF(flash:DisplayObject, key:String):Resource{
//			
//		}
		
		public function get(key:String):Resource{
			return this.storage[key] as Resource;
		}
		
		public function getKeys():Array{
			var list:Array = new Array();
			for(var key:String in this.storage){
				list.push(key);
			}
			return list;
		}
	}
}