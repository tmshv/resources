package ru.gotoandstop.resources{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="open", type="flash.events.Event")]
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]
	
	/**
	 *
	 * @author Timashev Roman
	 */
	internal class SingleLoader extends EventDispatcher{
		public var busy:Boolean;
		public var loadAsDisplayObject:Boolean;
		
		private var _data:*;
		public function get data():*{
			return this._data;
		}
		
		private var _index:uint;
		public function get index():uint{
			return this._index;
		}
		
		public function SingleLoader(index:uint){
			super();
			this._index = index;
			this.busy = false;
		}
		
		public function load(request:URLRequest):void{
			if(this.loadAsDisplayObject){
				this.loadDisplayObject(request);
			}else{
				this.loadBytes(request);
			}
		}
		
		private function loadBytes(request:URLRequest):void{
			var loader:URLLoader = new URLLoader();
			this.addBytesListeners(loader);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(request);
		}
		
		private function loadDisplayObject(request:URLRequest):void{
			var loader:Loader = new Loader();
			this.addDOListeners(loader.contentLoaderInfo);
			loader.load(request);
		}
		
		private function handleLoadBytesComplete(event:Event):void{
			const loader:URLLoader = event.target as URLLoader;
			this.removeBytesListeners(loader);
			this._data = loader.data;
			super.dispatchEvent(event);
		}
		
		private function handlerLoadDOComplete(event:Event):void{
			const loader_info:LoaderInfo = event.target as LoaderInfo;
			this.removeDOListeners(loader_info);
			
			const loader:Loader = loader_info.loader;
			if(loader.content is Bitmap){
				this._data = (loader.content as Bitmap).bitmapData;
			}else{
				this._data = loader.content;
			}
			super.dispatchEvent(event);
		}
		
		private function handleLoadError(event:Event):void{
			this.removeDOListeners(event.target as IEventDispatcher);
			super.dispatchEvent(event);
		}
		
		private function addDOListeners(target:IEventDispatcher):void{
			target.addEventListener(Event.COMPLETE, this.handlerLoadDOComplete);
			target.addEventListener(IOErrorEvent.IO_ERROR, this.handleLoadError);
			target.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.handleLoadError);
			target.addEventListener(Event.OPEN, super.dispatchEvent);
			target.addEventListener(ProgressEvent.PROGRESS, super.dispatchEvent);
			target.addEventListener(HTTPStatusEvent.HTTP_STATUS, super.dispatchEvent);
		}
		
		private function removeDOListeners(target:IEventDispatcher):void{
			target.removeEventListener(Event.COMPLETE, this.handlerLoadDOComplete);
			target.removeEventListener(IOErrorEvent.IO_ERROR, this.handleLoadError);
			target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.handleLoadError);
			target.removeEventListener(Event.OPEN, super.dispatchEvent);
			target.removeEventListener(ProgressEvent.PROGRESS, super.dispatchEvent);
			target.removeEventListener(HTTPStatusEvent.HTTP_STATUS, super.dispatchEvent);
		}
		
		private function addBytesListeners(target:IEventDispatcher):void{
			target.addEventListener(Event.COMPLETE, this.handleLoadBytesComplete);
			target.addEventListener(IOErrorEvent.IO_ERROR, this.handleLoadError);
			target.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.handleLoadError);
			target.addEventListener(Event.OPEN, super.dispatchEvent);
			target.addEventListener(ProgressEvent.PROGRESS, super.dispatchEvent);
			target.addEventListener(HTTPStatusEvent.HTTP_STATUS, super.dispatchEvent);
		}
		
		private function removeBytesListeners(target:IEventDispatcher):void{
			target.removeEventListener(Event.COMPLETE, this.handleLoadBytesComplete);
			target.removeEventListener(IOErrorEvent.IO_ERROR, this.handleLoadError);
			target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.handleLoadError);
			target.removeEventListener(Event.OPEN, super.dispatchEvent);
			target.removeEventListener(ProgressEvent.PROGRESS, super.dispatchEvent);
			target.removeEventListener(HTTPStatusEvent.HTTP_STATUS, super.dispatchEvent);
		}
	}
}