package  
{	
	import com.topspin.api.config.EnvironmentDetector;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSApplications;
	import com.topspin.api.logging.TSEvents;
	import com.topspin.redeem.RedemptionControl;
	
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Security;
	import flash.system.System;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import gs.TweenLite;
	
	/**
	 * Simple Redemption Application widget utilizing the 
	 * topspin redemption widget api.
	 * 
	 * Note:  To compile include the following packages from
	 * Github:
	 * 
	 * TSAPI
	 *  
	 * 
	 * @author amehta@topspinmedia.com
	 */	
	[SWF(frameRate="31", backgroundColor="#000000")]
	public class TSRedemptionWidget extends Sprite {
		
		public var VERSION:String = "R.IGGY.060710";
		
		//Properties
		private var _width:Number = 400;
		private var _height:Number = 80;
		private var baseURL:String;	
		
		//UI config
		private var highlightColor : Number = 0x00A1FF;
		private var fontColor : Number = 0x333333;
		private var errColor : Number = 0xff0000;
		private var bgColor : Number = 0x000000;
		private var bgAlpha : Number = 1;
		
		//Data passed in via flashVars
		private var widget_id : String;
		
		// Static
		private static var FADE_RATE:Number = .3;
		
		//Embedded fonts
		[Embed( source='/fonts/LucidaGrande.ttf', fontName='LucidaGrandeFont', 
			unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E, U+0080, U+00BF,U+00C0,U+00C1,U+00C8,U+00C9,U+00CC,U+00CD,U+00D2,U+00D3,U+00D8,U+00D9,U+00DA,U+00DD,U+00E0,U+00E1,U+00E8,U+00E9,U+00EC,U+00ED,U+00F2,U+00F3,U+00F8,U+00F9,U+00FA,U+00FD,U+20A4,U+20AC,U+20B5,U+00A5,U+20A4,U+00A3', mimeType="application/x-font-truetype" )]		
		public static var REGULAR : Class;
		
		[Embed( source='/fonts/Lucida Grand Bolder.ttf', fontWeight="bold", fontName='LucidaGrandeFont', 
			unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E, U+0080, U+00BF,U+00C0,U+00C1,U+00C8,U+00C9,U+00CC,U+00CD,U+00D2,U+00D3,U+00D8,U+00D9,U+00DA,U+00DD,U+00E0,U+00E1,U+00E8,U+00E9,U+00EC,U+00ED,U+00F2,U+00F3,U+00F8,U+00F9,U+00FA,U+00FD,U+20A4,U+20AC,U+20B5,U+00A5,U+20A4,U+00A3', mimeType="application/x-font-truetype" )]
		public static var BOLD : Class;		
		
		/**
		 * Constructor 
		 * 
		 */		
		public function TSRedemptionWidget() {
			trace("**********VERSION: " + VERSION);
			Security.allowDomain("*");
			addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
		}
		
		/**
		 * handleAddedToStage 
		 * @param e
		 * 
		 */		
		private function handleAddedToStage( e : Event ) : void
		{
			removeEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
			// Set initial stage properties
			stage.align = "TL";
			stage.scaleMode = "noScale";
			stage.frameRate = 28;
			addEventListener(Event.ENTER_FRAME, onEnterFrame);				
		}
		/**
		 * Work around for FF3 bug on OSX, get the stage width and height 
		 * @param e
		 * 
		 */		
		private function onEnterFrame( e : Event) : void
		{
			if (stage.stageWidth != 0 && stage.stageHeight != 0)
			{
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);			
				var w:Number = stage.stageWidth;
				var h:Number = stage.stageHeight;
				
				_width = (loaderInfo.parameters.w != null) ? loaderInfo.parameters.w : w;
				_height = (loaderInfo.parameters.h != null) ? loaderInfo.parameters.h : h;
				init();	
			}
		}		
		/**
		 * Init 
		 * 
		 */		
		private function init() : void
		{
			//Test for external interface
			testEI();
			
			trace("--loader parameters--");
			for (var p:String in loaderInfo.parameters) {
				trace("\t" + p + "[" + loaderInfo.parameters[p] + "]");
			}
			trace("--end parameters--");
			
			baseURL = EnvironmentDetector.parseBaseURL(loaderInfo);
			trace("baseURL: " + baseURL);
			
			//Get the widget_id
			widget_id = (loaderInfo.parameters.widget_id) ? loaderInfo.parameters.widget_id:widget_id;
			var theme : String = (loaderInfo.parameters.theme != null ) ? loaderInfo.parameters.theme:"white";
			
			//Default UI theme
			if (theme == "white")
			{
				bgColor = 0xffffff;
				bgAlpha = 1;
				fontColor = 0xffffff;
				errColor = 0xff0000;
				highlightColor = 0x333333;
			}
			if (theme == "black")
			{
				bgColor = 0x000000;
				bgAlpha = 1;				
				fontColor = 0xffffff;
				errColor = 0xff0000;
				highlightColor = 0x00A1FF;
			}
			
			//Flash var ui styles
			fontColor = (loaderInfo.parameters.fontColor != null ) ? loaderInfo.parameters.fontColor:fontColor;
			bgColor = (loaderInfo.parameters.bgColor != null ) ? loaderInfo.parameters.bgColor:bgColor;
			bgAlpha = (loaderInfo.parameters.bgAlpha != null ) ? loaderInfo.parameters.bgAlpha:bgAlpha;
			errColor = (loaderInfo.parameters.errorColor != null ) ? loaderInfo.parameters.errorColor:errColor;
			highlightColor = (loaderInfo.parameters.highlightColor != null ) ? loaderInfo.parameters.highlightColor:highlightColor;
			
			//EventLogging, part of  TSAPI, must include TSAPI in your class path
			EventLogger.setEnv(TSApplications.REDEMPTION_WIDGET, loaderInfo);
			
			var isPreview : Boolean = (loaderInfo.parameters.preview_mode != null) ? (loaderInfo.parameters.preview_mode == "true") : false;
			if (isPreview) {
				EventLogger.getInstance().enabled = false;
			}
			
			//DEBUG RT CLICK MENU
			var debugMenu : ContextMenu = new ContextMenu();
			debugMenu.hideBuiltInItems();
			
			var m1 : ContextMenuItem = new ContextMenuItem(VERSION);
			var m2 : ContextMenuItem = new ContextMenuItem("Customer Support");
			m1.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, copyVersion);
			m2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, routeToCS);
			
			debugMenu.customItems.push(m1,m2);
			this.contextMenu = debugMenu;
			
			var CUSTOMER_SUPPORT_LINK : String = "http://support.topspinmedia.com"; 
			
			function copyVersion(e : ContextMenuEvent) : void
			{
				System.setClipboard(VERSION);
			}			
			function routeToCS(e : ContextMenuEvent) : void
			{
				var url:String = CUSTOMER_SUPPORT_LINK;
				var request:URLRequest = new URLRequest(url);
				try{
					navigateToURL(request, '_blank');
				}catch (e:Error) {
					trace("Couldn't redirect to Customer Support: " + e.message);
				}
			}							
			createChildren();
		}
		/**
		 * Create the RedemptionControl component and
		 * add it to the stage 
		 * 
		 */		
		private function createChildren() : void
		{
			var control : RedemptionControl = new RedemptionControl(_width, _height, widget_id,fontColor, 
				highlightColor, errColor,"LucidaGrandeFont",
				bgColor, bgAlpha);
			addChild(control);
			
			//Fire a EventLogger Loaded widget type.
			EventLogger.fire(TSEvents.TYPE.LOADED,{campaign:widget_id});			
		}
		/* Helper Methods */
		/**
		 * Test the script access of the flash in where it has
		 * been embedded.  Based on this information, the player
		 * will automatically determine which buttons and 
		 * behaviors to act upon. 
		 * 
		 */		
		public function testEI():void {
			var isEIAvailable:Boolean = true;
			if (ExternalInterface.available) {
				try {
					ExternalInterface.call ("dummyJS",null); 							
				} catch (e:Error) {
					isEIAvailable = false;
				} catch (e:SecurityError) {
					isEIAvailable = false;                    
				} 			
			} else {
				isEIAvailable = false;    
			}
		}		
	}
}