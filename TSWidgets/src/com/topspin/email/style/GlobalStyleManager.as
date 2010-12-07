package com.topspin.email.style {
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.text.Font;
	import flash.text.StyleSheet;
	import flash.text.TextFormat;
	
	public class GlobalStyleManager extends EventDispatcher {
		
		// Singleton class variables
		protected static var instance:GlobalStyleManager;
		protected static var allowInstantiation:Boolean;

		// Primary style variables
		private var linkColor:uint;
		private var baseColor:uint;
		private var linkOverColor:uint;
		private var fontColor:uint;
		private var errColor:uint;


		// Font Path Variables
		private var baseURL:String;
		private var fontSWFPath:String;
//		private var fontName:String;
		
		// Font Handling
		private var _embedFonts:Boolean = true;
		private var FONT_NAME_THIN : String = "LucidaGrandeFont"; 
		private var FONT_NAME : String = "LucidaGrandeFont"; 			
		
		private var format:TextFormat;
		private var emailFormat:TextFormat;
		private var btnFormat:TextFormat;
		private var btnOverFormat:TextFormat;
		private var errFormat:TextFormat;
		private var embFmt:TextFormat;
		private var versionFormat:TextFormat;
		private var dateFormat : TextFormat;
		private var smallFormat:TextFormat;
		private var smallFormatOver:TextFormat;
		private var errFontSize:uint = 11;
		private var defaultFontSize:uint = 18;
		public var emailFontSize:uint = 14;
		private var btnFontSize:uint = 16;

		// UI
		private var hAlign:String;
		private var imageVAlign : String;
		private var hPadding:Number;
		private var _wordwrap : Boolean = false;
		private var linkHasOutline:Boolean;
		private var bgAlpha;

		// Loader Variables
		private var fontLoader:Loader;
		private var loaderContext:LoaderContext;

		public var infoCSS : StyleSheet;
		public var optionsCSS : StyleSheet;
		public var headerCSS : StyleSheet;

		// Static
		public static var FONT_LOADED:String = "fontLoaded";
		public static const MIN_SIZE:Number = 6;  // Minimum size of a font

		public function GlobalStyleManager() : void {
			if(!allowInstantiation) {
				throw new Error("Error : GlobalStyleManager is a singleton - Use GlobalStyleManager.getInstance() instead of new." );
			}
		}
		
		/**
		 * Provides access to the class attributes and operations.
		 * @return	DataManager	- singleton instance of DataManager 
		 */ 
		public static function getInstance():GlobalStyleManager {
			if(instance == null) {
				allowInstantiation = true;
				instance = new GlobalStyleManager();
				allowInstantiation = false;
			}
			return instance;
		}

		public function init():void {
			loaderContext = new LoaderContext();
			loaderContext.checkPolicyFile = true;
			loaderContext.securityDomain = SecurityDomain.currentDomain;

			format = new TextFormat();
			emailFormat = new TextFormat();
			btnFormat = new TextFormat();
			btnOverFormat = new TextFormat();
			errFormat = new TextFormat();
			versionFormat = new TextFormat();
			smallFormat = new TextFormat();
			smallFormatOver = new TextFormat();
			embFmt = new TextFormat();
			dateFormat = new TextFormat();
			infoCSS = new StyleSheet();
			optionsCSS = new StyleSheet();
			headerCSS = new StyleSheet();
			
			refresh();
//			dispatchEvent(new Event(GlobalStyleManager.FONT_LOADED, true));
		}

		public function refresh():void {

			
			format.font = FONT_NAME;
			format.size = defaultFontSize;
			format.color = fontColor;
			format.align = getHAlign();
			format.bold = true;

			errFormat.font = FONT_NAME;
			errFormat.size = errFontSize;
			errFormat.color = errColor;
			errFormat.align = getHAlign();
			errFormat.bold = true;

			emailFormat.font = FONT_NAME;
			emailFormat.size = emailFontSize;
			emailFormat.color = 0x333333;
			emailFormat.align = "left";
			emailFormat.kerning = true;
			emailFormat.bold = true;

			dateFormat.font = FONT_NAME;
			dateFormat.size = emailFontSize - 1;
			dateFormat.color = 0x333333;
			dateFormat.align = "left";
			dateFormat.kerning = true;
			dateFormat.bold = true;
			
			

			btnFormat.font = FONT_NAME;
			btnFormat.size = btnFontSize;
			btnFormat.color = linkColor;
			btnFormat.bold = true;
			
			btnOverFormat.font = FONT_NAME;
			btnOverFormat.size = btnFontSize;
			btnOverFormat.color = linkOverColor;
			btnOverFormat.bold = true;

			versionFormat.font = FONT_NAME;
			versionFormat.size = 8;
			versionFormat.color = linkColor;
			versionFormat.bold = true;

			smallFormat.font = FONT_NAME;
			smallFormat.size = 8;
			smallFormat.color = linkColor;
			smallFormat.bold = true;
			
			smallFormatOver.font = FONT_NAME;
			smallFormatOver.size = 8;
			smallFormatOver.color = linkOverColor;
			smallFormatOver.bold = true;

			embFmt.font = FONT_NAME;
			embFmt.size = defaultFontSize - 6;
			embFmt.color = fontColor;
			embFmt.align = getHAlign();
			embFmt.bold = true;
			
			var hexLink : String = getNumberAsHexString(linkColor);
			var hexBody : String = getNumberAsHexString(fontColor);
			var mainFont : String = getFormattedFontName();
//			var hexSecondaryFont : String = getNumberAsHexString(secondaryFontColor);
			var hexErrColor : String = getNumberAsHexString(0xcc0000);
			var infoBody : String = "#ffffff";
			infoCSS.setStyle("header", {color:infoBody,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal'});
			infoCSS.setStyle("h1", {color:infoBody,fontSize:'14', fontFamily : mainFont, fontWeight : 'bold'});
			infoCSS.setStyle("message", {color:infoBody,fontSize:'9', fontFamily : mainFont, fontWeight : 'normal'});	
			infoCSS.setStyle("content", {color:infoBody,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal'});	
			infoCSS.setStyle("body", {color:hexLink,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal'});	
			
			
			optionsCSS.setStyle("a:link", {color:hexLink,textDecoration:'none',fontSize:'9', fontFamily : mainFont, fontWeight : 'normal'});
			optionsCSS.setStyle("a:hover", {color:hexLink,textDecoration:'underline',fontSize:'9', fontFamily : mainFont, fontWeight : 'normal'});	
			optionsCSS.setStyle("header", {color:hexBody,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal'});
			optionsCSS.setStyle("h1", {color:hexBody,fontSize:'14', fontFamily : mainFont, fontWeight : 'bold'});
			optionsCSS.setStyle("message", {color:hexBody,fontSize:'9', fontFamily : mainFont, fontWeight : 'normal'});	
			optionsCSS.setStyle("content", {color:hexBody,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal'});	
			optionsCSS.setStyle("body", {color:hexLink,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal'});	

			headerCSS.setStyle("hdr", {color:hexBody,fontSize:'12', fontFamily : mainFont, fontWeight : 'normal'});
			headerCSS.setStyle(".error", {color:hexErrColor,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal'});
			headerCSS.setStyle(".status", {color:hexBody,fontSize:'11', fontFamily : mainFont, fontWeight : 'bold'});
			headerCSS.setStyle("title", {color:hexLink,fontSize:'12', fontFamily : mainFont, fontWeight : 'bold'});				
			headerCSS.setStyle("body",{color:hexBody,fontSize:'10', fontFamily : mainFont, fontWeight : 'normal' });			
			
			
		}


		// Getters/Setters
		public function getLinkColor():uint {
			return this.linkColor;
		}
		
		public function setLinkColor(overrideLinkColor:uint):void {
			this.linkColor = overrideLinkColor
		}

		public function getBaseColor():uint {
			return this.baseColor;
		}
		
		public function setBaseColor(overrideBaseColor:uint):void {
			this.baseColor = overrideBaseColor;
		}

		public function getLinkOverColor():uint {
			return this.linkOverColor;
		}
		
		public function setLinkOverColor(overrideLinkOverColor:uint):void {
			this.linkOverColor = overrideLinkOverColor;
		}

		public function getFontColor():uint {
			return this.fontColor;
		}

		public function setFontColor(overrideFontColor:uint):void {
			this.fontColor = overrideFontColor;
		}

		public function getErrColor():uint {
			return this.errColor;
		}

		public function setErrColor(overrideErrColor:uint):void {
			this.errColor = overrideErrColor;
		}
		
		public function getFormat():TextFormat {
			return this.format;
		}
		
		public function getBtnFormat():TextFormat {
			return this.btnFormat;
		}
		
		public function getBtnOverFormat():TextFormat {
			return this.btnOverFormat;
		}
		
		public function getEmailFormat():TextFormat {
			return this.emailFormat;
		}
		public function getDateFormat() : TextFormat {
			return this.dateFormat;
		}
		public function getVersionFormat():TextFormat {
			return this.versionFormat;
		}
		
		public function getSmallFormat():TextFormat {
			return this.smallFormat;
		}
		
		public function getSmallFormatOver():TextFormat {
			return this.smallFormatOver;
		}
		
		public function getErrFormat():TextFormat {
			return this.errFormat;
		}
		
		public function getEmbFormat():TextFormat {
			return this.embFmt;
		}
		
		public function getFormattedFontName():String {
			return this.FONT_NAME;
		}
		public function getFormattedFontNameLight():String {
			return this.FONT_NAME_THIN;
		}

		public function getDefaultFontSize():Number {
			return this.defaultFontSize;
		}
		
		public function getErrorFontSize():Number {
			return this.errFontSize;
		}
		
		public function getEmbedFonts():Boolean {
			return this._embedFonts;
		}

		public function getEmailFontSize():Number {
			return this.emailFontSize;
		}

		public function setHPadding(overrideHPadding:Number):void {
			this.hPadding = overrideHPadding;
		}
		
		public function getHPadding():Number {
			return this.hPadding;
		}
		
		public function setWordWrap( wordwrap : Boolean ) : void
		{
			_wordwrap = wordwrap;
		}
		public function getWordWrap() : Boolean
		{
			return _wordwrap;
		}		
		public function setHAlign(overrideHAlign:String):void {
			this.hAlign = overrideHAlign;
		}
		
		public function getHAlign():String {
			return this.hAlign;
		}
		
		public function getImageVAlign():String {
			return this.imageVAlign;
		}
		public function setImageVAlign(overrideVAlign:String):void {
			this.imageVAlign = overrideVAlign;
		}		
		
		public function setLinkHasOutline(overrideLinkHasOutline:Boolean):void {
			this.linkHasOutline = overrideLinkHasOutline;
		}
		
		public function getLinkHasOutline():Boolean {
			return this.linkHasOutline;
		}
		
//		public function setBaseURL(overrideBaseURL:String):void {
//			this.baseURL = overrideBaseURL;
//		}
//		
//		public function getBaseURL():String {
//			return this.baseURL;
//		}
		
		public function setFontSWFPath(overrideFontSWFPath:String):void {
			this.fontSWFPath = overrideFontSWFPath;
		}
		
		public function getFontSWFPath():String {
			return this.fontSWFPath;
		}
		
//		public function setFontName(overrideFontName:String):void {
//			trace("setFontName: " + overrideFontName);
//			this.fontName = overrideFontName;
//		}
//		
//		public function getFontName():String {
//			return this.fontName;
//		}
		
		public function setBgAlpha(overrideBgAlpha:Number):void {
			this.bgAlpha = overrideBgAlpha;
		}
		
		public function getBgAlpha():Number {
			return this.bgAlpha;
		}
		
        public function getNumberAsHexString(number:uint, minimumLength:uint = 1, showHexDenotation:Boolean = true):String {
                // The string that will be output at the end of the function.
                var string:String = number.toString(16).toUpperCase();
                // While the minimumLength argument is higher than the length of the string, add a leading zero.
                while (minimumLength > string.length) {
                        string = "0" + string;
                }
                // Return the result with a "0x" in front of the result.
                if (showHexDenotation) { string = "#" + string; }
                return string;
        }		
		
	}
}