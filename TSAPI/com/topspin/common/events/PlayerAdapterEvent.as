package com.topspin.common.events
{
	import flash.events.Event;

	public class PlayerAdapterEvent extends Event {
		
		public static const PLAY_MEDIA_READY:String = "playMediaReady";
		public static const MEDIA_PLAY:String = "mediaPlay";
		public static const MEDIA_PAUSE:String = "mediaPause";
		
		public function PlayerAdapterEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
            return new PlayerAdapterEvent(type, bubbles, cancelable);
        }

	}
}