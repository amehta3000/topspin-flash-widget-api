/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Custom event for TSPlaylistAdapter Event
 * 
 *
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 */  
package com.topspin.api.events
{
 	
	import flash.events.Event;

	public class TSPlaylistAdapterEvent extends Event
	{	
		//Custom event strings
		public static var PLAYLIST_COMPLETE : String = "playlist_load_complete"; //deprecated
		public static var PLAYLIST_LOAD_COMPLETE : String = "playlist_load_complete";  

		public static var PLAYLIST_ERROR : String = "playlist_load_error"; //deprecated
		public static var PLAYLIST_LOAD_ERROR : String = "playlist_load_error";
				
		public var _data : Object;
		
		public function TSPlaylistAdapterEvent(type : String, data : Object = null, bbl:Boolean=false, ccb:Boolean=false):void
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