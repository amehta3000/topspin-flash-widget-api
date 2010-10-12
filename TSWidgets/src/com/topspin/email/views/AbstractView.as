package com.topspin.email.views
{
	import flash.display.Sprite;
	import flash.events.Event;

	public class AbstractView extends Sprite
	{
		public var _root:TSEmailMediaWidget;			
		protected var _width:Number;				
		protected var _height:Number;
		
		//dialog container
		public var dialogContainer : Sprite;			//Holds any dialogs
		
		
		public function AbstractView( width:Number, height:Number, root:TSEmailMediaWidget ) {
	
			this._width = width;
			this._height = height;
			this._root = root;
		}
		
		public function init() : void {}
		
		public function displayStatus(msg1:String, isError1:Boolean = false):void {}
		
		public function showDOBFailDialog(e : Event = null) : void {}
		
	}
}