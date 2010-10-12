package com.topspin.common.media {
	
	import flash.events.IEventDispatcher;
	
	/**
	 * Interface used by E4M widget to load in
	 * and external swf and control playback 
	 * @author amehta@topspinmedia.com
	 * 
	 */	
	public interface IPlayerAdapter extends IEventDispatcher {

		function setSize(width:Number, height:Number):void;
		
		function parse(node:XML):void;	
		
		function setPlaylistParams(widgetID:String, clickTag:String, width:Number, height:Number, linkColor:uint):void;

		function displayOverlayButton():void;

		function hideOverlayButton():void;
		
		function setVAlign( valign :String):void;
		
		function play( delaystart : Number = 1000 ) : void;
		
		function pause() : void; 
		
		function stop() : void;
		
		function set loop( loopIt : Boolean ) : void;
	}
}