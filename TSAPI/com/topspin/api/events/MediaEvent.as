/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Custom events for Sound and NetStream used in Media players.
 * 
 *
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 */  	
package com.topspin.api.events
{	
	import flash.events.Event;

	public class MediaEvent extends Event
	{
		
		public static const TYPE : String = "MediaEvent";
		public static const INIT : String = "load_init";
		public static const LOAD_COMPLETE : String = "load_complete";
		public static const LOAD_ERROR : String = "load_error";
		public static const PLAY_COMPLETE : String = "media_play_complete";
		public static const METADATA : String  = "metadata";
		//		public static const PROGRESS : String = "load_progress";		
		//		public static const PLAY_READY : String  = "play_ready";
		//		public static const STOP : String  = "stop_track";

		
		protected var _command : String;
		protected var _invoker : Object;
		protected var _data : Object;
		
		/**
		 * MediaEvent constructor.  Type is alwayd MediaEvent, command will
		 * be one of the public static types sent via ITrackData instances
		 *  
		 * @param command : String - INIT, LOAD_COMPLETE, LOAD_ERROR, PROGRESS, PLAY_COMPLETE, PLAY_READY, METADATA, STOP
		 * @param invoker : Object - ITrackData object
		 * @param data : Object - Optional data t be sent
		 * @param bubbles : Boolean - Event will bubble
		 * @param cancelable : Boolean
		 * 
		 */		
		public function MediaEvent(command : String, invoker : Object = null, data : Object = null, bubbles:Boolean=true, cancelable:Boolean=false):void
		{
			super(TYPE, bubbles, cancelable);
			_command = command;
			_invoker = invoker;
			_data = data;
		}
		public function get command() : String
		{
			return _command;
		}
		public function get invoker() : Object
		{
			return _invoker;
		}
		public function get data() : Object
		{
			return _data;
		}
		
		
	}
}