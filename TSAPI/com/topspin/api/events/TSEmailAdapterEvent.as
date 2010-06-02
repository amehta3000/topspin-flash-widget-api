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
package com.topspin.api.events
{
 	
	import flash.events.Event;

	public class TSEmailAdapterEvent extends Event
	{	
		//Custom event strings
		public static var EMAIL_SUCCESS : String = "email_success";  
		public static var EMAIL_ERROR : String = "email_error"; 
		
		private var _data : Object;
		
		public function TSEmailAdapterEvent(type : String, data : Object = null, bbl:Boolean=false, ccb:Boolean=false):void
		{
			super(type, bbl, ccb);
			_data = data;
		}
		
		public function get data() : Object
		{
			return _data;
		}
		public function set data( dataObj : Object) : void
		{
			_data = dataObj;
		}
	}
}