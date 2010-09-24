package com.topspin.common.controls
{
	import fl.motion.easing.Linear;
	
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.AntiAliasType;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import gs.TweenLite;

	public class MaskTextMarquee extends Sprite
	{
		// Text Variables
		private var textField:TextField;
		private var titleTextFormat:TextFormat;
		private var artistTextFormat:TextFormat;
		private var titleText:String;
		private var artistText:String;

		// UI Variables
		private var _width:Number;
		private var _height:Number;
		private var _align : String = "left";
		private var textMask:Sprite;
		private var textFieldStartPosition:Number = 0;
		private var scrollSpeed:Number = 0;
		
		// Gradient Class Variables
		private var fillType:String = GradientType.LINEAR;  // Styles of gradient (Linear or Radial)
		private var matrix:Matrix;  // Transformation Matrix that allows the gradient to be vertically oriented
		private var _colors:Array = [0x0000FF, 0x000000];  // RGB Array of colors used to make the gradient fill
		private var _alphas:Array = [1, 0];  // Alpha values of colors in the color array
		private var _ratios:Array = [200, 255];  // Array of color distribution ratios (0 - 255 means a straight 50/50 gradient split in the space)
	
		//data holder
		private var _data : Object;
		private var _continuousScrolling : Boolean;
		
		// State
		private var isScrolling:Boolean = false;
	
		public static const MASK_TEXT_MARQUEE_CLICK:String = "maskTextMarqueeClick";

		public function MaskTextMarquee(width:Number, height:Number, continuousScrolling : Boolean = true)
		{
			// Set input variables
			this._width = width;
			this._height = height;
			this._continuousScrolling = continuousScrolling;
			init();			
			createChildren();
		}
		
		private function init():void {
			titleText = "";
			artistText = "";
		}
		
		private function createChildren():void {
			textMask = new Sprite();
			addChild(textMask);

			textField = new TextField();			
			textField.embedFonts = true;
			textField.antiAliasType = AntiAliasType.ADVANCED;
			addChild(textField);
			
			this.artistTextFormat = new TextFormat();
			this.titleTextFormat = new TextFormat();
			
			matrix = new Matrix();
			
			draw();
		}

		private function draw():void {
			matrix.createGradientBox(this._width, this._height, 0, 0, 0);  // Orient the gradient in radians

			if (_htmlText != null && _htmlText != "" && css)
			{
				textField.styleSheet = css;
				textField.htmlText = _htmlText;
			}else{
				textField.text = this.titleText;
				textField.setTextFormat(this.titleTextFormat);

				if(this.artistText != "") {
//					textField.appendText(" by ");
					textField.appendText(this.artistText);
					textField.setTextFormat(this.artistTextFormat, (this.titleText.length), (this.titleText.length + this.artistText.length));
				}
			}
			
			if (_align == "right")
			{
				_alphas = [1,1];
				_colors = [0x000000, 0x0000ff];  // RGB Array of colors used to make the gradient fill
				_ratios = [0, 55]; 				
			}

			textMask.graphics.clear();
			textMask.graphics.beginGradientFill(GradientType.LINEAR, _colors, _alphas, _ratios, matrix);
			textMask.graphics.drawRect(0, -2, (_width - 7), _height + 2);
			textMask.graphics.endFill();
			textMask.cacheAsBitmap = true;
//			addChild(textMask);

			textField.cacheAsBitmap = true;
			textField.mask = textMask; 
			textField.selectable = false;
			textField.autoSize = TextFieldAutoSize.LEFT;		
			textField.y = ((this._height - textField.height) / 2);
			
			//this needs to happen after the draw.
			if (_align == "right")
			{
				if (textField.textWidth < textMask.width)
				{
					textFieldStartPosition = textMask.width - textField.textWidth - 6;
				}
				textField.x = textFieldStartPosition;
			}else{
				textFieldStartPosition = 0;
				textField.x = textFieldStartPosition;				
			}	
		
//			if (_htmlText != null && _htmlText != "" && css)
//			{
//				scrollSpeed = Math.floor(textField.htmlText.length / 12);  // Vary the speed of the scrolling based on the length of the input text			
//			}else{
				scrollSpeed = Math.floor(textField.text.length / 12);  // Vary the speed of the scrolling based on the length of the input text
//			}
			addListeners();
		}
		
		private function addListeners():void {
			textField.addEventListener(MouseEvent.MOUSE_OVER, scrollText);
			if (!_continuousScrolling)
			{
				trace("Add listener for ROLL_OUT");
				textField.addEventListener(MouseEvent.MOUSE_OUT,snapText);
			}
		}
		
		private function scrollText(e:MouseEvent):void {
			doScrollText();
		}
		private function snapText(e: MouseEvent = null) : void {
			trace("snap text");
			TweenLite.killTweensOf(textField);
			isScrolling = false;
			textField.x = 0;
		}
		
		public function doScrollText():void {
			if((textField.textWidth > this.textMask.width) && !isScrolling) {
				isScrolling = true;
				TweenLite.to(textField, scrollSpeed, {x:(textField.width * -1), ease:Linear.easeOut, onComplete:resetTextPosition});
			}			
		}
		public function stopScrollText():void {
			snapText();
		}

		
		
		private function dispatchClickEvent(e:MouseEvent):void {
			dispatchEvent(new Event(MASK_TEXT_MARQUEE_CLICK, true));
		}

		private function resetTextPosition():void {
			textField.x = textField.width;
			TweenLite.to(textField, 1.5, {x:this.textFieldStartPosition});
			isScrolling = false;
		}

		public function setSize(width:Number, height:Number):void {
			this._width = width;
			this._height = height;
			
			draw();
		}

		// GET / SET METHODS	
		private var css : StyleSheet;
		private var _htmlText : String;
		public function setCSS( _css : StyleSheet) : void
		{
			css = _css;
		} 
		public function setHtmlText( htmltext : String ) : void
		{
			_htmlText = htmltext;
			draw();
		}
		
		public function setTitleText(overrideTitleText:String):void {
			this.titleText = overrideTitleText;
			draw();
		}

		public function setArtistText(overrideArtistText:String):void {
			this.artistText = overrideArtistText;
			draw();
		}
		
		public function setTitleTextFormat(overrideTitleTextFormat:TextFormat):void {
			this.titleTextFormat = overrideTitleTextFormat;
			draw();
		}

		public function setArtistTextFormat(overrideArtistTextFormat:TextFormat):void {
			this.artistTextFormat = overrideArtistTextFormat;
			draw();
		}

		public function setFontSize(overrideFontSize:Number):void {
//			trace("MaskTextMarquee.setFontSize(" + overrideFontSize + ")");
			this.titleTextFormat.size = overrideFontSize;
			draw();
		}		

		public function get textWidth():Number {
			return this.textField.width;
		}
		
		public function get textHeight():Number {
			return this.textField.height;
		}
		
		public function getWidth():Number {
			return this._width;
		}
		
		public function set data( d : Object) : void
		{
			_data = d;
		}
		public function get data() : Object
		{
			return _data;
		}
		
		public function setAlign( align : String ): void
		{
			_align = align;
			draw();
		}
		
	}
}