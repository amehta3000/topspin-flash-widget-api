package com.topspin.api.events
{
/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Custom event for TSEmailAdapterEvent Event
 * 
 *
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 */  
 	import flash.events.Event;
	
	public class E4MEvent extends Event
	{
		//Custom event strings
		public static var EMAIL_SUCCESS : String = "email_success";  
		public static var EMAIL_ERROR : String = "email_error"; 
		public static var UNDERAGE_ERROR : String = "underage_error"; 
		
		private var _data : Object;
		private var _message : String;
		
		public function E4MEvent(type : String, data : Object = null, message : String = null, bbl:Boolean=false, ccb:Boolean=false):void
		{
			super(type, bbl, ccb);
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

