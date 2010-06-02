/**
 * -----------------------------------------------------------------
 * Copyright (c) 2010 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Custom event for TSWidgets.  Dispatch when used
 * by all TS widget adapters.  Optional data can be added 
 * to pass on to listeners.
 *
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 */ 
package com.topspin.api.events
{
	import flash.events.Event;
	
	public class TSWidgetEvent extends Event
	{ 
				//Custom event strings
		public static const WIDGET_LOAD_COMPLETE : String = "widget_load_complete";  
		public static const WIDGET_LOAD_ERROR : String = "widget_error";   //Deprecated
		public static const WIDGET_ERROR : String = "widget_error";
		
		public static const PLAYLIST_READY : String = "playlist_ready";
				
		//Streaming player only Sharing email Event
		public static const SHARE_EMAIL_COMPLETE : String = "share_email_complete";
		public static const SHARE_EMAIL_ERROR : String = "share_email_error";
			
				
		private var _data : Object;
		private var _message : String;
		
		public function TSWidgetEvent(type : String, data : Object = null, message : String = null, bubbles:Boolean=false, cancelable:Boolean=false):void
		{
			super(type, bubbles, cancelable);
			_data = data;
			_message = message;
		}
		
		public function get data() : Object
		{
			return _data;
		}
		public function set data( dataObj : Object) : void
		{
			_data = dataObj;
		}
		public function get message() : String
		{
			return _message;
		}
		public function set message( message : String) : void
		{
			_message = message;
		}				
	}
}