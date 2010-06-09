package com.topspin.redeem
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.StringUtil;
	import com.adobe.validation.as3DataValidation;
	import com.adobe.validation.as3ValidationResult;
	import com.topspin.common.controls.SimpleLinkButton;
	
	import fl.motion.easing.Cubic;
	import fl.transitions.TweenEvent;
	
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	import gs.TweenLite;

	/**
	 * Simple reusuable RedemptionControl component that will render
	 * a textfield and submit button.  Calls the Topspin
	 * redemption api as specified by the widget_id passed 
	 * in.  The redemption code is appended to the widget_id
	 * and then submitted.
	 *  
	 * @author amehta@topspinmedia.com
	 * 
	 */	
	public class RedemptionControl extends Sprite
	{
		//main api url
		private var _widgetId : String;
		//properties from contructor
		private var _width : Number;
		private var _height : Number;
		private var _fontColor : Number;
		private var _errColor : Number;
		private var _highlightColor : Number;
		private var _fontName : String;
		private var _bgColor : Number;
		private var _bgAlpha : Number;
		
		//Validation
		private var _isSubmitting : Boolean = false;
		private var _savedCode : String;
		private var _validator : as3DataValidation;
		
		//Containers
		private var reedemHolder : Sprite;
		private var linkHolder : Sprite;
		
		//Components
		private var codeTxt : TextField;
		private var submitBtn : SimpleLinkButton;
		private var linkTxt : TextField;
		
		//Properties
		private var PAD : Number = 4;		
		private var _dlink : String;
		
		//States
		private var REDEEM_STATE : String = "redeemer";
		private var DOWNLOAD_STATE : String = "downloader";
		
		//Error messages
		private var ALPHA_NUMERIC_ERROR : String = "Alpha numeric codes only";
		private var INVALID_CODE : String = "Invalid Code";
		private var INVALID_ARTIST : String = "Invalid Artist";
		private var EXPIRED_CODE : String = "Code is expired";
		private var INACTIVE : String = "Offer is not active";
		private var OFFER_REDEEMABLE : String = "Offer redeemable";

		
		/**
		 * Constructor 
		 * @param w	- width
		 * @param h = height
		 * @param widget_id - widget_id api
		 * @param fontColor	
		 * @param highlightColor
		 * @param errorColor
		 * @param fontName
		 * @param bgColor
		 * @param bgAlpha
		 * 
		 */		
		public function RedemptionControl(w : Number, h : Number, widget_id : String, 
										  fontColor : Number = 0x333333, 
										  highlightColor : Number = 0x00A1FF, 
										  errorColor : Number = 0xff0000,
										  fontName : String = "LucidaGrandeFont",
										  bgColor : Number = 0xffffff,
										  bgAlpha : Number = 1) {
			_width = w;
			_height = h;
			_widgetId = widget_id;
			_fontColor = fontColor;
			_highlightColor = highlightColor;
			_errColor = errorColor;
			_fontName = fontName;
			_bgColor = bgColor;
			_bgAlpha = bgAlpha;
			init();
			createChildren();
		}
		/**
		 * Init 
		 * 
		 */		
		private function init() : void
		{
			_validator = new as3DataValidation();
			addEventListener(Event.ADDED_TO_STAGE, handleAdded);
		}
		/**
		 * Create the children of the component 
		 * 
		 */			
		private function createChildren() : void
		{
			reedemHolder = new Sprite();
			linkHolder = new Sprite();
			this.graphics.beginFill(_bgColor,_bgAlpha);
			this.graphics.drawRect(0,0,_width, _height);
			this.graphics.endFill();			
			
			addChild(reedemHolder);
			addChild(linkHolder);
			
			var btnFontSize : Number = 11;
			var btnFormat : TextFormat = new TextFormat();
			var btnOverFormat : TextFormat = new TextFormat();
			btnFormat.font = _fontName;
			btnFormat.size = btnFontSize;
			btnFormat.color = _highlightColor;
			btnFormat.bold = true;
			
			btnOverFormat.font = _fontName;
			btnOverFormat.size = btnFontSize;
			btnOverFormat.color = _fontColor;
			btnOverFormat.bold = true;
						
			submitBtn = new SimpleLinkButton("Redeem", btnFormat, btnOverFormat, null, true, 3,2, 14, "center",1,true,0); 
			reedemHolder.addChild(submitBtn);
			
			var codeFormat : TextFormat = new TextFormat();
			codeFormat.font = _fontName;
			codeFormat.size = 10;
			codeFormat.color = 0x333333;
			codeFormat.align = "left";
			codeFormat.kerning = true;
			codeFormat.bold = true;
				
			codeTxt = new TextField();
			codeTxt.embedFonts = true;
			codeTxt.type = "input";
			codeTxt.antiAliasType = "advanced";
			var w = (_width - submitBtn.getWidth() - PAD - 4);
			codeTxt.width = w;
			codeTxt.background = true;
			codeTxt.backgroundColor = 0xffffff;	
			codeTxt.border = true;
			codeTxt.borderColor = _highlightColor;
			codeTxt.text = "";
			codeTxt.defaultTextFormat = codeFormat;
			codeTxt.setTextFormat(codeFormat);
			codeTxt.height = 20;// -2*dm.getHPadding;
			codeTxt.selectable = true;
			codeTxt.restrict = "a-zA-Z0-9";
			
			reedemHolder.addChild(codeTxt);
			
			codeTxt.x = 1;
			submitBtn.x = _width - submitBtn.getWidth() - 3;
			submitBtn.y = 1;
			codeTxt.y = 3;
			
			var hexLink : String = getNumberAsHexString(_highlightColor);			
			var css : StyleSheet = new StyleSheet();
			css.setStyle("a:link", {color:hexLink,textDecoration:'none',fontSize:'10', fontFamily : _fontName, fontWeight : 'bold'});
			css.setStyle("a:hover", {color:hexLink,textDecoration:'underline',fontSize:'10', fontFamily : _fontName, fontWeight : 'bold'});
			
			//Contains the download link
			linkTxt = new TextField();
			linkTxt.embedFonts = true;
			linkTxt.antiAliasType = "advanced";
			linkTxt.width = _width - 4;
			linkTxt.height = 20;
			linkTxt.styleSheet = css;
			linkTxt.x = 1;
			linkTxt.y = 3;
			
			linkHolder.addChild(linkTxt);
			
			configureListeners();
			showState(REDEEM_STATE);
		}
		/**
		 * Configures listeners 
		 * 
		 */		
		private function configureListeners() : void
		{
			submitBtn.addEventListener(MouseEvent.CLICK, handleSubmit);
			codeTxt.addEventListener(FocusEvent.FOCUS_IN, handleFocusIn);
		}
		/**
		 * Sets the value of the download link 
		 * @param link
		 * 
		 */		
		private function setDownloadLink( link : String ) : void
		{
			var link : String = "<a href='" + link + "'>" + link + "</a>";	
			linkTxt.htmlText = link;
		}
		/**
		 * Sets the codeTxt textfield and changes the color if
		 * it is an error message 
		 * @param str
		 * @param isError
		 * 
		 */		
		private function setCodeText( str : String , isError : Boolean = false) : void
		{
			codeTxt.text = str;
			codeTxt.borderColor = (isError) ? _errColor : _highlightColor;
		}
		/**
		 * Handles focus in of the codeTxt 
		 * @param e
		 * 
		 */		
		private function handleFocusIn( e : Event ) : void
		{
			var txt : String = codeTxt.text;
			if (txt == INVALID_CODE || txt == INVALID_ARTIST 
				|| txt == EXPIRED_CODE || txt == INACTIVE)		
			{
				setCodeText("", false);
			}
			
			if (txt == ALPHA_NUMERIC_ERROR && _savedCode != null)
			{
				setCodeText(_savedCode, false);
				_savedCode = null;
			}
			
			if (txt.indexOf(OFFER_REDEEMABLE) != -1)
			{
				setCodeText("", false);
			}
			
			codeTxt.stage.focus = codeTxt;
			codeTxt.setSelection(0,codeTxt.length);
			trace("Focus: " + e.target, codeTxt.length);
		}
		/**
		 * Shows the proper state 
		 * @param state
		 * 
		 */		
		private function showState( state : String ) : void
		{
			switch (state){
				case REDEEM_STATE:
					reedemHolder.visible = true;					
					linkHolder.visible = false;
					break;
				case DOWNLOAD_STATE:
					linkHolder.y = -linkHolder.height;
					reedemHolder.visible = false;	
					linkHolder.visible = true;
					TweenLite.to(linkHolder, .2, {y:0, ease:Cubic.easeIn});
					break
			}	
		}
		/**
		 * Submit handler 
		 * @param e
		 * 
		 */		
		private function handleSubmit( e : MouseEvent = null) : void
		{
			var code : String = StringUtil.trim(codeTxt.text);
			if (!_validator.isAlphaNumeric(code))
			{
				_savedCode = code;
				setCodeText(ALPHA_NUMERIC_ERROR, true);				
				_isSubmitting = false;
				return;
			}
			
			if (_isSubmitting) return;
			
			if (code.length == 0) return;
			
			var api : String = _widgetId;
			api += escape(code);
			
			trace("REDEEM THIS : " + api);
			var loader : URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, handleJSONResponse);
			loader.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			
			loader.load(new URLRequest(api));			
			_isSubmitting = true;
			codeTxt.text = "Submitting. . .";
		}
		private function handleIOError( e : IOErrorEvent) : void
		{
			_isSubmitting = false;
			trace("Error: " + e);
		}
		private function handleSecurityError( e : SecurityErrorEvent ) : void
		{
			_isSubmitting = false;
			trace("SecurityError: " + e);
		}
		/**
		 * Handler for JSON response 
		 * @param e
		 * 
		 */		
		private function handleJSONResponse( e : Event) : void
		{
			var jsonStr : String = e.target.data;
			trace("JSON: " + jsonStr);
			try {
				var json : Array = JSON.decode("[" + jsonStr + "]");
				trace("json:" + json);
				var data : Object = json[0];
				if (data.status == "ok")
				{
					setCodeText("", false);	
					_dlink = data.download_url;
					setDownloadLink(_dlink);
					showState(DOWNLOAD_STATE);
				}
				if (data.status == "error")
				{
					setCodeText( data.message, true);	
				}
								
			}catch(e : Error){
				trace("Error cannot parse JSON response: " + jsonStr);
			}
			_isSubmitting = false;
		}
		/**
		 * ADDED TO STAGE handler 
		 * @param e
		 * 
		 */		
		private function handleAdded( e : Event ) : void
		{
			removeEventListener(Event.ADDED_TO_STAGE, handleAdded);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, enterKeyDown,true);	
		}	
		/**
		 * Key down event handler 
		 * @param e
		 * 
		 */		
		public function enterKeyDown(e:KeyboardEvent):void
		{ 
			var kc:Number = e.keyCode;
			if (codeTxt && codeTxt.visible) {
				if (stage.focus == codeTxt && e.keyCode == Keyboard.ENTER) {
					handleSubmit();
				}			
			}
		}		
		/**
		 * Utility function to convert to number to hex. 
		 * @param number
		 * @param minimumLength
		 * @param showHexDenotation
		 * @return 
		 * 
		 */		
		public function getNumberAsHexString(number:uint, minimumLength:uint = 1, showHexDenotation:Boolean = true):String {
			var string:String = number.toString(16).toUpperCase();
			while (minimumLength > string.length) {
				string = "0" + string;
			}
			// Return the result with a "0x" in front of the result.
			if (showHexDenotation) { string = "#" + string; }
			return string;
		}		
		
	}
}