/**
 *
 * User: tmshv
 * Date: 7/11/12
 * Time: 5:53 PM
 */
package ru.gotoandstop.resources {
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

public class QueueLoaderBytes extends EventDispatcher{
    private var _queue:Vector.<Object> = new Vector.<Object>();
    private var _worked:Boolean;

    public var loadedData:Vector.<Loader>;

    public function QueueLoaderBytes() {
    }

    public function addToQueue(bytes:ByteArray, context:LoaderContext=null):void{
        if(!_worked) {
            _queue.push({
                bytes:bytes,
                context:context
            });
        }
    }

    public function start():void{
        _worked = true;
        loadedData = new Vector.<Loader>();
        loadNext();
    }

    private function loadNext():void{
        var task:Object = _queue.shift();
        if(task) {
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleComplete);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleError);
            loader.loadBytes(task.bytes, task.context);
        }else{
            _worked = false;
            dispatchEvent(new Event(Event.COMPLETE));
        }
    }

    private function handleError(event:Event):void{
        killListeners(event.target as LoaderInfo);
        loadNext();
    }

    private function handleComplete(event:Event):void{
        var info:LoaderInfo = event.target as LoaderInfo;
        killListeners(info);

        loadedData.push(info.loader);
        loadNext();
    }

    private function killListeners(info:LoaderInfo):void{
        info.removeEventListener(Event.COMPLETE, handleComplete);
        info.removeEventListener(IOErrorEvent.IO_ERROR, handleError);
    }
}
}
