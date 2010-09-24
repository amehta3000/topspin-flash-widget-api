package com.topspin.common.controls
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * Simple Icon Button, that loads in an external image and places text
	 * beside it. 
	 * @author amehta@topspinmedia.com
	 * 
	 */	
	public class SimpleIconButton extends Sprite {
		// CONFIG VARIABLES
		//URL to where the icon lives at
		private var _assetURL : String;
		private var _txt:String;
		private var _format:TextFormat;
		private var _overFormat:TextFormat; 
		private var _overTxt:String; 
		
		//Components		
		private var icon : Loader;
		private var btn : Sprite;
		private var tf : TextField;
		private var PAD : int = 4;
		
		public function SimpleIconButton(assetURL : String, txt:String, format:TextFormat, overFormat:TextFormat, overTxt:String = null) {

			// Assign input variables
			this._assetURL = assetURL;
			this._txt = txt;
			this._format = format;
			this._overFormat = overFormat;
			this._overTxt = (overTxt) ? overTxt : this._txt;
			
			btn = new Sprite();
			addChild(btn);
		}

		public function load() : void
		{
			var request : URLRequest = new URLRequest(this._assetURL);
//			trace("loading: " + _assetURL);
			var loader : Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			try {
				loader.load(request);
			} catch (e:Error) {
				trace("SimpleIconButton: Cannot load asset: " + e.message);
				createChildren();		
			}
		}			
			
		/**
		 * Handler for when the Loader image is loaded 
		 *
		 *  @param e
		 */
		private function handleLoaded( e : Event ) : void
		{
			icon = e.target.loader;
			icon.contentLoaderInfo.removeEventListener(Event.COMPLETE,handleLoaded);
			icon.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			btn.addChild(icon);
			createChildren();	
		}	
        private function ioErrorHandler(event:IOErrorEvent):void {
            trace("SimpleIconButton: IOErrorEventHandler: " + event);
            createChildren();	
        }				

		private function createChildren() : void
		{
			tf = new TextField();
			tf.embedFonts = true;
			tf.autoSize = "left";
			tf.defaultTextFormat = this._format;
			tf.antiAliasType = "advanced";
			tf.selectable = false;
			tf.text = this._txt;
			tf.name = "tf";			
			
			btn.addChild(tf);
			
			draw();
			
			this.buttonMode = true;
			this.useHandCursor = true;
			
			addEventListeners();			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function draw() : void
		{
			if (icon && btn.contains(icon))
			{
			
				icon.x = 0;
				icon.y = 0;	
								
				tf.x = icon.width + PAD;
				tf.y = Math.floor((icon.height - tf.height)/2);
			}
		}
		
		private function addEventListeners() : void
		{
			this.addEventListener(MouseEvent.ROLL_OVER, btnRollOver );
			this.addEventListener(MouseEvent.ROLL_OUT, btnRollOut );
			this.addEventListener(MouseEvent.MOUSE_DOWN, btnMouseDown );			
		}
		

		private function btnRollOut(e:MouseEvent):void {
			this.alpha = 1;
			var f : TextFormat = tf.getTextFormat();
				f.color = _format.color;
				f.size = _format.size;				
			tf.text = this._txt;
			tf.setTextFormat(f);				
		}
		
		private function btnRollOver(e:MouseEvent):void {
			this.alpha = 1;
			var f : TextFormat = tf.getTextFormat();
				f.color = _overFormat.color;
				f.size = _overFormat.size;
			tf.text = this._overTxt;
			tf.setTextFormat(f);		
		}			
				
		private function btnMouseDown(e:MouseEvent):void {
			this.alpha = .8;
		}				

	}
}