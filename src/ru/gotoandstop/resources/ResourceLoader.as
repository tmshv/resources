package ru.gotoandstop.resources {
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.HTTPStatusEvent;
import flash.events.IEventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

[Event(name="queueComplete", type="ru.gotoandstop.resources.ResourceLoaderEvent")]

/*
 *
 * @author Timashev Roman
 */
public class ResourceLoader extends EventDispatcher {
    private var _queue:Vector.<Object>;
    private var _loaders:Vector.<SingleLoader>;
    private var _resourceByLoader:Dictionary;
    private var _working:Boolean;
    public var notifyIOError:Boolean = true;
    public var library:Object;

    /**
     * Создает экземпляр ResourceLoader
     * @param streamNumber количество потоков (количество используемых экземпляров Loader)
     */
    public function ResourceLoader(streamNumber:uint = 1) {
        super();
        init(Math.max(1, streamNumber));
    }

    /**
     * Инициализация экземпляра
     * @param streamNumber количество потоков загрузки (количество лоадеров)
     */
    private function init(streamNumber:uint):void {
        library = {};
        _queue = new Vector.<Object>();
        _loaders = new Vector.<SingleLoader>();
        _resourceByLoader = new Dictionary();
        for (var i:uint; i < streamNumber; i++) {
            var loader:SingleLoader = new SingleLoader(i);
            configureListenersFor(loader);
            _loaders.push(loader);
        }
    }

    public function queueIsEmpty():Boolean {
        for each(var loader:SingleLoader in _loaders) {
            if (loader.busy) return false;
        }
        return !_queue.length;
    }

    private function configureListenersFor(loader:IEventDispatcher):void {
        loader.addEventListener(Event.COMPLETE, handleLoadComplete);
        loader.addEventListener(Event.OPEN, handleLoad);
        loader.addEventListener(ProgressEvent.PROGRESS, handleLoad);
        loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleLoad);
        loader.addEventListener(IOErrorEvent.IO_ERROR, handleLoadError);
        loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleLoadError);
    }

    private function deconfigureListenersFor(loader:IEventDispatcher):void {
        loader.removeEventListener(Event.COMPLETE, handleLoadComplete);
        loader.removeEventListener(Event.OPEN, handleLoad);
        loader.removeEventListener(ProgressEvent.PROGRESS, handleLoad);
        loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, handleLoad);
        loader.removeEventListener(IOErrorEvent.IO_ERROR, handleLoadError);
        loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleLoadError);
    }

    /**
     * Добавить ресурс в очередь на загрузку
     * @return экземпляр Resource
     */
    public function add(resource:Resource):Resource {
        resource.loader = this;
        _queue.push({
            resource:resource,
            loadAsDisplayObject:false
        });
        return resource;
    }

    public function push(url:String, id:String = null, callback:Function = null):Resource {
        return add(new Resource(id, url, callback));
    }

    /**
     * Запускает процесс загрузки
     */
    public function start():void {
        if (_working) return;
        _working = true;
        loadStep();
    }

    /**
     * Останавливает процесс загрузки очереди. Метод не останавливает загрузку активных потоков.
     *
     */
    public function stop():void {
        _working = false;
    }

    /**
     * Приступить к загрузке следующего в очереди ресурса
     */
    private function loadStep():void {
        if (queueIsEmpty()) {
            _working = false;
            dispatchEvent(new ResourceLoaderEvent(ResourceLoaderEvent.QUEUE_COMPLETE));
        } else {
            while(1) {
                var loader:SingleLoader = getFreeLoader();
                if (!loader) break;
                var item:Object = _queue.shift();
                if(!item) break;

                var resource:Resource = item.resource;
                _resourceByLoader[loader] = resource;
                loader.loadAsDisplayObject = item.loadAsDisplayObject;
                loader.busy = true;
                loader.load(new URLRequest(resource.url));
            }
        }
    }

    /**
     * Возвращает незанятый загрузчик
     * @return экземпляр SingleLoader со свойством busy со значением false
     */
    private function getFreeLoader():SingleLoader {
        var free_loader:SingleLoader;
        for each(var loader:SingleLoader in this._loaders) {
            if (!loader.busy) {
                free_loader = loader;
                break;
            }
        }
        return free_loader;
    }

    private function freeLoaderAvailable():Boolean{
        return false;
    }

    public function dispose():void {

    }

    private function handleLoadComplete(event:Event):void {
        const loader:SingleLoader = event.target as SingleLoader;
        var resource:Resource = _resourceByLoader[loader] as Resource;

        if (loader.loadAsDisplayObject) {
            if (loader.data is DisplayObject) {
                var d_o:DisplayObject = loader.data as DisplayObject;
                resource.setData(d_o.loaderInfo.bytes, loader.data);
            } else {
                resource.setData(new ByteArray(), loader.data);
            }
        } else {
            var bytes:ByteArray = new ByteArray();
            bytes.writeBytes(loader.data as ByteArray);
            resource.setData(bytes, loader.data);
        }

        library[resource.id] = resource;
        resource.dispatchEvent(event);
        loader.busy = false;
        loadStep();
    }

    private function handleLoad(event:Event):void {
        const loader:SingleLoader = event.target as SingleLoader;
        var resource:Resource = this._resourceByLoader[loader] as Resource;
        resource.dispatchEvent(event);
    }

    private function handleLoadError(event:Event):void {
        const loader:SingleLoader = event.target as SingleLoader;
        loader.busy = false;
        var resource:Resource = _resourceByLoader[loader] as Resource;
        if (notifyIOError) resource.dispatchEvent(event);
        loadStep();
    }
}
}