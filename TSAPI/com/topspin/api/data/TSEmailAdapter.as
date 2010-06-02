package com.topspin.api.data
{
	import com.topspin.api.events.TSEmailAdapterEvent;
	import com.topspin.api.events.TSWidgetEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSApplications;
	import com.topspin.api.logging.TSEvents;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * TSEmailAdapter is singleton class which will parse a Topspin 
 * Email for Media widget_id and provide a simple interface to 
 * submit emails and mask all Topspin logging from where the
 * adapter is implemented.
 * 
 * Usage:
 *	var tsEmail : TSEmailAdapter = TSEmailAdapter.getInstance();
 *	tsEmail.addEventListener(TSWidgetEvent.WIDGET_COMPLETE, handleWidgetLoad);
 *	tsEmail.addEventListener(TSWidgetEvent.WIDGET_ERROR, handleWidgetError);
 *
 * 	function handlePlaylistLoad( e : TSWidgetEvent) : void {
 * 		var trackDataArray : Array = e.data as Array;   //array of ITrackData objects
 *  }
 * 
 * @see com.topspin.player.PlaylistModel for additional usage
 *  
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 * 
 */		
	public class TSEmailAdapter extends EventDispatcher
	{
		// Static:  Indicates the status of the widget
		public static var STATUS_UNPUBLISHED:Number = 1;
		public static var STATUS_PUBLISHED:Number = 2;
		public static var STATUS_DELETED:Number = 3;		
		
		//Singleton implementation
		protected static var instance : TSEmailAdapter;
		protected static var allowInstantiation : Boolean;
		protected static var NAME : String = "TSEmailAdapter";
						
		// Internal variables, logging
		private var _data:XML;  // XML returned by the widgetID
		//instance of loader used to load data
		private var loader : URLLoader;		
		private var _referringURL : String;
		private var _status : Number;
		private var _email : String;
		private var _submitting : Boolean = false;
		private var _loggingEnabled : Boolean = true;
		/**
		 * Singleton instance of TSPlaylistAdapter 
		 * 
		 */		
		public function TSEmailAdapter()
		{
			if( !allowInstantiation )
			{
				throw new Error( "Error : Instantiation failed: Use TSEmailAdapter.getInstance() instead of new." );
			}else{		
				init();	
			}			
		}
		/**
		 * Init method sets up the loader and all the listeners 
		 * 
		 */				
		private function init() : void
		{
			loader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, handleComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		}
		/**
		 * Singleton constructor 
		 * @return TSEmailAdapter
		 * 
		 */		
		public static function getInstance() : TSEmailAdapter
		{
			if( instance == null )
			{
				allowInstantiation = true;
				instance = new TSEmailAdapter();
				allowInstantiation = false;
			}
			return instance;
		}
				
		//////////////////////////////////////////////////////
		//
		// PUBLIC API METHODS
		//
		//////////////////////////////////////////////////////
		/**
		 * Public method which will initiate a load of a
		 * Topspin widget_id 
		 *  
		 * @param widget_id : Topspin generate widget_id taken from a Spin
		 */		
		public function load(widget_id : String, inProductionMode : Boolean = false) : void
		{
			_loggingEnabled = inProductionMode;
			
			if (widget_id != "" && widget_id != null ) {
				try{
					loader.load(new URLRequest(widget_id));
				} catch (e : Error) {
					trace(NAME + "::" + e.name + " error occurred : " + e);
				} 
			}else{
				//throw new Error(NAME + ":: No url provided to load");
				broadcastWidgetError(NAME + ": Please specify a valid widget_id to load");
			}					
		}
		
		/**
		 * Saves a reference of the widget_id xml, so that
		 * you may pass in a local XML model or use the load
		 * api call to load the external widget id.  Sets
		 * up the internal EventLogger for the application. 
		 * Since we are using a widget_id generated from the
		 * Publish Platform, all tracking will be summarized in
		 * that spin and thus we will identify the widget as a normal
		 * TSApplications.EMAIL_WIDGET_2
		 * @param tsData - XML
		 * 
		 */		
		public function parse(tsData:XML):void 
		{
			_data = tsData;			
			
//			EventLogger.setEnv(TSApplications.E4M);
			// Check the widget status
			//If the widget is unpublished or deleted, 
			//disable the EventLogger
		 	if (_data.campaign) {
		 		_status = Number(_data.campaign.status); 
		 	} else {
		 		_status = STATUS_UNPUBLISHED;
		 	}
			EventLogger.getInstance().enabled = (_status == STATUS_PUBLISHED);
			
			var refURL : String = EventLogger.getPageURL();
			if (refURL != null)
			{
				_referringURL = refURL;
			}else{
				_referringURL = _data.parent_page_url;
				EventLogger.setPageURL(_referringURL);
			}
			
			//If the widget is in testing mode, do not begin to log to production.
			if (EventLogger.getInstance().enabled)
			{
				EventLogger.getInstance().enabled = _loggingEnabled;
			}
			broadcastWidgetComplete();
		}	
		
		/**
		 * Submits an email to Topspin and logs the event. 
		 * @param email : String, single email address.
		 * 
		 */		
		public function submitEmail( email : String ) : void
		{
			if (isSubmitting())
			{
				return;
			}else{
				_submitting = true;
			}
			
			_email = email;
			var fanXML:XML = <fan />;
			fanXML["source-campaign"] = getCampaignId();
			fanXML["confirmation-target"] = (getConfirmationTarget()) ? getConfirmationTarget() : "";
			fanXML["email"] = email;
			fanXML["referring-url"] = EventLogger.getPageURL(); 
						
			var postUrl:String = getPostURL();
			var req:URLRequest = new URLRequest(postUrl);
				req.method = URLRequestMethod.POST;
				req.contentType = "text/xml";
				req.data = fanXML;
			
			var ldr:URLLoader = new URLLoader();
				ldr.addEventListener(Event.COMPLETE, onCompleteHandler );
				ldr.addEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
				ldr.load(req);
			
			function onCompleteHandler (event:Event):void {	
				XML.ignoreWhitespace = true;
				var response:XML =new XML(event.target.data);				
				_submitting = false;
				if (response.success.length()) {
					broadcastEmailSuccess();					
				} else {
					broadcastEmailError("Unsuccessful submission! Please try again");												
				}
			}
			
			function onErrorHandler( ev:IOErrorEvent):void {
				ev.target.removeEventListener(Event.COMPLETE, onCompleteHandler );
				ev.target.removeEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);			
				broadcastEmailError("Sorry, we cannot reach the server to submit your request.");	
				_submitting = false;											
			}
		}
		
		/**
		 * Getter to get the resulting widget_id XML
		 * data.  
		 * @return XML
		 * 
		 */		
		public function set data(dataXML : XML) : void
		{
			_data = dataXML;
			parse(_data);	
		}
		
		/**
		 * Getter to get the resulting widget_id XML
		 * data.  
		 * @return XML
		 * 
		 */		
		public function get data() : XML
		{
			return _data;
		}
		/**
		 * Return the campaign if of the widget 
		 * @return String - campaign id
		 * 
		 */		
		public function getCampaignId() : String
		{
			return _data.campaign.id;
		}
		/**
		 * Returns the confirmation target of where this
		 * email will send new users to. 
		 * @return String
		 * 
		 */			
		public function getConfirmationTarget():String {
			return _data.confirmation_target;
		}				
		/**
		 * Return the artist name from the campaign 
		 * @return String - artist name
		 * 
		 */		
		public function getArtistName() : String
		{
			return _data.campaign.artist.name;
		}
		/**
		 * Return the artist id from the campaign 
		 * @return String - artist name
		 * 
		 */		
		public function getArtistId() : String
		{
			return _data.campaign.artist.id;
		}		
		/**
		 * Returns the widget status based on the status id 
		 * @return Number 
		 * 
		 */		
		public function getWidgetStatus() : Number
		{
			return _status;
		}
		/**
		 * Returns whether the adapter is in the process of
		 * submitting a request to the server. 
		 * @return Boolean
		 * 
		 */		
		public function isSubmitting() : Boolean
		{
			return _submitting;
		}
		/**
		 * Returns the postUrl, to send out the email. 
		 * @return string url
		 * 
		 */		
		public function getPostURL():String {
			var postUrl:String;
			if (_data) {
				if (_data.submit_url != null) {
					postUrl = _data.submit_url;
				}
			}
			return postUrl;
		} 			
		//////////////////////////////////////////////////////
		//
		// PRIVATE METHODS
		//
		//////////////////////////////////////////////////////		
		/**
		 * Loader handleComplete method, coerces the 
		 * data into an XML object and sends it on to 
		 * get parsed. 
		 * @param e
		 * 
		 */		
		private function handleComplete( e : Event) : void
		{
			try {
				var _xml : XML = new XML(e.target.data);				
				parse(_xml);	
			} catch (e:TypeError)  {
				
				trace("Tried to parse(_xml) but : " + e.message);
				broadcastWidgetError(e.message);				
			} 			
		}
		/**
		 * IO and security error handler 
		 * @param e
		 * 
		 */		
		private function errorHandler( e : Event ) : void
		{
			trace(NAME + "::" + e.type + " occurred: " + e);
			broadcastWidgetError(e.toString());
		}		
		/**
		 * Dispatch and email complete event. 
		 * @param msg
		 * 
		 */		
		private function broadcastEmailSuccess(msg : String = null) : void
		{
//			EventLogger.fire(TSEvents.EMAIL_WIDGET.NEW_USER_EMAIL_SIGNUP, {campaign:getCampaignId(), artist:getArtistId(), email:_email});
			EventLogger.fire(TSEvents.TYPE.CLICK, {campaign:getCampaignId(), artist:getArtistId(), email:_email});
			dispatchEvent(new TSEmailAdapterEvent(TSEmailAdapterEvent.EMAIL_SUCCESS, msg));			
		}
		/**
		 * Dispatch an email error event 
		 * @param msg - Additional messaging
		 * 
		 */		
		private function broadcastEmailError(msg : String = null) : void
		{
			dispatchEvent(new TSEmailAdapterEvent(TSEmailAdapterEvent.EMAIL_ERROR, msg));			
		}
		/**
		 * Broadcasts a TSWidgetEvent.WIDGET_LOAD_COMPLETE when data has been loaded
		 * 
		 */		
		private function broadcastWidgetComplete() : void
		{
			trace(NAME + ": broadcastWidgetComplete()");
			EventLogger.fire(TSEvents.TYPE.LOADED, {campaign:getCampaignId(), artist:getArtistId()});
			var event : TSWidgetEvent = new TSWidgetEvent(TSWidgetEvent.WIDGET_LOAD_COMPLETE);
			dispatchEvent(event);							
		}
		/**
		 * Broadcasts a TSWidgetEvent.WIDGET_LOAD_ERROR
		 * @param msg - messaging about the error
		 * 
		 */		
		private function broadcastWidgetError( msg : String) : void
		{
			trace(NAME + ": broadcastWidgetError = " + msg);
			var event : TSWidgetEvent = new TSWidgetEvent(TSWidgetEvent.WIDGET_LOAD_ERROR,msg);
			dispatchEvent(event);							
		}
	}
}