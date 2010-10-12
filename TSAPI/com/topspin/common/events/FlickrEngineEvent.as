package com.topspin.common.events {
	import flash.events.Event;

	public class FlickrEngineEvent extends Event {

		public static const ON_FROB_ERROR : String = "onFrobError";
		public static const ON_FROB_SUCCESS : String = "onFrobSuccess";
		public static const ON_USERNAME_SUCCESS : String = "onUserNameSuccess";
		public static const ON_USERNAME_FAIL : String = "onUserNameFail";
		public static const ON_PHOTO_SUCCESS : String = "onPhotoSuccess";  //single photo load success
		public static const ON_FLICKR_LOAD_COMPLETE : String = "onFlickrLoadComplete";  //all flickr photos loaded

		public function FlickrEngineEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
	}
}