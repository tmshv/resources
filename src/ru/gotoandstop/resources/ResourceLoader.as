package ru.gotoandstop.resources{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	[Event(name="queueComplete", type="ru.gotoandstop.resources.ResourceLoaderEvent")]
	
	/*
	*
	* @author Timashev Roman
	*/
	public class ResourceLoader extends EventDispatcher{
		private static var createForLibrary:Boolean;
		internal static function createWithLibrary(streamNumber:uint, library:ResourceLibrary):ResourceLoader{
			ResourceLoader.createForLibrary = true;
			var loader:ResourceLoader = new ResourceLoader(streamNumber);
			loader.init(streamNumber, library);
			ResourceLoader.createForLibrary = false;
			return loader;
		}
		
		private var queue:Vector.<QueueItem>;
		private var loaders:Vector.<SingleLoader>;
		private var history:Vector.<String>;
		
		private var currentlyLoadedResources:Dictionary;
		
		private var processLoading:Boolean;
		
		private var _library:ResourceLibrary;
		public function get library():ResourceLibrary{
			return this._library;
		}

        public var notifyIOError:Boolean = true;

		public function ResourceLoader(streamNumber:uint=1){
			super();
			
			if(!ResourceLoader.createForLibrary){
				this.init(
					Math.max(1, streamNumber),
					ResourceLibrary.createWithLoader(this)
				);
			}
		}
		
		/**
		 * Инициализация экземпляра
		 * @param streamNumber количество потоков загрузки (количество лоадеров)
		 * @param library экземпляр ResourceLibrary
		 */
		private function init(streamNumber:uint, library:ResourceLibrary):void{
			this._library = library;
			
			this.queue = new Vector.<QueueItem>();
			this.loaders = new Vector.<SingleLoader>();
			this.history = new Vector.<String>();
			
			for(var i:uint; i<streamNumber; i++){
				this.addLoader(new SingleLoader(i));
			}
			
			this.currentlyLoadedResources = new Dictionary();
		}
		
		/**
		 * Добавляет загрузчику загрузчик
		 * @param loader
		 */
		private function addLoader(loader:SingleLoader):void{
			//this.deconfigureListenersFor(loader);
			this.configureListenersFor(loader);
			this.loaders.push(loader);
		}
		
		private function queueIsEmpty():Boolean{
			var mask:uint;
			for each(var loader:SingleLoader in this.loaders){
				var value:uint = Number(loader.busy);
				
				mask = mask | value;
				mask = mask << 1;
			}
			mask = mask >> 1;
			
			return mask==0 && this.queue.length==0;
		}
		
		private function configureListenersFor(loader:IEventDispatcher):void{
			loader.addEventListener(Event.COMPLETE, this.handlerLoadComplete);
			loader.addEventListener(Event.OPEN, this.handlerLoad);
			loader.addEventListener(ProgressEvent.PROGRESS, this.handlerLoad);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, this.handlerLoad);
			loader.addEventListener(IOErrorEvent.IO_ERROR, this.handlerLoadError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.handlerLoadError);
		}
		
		private function deconfigureListenersFor(loader:IEventDispatcher):void{
			loader.removeEventListener(Event.COMPLETE, this.handlerLoadComplete);
			loader.removeEventListener(Event.OPEN, this.handlerLoad);
			loader.removeEventListener(ProgressEvent.PROGRESS, this.handlerLoad);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this.handlerLoad);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, this.handlerLoadError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.handlerLoadError);
		}
		
		/**
		 * Добавить ресурс в очередь на загрузку
		 * @param resourceURL ссылка на ресурс
		 * @param key идентификатор ресурса
		 * @return экземпляр Resource
		 */
		public function add(resourceURL:String, key:String, loadAsDisplayObject:Boolean=false, addAsStack:Boolean=false):Resource{
			var resource:Resource = new Resource(key, resourceURL);
			resource.loader = this;
			
			var item:QueueItem = new QueueItem(resource, loadAsDisplayObject);
			
			if(addAsStack){
				this.queue.unshift(item);
			}else{
				this.queue.push(item);
			}
			return resource;
		}

        public function addResource(key:String, url:String, callback:Function=null, loadAsDO:Boolean=false):Resource{
            var r:Resource = add(url, key, loadAsDO);
            r.completeCallback = callback;
            return r;
        }
		
		/**
		 * Запускает процесс загрузки
		 */
		public function start():void{
			if(this.processLoading) return;
			this.processLoading = true;
			this.loadQueue();
		}
		
		/**
		 * Приступить к загрузке следующего в очереди ресурса
		 */
		private function loadQueue():void{
			var length:uint = this.queue.length;
			if(length){
				for(var i:uint; i<length; i++){
					var loader:SingleLoader = this.getFreeLoader();
					if(!loader) break;
					
					const item:QueueItem = this.queue.shift();
					var resource:Resource = item.resource;
					this.currentlyLoadedResources[loader] = resource;
					
					loader.loadAsDisplayObject = item.loadAsDisplayObject;
					loader.busy = true;
					loader.load(new URLRequest(resource.url));
				}
			}
		}
		
		private function markLoaderAsFree(loader:SingleLoader):void{
			loader.busy = false;
			
//			if(this.queue.length==0 && this._workNumber==0){
//				this.stop();
//				super.dispatchEvent(new ResourceLoaderEvent(ResourceLoaderEvent.QUEUE_COMPLETE));
//			}
		}
		
		/**
		 * Возвращает незанятый загрузчик 
		 * @return экземпляр SingleLoader со свойством busy со значением false
		 */
		private function getFreeLoader():SingleLoader{
			var free_loader:SingleLoader;
			for each(var loader:SingleLoader in this.loaders){
				if(!loader.busy){
					free_loader = loader;
					break;
				}
			}
			return free_loader;
		}
		
		/**
		 * Останавливает процесс загрузки очереди. Метод не останавливает загрузку активных потоков.
		 * 
		 */
		public function stop():void{
			this.processLoading = false;
		}
		
		public function dispose():void{
			
		}
		
		private function handlerLoadComplete(event:Event):void{
			const loader:SingleLoader = event.target as SingleLoader;
			var resource:Resource = currentlyLoadedResources[loader] as Resource;
			
			if(loader.loadAsDisplayObject){
				if(loader.data is DisplayObject){
					var d_o:DisplayObject = loader.data as DisplayObject;
					resource.setData(d_o.loaderInfo.bytes, loader.data);
				}else{
					resource.setData(new ByteArray(), loader.data);
				}
			}else{
				var bytes:ByteArray = new ByteArray();
				bytes.writeBytes(loader.data as ByteArray);
				resource.setData(bytes, loader.data);
			}
			
			_library.add(resource);
			
			resource.dispatchEvent2(event);
			markLoaderAsFree(loader);
			
			if(queueIsEmpty()){
				super.dispatchEvent(new ResourceLoaderEvent(ResourceLoaderEvent.QUEUE_COMPLETE));
			}else{
				loadQueue();
			}
		}
		
		private function handlerLoad(event:Event):void{
			const loader:SingleLoader = event.target as SingleLoader;
			var resource:Resource = this.currentlyLoadedResources[loader] as Resource;
			resource.dispatchEvent2(event);
		}
		
		private function handlerLoadError(event:Event):void{
			const loader:SingleLoader = event.target as SingleLoader;
			loader.busy = false;
			var resource:Resource = this.currentlyLoadedResources[loader] as Resource;
			if(notifyIOError) resource.dispatchEvent2(event);
			this.loadQueue();
		}
	}
}

import ru.gotoandstop.resources.Resource;

internal class QueueItem{
	public var resource:Resource;
	public var loadAsDisplayObject:Boolean;
	
	public function QueueItem(resource:ru.gotoandstop.resources.Resource, loadAsDO:Boolean){
		this.resource = resource;
		this.loadAsDisplayObject = loadAsDO;
	}
}