package com.topspin.common.controls
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * A Simple Link Button which is completely
	 * customizable.  Default button used in most
	 * of Topspin widgets
	 * 
	 * @author amehta@tospinmedia.com
	 * 
	 */	
	public class SimpleLinkButton extends Sprite {

		// CONFIG VARIABLES
		private var _txt:String;
		private var _format:TextFormat;
		private var _overFormat:TextFormat; 
		private var _overTxt:String; 
		
		private var _enabled : Boolean = true;
		private var _toggle : Boolean = false;
		private var _selected : Boolean = false;
		
		private var _fontOutColor : Number;
		private var _fontOverColor : Number;
		
		private var _includeBorder:Boolean; 
		private var _xPad:Number; 
		private var _yPad:Number;
		private var _curve:Number;
		private var _anchor:String;
		private var _borderThickness : int;
		private var _preserveSize : Boolean;
		private var _bgAlpha : Number;
		private var _bgOverAlpha : Number;
		private var _bgColor : Number;		
		private var _bgOverColor : Number;
		private var _borderOverColor : Number;
		private var _borderOutColor : Number;
		
		private var _embedFonts : Boolean = true;
		
		// UI
		private var btn:Sprite;
		private var btnHitArea:Sprite;
		private var outShape:Shape;
		private var myTxt:TextField;
		private var baseW : Number;
		
		private var inited : Boolean = false;
		
		private var origW : Number;
		private var origH : Number;
		private var _width : Number;
		private var _height : Number;
		
		// STATIC
		private static var AUTOSIZE:String = "center";

		public function SimpleLinkButton(txt:String, format:TextFormat, overFormat:TextFormat, 
										overTxt:String = null, includeBorder:Boolean = true, 
										xPad:Number = 5, yPad : Number = 3, curve : Number = 10, 
										anchor:String = "center", borderThickness : int = 1, preserveSize : Boolean = false, 
										bgAlpha : Number = 1,
										bgOverAlpha : Number = 1,
										bgColor : Number = -69) {

			// Assign input variables
			this._txt = txt;
			this._format = format;
			this._overFormat = overFormat;
			this._fontOutColor = Number(this._format.color);
			this._fontOverColor = Number(this._overFormat.color);
			this._overTxt = (overTxt) ? overTxt : this._txt;
			this._includeBorder = includeBorder; 
			this._xPad = xPad; 
			this._yPad = yPad;
			this._curve = curve;
			this._anchor = anchor;
			this._borderThickness = borderThickness;
			this._preserveSize = preserveSize;
			this._bgAlpha = bgAlpha;
			this._bgOverAlpha = bgOverAlpha;
			this._bgColor = (bgColor!=-69) ? bgColor : Number(_overFormat.color);
			this._bgOverColor = Number(this._format.color);
			this._borderOutColor = Number(this._format.color);
			this._borderOverColor = Number(this._format.color);
			
			createChildren();
			addEventListeners();
		}

		/**
		 *  Utility to create a very simple reusable button, 
		 *  will be moved into its own class called SimpleLinkButton
		 *
		 */
		private function createChildren():void {
			btn = new Sprite();
			outShape = new Shape();
			btnHitArea = new Sprite();
			
			btnHitArea.buttonMode = true;
			btnHitArea.useHandCursor = true;

			myTxt = new TextField();
			myTxt.embedFonts = _embedFonts;
			myTxt.autoSize = SimpleLinkButton.AUTOSIZE;
			myTxt.defaultTextFormat = this._format;
			myTxt.antiAliasType = "advanced";
			myTxt.selectable = false;
			myTxt.text = " " + this._txt + " ";
			myTxt.name = "myTxt";
			
			btn.addChild(outShape);
			btn.addChild(myTxt);
			
			_width = myTxt.width;
			_height = myTxt.height;

			addChild(btn);
			addChild(btnHitArea);

			draw();						
		}
		///////////////////////////////////////////////
		//
		// GETTER SETTERS
		//
		///////////////////////////////////////////////
		public function set text( txt : String ) : void
		{
			this._txt = txt;
			myTxt.text = " " + this._txt + " ";
			draw();
		} 
		public function set overText( txt : String) : void
		{
			this._overTxt = txt;
			draw();
		}
		public function get text() : String 
		{
			return this._txt;
		} 
		
		public function get overText() : String 
		{
			return this._overTxt;
		}
		/**
		 * Sets the width and height of the widget. 
		 * @param w
		 * @param h
		 * 
		 */		
		public function setSize( w : Number, h : Number ) : void
		{
			_width = w;
			_height = h;
			draw();
		}
		public override function set width( w : Number ) : void
		{
			_width = w;
			draw();
		}
		public override function get width() : Number
		{
			return _width;
		}
		public function getWidth() : Number
		{
			return _width;
		}		
		public override function set height( h : Number ) : void
		{
			_height = h;
			draw();
		}
		public override function get height() : Number
		{
			return _height;
		}		
		public function get enabled() : Boolean
		{
			return _enabled;
		}
		public function set enabled( enable : Boolean) : void
		{
			_enabled = enable;
			draw();
		}	
		public function get toggle() : Boolean
		{
			return _toggle;
		}
		public function set toggle( toggleIt : Boolean) : void
		{
			_toggle = toggleIt;
			draw();
		}			
		public function get selected() : Boolean
		{
			return _selected;
		}
		public function set selected( selectIt : Boolean) : void
		{
			_selected = selectIt;
			refresh();
		}			
		
		public function set bgAlpha( bga : Number ) : void
		{
			_bgAlpha = bga;
			draw();
		}
		public function set preserveSize( preserve : Boolean ) : void
		{
			_preserveSize = preserve;
			draw();
		}
		public function set curve( c : Number ) : void
		{
			_curve = c;
			draw();
		}
		
		///////////////////////////////////////////////
		//
		// HANDLERS
		//
		///////////////////////////////////////////////
		private function addEventListeners():void {
			btnHitArea.addEventListener(MouseEvent.ROLL_OVER, btnRollOver );
			btnHitArea.addEventListener(MouseEvent.ROLL_OUT, btnRollOut );
			btnHitArea.addEventListener(MouseEvent.MOUSE_DOWN, btnMouseDown );
		}

		private function btnRollOut(e:MouseEvent = null):void {

			if (toggle && selected)
			{
				return;	
			}			
			// var btn : Sprite = Sprite(e.target);
			var clip : TextField = TextField(btn.getChildByName("myTxt"));
			var f : TextFormat = clip.getTextFormat();
				f.color = _fontOutColor; //_format.color;
			clip.text = " " + this._txt + " ";
			clip.autoSize = SimpleLinkButton.AUTOSIZE;
			clip.setTextFormat(f);				
			draw();
			outShape.alpha = 1;	
			alignBtn(false);
		}
		
		private function btnRollOver(e:MouseEvent = null):void {
			
			if (toggle && selected)
			{
				return;	
			}				
			// var btn : Sprite = Sprite(e.target);
			var clip : TextField = TextField(btn.getChildByName("myTxt"));
			var f : TextFormat = clip.getTextFormat();
			f.color = _fontOverColor; //_overFormat.color;
			clip.text = " " + _overTxt  + " ";
			clip.autoSize = SimpleLinkButton.AUTOSIZE;				
			clip.setTextFormat(f);
			
			draw();
			outShape.graphics.clear();	
			if (_includeBorder)
			{	
				outShape.graphics.lineStyle(this._borderThickness, _borderOverColor, 1 , true);
			}
			outShape.graphics.beginFill(_bgOverColor, this._bgOverAlpha);			
			if (inited && this._preserveSize) {
				outShape.graphics.drawRoundRect(0, 0, _width, _height, _curve);				
			}else{
				outShape.graphics.drawRoundRect(0, 0, clip.width + 2 * _xPad, clip.height + 2 * _yPad, _curve);
			}
			outShape.graphics.endFill();					
			outShape.alpha = 1;	
			alignBtn(true);
		}			
		
		private function btnMouseDown(e:MouseEvent):void {
			outShape.alpha = .5;				
			alignBtn(true);
		}						
		
		private function draw():void {

				outShape.graphics.clear();	
				if (_includeBorder)
				{	
					outShape.graphics.lineStyle(this._borderThickness, uint(_borderOutColor), 1 , true);
				}
				outShape.graphics.beginFill(uint(_bgColor), this._bgAlpha);
				if (inited && this._preserveSize) {
					outShape.graphics.drawRoundRect(0, 0, _width, _height, _curve);				
				}else{
					outShape.graphics.drawRoundRect(0, 0, myTxt.width + 2 * _xPad, myTxt.height + 2 * _yPad, _curve);
				}
				outShape.graphics.endFill();	
	
				btnHitArea.graphics.clear();
				btnHitArea.graphics.lineStyle(1, 0x000000, 0);
				btnHitArea.graphics.beginFill(0x000000, 0);
				btnHitArea.graphics.drawRoundRect(0, 0, outShape.width, outShape.height, _curve);
				btnHitArea.graphics.endFill();
	
				myTxt.x = Math.floor(outShape.x + (outShape.width - myTxt.width) / 2); // - 1;
				myTxt.y = Math.floor(outShape.y + (outShape.height - myTxt.height) / 2); - 1;			
				//needed for resize.  preserve initial size
				baseW = btn.width;	
			
			if (enabled)
			{			
				this.alpha = 1;				
			} else {
				this.alpha = .6;	
				btnHitArea.graphics.clear();							
			}
			
			if (!inited)
			{
				_width = outShape.width;
				_height = outShape.height;
				inited = true;
			}
		}		
		private function alignBtn(over:Boolean = false):void {
			if (over) {
				if (_anchor == "right") {
					outShape.x = baseW - outShape.width;
				}
				if (_anchor == "center") {
					outShape.x = (baseW - outShape.width)/2;
				}
				if (_anchor == "left") {
					outShape.x = 0; //(baseW - outShape.width)/2;
				}
			} else {
				outShape.x = 0;
			}
  			myTxt.x = outShape.x + (outShape.width - myTxt.width)/2 -1; //xpad;								
		}
		
		private function refresh() : void
		{
			
			btnRollOut();			
		}
		public function set fontOutColor( c : Number ) : void
		{
			_fontOutColor = c;
			refresh();
		}
		public function set fontOverColor( c : Number ) : void
		{
			_fontOverColor = c;
			refresh();
		}
		public function set bgOverColor( c : Number ) : void
		{
			_bgOverColor = c;
			refresh();
		}
		
		public function set borderOverColor( c : Number ) : void
		{
			_borderOverColor = c;
			refresh();
		}
		public function set borderOutColor( c : Number ) : void
		{
			_borderOutColor = c;
			refresh();
		}		
		
	}
}