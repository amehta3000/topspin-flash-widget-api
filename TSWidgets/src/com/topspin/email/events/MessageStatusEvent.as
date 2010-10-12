package com.topspin.email.events
{
	import flash.events.Event;

	public class MessageStatusEvent extends Event
	{
		public static var TYPE : String = "MessageStatusEvent";
		private var _isError : Boolean = false;
		private var _message : String;
		public function MessageStatusEvent( message : String, isError : Boolean = false )
		{
			super(TYPE);
			_message = message;
			_isError = isError;
		}
		
		public function get message() : String
		{
			return _message;
		}
		
		public function get isError() : Boolean
		{
			return _isError;
		}
	}
}