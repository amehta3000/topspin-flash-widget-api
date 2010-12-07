/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 *  
 * Tooltip - Creates a tooltip element
 * 
 * @copyright	Topspin Media
 * @author		kevans@topspinmedia.com
 * 
 */
package com.topspin.common.controls {
	
	// Flash imports
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	
	public class Tooltip extends Sprite {
		// Input Variables
		private var _tooltipColor:uint;  // Color of the element
		private var _text:String;  // Input text for the element
		private var _textFormat:TextFormat;  // Format for the input text
		private var _corners : Number;
		
		// UI Elements
		private var body:Sprite;
		private var arrow:Sprite;
		private var tooltipText:TextField;
		private var elementWidth:Number;
		private var elementHeight:Number;
		private var distanceFromLeftBorder:Number = 0;  // Distance to left border from center of element that is being clarified (used to position arrow in element)
		private var distanceFromRightBorder:Number = 0;  // Distance to right border from center of element that is being clarified (used to position arrow in element)
		
		// Other
		private var metrics:TextLineMetrics;
		private static var HORIZONTAL_PADDING:Number = 10;
		private static var VERTICAL_PADDING:Number = 6;
		
		public static var ANCHOR_LEFT : String = "left";
		public static var ANCHOR_CENTER : String = "center";
		public static var ANCHOR_RIGHT : String = "right";
		
		
		public function Tooltip(tooltipColor:uint, text:String, textFormat:TextFormat) {
			// Assign input variables
			this._tooltipColor = tooltipColor;
			this._text = text;
			this._textFormat = textFormat;
			this.distanceFromLeftBorder = distanceFromLeftBorder;
			
			createChildren();
			// draw();
		}
		
		private function createChildren():void {
			// Create sprites for main body and arrow
			body = new Sprite();
			arrow = new Sprite();
			tooltipText = new TextField();
			tooltipText.width=100;
			tooltipText.height=100;
			tooltipText.multiline = true;
			tooltipText.wordWrap = true;
			tooltipText.embedFonts = true;
			tooltipText.autoSize = TextFieldAutoSize.LEFT;
			tooltipText.defaultTextFormat = this._textFormat;
			
			addChild(body);
			addChild(arrow);
			body.addChild(tooltipText);
			draw();
		}
		
		private function draw():void {
			
			tooltipText.text = this._text;
			tooltipText.defaultTextFormat = this._textFormat;
			//			tooltipText.setTextFormat(this._textFormat);
			
			// Calculate the appropriate height and width of element from input text metrics
			metrics = tooltipText.getLineMetrics(0);
			this.elementWidth = metrics.width + HORIZONTAL_PADDING;
			this.elementHeight = tooltipText.height + VERTICAL_PADDING;// metrics.height + VERTICAL_PADDING;
			
			// Draw the individual sprites
			body.graphics.clear();
			body.graphics.beginFill(this._tooltipColor, 1);
			if (_corners)
			{
				body.graphics.drawRoundRect(0, 0, this.elementWidth, this.elementHeight, _corners);			
			}else{
				body.graphics.drawRect(0, 0, this.elementWidth, this.elementHeight);
			}
			body.graphics.endFill();
			
			arrow.graphics.clear();
			arrow.graphics.beginFill(this._tooltipColor, 1);
			arrow.graphics.moveTo(0, 0);
			arrow.graphics.lineTo(10, 0);
			arrow.graphics.lineTo(5, 7);
			arrow.graphics.lineTo(0, 0);
			arrow.graphics.endFill();
			
			// Calculate the appropriate position of the arrow and body elements from the elementWidth and distance from borders
			if (this.distanceFromLeftBorder < this.elementWidth / 2 ) {  // Arrow is too close to the left border
				body.x = this.distanceFromLeftBorder - (HORIZONTAL_PADDING/2);// - ((body.width - arrow.width) / 2);
				arrow.x = this.distanceFromLeftBorder - 1;
				//tooltipText.x = Math.floor(HORIZONTAL_PADDING / 2);// + body.x;
			} else if (this.distanceFromLeftBorder < this.elementWidth) {  // Arrow is too close to the left border
				body.x = this.distanceFromLeftBorder - (elementWidth/2) + (HORIZONTAL_PADDING/2);// - ((body.width - arrow.width) / 2);
				arrow.x = this.distanceFromLeftBorder;
				//tooltipText.x = Math.floor(HORIZONTAL_PADDING / 2);// + body.x;
			} else if(this.distanceFromRightBorder < this.elementWidth / 2) {  // Arrow is too close to the right border
				arrow.x = this.distanceFromRightBorder;
				body.x = ((body.width - arrow.width) / 2) - this.distanceFromRightBorder - HORIZONTAL_PADDING;			
			} else {  // Arrow is safe from both borders, can be placed in the middle
				arrow.x = (body.width - arrow.width) / 2;
				body.x = 0;
			}
			
			body.y = 0;
			arrow.y = body.height;
			tooltipText.x = Math.floor(HORIZONTAL_PADDING / 2) - 2;
			tooltipText.y = Math.floor(VERTICAL_PADDING / 2) - 1;			
		}
		
		public function setAnchor( postion : String = "center") : void
		{
			switch (postion) {
				case (ANCHOR_LEFT):
					arrow.x = 2;
					break;
				case (ANCHOR_CENTER):					
					arrow.x = (elementWidth - arrow.width)/2 - arrow.width/2;				
					break;								
				case (ANCHOR_RIGHT): 
					arrow.x = elementWidth - arrow.width - 2;								
					break;								
				default:
					arrow.x = (elementWidth - arrow.width)/2 - arrow.width/2;				
					break;												
			}
			
			draw();
		}
		
		// GETTERS
		public function get tooltipColor():uint {
			return this._tooltipColor;
		}
		
		public function get text():String {
			return this._text;
		}
		
		public function get textFormat():TextFormat {
			return this._textFormat;
		}
		
		// Methods for handling the visibility
		public function show():void {
			this.visible = true;
		}
		
		public function hide():void {
			this.visible = false;
		}
		
		public function get distanceFromBorder():Number {
			return this.distanceFromLeftBorder;
		}
		
		// SETTERS
		public function set tooltipColor(overrideTooltipColor:uint):void {
			this._tooltipColor = overrideTooltipColor;
			draw();
		}
		
		public function set text(overrideText:String):void {
			this._text = overrideText;
			draw();
		}
		
		public function set textFormat(overrideTextFormat:TextFormat):void {
			this._textFormat = overrideTextFormat;
			draw();
		}
		
		public function setBorders(overrideDistanceFromLeftBorder:Number, overrideDistanceFromRightBorder:Number):void {
			this.distanceFromLeftBorder = overrideDistanceFromLeftBorder;
			this.distanceFromRightBorder = overrideDistanceFromRightBorder;
			draw();
		}
		
		public function setWidth( w : Number ) : void
		{
			tooltipText.width = w;
			draw();
		}
		
		public function getWidth() : Number
		{
			return this.elementWidth;
		}
		
		public function roundedCorners( corners : Number ) : void
		{
			_corners = corners;
			draw();
		}
		
	}
}