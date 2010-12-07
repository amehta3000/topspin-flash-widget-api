/**
 * Base class that will instantiate the TSEmailMediaWidget.swf
 * which will be embedded by a swfObject with various
 * flashVars and parameters.
 * 
 * The resulting swf is used in the Publishing Platform 1.0
 * and will take in single wiget_id which will configure the
 * widget as is it to be seen in the wild.
 * 
 * The following parameters may be sent into the player
 * to customize its UI.
 * 
 * width:Number (min is 250)
 * height:Number (min is 80)
 * linkColor:Number - color of the LinkButton & rollover state
 * linkOverColor:Number - color of LinkButton txt in rollover state
 * baseColor:Number - color of the background of the player
 * 
 */
package 
{

	import com.topspin.api.config.EnvironmentDetector;
	import com.topspin.api.events.TSWidgetEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSApplications;
	import com.topspin.api.logging.TSEvents;
	import com.topspin.common.preloader.animation.SpinLoader;
	import com.topspin.common.styles.ThemeManager;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.style.GlobalStyleManager;
	import com.topspin.email.views.AbstractView;
	import com.topspin.email.views.E4MPlayerView;
	import com.topspin.email.views.EmailMediaWidgetView;
	
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Security;
	import flash.system.System;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import gs.TweenLite;

	[SWF(frameRate="31", backgroundColor="#000000")]
	public class TSEmailMediaWidget extends Sprite {
	
		// Static
		public static var VERSION:String = "E.HANK.120610";
		public static var FADE_RATE:Number = .3;
		
		//Properties 
		private var baseURL:String;						//base url of where the swf is loaded from
		private var _width:Number = 400;
		private var _height:Number = 80;
		private var widget_id:String;					//Main widget_id
		public var varMap : Object = new Object();		//Persistent flashVars map to pass on to the embed code
		public var flashVarObj:Object;					//Flashvars set to the DataManager
		
		
		// Data
		private var dm:DataManager;						//Data Manager
		private var styles:GlobalStyleManager;			//Style Manager
		
		//Components
		public var viewtype : String = "email";			//player	
		public var view:AbstractView;			//Main views
		public var progress:SpinLoader;					//Loading progress spinner
		public var app : Object;						//Reference to the main Application

		//Font embed Regular
		[Embed( source='/fonts/LucidaGrande.ttf', fontName='LucidaGrandeFont', 
			unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E, U+0080, U+00BF,U+00C0,U+00C1,U+00C8,U+00C9,U+00CC,U+00CD,U+00D2,U+00D3,U+00D8,U+00D9,U+00DA,U+00DD,U+00E0,U+00E1,U+00E8,U+00E9,U+00EC,U+00ED,U+00F2,U+00F3,U+00F8,U+00F9,U+00FA,U+00FD,U+20A4,U+20AC,U+20B5,U+00A5,U+20A4,U+00A3,U+00A9,U+00AE', mimeType="application/x-font-truetype" )]		
		public static var REGULAR : Class;
		//Font embed Bold
		[Embed( source='/fonts/Lucida Grand Bolder.ttf', fontWeight="bold", fontName='LucidaGrandeFont', 
			unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E, U+0080, U+00BF,U+00C0,U+00C1,U+00C8,U+00C9,U+00CC,U+00CD,U+00D2,U+00D3,U+00D8,U+00D9,U+00DA,U+00DD,U+00E0,U+00E1,U+00E8,U+00E9,U+00EC,U+00ED,U+00F2,U+00F3,U+00F8,U+00F9,U+00FA,U+00FD,U+20A4,U+20AC,U+20B5,U+00A5,U+20A4,U+00A3,U+00A9,U+00AE', mimeType="application/x-font-truetype" )]
		public static var BOLD : Class;		
		
		//Contructor
		public function TSEmailMediaWidget() {
			trace("**********VERSION: " + VERSION);
			Security.allowDomain("*");
			addEventListener(Event.ADDED_TO_STAGE, handleInit);
		}
		
		/**
		 * Setup stage properties 
		 * @param e
		 * 
		 */		
		private function handleInit( e : Event ) : void
		{
			removeEventListener(Event.ADDED_TO_STAGE, handleInit);
			// Set initial stage properties			
			stage.align = "TL";
			stage.scaleMode = "noScale";
			stage.frameRate = 28;
			this.app = this;
			addEventListener(Event.ENTER_FRAME, onEnterFrame);				
		}
		/**
		 * FF Mac OSX bug work around, where stage width and height
		 * are 0 initially.  Use onEnterFrame until we get the 
		 * dimensions.  flashvars for w and h can be sent in
		 * optionally.   
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
				
				w = (loaderInfo.parameters.w != null) ? loaderInfo.parameters.w : w;
				h = (loaderInfo.parameters.h != null) ? loaderInfo.parameters.h : h;
				setSize(w, h);		
				init();	
          	}
		}		
		/**
		 * Set up DataManager, progress spinner, data objects
		 * Event Logger 
		 * 
		 */		
		private function init() : void
		{
			if (_height >= 80) {
				var dim : Number = 40;
				progress = new SpinLoader(dim, dim, 0xFFFFFF);
				setProgressPosition();
				showLoader(true);
			}		
			
			flashVarObj = {};
			styles = GlobalStyleManager.getInstance();

			dm = DataManager.getInstance();
			dm.setAppRoot(this);
			dm.addEventListener(DataManager.DATA_LOAD_SUCCESS, handleDataLoadSuccess);
//			dm.addEventListener(DataManager.DATA_LOAD_ERROR, handleDataLoadError);
			dm.addEventListener(TSWidgetEvent.WIDGET_ERROR, handleDataLoadError);
			
			//Test for External Interface access
			testEI();

			trace("--loader parameters--");
			for (var p:String in loaderInfo.parameters) {
				trace("\t" + p + "[" + loaderInfo.parameters[p] + "]");
			}
			trace("--end parameters--");
			
			//Get the baseUrl
			baseURL = EnvironmentDetector.parseBaseURL(loaderInfo);
			trace("baseURL: " + baseURL);

			//GA tracking id optionally passed in via flashvars
			var gat : String = (loaderInfo.parameters.gat != null) ? loaderInfo.parameters.gat : null;	
			var debug : Boolean = (loaderInfo.parameters.debug != null) ? (loaderInfo.parameters.debug == "true") : false;					
			
			//Main widget_id pulled in via flashvars
			widget_id = (loaderInfo.parameters.widget_id) ? loaderInfo.parameters.widget_id:widget_id;
			
			//Set up ev logger for E4M application
//			EventLogger.setEnv(TSApplications.E4M, loaderInfo,null,null,this,gat, debug);

			//preview_mode sent in Topspin publish platform so that px logger events are not fired
			var isPreview : Boolean = (loaderInfo.parameters.preview_mode != null) ? (loaderInfo.parameters.preview_mode == "true") : false;
			if (isPreview) {
//				EventLogger.getInstance().enabled = false;
				dm.isPreview = isPreview;
			}

			//Create the context menu for right clickin
			var debugMenu : ContextMenu = new ContextMenu();
			debugMenu.hideBuiltInItems();
			
			var CUSTOMER_SUPPORT_LINK : String = "http://support.topspinmedia.com"; 
			var m1 : ContextMenuItem = new ContextMenuItem(VERSION);
			var m2 : ContextMenuItem = new ContextMenuItem("Customer Support");
			m1.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, copyVersion);
			m2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, routeToCS);
			
			debugMenu.customItems.push(m1,m2);
			this.contextMenu = debugMenu;

				function copyVersion(e : ContextMenuEvent) : void {
					System.setClipboard(VERSION);
				}			
				function routeToCS(e : ContextMenuEvent) : void {
					var url:String = CUSTOMER_SUPPORT_LINK;
					var request:URLRequest = new URLRequest(url);
					try{
						navigateToURL(request, '_blank');
					}catch (e:Error) {
						trace("Couldn't redirect to Customer Support: " + e.message);
					}
				}			

			//Next step, load up the config vars
			if (widget_id != null) {
				loadFlashVars();
			} else {
				displayErrorView("Sorry, the widget id cannot be found");
			}			
		}

		/**
		 * Loads up flashVar and gets default color pro 
		 * 
		 */		 
		private function loadFlashVars():void {
			trace("TSEmailMediaWidget.loadFlashVars()");
			// The theme for the widget UI
			var theme : String = (loaderInfo.parameters.theme != null) ? loaderInfo.parameters.theme : "black";
			
			// Default values and Data Handling		
			var bgImageLocation:String = null;  		// URL for the image used as the widget background
			var clickTag:String = null;					//ClickTag sent in via ad platforms
			var ctaImageLocation : String = null; 		//URL for the image used as the CTA button.
			var displayInitialScreen:Boolean = true;	//Displays the initial Call to Action button or not
			var embedAlign:String = "center";			//Alignment of the embed button
			var langCode:String = "en";  				// Language the primary font is rendered in
			var maxPhotos:Number = 50;					//max photos to be returned from flickr
			var submitImageLocation:String = null;  	// URL for image used for the submit button
			var toggleViews:Boolean = false;			//ToggleView, used to show headline message at the top of the widget
			var playMedia:Boolean = false;				//Plays a single audio or video stream from the E4M payload
			var autoplay:Boolean = false;				//Used in conjunction with playMedia, autoplays
			
			//Main properties
			flashVarObj.widgetID = widget_id;
			flashVarObj.height = _height;
			flashVarObj.width = _width;
			flashVarObj.theme = theme;
			
			// FlashVars
			flashVarObj.langCode = (loaderInfo.parameters.langCode != null) ? loaderInfo.parameters.langCode : langCode;
			flashVarObj.baseURL =  (loaderInfo.parameters.debug_baseurl != null) ? loaderInfo.parameters.debug_baseurl : baseURL;						
			flashVarObj.bgImageLocation = (loaderInfo.parameters.bgImage != null) ? loaderInfo.parameters.bgImage : bgImageLocation;
			flashVarObj.clickTag = (loaderInfo.parameters.clickTag != null) ? loaderInfo.parameters.clickTag : clickTag;
			flashVarObj.crossfaderate = (loaderInfo.parameters.crossfaderate != null) ? loaderInfo.parameters.crossfaderate : 5;
			flashVarObj.ctaImageLocation = (loaderInfo.parameters.ctaImage != null) ? loaderInfo.parameters.ctaImage : ctaImageLocation;
			flashVarObj.delaystart = (loaderInfo.parameters.delaystart != null) ? loaderInfo.parameters.delaystart : 1;
			flashVarObj.displayInitialScreen = (loaderInfo.parameters.displayInitialScreen != null) ? (loaderInfo.parameters.displayInitialScreen == "true" || loaderInfo.parameters.displayInitialScreen == 1) : displayInitialScreen
			flashVarObj.embedAlign = (loaderInfo.parameters.embedalign != null) ? loaderInfo.parameters.embedalign : embedAlign;		
			flashVarObj.embedwidth = (loaderInfo.parameters.embedwidth != null) ? loaderInfo.parameters.embedwidth : _width;
			flashVarObj.embedheight = (loaderInfo.parameters.embedheight != null) ? loaderInfo.parameters.embedheight : _height;
			flashVarObj.hideinfo = (loaderInfo.parameters.hideinfo != null) ? (loaderInfo.parameters.hideinfo == "true" || loaderInfo.parameters.hideinfo == 1): false;
			flashVarObj.maxPhotos = (loaderInfo.parameters.maxphotos != null) ? loaderInfo.parameters.maxphotos : maxPhotos;		
			flashVarObj.smoothing = (loaderInfo.parameters.smoothing != null) ? (loaderInfo.parameters.smoothing == "true" || loaderInfo.parameters.smoothing == 1) : true;
			flashVarObj.submitImageLocation = (loaderInfo.parameters.submitImage != null) ? loaderInfo.parameters.submitImage : submitImageLocation;			
			flashVarObj.toggleViews = (loaderInfo.parameters.toggleViews != null) ? (loaderInfo.parameters.toggleViews == "true" || loaderInfo.parameters.toggleViews == 1) : toggleViews;
			viewtype = (loaderInfo.parameters.viewtype != null) ? loaderInfo.parameters.viewtype : viewtype;
			//Pertaining to playing media
			flashVarObj.playMedia = (loaderInfo.parameters.playMedia != null) ? (loaderInfo.parameters.playMedia == "true" || loaderInfo.parameters.playMedia == 1) : playMedia;
			flashVarObj.autoplay = (loaderInfo.parameters.autoplay != null) ? (loaderInfo.parameters.autoplay == "true" || loaderInfo.parameters.autoplay == 1) : autoplay;
			flashVarObj.loop = (loaderInfo.parameters.loop != null) ? (loaderInfo.parameters.loop == "true") : false;

			//Awesm, Twitter tracking
			flashVarObj.pid = (loaderInfo.parameters.pid != null) ? (loaderInfo.parameters.pid) : "0";
			flashVarObj.awesm = (loaderInfo.parameters.awesm != null) ? (loaderInfo.parameters.awesm) : null;
			flashVarObj.twthash = (loaderInfo.parameters.twthash != null) ? (loaderInfo.parameters.twthash) : null;
			
			//Displays a custom link at the bottom right of the widget
			flashVarObj.customLinkUrl = (loaderInfo.parameters.customLinkUrl != null) ? (loaderInfo.parameters.customLinkUrl) : null;
			flashVarObj.customLinkLabel = (loaderInfo.parameters.customLinkLabel != null) ? (loaderInfo.parameters.customLinkLabel) : null;

			//Debug: Flush the COPPA cookie
			flashVarObj.flush = (loaderInfo.parameters.flush != null) ? (loaderInfo.parameters.flush == "true" || loaderInfo.parameters.flush == 1) : false;
						
			//New for the player
			flashVarObj.includeArtistName = (loaderInfo.parameters.includeArtistName != null) ? (loaderInfo.parameters.includeArtistName == "true" || loaderInfo.parameters.includeArtistName == 1)  : false;
			
			flashVarObj.playbutton = (loaderInfo.parameters.playbutton != null) ? (loaderInfo.parameters.playbutton == "true" || loaderInfo.parameters.playbutton == 1)  : true;
			
			// Style handling
			var highlightColor : Number;  				//Essentially, the same thing as linkColor, highlightColor
														//  used for consistency across all widgets
			var baseColor:Number = 0x00000;				//Bg color of the widget
			var bgAlpha:Number = 1;						//BG alpha 
			var errColor:Number = 0xFF0033;				//Error color
			var fontColor:Number = 0x000000;			//Main font color
			var hAlign:String = "center";  				// Horizontal alignment of text and text field
			var hPadding:Number = 4;					//horizontal padding between edges of the widget
			var imageVAlign : String = DataManager.VALIGN_CENTER; 	//Vertical align of the image/slideshow
			var linkColor:Number = 0x00A1FF;			//Color used for the Button
			var linkOverColor:Number = 0x000000;		//The opposite color for the button
			var linkHasOutline:Boolean = true;  		// Outline around the button
			var wrap : Boolean = false;
			
			// Playlist style colors
			var playlistItemBgColor1:Number = 0x515151;  // Background for master playlist item
			var playlistItemBgColor2:Number = 0x3D3D3D;  // Background for slave playlist item - if undefined, set as master playlist BGColor slightly desaturated
			var playlistItemOverColor:Number = 0xAAAAAA;  // Color displayed on playlist item mouseOver
			var playlistItemClickColor:Number = 0x66CCFF;  // Color displayed on playlist item click  // 0xB2E5FF
			var playlistItemSelectColor:Number = linkColor;  // Color displayed on when playlist item is selected
			var playlistItemFontColor:Number = 0xFFFFFF;  // Color of playlist item font 
			var playlistItemFontOverColor:Number = 0xFFFFFF;  // Color of playlist item font on mouse over
			var playlistItemFontSelectColor:Number = linkOverColor;  // Color of playlist item font when selected
			var playlistItemFontClickColor:Number = linkOverColor;  // Color of playlist item font on mouse down
			
			// Scrollbar style colors
			var scrollbarBgColor:Number = playlistItemBgColor1;  // Main color of the scrollbar
			var scrollbarButtonColor:Number = playlistItemOverColor;  // Color of scrollbar components
			
			//Master highlight color, overrides it all!
			highlightColor = (loaderInfo.parameters.highlightColor!=null) ? loaderInfo.parameters.highlightColor : null;

			// Theme Handling			
			if (theme) {
				var style:Object = ThemeManager.getTheme(theme);				
				if (style) {
					linkColor = (style.linkColor != null) ? style.linkColor : linkColor;
					linkOverColor = (style.linkOverColor != null) ? style.linkOverColor : linkOverColor;
					baseColor = (style.baseColor != null) ? style.baseColor : baseColor;
					fontColor = (style.fontColor != null) ? style.fontColor : fontColor;
					errColor = (style.errColor != null) ? style.errColor : errColor;
					
					playlistItemBgColor1 = (style.playlistItemBgColor1) ? style.playlistItemBgColor1 : playlistItemBgColor1;
					playlistItemBgColor2 = (style.playlistItemBgColor2) ? style.playlistItemBgColor2 : playlistItemBgColor2;
					playlistItemOverColor = (style.playlistItemOverColor) ? style.playlistItemOverColor : playlistItemOverColor;
					playlistItemClickColor = (style.playlistItemClickColor) ? style.playlistItemClickColor : playlistItemClickColor;
					playlistItemSelectColor = (style.playlistItemSelectColor) ? style.playlistItemSelectColor : playlistItemSelectColor;
					playlistItemFontColor = (style.playlistItemFontColor) ? style.playlistItemFontColor : playlistItemFontColor;
					playlistItemFontOverColor = (style.playlistItemFontOverColor) ? style.playlistItemFontOverColor : playlistItemFontOverColor;
					playlistItemFontSelectColor = (style.playlistItemFontSelectColor) ? style.playlistItemFontSelectColor : playlistItemFontSelectColor;
					playlistItemFontClickColor = (style.playlistItemFontClickColor) ? style.playlistItemFontClickColor : playlistItemFontClickColor;
					scrollbarBgColor = (style.scrollbarBgColor) ? style.scrollbarBgColor : scrollbarBgColor;
					scrollbarButtonColor = (style.scrollbarButtonColor) ? style.scrollbarButtonColor : scrollbarButtonColor;
				}					
			}
			if ( highlightColor ) linkColor = highlightColor;
				
			// Theme handling override
			baseColor = (loaderInfo.parameters.baseColor!= null) ? loaderInfo.parameters.baseColor : baseColor;
			bgAlpha = (loaderInfo.parameters.bgalpha != null) ? loaderInfo.parameters.bgalpha : bgAlpha;
			bgAlpha = (loaderInfo.parameters.bgAlpha != null) ? loaderInfo.parameters.bgAlpha : bgAlpha;
			errColor = (loaderInfo.parameters.errorColor != null) ? loaderInfo.parameters.errorColor : errColor;
			fontColor = (loaderInfo.parameters.fontColor != null) ? loaderInfo.parameters.fontColor : fontColor;
			hAlign = (loaderInfo.parameters.halign != null) ? loaderInfo.parameters.halign : hAlign;
			hPadding = (loaderInfo.parameters.hpadding != null) ? loaderInfo.parameters.hpadding : hPadding;		
			imageVAlign = (loaderInfo.parameters.imageVAlign != null) ? loaderInfo.parameters.imageVAlign : imageVAlign;
			linkHasOutline = (loaderInfo.parameters.linkHasOutline != null) ? (loaderInfo.parameters.linkHasOutline == "true" || loaderInfo.parameters.linkHasOutline == 1)  : linkHasOutline;
			linkColor = (loaderInfo.parameters.linkColor != null) ? loaderInfo.parameters.linkColor : linkColor;
			linkOverColor = (loaderInfo.parameters.linkOverColor!= null) ? loaderInfo.parameters.linkOverColor : linkOverColor;
			wrap = (loaderInfo.parameters.wrap != null) ? (loaderInfo.parameters.wrap == "true" || loaderInfo.parameters.wrap == 1) : wrap;
			
			//Playlist config
			playlistItemBgColor1 = (loaderInfo.parameters.playlistItemBgColor1!=null) ? loaderInfo.parameters.playlistItemBgColor1 : playlistItemBgColor1;
			playlistItemBgColor2 = (loaderInfo.parameters.playlistItemBgColor2!=null) ? loaderInfo.parameters.playlistItemBgColor2 : playlistItemBgColor2;
			playlistItemOverColor = (loaderInfo.parameters.playlistItemOverColor!=null) ? loaderInfo.parameters.playlistItemOverColor : playlistItemOverColor;
			playlistItemClickColor = (loaderInfo.parameters.playlistItemClickColor!=null) ? loaderInfo.parameters.playlistItemClickColor : playlistItemClickColor;
			playlistItemSelectColor = (loaderInfo.parameters.playlistItemSelectColor!=null) ? loaderInfo.parameters.playlistItemSelectColor : playlistItemSelectColor;
			playlistItemFontColor = (loaderInfo.parameters.playlistItemFontColor!=null) ? loaderInfo.parameters.playlistItemFontColor : playlistItemFontColor;
			playlistItemFontOverColor = (loaderInfo.parameters.playlistItemFontOverColor!=null) ? loaderInfo.parameters.playlistItemFontOverColor : playlistItemFontOverColor;
			playlistItemFontSelectColor = (loaderInfo.parameters.playlistItemFontSelectColor!=null) ? loaderInfo.parameters.playlistItemFontSelectColor : playlistItemFontSelectColor;
			playlistItemFontClickColor = (loaderInfo.parameters.playlistItemFontClickColor!=null) ? loaderInfo.parameters.playlistItemFontClickColor : playlistItemFontClickColor;
			scrollbarBgColor = (loaderInfo.parameters.scrollbarBgColor!=null) ? loaderInfo.parameters.scrollbarBgColor : scrollbarBgColor;
			scrollbarButtonColor = (loaderInfo.parameters.scrollbarButtonColor!=null) ? loaderInfo.parameters.scrollbarButtonColor : scrollbarButtonColor;
			
//			controlIconColor = (loaderInfo.parameters.controlIconColor != null) ? loaderInfo.parameters.controlIconColor : controlIconColor;
//			controlIconOverColor = (loaderInfo.parameters.controlIconOverColor!=null) ? loaderInfo.parameters.controlIconOverColor : controlIconOverColor;
			
			
			//Fill up the varMap to make the flashVar persistent, when sharing the embed code again.
			varMap["playMedia"] = loaderInfo.parameters.playMedia;
			varMap["autoplay"] = loaderInfo.parameters.autoplay;
			varMap["baseColor"] = loaderInfo.parameters.baseColor;						
//			varMap["bgalpha"] = (loaderInfo.parameters.bgalpha != null) ? loaderInfo.parameters.bgalpha : loaderInfo.parameters.bgAlpha;
			varMap["bgImage"] = loaderInfo.parameters.bgImage;
			varMap["crossfaderate"] = loaderInfo.parameters.crossfaderate;	
			varMap["ctaImage"] = loaderInfo.parameters.ctaImage;
			varMap["customLinkUrl"] = loaderInfo.parameters.customLinkUrl;
			varMap["customLinkLabel"] = loaderInfo.parameters.customLinkLabel;
			varMap["delaystart"] = loaderInfo.parameters.delaystart;						
			varMap["displayInitialScreen"] = loaderInfo.parameters.displayInitialScreen;
			varMap["embedalign"] = loaderInfo.parameters.embedalign;		
			varMap["errorColor"] = loaderInfo.parameters.errorColor;
			varMap["fontColor"] = loaderInfo.parameters.fontColor;
			varMap["halign"] = loaderInfo.parameters.halign;
			varMap["hideinfo"] = loaderInfo.parameters.hideinfo;
			varMap["highlightColor"] = loaderInfo.parameters.highlightColor;			
			varMap["hpadding"] = loaderInfo.parameters.hpadding;		
			varMap["imageVAlign"] = loaderInfo.parameters.imageVAlign;
			varMap["linkColor"] = loaderInfo.parameters.linkColor;		
			varMap["linkOverColor"] = loaderInfo.parameters.linkOverColor;			
			varMap["linkHasOutline"] = loaderInfo.parameters.linkHasOutline;
			varMap["langCode"] = loaderInfo.parameters.langCode;
			varMap["loop"] = loaderInfo.parameters.loop;			
			varMap["maxphotos"] = loaderInfo.parameters.maxphotos;		
			varMap["toggleViews"] = loaderInfo.parameters.toggleViews;
			varMap["smoothing"] = loaderInfo.parameters.smoothing;			
			varMap["submitImage"] = loaderInfo.parameters.submitImage;
			varMap["theme"] = loaderInfo.parameters.theme;
			varMap["twthash"] = loaderInfo.parameters.twthash;
			varMap["wrap"] = loaderInfo.parameters.wrap;
			varMap["playbutton"] = loaderInfo.parameters.playbutton;
			//new
			varMap["viewtype"] = loaderInfo.parameters.viewtype;
			varMap["includeArtistName"] = loaderInfo.parameters.includeArtistName;			
			
			//playlist
			varMap["playlistItemBgColor1"] = loaderInfo.parameters.playlistItemBgColor1;			
			varMap["playlistItemBgColor2"] = loaderInfo.parameters.playlistItemBgColor2;			
			varMap["playlistItemOverColor"] = loaderInfo.parameters.playlistItemOverColor;			
			varMap["playlistItemClickColor"] = loaderInfo.parameters.playlistItemClickColor;			
			varMap["playlistItemSelectColor"] = loaderInfo.parameters.playlistItemSelectColor;			
			varMap["playlistItemFontColor"] = loaderInfo.parameters.playlistItemFontColor;			
			varMap["playlistItemFontOverColor"] = loaderInfo.parameters.playlistItemFontOverColor;			
			varMap["playlistItemFontSelectColor"] = loaderInfo.parameters.playlistItemFontSelectColor;			
			varMap["playlistItemFontClickColor"] = loaderInfo.parameters.playlistItemFontClickColor;			
			varMap["scrollbarBgColor"] = loaderInfo.parameters.scrollbarBgColor;			
			varMap["scrollbarButtonColor"] = loaderInfo.parameters.scrollbarButtonColor;			
			
			//Set the var map on the DataManager
			dm.setVarMap(varMap);			
			
			// Set the styles in the GlobalStyleManager
			styles.setBaseColor(baseColor);
			styles.setBgAlpha(bgAlpha);
			styles.setErrColor(errColor);			
			styles.setFontColor(fontColor);
			styles.setLinkColor(linkColor);
			styles.setLinkOverColor(linkOverColor);
			styles.setHAlign(hAlign);
			styles.setHPadding(hPadding);
			styles.setImageVAlign(imageVAlign);
			styles.setLinkHasOutline(linkHasOutline);
			styles.setWordWrap( wrap );

			// Call the DataManager to parse the information
			dm.setFlashVars(flashVarObj);
		}
		
		/**
		 * Handles callback from DataManager when everything is loaded 
		 * and ready to roll 
		 * @param e
		 * 
		 */		
		private function handleDataLoadSuccess( e : Event) : void {
			trace("E4M: handleDataLoadSuccess");
			// Initialize the font paths within the style manager (unbinding it from the dAtaManAgER)
			if (!view) {
				if (viewtype == "player" && dm.hasPlaylistData()) {
					view = new E4MPlayerView(_width, _height, this);				
				}else{
					view = new EmailMediaWidgetView(_width, _height, this);
				}
				view.addEventListener(Event.COMPLETE, handleViewComplete);
				view.init();
			}			
			if (progress && this.contains(progress)) {
				addChildAt(view, getChildIndex(progress));
			} else {
				addChild(view);
			}
		}
		/**
		 * Handles DataManager load error 
		 * @param e
		 * 
		 */		
		private function handleDataLoadError(e:TSWidgetEvent):void {
			displayErrorView(e.message);
		}
		/**
		 * Handler for the view once it has been drawn and waiting
		 * user input. 
		 * @param e
		 * 
		 */		
		private function handleViewComplete(e:Event):void {
			view.removeEventListener(Event.COMPLETE, handleViewComplete);
// 			App has been loaded fire LOADED event
//			var gat : String = dm.getGATrackinId();
//			if (gat) EventLogger.setGATrackingId(gat);
//            EventLogger.fire(TSEvents.TYPE.LOADED,{campaign:dm.getCampaignId(), referring_url : dm.getReferringURL()});
			showLoader(false);
			//Fade the widget in
			TweenLite.to(this, FADE_RATE, {autoAlpha:1});
		}
		/**
		 * Sets the size of the widget. 
		 * @param w
		 * @param h
		 * 
		 */		
		public function setSize(w:Number, h:Number):void {
			this._width = w;
			this._height = h;	
		}

		/**
		 * Displays the Error dialog 
		 * @param inputText string message
		 * 
		 */
		public function displayErrorView(inputText:String = "This content has been removed by the artist."):void {
			showLoader(false);
			var errClip:Sprite = new Sprite();
				errClip.graphics.clear();
				errClip.graphics.beginFill(0x000000, 1);
				errClip.graphics.drawRect(0, 0, _width, _height);
				errClip.graphics.endFill();

			var errFormat:TextFormat = new TextFormat(styles.getFormattedFontName(),10,0xcc0000, true);
//			trace("getFormattedFontName: " + styles.getFormattedFontName());
				
//			var errcss : StyleSheet = new StyleSheet();
				
			var errorText:TextField = new TextField();
				errorText.text = inputText;
				errorText.width = _width;
				errorText.height = 17;
				errorText.setTextFormat(errFormat);
				errorText.autoSize = "left";
				errorText.embedFonts = styles.getEmbedFonts();
				errorText.antiAliasType = "advanced";
				errorText.y = (_height - errorText.height) / 2 ;
				errorText.x = (_width - errorText.width) / 2 ;
				errClip.addChild(errorText);

			addChildAt(errClip, numChildren);
			
			TweenLite.to(this, FADE_RATE, {autoAlpha:1});
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
			dm.setExternalInterfacesAvailable(isEIAvailable);
		}		
	
		/**
		 * Draws the throbber progress bar and centers it 
		 * in the application 
		 * 
		 */		
		public function setProgressPosition() : void
		{
	
			var w : Number = _width; //stage.stageWidth;
			var h : Number = _height; //stage.stageHeight;
			
			if (stage.displayState == StageDisplayState.FULL_SCREEN) {
				w = stage.fullScreenWidth;
				h = stage.fullScreenHeight;
			}else{
				
			}
			progress.x = (w - progress.width) / 2;
			if (h > 150)
			{
				progress.y = Math.floor( (h - 28 - progress.height) / 2 ); //hard code 28 the footer (which is 23), to line up with play btn
			}else{
				progress.y = Math.floor( (h - progress.height) / 2 );
			}
		}		
		/**
		 * Public method to show the throbber or not 
		 * @param bool
		 * 
		 */		
		public function showLoader(bool:Boolean):void {
			if (bool) {
				addChildAt(progress, numChildren);
				progress.alpha = .8;
			} else {
				if (progress && this.contains(progress)) {
					removeChild(progress);
				}
			}
		}				
		
	}
}