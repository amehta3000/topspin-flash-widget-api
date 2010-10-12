package com.topspin.common.events
{
/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Custom event for Playlist interface type of control
 * 
 *
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 */  
 	
	import flash.events.Event;

	public class PlaylistEvent extends Event
	{
		public static const TYPE : String = "PlaylistEvent";
		public static const CHANGE : String = "playlistChange";
		
		public var _command : String;
		public var _invoker : Object;
		public var _data : Object;
		
		public function PlaylistEvent(command : String, invoker : Object = null, data : Object = null)
		{
			super(TYPE);
			_command = command;
			_invoker = invoker;
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