package com.topspin.email.data {
	import com.adobe.utils.StringUtil;
	import com.topspin.api.TSWidgetAPI;
	import com.topspin.api.data.ITSPlaylist;
	import com.topspin.api.data.ITSWidget;
	import com.topspin.api.data.media.ImageData;
	import com.topspin.api.data.media.Playlist;
	import com.topspin.api.events.E4MEvent;
	import com.topspin.api.events.MediaEvent;
	import com.topspin.api.events.TSWidgetEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSApplications;
	import com.topspin.api.logging.TSEvents;
	import com.topspin.common.utils.SocialUtils;
	import com.topspin.common.utils.StringUtils;
	import com.topspin.email.validation.COPPAComplianceValidation;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	
	/**
	 * com.topspin.email.data.DataManager 
	 * DataManager for the E4M widget
	 * 
	 * @author amehta@topspinmedia.com
	 * 
	 */
	public class DataManager extends EventDispatcher {
		
		// Singleton class variables
		protected static var instance:DataManager;
		protected static var allowInstantiation:Boolean;
		
		//Flash Widget API
		public var _tsWidget : ITSWidget;
		public var tsWidgetAPIUrl : String = "/widgets/api/TSWidgetAPI.swf"
		
		//Data
//		private var _widgetDataXML:XML;  			// XML returned by the widgetID

		//Properties
		private var _widgetID:String;
		private var _height:Number;
		private var _width:Number;
		private var _app : TSEmailMediaWidget;
		private var _widgetStatus:Number;
		private var _externalInterfacesAvailable:Boolean;
		private var _inited : Boolean = false;
		private var _dob : Date;
		
		//COPPA regulation state
		private var _coppaState : String;
		private var _flushCookie : Boolean;

		public static const TS_SHARED_OBJECT : String = "ts_widget_so";		

		//Validators
		private var _coppaCompliance : COPPAComplianceValidation;
		private var _coppaCompliant : Boolean = true;		
		
		// Default messaging 
		private var _successMessage:String = "Check Your Inbox to Download";
		private var _successEmailMessage:String = "Thanks!"
		private var _emailErrorMessage:String = "Please enter a valid email address.";
		private var _submitMessage:String = "Submitting email..."
		private var _submitFailMessage:String = "Unsuccessful submission! Please try again";		
		
		//GET RID OF THESE USE API // UI
		private var _headlineMsg:String;  			// Primary headline text
		private var _offerBtnLabel:String;  		// Text displayed on the offer button
		private var _sharing:Boolean;  				// Whether the sharing functionality on/off

		// Data
		private var _artistId:String;
		private var _campaignId:String;	
		private var _confirmationTarget:String;
		private var _referringURL:String;
		private var _clickTag:String;
		private var _offerURL:String;
		private var _flickrID:String;  				// Flickr ID (username)
		private var _flickrTags:String;  			// Flickr tags
		private var _isPreview : Boolean = false;
		private var _hideinfo : Boolean;
		private var _embedCode : String;			//Embed code
		private var _varMap : Object; 				//persistent varMap
		private var _viewtype : String = "email";	//player
		private var _playlist : ITSPlaylist;
		
		// FlashVars
		private var _langCode:String;  // Language the primary font is rendered in
		private var _bgImageLocation:String;  // URL for the image used as the widget background
		private var _submitImageLocation:String;  // URL for image used for the submit button
		private var _ctaImageLocation:String;  // URL for image used CTA Image
		private var _linkHasOutline:Boolean;  // Outline around the primary link button
		private var _hAlign:String;  // Horizontal alignment of 
		private var _hPadding:Number;
		private var _embedAlign:String;
		private var _imageVAlign : String;
		private var _maxPhotos:Number;
		private var _baseURL:String;
		private var _displayInitialScreen:Boolean;  // The presence of a call to action
		private var _toggleViews:Boolean;
		private var _playMedia:Boolean;
		
		private var _autoplay:Boolean;
		private var _delaystart : Number = 0;
		
		private var _embedwidth : Number;
		private var _embedheight : Number;
		
		private var _awesm : String;
		private var _pid : String;
		private var _theme : String = "black";
		private var _loop : Boolean = false;
		private var _smoothing : Boolean = false;
		private var _crossfaderate : Number = 10;
		
		//If it exist, then show a privacy policy url link
		private var _customLinkUrl : String = "null";
		private var _customLinkLabel : String;
		
		//Generated once, for the 
		private var _awesmOfferUrl : String;
		private var _awesm_api_key : String;
		private var _twthash : String;
		
		//Player vars
		private var _includeArtistName : Boolean;
		private var _playbutton : Boolean;
		
		public static const VALIGN_TOP : String = "top";
		public static const VALIGN_CENTER : String = "center";
		public static const VALIGN_BOTTOM : String = "bottom";
				
		private var _env : String;  //is this production or pp or qa?
		
		// Static
		public static var STATUS_UNPUBLISHED:Number = 1;
		public static var STATUS_PUBLISHED:Number = 2;
		public static var STATUS_DELETED:Number = 3;
		public static var FONT_SWF_PATH:String = "/flash/fonts/";
		
		// Events
		public static var DATA_LOAD_ERROR:String = "dataLoadError";
		public static var DATA_LOAD_SUCCESS:String = "dataLoadSuccess";
		public static var SLIDESHOW_INIT:String = "slideshowInit";
		public static var IMAGE_DATA_UPDATE:String = "imageDataUpdate";

		// Images
		private var imageData:Array;

		public function DataManager() : void {
			if(!allowInstantiation) {
				throw new Error("Error : DataManager is a singleton - Use DataManager.getInstance() instead of new." );
			}
		}
		
		/**
		 * Provides access to the class attributes and operations.
		 * @return	DataManager	- singleton instance of DataManager 
		 */ 
		public static function getInstance():DataManager {
			if(instance == null) {
				allowInstantiation = true;
				instance = new DataManager();
				allowInstantiation = false;
			}
			return instance;
		}
		/**
		 * Set reference to the Application root 
		 * @param app
		 * 
		 */		
		public function setAppRoot( app : TSEmailMediaWidget) : void
		{
			_app = app;
		}
		/**
		 * Setup the internal flashvar so view can access it 
		 * @param obj
		 * 
		 */		
		public function setFlashVars(obj:Object):void {

			_widgetID = obj.widgetID;
			_height = obj.height;
			_width = obj.width;
			_embedwidth = obj.embedwidth;				
			_embedheight = obj.embedheight;
			
			_langCode =  obj.langCode;
			_bgImageLocation = obj.bgImageLocation;
			_submitImageLocation = obj.submitImageLocation;
			_ctaImageLocation = obj.ctaImageLocation;
			_imageVAlign = obj.imageVAlign;
			_linkHasOutline = obj.linkHasOutline;
			_hAlign = obj.hAlign;
			_hPadding = obj.hPadding;
			_embedAlign = obj.embedAlign;
			_maxPhotos = obj.maxPhotos;
			_baseURL = obj.baseURL;
			_displayInitialScreen = obj.displayInitialScreen;
			_clickTag = obj.clickTag;
			_toggleViews = obj.toggleViews;
			_playMedia = obj.playMedia;
			_autoplay = obj.autoplay;
			_delaystart = obj.delaystart;
			_hideinfo = obj.hideinfo;
			_viewtype = obj.viewtype;
			
			_awesm = obj.awesm;
			_pid = obj.pid;
			_twthash = obj.twthash;
			_theme = obj.theme;
			_customLinkUrl = obj.customLinkUrl;
			_customLinkLabel = obj.customLinkLabel;

			_loop  = obj.loop;
			_smoothing = obj.smoothing;
			_crossfaderate = obj.crossfaderate;
			
			//player vars
			_includeArtistName = obj.includeArtistName;
			_playbutton = obj.playbutton;
			_flushCookie = obj.flush;
			
			//Default to the TOPSPIN_API_KEY, if an artist has one that exists
//			_awesm_api_key = AwesmService.TOPSPIN_API_KEY;
			
			_coppaState = COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_COLLECT;
			
			//Since this is a Topspin product, we are going to directing invoke the TSWidgetAPI 
			//from the source tree.  When building custom widgets, you should follow the loadAPI()
			//route since the underlying data model may change and the ITSWidget interface will
			//always remain the same.  
			var useAPISwf : Boolean = false;
			if (useAPISwf) {
				//Load the external TSWidgetAPI swf adapter from Topspin cdn
				//Use this method when creating custom widgets so underlying
				//model changes do not break your widgets.
				loadAPI();
			}else{
				//Bypass the loading of the swf and invoke the TSWidgetAPI				
				_tsWidget = new TSWidgetAPI();
				configureAPIListeners();
				registerWidgetId(_widgetID);
			}	
		}

		/**
		 * ITSWidget implmentation.  Load up the ITSWidget
		 * from the Tospin cdn. 
		 * 
		 */		
		private function loadAPI() : void
		{	
			var apiURL : String = _baseURL + tsWidgetAPIUrl;
			trace("loadAPI: " + apiURL);
			var request : URLRequest = new URLRequest(apiURL);
			var loaderContext : LoaderContext = new LoaderContext();
			loaderContext.securityDomain = SecurityDomain.currentDomain;		
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.INIT, handleWidgetAPILoader);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, widgetIOErrorHandler);
			loader.load(request, loaderContext);				
		}
		/**
		 * Handler for success load of TSWidget api swf.
		 * Configure the API Listeners
		 * Register the widget ID 
		 * @param e
		 * 
		 */		
		private function handleWidgetAPILoader( e : Event) : void
		{
			e.target.loader.contentLoaderInfo.removeEventListener(Event.INIT,handleWidgetAPILoader);
			e.target.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, widgetIOErrorHandler);			
			//TSWidget.swf loaded, now cast it to an ITSWidget interface 
			_tsWidget = ITSWidget(e.currentTarget.content);
			trace("ITSWidget Loaded Version : " + _tsWidget.getVersion() + " -- Waiting for widget id");
			//Configure _tsWidget event listeners
			configureAPIListeners();
			trace("Register WidgetId: " + _widgetID);
			//Register the widget id
			registerWidgetId(_widgetID);
		}
		/**
		 * Register the widget id with the ITSWidgetAPI adapter. 
		 * @param wid
		 * 
		 */		
		private function registerWidgetId(wid : String) : void
		{
			_tsWidget.registerWidgetId(wid, EventLogger.getInstance().enabled, TSApplications.E4M);			
		}
		/**
		 * Error handler on the load of the widget api  
		 * @param e
		 * 
		 */		
		private function widgetIOErrorHandler( e : IOErrorEvent ) : void
		{
			e.target.loader.contentLoaderInfo.removeEventListener(Event.INIT,handleWidgetAPILoader);
			e.target.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, widgetIOErrorHandler);			
			trace("widgetIOErrorHandler: " + e);
			dispatchEvent(new Event(DataManager.DATA_LOAD_ERROR, true));
		}		
		
		private function configureAPIListeners() : void
		{
			//create the instance of the TSEmailAdapter and add listeners
			//Add listeners
			_tsWidget.addEventListener(TSWidgetEvent.WIDGET_LOAD_COMPLETE, handleWidgetEvent);
			_tsWidget.addEventListener(TSWidgetEvent.WIDGET_LOAD_ERROR, handleWidgetEvent);
			_tsWidget.addEventListener(TSWidgetEvent.WIDGET_ERROR, handleWidgetEvent);
			
			//Playlist load
			_tsWidget.addEventListener(TSWidgetEvent.PLAYLIST_READY, handleWidgetEvent);
		}
		
		public function addE4MHandler( listenerFunc : Function) : void
		{
			//E4M 
			_tsWidget.addEventListener(E4MEvent.EMAIL_SUCCESS, listenerFunc);
			_tsWidget.addEventListener(E4MEvent.EMAIL_ERROR, listenerFunc);
			_tsWidget.addEventListener(E4MEvent.UNDERAGE_ERROR, listenerFunc);
//			_tsWidget.addEventListener(E4MEvent.UNDERAGE_ERROR, handleE4MEvent);
		}
		
		public function get tsWidget() : ITSWidget
		{
			return _tsWidget;
		}
		
		private function init() : void
		{
			_campaignId = _tsWidget.getCampaignId();
			//Set up coppa compliance

			//Only if it is sony, check that COPPA compliance bit
			if ( isSonyCheckReqired() || requireDOB() )
			{
				checkCOOPACompliance();
			}else{
				dispatchEvent(new Event(DataManager.DATA_LOAD_SUCCESS, true));			
			}			
			
			if( this._height > 100) {
				trace("PARSE THE IMAGES");
				parseImages();
			}			
			
			//Use for QA internal testbed 
			//for facebook sharing.
			var wid : String = getFullWidgetId();
			if (wid.indexOf("qa1") != -1)
			{
				_env = SocialUtils.ENV_QA1;
			} 			
			if (wid.indexOf("qa2") != -1)
			{
				_env = SocialUtils.ENV_QA2;
			} 
			if (wid.indexOf("qa3") != -1) {
				_env = SocialUtils.ENV_QA3;
			} 			
			if (wid.indexOf("qa.cdn") != -1) {
				_env = SocialUtils.ENV_QA;
			}
			if (wid.indexOf("preprod") != -1 || wid.indexOf("pp.cdn") != -1) {
				_env = SocialUtils.ENV_PP;
			}				
			
			_inited = true;
		}
		
//		private function handleConfigLoaded(e:Event):void {
//			trace("DataManager.handleConfigLoaded");
//			//Set up coppa compliance
//			_coppaCompliance = new COPPAComplianceValidation();
//			
//			// Assign and cleanup
//			_widgetDataXML = new XML(e.target.data);
//			e.target.removeEventListener(Event.COMPLETE,handleConfigLoaded);
//			e.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);	
//			
//			// Check the widget status
//			if (_widgetDataXML.campaign) {
//				setWidgetStatus(Number(_widgetDataXML.campaign.status)); 
//			} else {
//				setWidgetStatus(STATUS_UNPUBLISHED);
//			}
//			
//			// Widget UI
//			_headlineMsg = _widgetDataXML.message;
//			_offerBtnLabel = _widgetDataXML.offer_button_label;
//			_sharing = (_widgetDataXML.sharing.length()) ? (_widgetDataXML.sharing=="true") : _sharing;
//			
//			// Widget Data
//			_artistId = _widgetDataXML.campaign.artist.id;
//			_campaignId = _widgetDataXML.campaign.id;		
//			_confirmationTarget = _widgetDataXML.confirmation_target;
//			
//			//_offerURL = _widgetDataXML.offer_url;
//			
//			EventLogger.setCampaign(_campaignId);
//			
//			var refURL : String = EventLogger.getPageURL();
//			if (refURL != null)
//			{
//				_referringURL = refURL;
//			}else{
//				_referringURL = _widgetDataXML.parent_page_url;
//				EventLogger.setPageURL(_referringURL);
//			}
//			
//			// Flickr Information
//			if (_widgetDataXML.flickr.length()) {
//				_flickrID = _widgetDataXML.flickr.flickr_id;			
//				_flickrTags = _widgetDataXML.flickr.flickr_tags;			
//			}	
//
//			var wid : String = getFullWidgetId();
//			if (wid.indexOf("qa1") != -1)
//			{
//				_env = SocialUtils.ENV_QA1;
//			} 			
//			if (wid.indexOf("qa2") != -1)
//			{
//				_env = SocialUtils.ENV_QA2;
//			} 
//			if (wid.indexOf("qa3") != -1) {
//				_env = SocialUtils.ENV_QA3;
//			} 			
//			if (wid.indexOf("qa.cdn") != -1) {
//				_env = SocialUtils.ENV_QA;
//			}
//			if (wid.indexOf("preprod") != -1 || wid.indexOf("pp.cdn") != -1) {
//				_env = SocialUtils.ENV_PP;
//			}				
//			
//			//Only if it is sony, check that COPPA compliance bit
//			if ( isSonyCheckReqired() ) {
//				checkCOPPACompliance();
//			} else {
//				dispatchEvent(new Event(DataManager.DATA_LOAD_SUCCESS, true));			
//			}
//			
//			if( this._height > 100) {
//				trace("PARSE THE IMAGES");
//				parseImages();
//			}
//			
//		}		
		
		
		////////////////////////////////////////////////////
		//
		// Event Handlers
		//
		////////////////////////////////////////////////////
		/**
		 * Main widget manager event 
		 * @param e
		 * 
		 */		
		private function handleWidgetEvent( e : TSWidgetEvent ) : void
		{
			switch (e.type) {
				case TSWidgetEvent.WIDGET_LOAD_COMPLETE:
					trace("TSWidgetEvent.WIDGET_LOAD_COMPLETE");
					//Widget registered, pull the camapaign_id 
					//so that you can use multiple campaigns with
					//single ITSWidget instance
					
					
					
					init();
					break;
				
				case TSWidgetEvent.WIDGET_LOAD_ERROR:
					trace("TSWidgetEvent.WIDGET_LOAD_ERROR: Widget swf failed to load.");
					dispatchEvent(new Event(DataManager.DATA_LOAD_ERROR, true));
					break;
				
				case TSWidgetEvent.PLAYLIST_READY:
					_playlist = _tsWidget.getPlaylist(_tsWidget.getCampaignId());
								

					trace("TSWidgetEvent.PLAYLIST_READY: Number Tracks: " + _playlist.getTotalTracks());

					//					playlist = _tsWidget.getPlaylist(_tsWidget.getCampaignId());
//					//MUST ADD THIS MEDIAEVENT LISTENER TO LISTEN TO MEDIA EVENTS
//					playlist.addMediaEventListener( onMediaEventHandler );
//					setupPlayer();
					dispatchEvent(new TSWidgetEvent(TSWidgetEvent.PLAYLIST_READY));
					break;
			}
		}		
		
				
		
		
		public function getPlaylist() : ITSPlaylist
		{
			return _playlist;
		}
		
		public function hasPlaylistData() : Boolean
		{
			var tsData : XML = _tsWidget.widgetData();
			return (tsData.media && tsData.media.length());
		}
		
//		/**
//		 * Loads the widget data 
//		 * 
//		 */		
//		public function loadConfig():void {
//			var loader:URLLoader = new URLLoader();
//				loader.dataFormat = URLLoaderDataFormat.TEXT;
//				loader.addEventListener(Event.COMPLETE, handleConfigLoaded);
//				loader.addEventListener(ProgressEvent.PROGRESS, traceProgress);
//				loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
//			try {
//				trace("Try to load config:" );
//				loader.load(new URLRequest(_widgetID));
//				
//			} catch (err:SecurityError) {
//				trace("Email Widget Data:: Security error occurred:" + err);
//				dispatchEvent(new Event(DataManager.DATA_LOAD_ERROR, true));
//			}
//		}
		
//		private function traceProgress(e:ProgressEvent):void {
//			trace("Progress is being made!! - " + e);
//		}

		public function getCoppaState() : String
		{
			return _coppaState;
		}
		
		public function collectDOB() : Boolean
		{
			return (requireDOB() && getCoppaState() == COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_COLLECT);
		}
		
		public function updateSavedAge( dob : Date ) : void
		{
			
			trace("DM  Check Required updateSavedAge: " + dob );		
			_coppaCompliance.updateSavedDOB(dob, getMinAge(), isSonyCheckReqired());
		}
		
		public function checkCOOPACompliance() : void
		{
			
			//Set up coppa compliance
			if (!_coppaCompliance)
			{
				_coppaCompliance = new COPPAComplianceValidation();			
			}
			
			trace("--checkCOOPACompliance--");
			if (getMinAge() != -1)
			{
				trace("E4M DM checkCOOPACompliance: " + getMinAge());
				_coppaCompliance.addEventListener(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_PASSED, handleCOPPA);
				_coppaCompliance.addEventListener(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_COLLECT, handleCOPPA);
				_coppaCompliance.addEventListener(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_FAILED, handleCOPPA);
				_coppaCompliance.validateDOB_SO(getMinAge(), isSonyCheckReqired(), _flushCookie)
			}else{
				dispatchEvent(new Event(DataManager.DATA_LOAD_SUCCESS, true));					
			}
			
			function handleCOPPA( e : Event) : void
			{
				trace("DM COPPA: " + e.type);
				_coppaCompliance.removeEventListener(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_PASSED, handleCOPPA);
				_coppaCompliance.removeEventListener(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_COLLECT, handleCOPPA);
				_coppaCompliance.removeEventListener(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_FAILED, handleCOPPA);
				
				_coppaState = e.type;
				trace("_coppaState: " + _coppaState);
				
				dispatchEvent(new Event(DataManager.DATA_LOAD_SUCCESS, true));				
			}
			

		}
		
		/**
		 * Shows the progress loader 
		 * @param show
		 * 
		 */		
		public function showLoader( show : Boolean) : void
		{
			_app.showLoader(show);
		}
		/**
		 * Error handler 
		 * @param e
		 * 
		 */		
		private function errorHandler(e:Event):void {
			trace("DataManager.errorHandler e: " + e.toString());
		}
		/**
		 * Retrieve the images and also from Flickr using the engine.
		 * 
		 */		
		public function parseImages():void {
			var myImageParser:ImageDataParser = new ImageDataParser(tsWidget,_campaignId, _baseURL);			
			myImageParser.addEventListener(Event.COMPLETE, handleImages);
			myImageParser.addEventListener(ImageDataParser.FLICKR_PHOTO_COMPLETE, handleImages);
			myImageParser.addEventListener(ImageDataParser.FLICKR_FEED_COMPLETE, handleFeedComplete);
			
			myImageParser.parseImages();
			
			function handleImages(e:Event):void {
				var imgArray : Array = myImageParser.getImageData();
				if (imgArray.length > 0) {
					setImageData(imgArray);
				}
				if(e.type == Event.COMPLETE) {
					myImageParser.removeEventListener(Event.COMPLETE, handleImages);
				}
//				} else {
//					dispatchEvent(new Event(DataManager.SLIDESHOW_INIT, true));
//				}
			}			
			function handleFeedComplete( e:Event):void {
				myImageParser.removeEventListener(ImageDataParser.FLICKR_PHOTO_COMPLETE, handleImages);
				myImageParser.removeEventListener(ImageDataParser.FLICKR_FEED_COMPLETE, handleFeedComplete);
			}			
	
		}	
		/**
		 * Returns a clickTag if one is passed via a DoubleClick network,
		 * if not, use the OfferUrl. 
		 * @return 
		 * 
		 */				
		public function getClickTag():String {
			var returnValue:String = (this._clickTag != null) ? this._clickTag : getOfferURL();
			return returnValue;
		}

		public function getOfferURL():String {
			return tsWidget.getOfferURL(_campaignId);			
		}

		public function getFullWidgetId() : String
		{
			return tsWidget.getWidgetId( _campaignId );						
		}
		/**
		 * Returns the campaign id. 
		 * @return 
		 * 
		 */	
		public function getCampaignId():String {
			return this._campaignId;
		}
		/**
		 * Returns the artist id 
		 * @return 
		 * 
		 */		
		public function getArtistId():String {
			return _tsWidget.getArtistId(_campaignId);
		}
		/**
		 * Internal  
		 * @param overrideExternalInterfacesAvailable
		 * 
		 */		
		public function setExternalInterfacesAvailable(overrideExternalInterfacesAvailable:Boolean):void {
			_externalInterfacesAvailable = overrideExternalInterfacesAvailable
		}
		/**
		 * Returns EI available 
		 * @return 
		 * 
		 */		
		public function getExternalInterfacesAvailable():Boolean {
			return _externalInterfacesAvailable;
		}
		/**
		 * Returns GA tracking id. 
		 * @return 
		 * 
		 */
		public function getGATrackinId() : String
		{
			return tsWidget.getArtistGATrackingId(_campaignId);			
		}	
		 /**
		  * Sets the persistent flash vars that will be
		  * carried over when embed code is copied
		  * @param map
		  * 
		  */		
		 public function setVarMap( map : Object ) : void
		 {
		 	_varMap = map;	
		 }
		 /**
		  * Gets the varMap 
		  * @return 
		  * 
		  */		 
		 public function getVarMap() : Object
		 {
		 	return _varMap;	
		 }

		/**
		 * Puts all the flashvar customizations in a key value pair based on the delimiters. 
		 * @param delimiter1
		 * @param delimiter2
		 * @return 
		 * 
		 */		
		public function getFlashVarQueryString( delimiter1 : String = "&amp;", delimiter2 : String = "=") : String
		{
			var flashVars : String = "";
			for (var p : String in _varMap)
			{
				if (_varMap[p] != null && _varMap[p] != undefined)
				{
					if (flashVars.length > 0 )
					{
						flashVars += delimiter1 + p  + delimiter2 + _varMap[p];					
					}else{
						flashVars += p  + delimiter2 + _varMap[p];
					}	
				}	
			}
			trace("flashVars: " + flashVars);
			return flashVars;
		}
		/**
		 * Builds the embed code found in the widget id xml
		 * then adds persistent flashvars
		 * @return embed code
		 * 
		 */		
		public function getEmbedCode() : String 
		{
			if (!_embedCode){
				var regEx : RegExp = new RegExp(/widget_id=/);
				_embedCode = tsWidget.getEmbedCode(_campaignId);		
				
				var scriptCode : String = "";
				//keep the size persistent.
				if (_embedCode.indexOf("<script") != -1)
				{	
						_embedCode = StringUtil.trim(_embedCode);
						scriptCode = _embedCode.substring(0,_embedCode.indexOf("<div")) + "\n";
						_embedCode = _embedCode.substring(_embedCode.indexOf("<div"));						
				}
				trace("NEW EMBED: " + _embedCode);
				var embedXML : XML = new XML(_embedCode);
				if (embedXML.object.length())
				{
					embedXML.object.@width = _embedwidth;					
					embedXML.object.@height = _embedheight;					
					_embedCode = embedXML.toXMLString();						
				}

				var flashVars : String = getFlashVarQueryString("&");
				if (flashVars.length > 0)
				{
					embedXML = new XML(_embedCode);
					
					flashVars += "&widget_id=" + getWidgetId();
					embedXML.object.param.(@name == "flashvars").@value = encodeURI(flashVars);
					_embedCode = embedXML.toXMLString();	
				}
				
				if (_awesm != null && _embedCode.indexOf("awesm=") == -1)
				{
					_embedCode = _embedCode.replace(regEx, "awesm=" + _awesm + "&amp;widget_id=");	
				}					
				
				_embedCode = scriptCode + _embedCode;
					
			}	
			return _embedCode;				
		}

				
		/**
		 * Sets the DOB 
		 * @param dob
		 * 
		 */		
		public function setDOB( dob : Date) : void
		{
			_dob = dob;	
		}
		/**
		 * Gets the DOB 
		 * @return 
		 * 
		 */		
		public function getDOB() : Date
		{
			return _dob;
		}
		/**
		 * Requires DOB 
		 * @return 
		 * 
		 */		
		public function requireDOB() : Boolean
		{
			return _tsWidget.isE4MDOBRequired(_campaignId);			
		}
		/**
		 * Gets the min age requirement 
		 * @return Number
		 * 
		 */		
		public function getMinAge() : Number
		{
			var minAge : Number = -1;
			minAge = tsWidget.getE4MMinimumAgeRequirement(_campaignId);
			return minAge;		
		}
		/**
		 * Gets the underage message
		 * @return 
		 * 
		 */		
		public function getUnderageMessage() : String
		{
			var msg : String = "Thank you for your interest in registering. As we are committed to protecting your privacy, we are unable to accept your registration. However, we invite you to continue browsing the site without registering.";
			msg = tsWidget.getE4MUnderageMessage(_campaignId);
			return msg;				
		}
		/**
		 * Checks the Sony COPPA check 
		 * @return 
		 * 
		 */		
		public function isSonyCheckReqired() : Boolean
		{
			var bool : Boolean = false;
			var label : String = tsWidget.getArtistLabel(_campaignId);
			trace("isSonyCheckRequired label: " + label);
			if (label != null && label != "")
			{
				bool = ("sony" == label.toLowerCase());
			} 
			trace("isSonyCheckReqired: " + bool);
			return bool;
		}
		/**
		 * Returns the image data 
		 * @return 
		 * 
		 */		 		
		public function getImageData():Array {
			return imageData;
		}
		/**
		 * Sets the model image data. 
		 * @param imageDataArray
		 * 
		 */
		public function setImageData( imageDataArray:Array ):void {
			imageData = imageDataArray;
			dispatchEvent(new Event(DataManager.IMAGE_DATA_UPDATE, true));
			// updateSlideshow();
		}
		
		// Getters / Setters

		private function setWidgetStatus(status:Number):void {
			_widgetStatus = status;
			if (status != STATUS_PUBLISHED) {
		 		EventLogger.getInstance().enabled = false;  // Disable the event logger so that no events get fired
			}
		}
		
		public function set isPreview( bool : Boolean) : void
		{
			_isPreview = bool;
		}
		public function get isPreview() : Boolean
		{
			return _isPreview;
		}
		
		/**
		 * Returns the artist name 
		 * @return string
		 * 
		 */ 		
		public function getArtistName() : String
		{
			return _tsWidget.getArtistName(_campaignId);
		}		
		
		public function getBaseURL():String {
			return this._baseURL;
		}

		public function getSubmitImageLocation():String {
			return this._submitImageLocation;
		}

		public function getCTAImageLocation():String {
			return this._ctaImageLocation;
		}

		public function getImageVAlign():String {
			return this._imageVAlign;
		}

		
		public function getBGImageLocation():String { 
			return this._bgImageLocation;
		}
		
		
		public function getWidgetStatus():Number {
			return this._widgetStatus;
		}		

		public function getHeadlineMessage():String {
			return _tsWidget.getHeadlineMessage(_campaignId);
		}
		
		public function getOfferButtonLabel():String {
			return _tsWidget.getOfferButtonLabel(_campaignId);
		}
				
		public function getSharing():Boolean {
			return _tsWidget.isSharingEnabled(_campaignId); 
		}
		
		public function getDOBMessage() : String {
			return tsWidget.getE4MDOBMessage( _campaignId );
		}
		public function getInfoHeadline() : String
		{
			return _tsWidget.getE4MOptInHeadline(_campaignId);
		}
		public function getInfoContent() : String
		{
			return _tsWidget.getE4MOptInMessage(_campaignId);
		}
		
		//Flashvars
		public function getEmbedAlign():String {
			return this._embedAlign;
		}
		
		public function getDisplayInitialScreen():Boolean {
			return _displayInitialScreen;
		}
		
		
		public function getPrivacyUrl() : String
		{
			var url : String = tsWidget.getPrivacyUrl(_campaignId);
			if (url == "")
			{
				url = getBaseURL() + "/account/privacypolicy_public";
			}
			trace("getPrivacyURL : " + url);
			return url;				
		}		
		
		public function getCustomLinkUrl() : String
		{
			return _customLinkUrl || tsWidget.getCustomLinkUrl();
		}
		public function getCustomLinkLabel() : String
		{
			return _customLinkLabel || tsWidget.getCustomLinkLabel()
		}
		public function get hideinfo() : Boolean
		{
			return _hideinfo;
		}
		
		/**
		 * TSWidget API submitE4M. 
		 * @param email
		 * @param dob (optional)
		 * 
		 */		
		public function submitE4M( email : String, dob : Date = null ) : void {
			trace("DOB : " + dob);
			tsWidget.submitE4MEmail(_campaignId, email,tsWidget.getE4MConfirmationTarget(_campaignId), dob );
		}
		
		public function getSuccessMessage():String { 
			var data : String = _successMessage;
			if (_tsWidget.isE4MEmailOnly()) {
				data  = "Check Your Inbox for Confirmation";
			}			
			return this._successMessage;
		}
		
		public function getSuccessEmailMessage():String { 
			return this._successEmailMessage;
		}
		
		public function getEmailErrorMessage():String { 
			return this._emailErrorMessage;
		}
		
		public function getSubmitMessage():String { 
			return this._submitMessage;
		}

		public function getSubmitFailMessage():String {
			return this._submitFailMessage;
		}

		public function getConfirmationTarget():String {
			return _tsWidget.getE4MConfirmationTarget(_campaignId);
		}

//		public function doesMediaExist():Boolean {
//			if(this._widgetDataXML && (_widgetDataXML.media.length() > 0)) {
//				return true;
//			} else {
//				return false;
//			}
//		}
		
		public function getToggleViews():Boolean {
			return this._toggleViews;
		}
		
		public function getPlayMedia():Boolean {
			return this._playMedia;
		}
		
		public function isAutoPlay() : Boolean {
			return this._autoplay;
		}
		
		public function getDelayStart() : Number {
			return _delaystart;
		}
				
//		public function getWidgetXML():XML {
//			return this._widgetDataXML;
//		}

		public function getWidgetId():String {
			return this._widgetID;
		}
		
		public function getWidgetXML() : XML {
			return tsWidget.widgetData( _campaignId );
		}
		public function isLoop() : Boolean
		{
			return _loop;
		}
		public function get crossfaderate() : Number
		{
			return _crossfaderate;
		}
		public function get smoothing() : Boolean
		{
			return _smoothing;
		}
				
		public function getAwesmParentId() : String
		{
			return _awesm;
		}
		public function get viewtype() : String
		{
			return _viewtype;
		}
		public function get includeArtistName() : Boolean
		{
			return _includeArtistName;
		}
		public function showPlayButton() : Boolean
		{
			return _playbutton;
		}
		/**
		 * Topspin awesm api key, eventually artists
		 * will get their own awesm key to use in the widgets 
		 * @return 
		 * 
		 */		
		public function getAwesmAPIKey() : String
		{
			return tsWidget.getAwesmAPIKey(_campaignId);
		}
		/**
		 * Get the page where this widget resides 
		 * @return String
		 * 
		 */		
		public function getActualPageURL() : String {
		    var url : String;
		    if (getExternalInterfacesAvailable()) {
				url = ExternalInterface.call("window.location.href.toString");				
			}
			return url;
		}
				
		/**
		 * Returns the URL, where sharing will target. 
		 * For E4M, whatever page the widget is shared from
		 * is shared.
		 * @return 
		 * 
		 */		
		public function getProperShareUrl() : String
		{
			var shareUrl : String = getOfferURL();
			if (!shareUrl || shareUrl == "null") {
				shareUrl = getActualPageURL();
			}	
			trace("getProperShareUrl() shareUrl: " + shareUrl);
			if (!shareUrl)
			{
				trace("shareUrl is null so creating gidget url to share");
				shareUrl = SocialUtils.parseGidgetId(getFullWidgetId(),getArtistName(),getBaseURL(),_env);	
			}
			return shareUrl;		
		}
		
		/**
		 * Sharing mechanism 
		 * @param platform
		 * 
		 */		
		public function sharePlatform(platform : String ) : void
		{
			var title : String = "Check this out from " + getArtistName();
			
			trace("DATA: sharePlatform : " + title);
			
			var create_type : String = "topspin_" + SocialUtils.WIDGET_TYPE_E4M;			
			var shareURL : String = getProperShareUrl();
			switch (platform) 
			{
				case SocialUtils.PLATFORM_FACEBOOK:
					//build up the flash var query string used for 
					//Topspin fbshare.  
					//FBShare is specific to Topspin widgets only,
					//Any third party widgets will be be shared in the 
					//same fashion.
					var fv : String = getFlashVarQueryString("|","-");
					if (fv.length>0){
						fv = "fv=" + fv;
						fv += "&w="+_embedwidth+"&h="+_embedheight;
					}else {
						fv = "w="+_embedwidth+"&h="+_embedheight;
					}
					SocialUtils.shareFacebook(getFullWidgetId(), getArtistName(), getAppBaseId(), getAwesmParentId(), create_type, _env, getAwesmAPIKey(), fv);
					EventLogger.fire(TSEvents.TYPE.SHARE,{campaign:getCampaignId(), sub_type : TSEvents.SUBTYPE.SHARE_FACEBOOK});
					break;
				case SocialUtils.PLATFORM_MYSPACE:
					SocialUtils.shareMySpace(shareURL,title,getEmbedCode(), getAwesmParentId(), create_type, getAwesmAPIKey());
					EventLogger.fire(TSEvents.TYPE.SHARE,{campaign:getCampaignId(), sub_type : TSEvents.SUBTYPE.SHARE_MYSPACE});
					break;
				case SocialUtils.PLATFORM_TWITTER:
					SocialUtils.shareTwitter(shareURL,title, getAwesmParentId(), create_type, getAwesmAPIKey(),_twthash);				
					EventLogger.fire(TSEvents.TYPE.SHARE,{campaign:getCampaignId(), sub_type : TSEvents.SUBTYPE.SHARE_TWITTER});
					break;
				case SocialUtils.PLATFORM_DIGG:
					SocialUtils.shareDigg(shareURL,title, getAwesmParentId());								
					EventLogger.fire(TSEvents.TYPE.SHARE,{campaign:getCampaignId(), sub_type : TSEvents.SUBTYPE.SHARE_DIGG});
					break;
				case SocialUtils.PLATFORM_DELICIOUS:
					SocialUtils.shareDelicious(shareURL,title, getAwesmParentId());				
					EventLogger.fire(TSEvents.TYPE.SHARE,{campaign:getCampaignId(), sub_type : TSEvents.SUBTYPE.SHARE_DELICIOUS});
					break;
			}			
		}
		/**
		 * Returns the App Base Id, used for qa testing. 
		 * @return base id
		 * 
		 */		
		public function getAppBaseId() : String
		{
			var id : String = _widgetID; //_widgetDataXML.id;
			var base : String = id;
			var regEx : RegExp = new RegExp(/[A-Za-z]+:\/\/[A-Za-z0-9-_]+\.[A-Za-z0-9-_~:.=]+\//g);
			var matches : Array = regEx.exec(id);
			if (matches)
			{
				base = matches[0];
				for (var i: Number = 0;i<matches.length;i++)
				{
					trace("MATCH: " + i, matches[i]);
				}
			}else{
				trace("NO MATCH");
			}
			return base;
		}		
				
	}
}