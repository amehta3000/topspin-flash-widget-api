package com.topspin.email.dialogs {

	import com.topspin.email.style.GlobalStyleManager;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import gs.TweenLite;
	
	public class Dialog extends Sprite {
		// Input Variables
		private var _width:Number;
		private var _height:Number;
		private var _embedCode:String;
		private var _titleString:String;

		// UI
		private var embedHdrTxt:TextField;
		private var embedTxt:TextField;
		private var PAD : uint = 4;

		// Class Instances
		private var styles:GlobalStyleManager;

		// Static
		private static var FADE_RATE:Number = .3;
		
		public function Dialog(width:Number, height:Number, embedCode:String, titleString:String) {
			this._width = width;
			this._height = height;
			this._embedCode = embedCode;	
			
			styles = GlobalStyleManager.getInstance();
			
			this.graphics.beginFill(styles.getBaseColor(), 1);
			this.graphics.drawRect(0,0,_width,_height);
			this.graphics.endFill();
			
			var embFmt:TextFormat = new TextFormat(styles.getFormattedFontName(), styles.getDefaultFontSize() - 6, styles.getFontColor(), true);
				embFmt.align = styles.getHAlign();
			var codeFormat:TextFormat  = new TextFormat(styles.getFormattedFontName(), styles.getEmailFontSize() - 4, 0x333333, true);
				codeFormat.align = "left";
				codeFormat.kerning = true;			
			var copyFormat:TextFormat = new TextFormat(styles.getFormattedFontName(), styles.getDefaultFontSize() - 4, styles.getLinkColor(), true);
			var copyFormatOver:TextFormat =  new TextFormat(styles.getFormattedFontName(), styles.getDefaultFontSize() - 4, styles.getLinkOverColor(), true);				

			var closeBtn:SimpleLinkButton = new SimpleLinkButton("Close", styles.getSmallFormat(), styles.getSmallFormatOver(), null, false, 5, 0, 16);
			var copyBtn:SimpleLinkButton =  new SimpleLinkButton("Copy", copyFormat, copyFormatOver, null, styles.getLinkHasOutline(), 10, 0, 16, "center");

			embedHdrTxt = new TextField();
			embedHdrTxt.embedFonts = styles.getEmbedFonts();
			embedHdrTxt.antiAliasType = "advanced";
			embedHdrTxt.width = _width - 2 * styles.getHPadding();
			embedHdrTxt.defaultTextFormat = styles.getEmbFormat();
			embedHdrTxt.text = _titleString; // "Embed";
			embedHdrTxt.height = embedHdrTxt.textHeight;
			embedHdrTxt.autoSize ="left";			
			embedHdrTxt.x = styles.getHPadding();			

			embedTxt = new TextField();
			embedTxt.embedFonts = styles.getEmbedFonts();
			embedTxt.selectable = false;
			embedTxt.type = "input";
			embedTxt.antiAliasType = "advanced";
			embedTxt.width = _width - (copyBtn.width + 2 * styles.getHPadding() + PAD);	
			embedTxt.background = true;
			embedTxt.backgroundColor = 0xaaaaaa;	
			embedTxt.border = true;
			embedTxt.borderColor = 0x333333;
			embedTxt.defaultTextFormat = codeFormat;				
			embedTxt.text = this._embedCode;
			embedTxt.height = styles.getEmbFormat().size + 8; //embedTxt.textHeight + PAD;// -2*_padding;
			
			embedHdrTxt.y = Math.floor((_height - (embedHdrTxt.height + embedTxt.height))/2);
			embedTxt.y = embedHdrTxt.y + embedHdrTxt.height + PAD;
			embedTxt.x = styles.getHPadding();
			copyBtn.y = embedTxt.y + (embedTxt.height - copyBtn.height)/2;
			copyBtn.x = Math.floor(embedTxt.x + embedTxt.width + (2*PAD));
			
			closeBtn.x = (_width - closeBtn.width- PAD);
			closeBtn.y = PAD;
			
			closeBtn.addEventListener(MouseEvent.CLICK, handleCloseEmbed);				
			copyBtn.addEventListener(MouseEvent.CLICK, handleCopy);			
			
			addChild(closeBtn);
			addChild(embedHdrTxt);
			addChild(embedTxt);
			addChild(copyBtn);			
		}

		private function handleCloseEmbed(e:Event):void {
			TweenLite.to(this, FADE_RATE, {autoAlpha:0});
		}
		
		private function handleCopy(event:MouseEvent):void {
			stage.focus = embedTxt;
			embedTxt.setSelection(0, embedTxt.length-1);
			System.setClipboard(embedTxt.text);
		}
		
	}
}