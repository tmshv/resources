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
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;

public class QueueLoader extends EventDispatcher{
    private var _queue:Vector.<Object> = new Vector.<Object>();
    private var _worked:Boolean;

    public var loadedData:Vector.<Loader>;

    public function QueueLoader() {
    }

    public function addToQueue(request:URLRequest, context:LoaderContext=null):void{
        if(!_worked) {
            _queue.push({
                request:request,
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
            loader.load(task.request, task.context);
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

    public function getQueueURLList():Vector.<String>{
        var list:Vector.<String> = new Vector.<String>();
        for each(var i:Object in _queue) {
            list.push(i.request.url);
        }
        return list;
    }
}
}
