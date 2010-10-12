package com.topspin.common.events
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class DialogEvent extends Event
	{
		
		public static const TYPE : String = "DialogEvent";
		public static const CLOSE : String = "close";		
		
		//Dispatch after the dialog is CLOSED
		public static var CLOSED: String = "dialogClosed";
		public static var OPENED : String = "dialogOpened";
		
		private var _dialog : Sprite;
		
		public var _command : String;
		public var _callbackFunc : Function;
		
		public function DialogEvent(command : String, dialog : Sprite = null, callbackFunc : Function = null)
		{
			super(TYPE);
			_command = command;
			_dialog = dialog;
			_callbackFunc = callbackFunc;
		}		
		
		public function set dialog( dialog : Sprite ) : void
		{
			_dialog = dialog;
		}

		public function get dialog() : Sprite
		{
			return _dialog;
		}		

	}
}