package com.topspin.api
{
	import com.topspin.api.data.ITSPlaylist;
	import com.topspin.api.data.ITSWidget;
	import com.topspin.api.data.TSPlaylistAdapter;
	import com.topspin.api.data.media.ImageData;
	import com.topspin.api.data.media.Playlist;
	import com.topspin.api.events.E4MEvent;
	import com.topspin.api.events.TSWidgetError;
	import com.topspin.api.events.TSWidgetEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSApplications;
	import com.topspin.api.logging.TSEvents;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.utils.Dictionary;
	
	
	public class TSWidgetAPI extends Sprite implements ITSWidget
	{
		public var NAME : String = "TSWidgetAPI";
		public var VERSION : String = "TSWidgetAPI.1.0.3";
		
		private static var TOPSPIN_AWESM_API_KEY : String = "493340768445cf1788338b22b530d2ff6d59693b0788d5b94f8d31071ce73ade";
		
		//Set true if api is used for JS proxy.
		private var _isJSProxy : Boolean = false;
		
		// Static:  Indicates the status of the widget
		public static var STATUS_UNPUBLISHED:Number = 1;
		public static var STATUS_PUBLISHED:Number = 2;
		public static var STATUS_DELETED:Number = 3;		
		
		//Static current widget types		
		public static var WIDGET_TYPE_E4M : String = "email_for_media";
		public static var WIDGET_TYPE_BUNDLE : String = "bundle_widget";
		public static var WIDGET_TYPE_SINGLE : String = "single_track_player_widget";
		public static var WIDGET_TYPE_COMBO : String = "combo";
		public static var WIDGET_TYPE_CUSTOM : String = "custom";		
		private var _widgetType : String;
		
		//see com.topspin.api.logging.TSApplication
		private var _event_source : Number; 
		
		//Internal properties
		private var tsPlaylistAdapter : TSPlaylistAdapter;
		
		//Contains loaded widget_id XML hash by the widget_id
		private var WIDGET_MAP : Dictionary;
		//Contains playlist hashed by campaign id
		private var WIDGET_PLAYLIST_MAP : Dictionary;
		
		//May want to change this.		
		private var _loggingEnabled : Boolean = true;
		
		//Internal ordered array of tracks.
		private var _tracks : Array;		
		
		//Properties
		private var _isSubmitting : Boolean = false;
		private var _currentCampaignId : String;
		
		//Stock message for underage email collection
		private static var _UNDERAGE_STOCK_MESSAGE : String = "Thank you for your interest in registering. As " + 
			"we are committed to protecting your privacy, we are unable to accept your " + 
			"registration. However, we invite you to continue browsing the site without registering.";
		
		/**
		 * Constructor - allows any domain to access this widget
		 * via the ITSProxy interface.
		 */ 
		public function TSWidgetAPI()
		{
			Security.allowDomain("*");		
			WIDGET_MAP = new Dictionary();
			WIDGET_PLAYLIST_MAP = new Dictionary();	
		}
		/**
		 * Returns the version of the widget 
		 * @return String
		 * 
		 */		
		public function getVersion() : String
		{
			return VERSION;
		}
		/**
		 * Registers widget id with the proxy
		 * Will initiate the loading and parsing of the widget_id
		 * 
		 * @param widget_id String id found in the widget embed code from the Topspin widget spin. 
		 * @param production_mode Boolean : Setting to true enables Topspin logging for in application metrics  
		 * @param event_source : Number - Topspin internal usage for the event logger.  
		 * 						By default, event_source will be com.topsin.api.logging.TSApplications.CUSTOM_API_PLAYER
		 * 						Internal topspin widgets will set this to whatever widget type it is.  
		 * 						Dev partners may want to leave it to the default setting.
		 * 						@see com.topspin.api.logging.TSApplications 
		 * 						CUSTOM_API_PLAYER = 10
		 */ 
		public function registerWidgetId( widget_id : String, production_mode : Boolean = false, event_source : Number = -1 ) : void
		{
			_loggingEnabled = production_mode;
			_event_source = (event_source && event_source != -1) ? event_source : TSApplications.CUSTOM_API_PLAYER;
			
			//load this up in the widget.
			var _loader : URLLoader = new URLLoader();
			_loader.addEventListener(Event.COMPLETE, handleWidgetComplete);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, widgetErrorHandler);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, widgetErrorHandler);
			//Load the widget id.
			_loader.load(new URLRequest(widget_id));
		}
		
		//Returns an list of available api mehtods after widget_id is registered
		//		function getApiList() : Array;
		//
		//////////////////////////////////////////////////////
		//
		// PUBLIC METHODS
		//
		//////////////////////////////////////////////////////	
		/**
		 * Return the artist id from the campaign 
		 * @return String - artist name
		 * 
		 */		
		public function getArtistId( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).campaign.artist.id;
		}	
		/**
		 * Return Artist Google Analytics tracking UID for use with
		 * Google Analytics 
		 * @param campaign_id
		 * @return Google Analytics tracking UID
		 * 
		 */
		public function getArtistGATrackingId( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).campaign.artist.gat;
		}
		/**
		 * Return the Artist's record Label if applicable, used specifically
		 * for COPPA Compliant partners, such as Sony
		 * @return String - artist record label
		 * 
		 */		
		public function getArtistLabel( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).campaign.artist.label;
		}
		/**
		 * Return the artist name from the campaign 
		 * @return String - artist name
		 * 
		 */		
		public function getArtistName(campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).campaign.artist.name;
		}		
		/**
		 * Returns Artist Awesm API key if applicable, if not, will 
		 * return the Topspin key used to awesmize links. 
		 * @param campaign_id
		 * @return Awesm API key
		 * 
		 */		
		public function getAwesmAPIKey( campaign_id : String = null ) : String
		{
			var data : String = TOPSPIN_AWESM_API_KEY;
			var wid : XML = widgetData( campaign_id );
			if (wid.awesm_api_key.length() )
			{
				data = wid.awesm_api_key;
			}
			return data;			
		}
		/**
		 * Return the campaign if of the widget 
		 * @return String - campaign id
		 * 
		 */		
		public function getCampaignId() : String
		{
			return widgetData().campaign.id;
		}
		/**
		 * Returns the base embed code of the widget found in the
		 * widget_id XML 
		 * @param campaign_id
		 * @return embed code
		 * 
		 */		
		public function getEmbedCode( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).embed_code;
		}
		/**
		 * Returns the flickrId specified by the Artist for
		 * slide show images  
		 * @return String 
		 * 
		 */		
		public function getFlickrId( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).flickr.flickr_id;			
		}
		/**
		 * Returns the flickrTags specified by the Artist for
		 * slide show images.  Comman delimited.  
		 * @return String 
		 * 
		 */		
		public function getFlickrTags( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).flickr.flickr_tags;				
		}		
		/**
		 * Returns main campaign headline message as specified by the Artist 
		 * @return String
		 * 
		 */		
		public function getHeadlineMessage( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).message;	
		}
		/**
		 * Returns an artist homepage url if specified in the Artist Account 
		 * @return String
		 * 
		 */		
		public function getHomepageURL( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).homepage;
		}		
		/**
		 * Returns the Offer Button/ Call to Action Label set up in the Manager 
		 * @return - String
		 * 
		 */		
		public function getOfferButtonLabel( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).offer_button_label;
		}
		/**
		 * Returns the destination URL specified for Streaming and Single Track Player
		 * @return - String
		 * 
		 */		
		public function getOfferURL( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).offer_url;
		}	
		/**
		 * Returns the thumbnail images url of the poster image.  If no poster
		 * image is found, usually the Topspin default logo will be returned.
		 * @return URL string to thumbnail
		 * 
		 */		
		public function getPosterThumbnailURL( campaign_id : String = null ) : String
		{
			var wd : XML = widgetData(campaign_id);
			return wd.poster_image_url;
		}
		/**
		 * Will pull the ImageData object from the Single display image selected at Spin time. 
		 * @return ImageData object with multiple image sizes
		 * 
		 */
		public function getPosterImageData( campaign_id : String = null) : ImageData
		{
			var wd : XML = widgetData(campaign_id);
			var data : String;
			var imgData : ImageData;
			data = wd.poster_image_url;		
			if (wd.image && wd.image.length())
			{
				imgData = new ImageData(new XML(wd.image.toXMLString()));				
			}
			if  (!imgData && wd.poster_image.length() && wd.poster_image.image.length() )
			{
				imgData = new ImageData(new XML(wd.poster_image.image.toXMLString()));
			}				
			return imgData;
		}			
		/**
		 * Will pull the image from the Single display image selected at Spin time. 
		 * Pass in the size string to retrieve a particular size.
		 * @param size:  small || medium || large
		 * @return URL to an image
		 * 
		 */
		public function getPosterImageURL( campaign_id : String = null, size : String = "source") : String
		{
			var wd : XML = widgetData(campaign_id);
			var data : String;
			data = wd.poster_image_url;		
			
			if  (wd.poster_image.length())
			{
				data = wd.poster_image.image[size];
			}			
			//Pull from the single image			
			if (wd.image.length() && !wd.poster_image.length())
			{
				data = wd.image[size];
			}			
			return data;
		}		
		
		/**
		 * Returns the ITSPlaylist given the campaign id 
		 * @param campaign_id
		 * @return ITSPlaylist object
		 * 
		 */		
		public function getPlaylist( campaign_id : String ) : ITSPlaylist
		{
			var playlist : ITSPlaylist;
			if (WIDGET_PLAYLIST_MAP[campaign_id] != null){
				playlist = WIDGET_PLAYLIST_MAP[campaign_id];
			}
			return playlist;
		}			
		/**
		 * Return and Array of ImageData objects found in the package and Single Display Image
		 * included in the spin 
		 * @return Array of urls
		 * 
		 */		
		public function getAllProductImageData( campaign_id : String = null) : Array	
		{
			var imgIdMap : Dictionary = new Dictionary();
			var id : String;
			var url : String;
			var imageDataArray : Array = new Array();
			var imagesXML : XMLList = widgetData(campaign_id)..image;
			if (imagesXML.length())
			{
//				imageDataArray = new Array();
				for each (var image : XML in imagesXML ) 
				{	
					id = image.id;	
					if (imgIdMap[id] == null) {		
						var imgData : ImageData = new ImageData(image);
						imageDataArray.push(imgData);
						imgIdMap[id] = imgData;
					}
				}
			}
			return imageDataArray;
		}			
		/**
		 * Given a size, will return all images found in the package and Single Display Image
		 * included in the spin 
		 * @param size: small || medium || large
		 * @return Array of urls
		 * 
		 */		
		public function getAllProductImageURLs( campaign_id : String = null, size : String = "large") : Array	
		{
			var imgIdMap : Dictionary = new Dictionary();
			var id : String;
			var url : String;
			var images : Array = new Array();
			var imagesXML : XMLList = widgetData(campaign_id)..image;
			
			if (imagesXML.length())
			{
				for each (var image : XML in imagesXML ) 
				{	
					id = image.id;	
					if (imgIdMap[id] == null) {		
						url = image[size];
						images.push(url);
						imgIdMap[id] = url;
						log("getAllProductImages: " + url);						
					}
				}
			}
			return images;
		}	
		/**
		 * Returns the non CDN widget id
		 * @return String actual widget id pointing to app.topspin.net
		 * 
		 */			
		public function getWidgetId( campaign_id : String = null ) : String
		{
			return widgetData( campaign_id ).id;
		}		
		/**
		 * Returns the 3 different types of widgets represented by
		 * the widget_id: 
		 * @return String : bundle_widget || single_track_player_widget || email_for_media
		 * 
		 */			
		public function getWidgetType( campaign_id : String = null ) : String
		{
			return _widgetType;
		}
		/*----------- E4M SPECIFIC -----------*/	
		/**
		 * E4M Specific: 
		 * Returns the confirmation target as specified by the artist. 
		 * @return String
		 * 
		 */				
		public function getE4MConfirmationTarget( campaign_id : String = null ) : String
		{
			return widgetData(campaign_id).confirmation_target;
		}
		/**
		 * E4M Specific: 
		 * Returns the Date of Birth messaging set up by artist
		 * @return String
		 * 
		 */				
		public function getE4MDOBMessage( campaign_id : String = null ) : String
		{
			var dobMsg : String = "Please enter your date of birth";
			var wd : XML = widgetData(campaign_id);
			dobMsg = (wd.dob_message.length()) ? wd.dob_message : dobMsg;
			
			return dobMsg;
		}		
		/**
		 * E4M Specific: 
		 * COPPA Regulation for minimum age requirement for E4M campaigns
		 * @return minimum age limit, -1 is age does not matter
		 * 
		 */		
		public function getE4MMinimumAgeRequirement( campaign_id : String = null ) : Number
		{
			var minAge : Number = -1;
			var wd : XML = widgetData(campaign_id);
			minAge = (wd.minimum_age) ? wd.minimum_age : minAge;
			return minAge;		
		}
		/**
		 * E4M Specific:  
		 * Returns artist specific underage messaging 
		 * @return String - message for underage messaging.
		 * 
		 */		
		public function getE4MUnderageMessage( campaign_id : String = null ) : String
		{
			var msg : String = _UNDERAGE_STOCK_MESSAGE; 
			var wd : XML = widgetData(campaign_id);
			if (wd && wd.underage_message)
			{
				msg = wd.underage_message;
			}
			return msg;				
		}
		/**
		 * Returns the Artist created Opt in headline
		 * @param campaign_id
		 * @return String
		 * 
		 */
		public function getE4MOptInHeadline( campaign_id : String = null ) : String
		{
			var msg : String = "";
			var wd : XML = widgetData(campaign_id);
			if (wd && wd.info.length())
			{
				msg = wd.info.headline;
			}
			return msg;				
		}
		/**
		 * Returns the Artist created Opt in messaging
		 * @param campaign_id
		 * @return String
		 * 
		 */
		public function getE4MOptInMessage( campaign_id : String = null ) : String
		{
			var msg : String = "";
			var wd : XML = widgetData(campaign_id);
			if (wd && wd.info.length())
			{
				msg = wd.info.content;
			}
			return msg;			
		}
		/**
		 * E4M Specific: 
		 * Returns the Topspin api url to post emails 
		 * @return String url
		 * 
		 */		
		public function getE4MPostURL( campaign_id : String = null ) : String 
		{
			return widgetData(campaign_id).submit_url;
		} 	
		/**
		 * E4M Specific: 
		 * Returns whether the E4M is an email in exchange for
		 * media or simply and email submission for subscription.
		 * Useful for returning descriptive messaging about the
		 * campaign 
		 * @return Boolean
		 * 
		 */		
		public function isE4MEmailOnly( campaign_id : String = null ) : Boolean 
		{
			var wd : XML = widgetData(campaign_id);
			if(wd && (wd.media.length() > 0)) {
				return false;
			} else {
				return true;
			}
		} 			
		/**
		 * E4M Specific: 
		 * Returns whether the E4M submission requires a fan's birthdate or not 
		 * @return Boolean
		 * 
		 */				
		public function isE4MDOBRequired( campaign_id : String = null ) : Boolean
		{
			var wd : XML = widgetData(campaign_id);
			if (_widgetType == WIDGET_TYPE_E4M)
			{
				return (wd.require_dob.length()) ? (wd.require_dob == "true") : false;
			}else{
				return false;
			}
		}
		/**
		 * E4M Specific: 
		 * Retreives the custom link url for E4M
		 * @return String
		 * 
		 */	
		public function getCustomLinkUrl(campaign_id : String = null ) : String
		{
			var wd : XML = widgetData(campaign_id);
			return wd.custom_link_url;
		}
		/**
		 * E4M Specific: 
		 * Retreives the custom link label for E4M
		 * @return String
		 * 
		 */			
		public function getCustomLinkLabel(campaign_id : String = null ) : String
		{
			var wd : XML = widgetData(campaign_id);
			return wd.custom_link_text;
		}		
		/**
		 * E4M Specific: 
		 * Retreives the privacy url for E4M
		 * @return String
		 * 
		 */				
		public function getPrivacyUrl(campaign_id : String = null) : String
		{
			var wd : XML = widgetData(campaign_id); 
			var url : String = "";
			if (wd && wd.privacy_url.length())
			{
				url = wd.privacy_url;
			}			
			return url;				
		}			
		/**
		 * Indicates whether sharing is enabled or not, as specificed in the MGR 
		 * @return Boolean
		 * 
		 */		
		public function isSharingEnabled( campaign_id : String = null ) : Boolean
		{
			var wd : XML = widgetData(campaign_id);
			return (wd.sharing.length()) ? (wd.sharing=="true") : false;
		}	
		/**
		 * Indicates artist specified selection on whether to display images associated with the product in the spin.
		 * Use in conjunction with getProductImageURLs() 
		 * @return Boolean
		 * 
		 */
		public function isShowProductImagesEnabled( campaign_id : String = null ) : Boolean
		{
			var wd : XML = widgetData(campaign_id);
			return (wd.show_product_artwork.length()) ? (wd.show_product_artwork=="true") : false;			
		}			
		/**
		 * E4M Specific: 
		 * Submit a fan email for an E4M offer.  Before submitting an email, add event listener for
		 * E4MEvent which is dispatched upon success and error.
		 *  
		 * @campaign_id String
		 * @param email
		 * @param confirmation_target (Optional:  If not sent, will use default landing page specified in the MGR)
		 * @param date_of_birth (Optional but should be used in conjunction with isE4MDOBRequired()) 
		 * 
		 */		
		public function submitE4MEmail( campaign_id : String, 
										email : String,  
										confirmation_target : String = null,
										date_of_birth : Date = null ) : void
		{
			if (_isSubmitting)
			{
				return;
			}else{
				_isSubmitting = true;
			}
			
			//Let the view manage this and not make the API concern itself
//			if (isE4MDOBRequired(campaign_id) && !date_of_birth)
//			{
//				trace("DOB is required but not provided, get DOB");
//				dispatchEvent(new E4MEvent(E4MEvent.DOB_NULL_BUT_REQUIRED, null, getE4MDOBMessage(campaign_id)));
//				_isSubmitting = false;
//				return;				
//			}
//			if (isE4MDOBRequired(campaign_id) && !validateEmailDOB( date_of_birth ))
//			{
//				dispatchEvent(new E4MEvent(E4MEvent.UNDERAGE_ERROR, null, getE4MUnderageMessage(campaign_id)));																	
//				_isSubmitting = false;
//				return;
//			}			
			if (!validateEmail(email))
			{	
				dispatchEvent(new E4MEvent(E4MEvent.EMAIL_ERROR, null,"Please enter a valid email address."));
				_isSubmitting = false;
				return;
			}

			var _confirmation_target : String = (confirmation_target) ? confirmation_target : getE4MConfirmationTarget(campaign_id);
			
			var fanXML:XML = <fan />;
			fanXML["source-campaign"] = campaign_id;
			fanXML["confirmation-target"] = _confirmation_target;
			fanXML["email"] = email;
			fanXML["referring-url"] = EventLogger.getPageURL(); 
			if (date_of_birth)
			{
				fanXML["dob"] = date_of_birth;
			}
			
			var postUrl:String = getE4MPostURL(campaign_id);
			var req:URLRequest = new URLRequest(postUrl);
			req.method = URLRequestMethod.POST;
			req.contentType = "text/xml";
			req.data = fanXML;
			
			var ldr:URLLoader = new URLLoader();
			ldr.addEventListener(Event.COMPLETE, onCompleteHandler );
			ldr.addEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
			ldr.load(req);
			
			function onCompleteHandler (event:Event):void {
				event.target.removeEventListener(Event.COMPLETE, onCompleteHandler );
				event.target.removeEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
				
				XML.ignoreWhitespace = true;
				var response:XML = new XML(event.target.data);				
				_isSubmitting = false;
				if (response.success.length()) {
					EventLogger.fire(TSEvents.TYPE.CLICK, {campaign:getCampaignId(), artist:getArtistId(campaign_id), email:email});
					dispatchEvent(new E4MEvent(E4MEvent.EMAIL_SUCCESS));			
					
				} else {
					dispatchEvent(new E4MEvent(E4MEvent.EMAIL_ERROR, null, "Unsuccessful submission! Please try again"));											
				}
			}
			function onErrorHandler( ev:IOErrorEvent):void {
				ev.target.removeEventListener(Event.COMPLETE, onCompleteHandler );
				ev.target.removeEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);			
				_isSubmitting = false;
				dispatchEvent(new E4MEvent(E4MEvent.EMAIL_ERROR, null, "Sorry, we cannot reach the server to submit your request."));						
			}
		}

		
		//////////////////////////////////////////////////////
		//
		// PRIVATE METHODS
		//
		//////////////////////////////////////////////////////	
		/* -------------- EVENTS --------------*/		
		private function handleWidgetComplete( e : Event) : void
		{
			e.target.removeEventListener(Event.COMPLETE, handleWidgetComplete);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, widgetErrorHandler);
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, widgetErrorHandler);
			
			try {
				log(NAME + ": handleWidgetComplete : Parsing");
				var _xml : XML = new XML(e.target.data);				
				parse(_xml);	
			} catch (e:TypeError)  {
				log(NAME + ":parsing error: " +  e.message);			
				broadcastWidgetError(e.message);				
			} 				
		}
		
		/**
		 * Parses loaded ts widget id xml and sets up
		 * logging for the type of widget. 
		 * @param tsData
		 * 
		 */				
		private function parse( tsData : XML ) : void
		{
			var _status : Number;
			var _data : XML = tsData;
			_currentCampaignId = _data.campaign.id;// EventLogger.getCID(_data.campaign.id);
			WIDGET_MAP[_currentCampaignId] = _data;
			
			var node : XML = _data.children()[0].parent();
			var app : Number = TSApplications.BUNDLE_WIDGET;
			if (node.localName() == WIDGET_TYPE_BUNDLE) app = TSApplications.BUNDLE_WIDGET;
			if (node.localName() == WIDGET_TYPE_SINGLE) app = TSApplications.SINGLE_PLAYER;
			if (node.localName() == WIDGET_TYPE_E4M) app = TSApplications.E4M;
			_widgetType = node.localName();
			log("app : " + app);
						
			//Anyone using the TSWidgetManager will 
			//be event source type:  custom_api_player
			EventLogger.setEnv(_event_source, loaderInfo,_currentCampaignId);
			
			// Check the widget status
			//If the widget is unpublished or deleted, 
			//disable the EventLogger
			if (_data.campaign) {
				_status = Number(_data.campaign.status); 
			} else {
				_status = STATUS_UNPUBLISHED;
			}
			EventLogger.getInstance().enabled = (_status == STATUS_PUBLISHED);
			
			if (_status == STATUS_DELETED)
			{
				broadcastWidgetError("This widget is currently unavailable.");
				return;
			}
			
			//Try and set up the referring url 
			var refURL : String = EventLogger.getPageURL();
			log("refURL : " + refURL);
			if (!refURL || refURL == "")
			{
				//try and get the referring url.
				refURL = _data.parent_page_url;
				if (refURL) EventLogger.setPageURL(refURL);
			}
			
			//If the widget is in testing mode, do not begin to log to production.
			if (EventLogger.getInstance().enabled)
			{
				//log("Logging Enabled : " + _loggingEnabled);
				EventLogger.getInstance().enabled = _loggingEnabled;
			}
			
			//Check to see if this is a bundle or single player widget and if so, parse more
			if (_data.media && _data.media.length())
			{
				log(NAME + ": parse Playlist : " + getCampaignId());			
				
				var playlist : Playlist = new Playlist( getCampaignId() );
				playlist.addEventListener(Event.COMPLETE, handlePlaylistComplete);
				playlist.load( XML(_data.media) );
				
				function handlePlaylistComplete( e : Event ) : void
				{
					WIDGET_PLAYLIST_MAP[_currentCampaignId] = playlist;		
					log(NAME + ": parse PlaylistComplete : " + playlist);			
					broadcastWidgetComplete( _currentCampaignId );
					dispatchEvent(new TSWidgetEvent(TSWidgetEvent.PLAYLIST_READY));
				}				
			} else{
				broadcastWidgetComplete( _currentCampaignId );
			}
		}				
		/**
		 * IO and security error handler 
		 * @param e
		 * 
		 */		
		private function widgetErrorHandler( e : Event ) : void
		{
			e.target.removeEventListener(Event.COMPLETE, handleWidgetComplete);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, widgetErrorHandler);
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, widgetErrorHandler);
			
			log(NAME + "::" + e.type + " occurred: " + e);
			broadcastWidgetError(e.toString());
		}		
		/**
		 * Broadcasts a TSWidgetEvent.WIDGET_LOAD_COMPLETE when data has been loaded
		 * @param cid : String of campaign id
		 */		
		private function broadcastWidgetComplete( cid : String ) : void
		{
			log(NAME + ": broadcastWidgetComplete()");
			
			//Set up Google Analytics if we have it.
			var gat : String = getArtistGATrackingId(cid);
			if (gat) EventLogger.setGATrackingId(gat);
			trace("fire LOADED event");			
			EventLogger.fire(TSEvents.TYPE.LOADED,{campaign: cid});	
			
			var event : TSWidgetEvent = new TSWidgetEvent(TSWidgetEvent.WIDGET_LOAD_COMPLETE, {campaign_id : cid} );
			dispatchEvent(event);							
		}
		/**
		 * Broadcasts a TSWidgetEvent.WIDGET_LOAD_ERROR
		 * @param msg - messaging about the error
		 * 
		 */		
		private function broadcastWidgetError( msg : String) : void
		{
			log(NAME + ": broadcastWidgetError = " + msg);
			var event : TSWidgetEvent = new TSWidgetEvent(TSWidgetEvent.WIDGET_ERROR, this, msg, true, true);
			dispatchEvent(event);							
		}
		
		private function setCurrentCampaignId( cid : String) : void
		{
			_currentCampaignId = cid;
		}
		/**
		 * Access to the underlying XML structure this api
		 * uses as the Data Model 
		 * @param campaign_id 
		 * @return XML
		 * 
		 */		
		public function widgetData( campaign_id : String = null ) : XML
		{
			var cid : String;
			if (campaign_id)
			{
				if (WIDGET_MAP[campaign_id])
				{
					_currentCampaignId = campaign_id;
				}else{
					//					broadcastWidgetError(NAME + ": Invalid campaign id specified: [" + campaign_id + "] is not registered.");
					throw new TSWidgetError("TSWidgetError: Invalid campaign id specified: [" + campaign_id + "] is not registered.");					
					return;
				}
			}
			return WIDGET_MAP[_currentCampaignId] as XML;
		} 		
		
		//////////////////////////////////////////////////////
		//
		// UTIL METHODS
		//
		//////////////////////////////////////////////////////	
		/**
		 * Regular expression for the email 
		 * @param input
		 * @return 
		 * 
		 */		
		private function validateEmail(input:String) : Boolean 
		{
			return RegExp(/^([a-zA-Z0-9_\.\-\+])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})$/).test(input);
		}
		/**
		 * Given a date, checks if the dob make the user older than the minimum age limit 
		 * @param dob
		 * @return Boolean - false if date of birth is under age
		 * 
		 */		
		private function validateEmailDOB( dob : Date ) : Boolean
		{
			var minAge : Number = getE4MMinimumAgeRequirement();
			if (minAge == -1)
			{
				return true;
			} 
			var age : Number = calculateAge(dob);
			return (age >= minAge);
		}
		/**
		 * Calculate the age in years based on today's date 
		 * @param birthdate
		 * @return Age
		 * 
		 */		
		private function calculateAge(birthdate:Date):Number {
			var dtNow:Date = new Date();// gets current date
			var currentMonth:Number = dtNow.getMonth();
			var currentDay:Number = dtNow.getDay();
			var currentYear:Number = dtNow.getFullYear();
			
			var bdMonth:Number = birthdate.getMonth();
			var bdDay:Number = birthdate.getDay();
			var bdYear:Number = birthdate.getFullYear();
			
			// get the difference in years
			var years:Number = dtNow.getFullYear() - birthdate.getFullYear();
			// subtract another year if we're before the
			// birth day in the current year
			if (currentMonth < bdMonth || (currentMonth == bdMonth && currentDay < bdDay)) {
				years--;
			}
			return years;
		}				
		public function log( msg : String ) : void
		{
			trace(msg);
		}
	}
}