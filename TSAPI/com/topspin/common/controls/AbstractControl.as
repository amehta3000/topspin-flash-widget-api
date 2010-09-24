package com.topspin.common.controls
{
	import flash.display.Sprite;
	
	public class AbstractControl extends Sprite
	{
		protected var activated : Boolean = true;
		
		protected var _width : Number;
		protected var _height : Number;
				
		public function AbstractControl()
		{ 
		}
		
		public function setSize( w: Number, h : Number ) : void
		{
			_width = w;
			_height = h;
			
			draw();
		}

		protected function draw() : void {}

		public function getHeight() : Number
		{
			return _height;
		}
			
		public function getWidth() : Number
		{
			return _width;
		}
		
		public function update() : void {}
		
		public function activate() : void {}
		
		public function deactivate() : void {}

	}
}