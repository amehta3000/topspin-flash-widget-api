/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * ImageManager manages the image data throughout the app  
 * 
 * <widget_xml> 
 *     <album>
 *         <image> - Album Image
 *         <media_collection>
 *             <track>
 *                 <image> - Track Image
 *             </track>
 *             <image> - Bundle Image
 *         </media_collection>
 *     </album>
 *     <image> - Single Image 
 * </widget_xml>
 * 
 * @copyright	Topspin Media
 * @author		kevans@topspinmedia.com
 * 
 */
package com.topspin.email.data {
	// Topspin imports
	import com.topspin.api.data.ITSWidget;
	import com.topspin.api.data.media.ImageData;
	import com.topspin.common.events.FlickrEngineEvent;
	import com.topspin.common.media.IFlickrAdapter;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	
	public class ImageDataParser extends EventDispatcher {
		// Input Variables
		private static const FLICKR_ADAPTER_PATH : String =  "/flash/adapters/FlickrAdapter.swf";
		public var _maxPhotos : Number = 50;
		
//		private var _widgetXML:XML;
//		private var _imageArray:Array;
//		private var _includeProductImages:Boolean;
//		private var _includeSingleImage:Boolean;
		private var _flickrID:String;
		private var _flickrTags:String;
		
		private var loaderContext : LoaderContext;
		
		private var _baseURL : String;
		private var flickrAdapter : IFlickrAdapter;
		// Objects
		private var imageXMLList:XMLList
		private var imgIdMap:Object;
		
		// Events
		public static var FLICKR_PHOTO_COMPLETE:String = "flickrLoadComplete";
		public static var FLICKR_FEED_COMPLETE:String = "flickrFeedComplete";
		
		private var _tsWidget : ITSWidget;
		private var _imageDataArray : Array;
		private var _campaignId : String;
		
		public function ImageDataParser( tsWidget : ITSWidget, campaignId : String, baseUrl : String) {
			// Input variables
			this._tsWidget = tsWidget;
			this._imageDataArray = new Array();
			this._baseURL = baseUrl;
			
			// Keep track of the images so no dupes occur - when we find a unique id, push it onto the map
			imgIdMap = new Object();  
		}
		
		public function parseImages():void {
			
			//First try and get all the images including the Single image 
			if (_tsWidget.isShowProductImagesEnabled(_campaignId) )
			{
				this._imageDataArray  = _tsWidget.getAllProductImageData(_campaignId);	
				trace("Show product Images: " + _imageDataArray.length);
			} else if (_tsWidget.getPosterImageData(_campaignId) != null) {
				//Single Poster Image will be the display
				this._imageDataArray.push(_tsWidget.getPosterImageData(_campaignId));
				trace("Show single image: " + this._imageDataArray.length);
			} 
				
			retrieveFlickrAdapter();
			
			this.dispatchEvent(new Event(Event.COMPLETE));  // At end, dispatch event
		}
		
		public function getImageData() : Array
		{
			return this._imageDataArray;
		}

		/**
		 * Loads the flickr adapter which will is a interface
		 * into the FlickrEngine 
		 * 
		 */		
		private function retrieveFlickrAdapter():void {
			this._flickrID = _tsWidget.getFlickrId(_campaignId);
			this._flickrTags = _tsWidget.getFlickrTags(_campaignId);
			
			if (!this._flickrID && !this._flickrTags) return;
			
			
			loaderContext = new LoaderContext();
			loaderContext.securityDomain = SecurityDomain.currentDomain;
			var request : URLRequest = new URLRequest(_baseURL + FLICKR_ADAPTER_PATH);
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoaded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			loader.load(request, loaderContext);				
		}
		/**
		 * IO Error Event handler 
		 * @param e
		 * 
		 */		
		private	function ioErrorHandler( e : IOErrorEvent ) : void
		{
			trace("ImageParser FlickrAdapter fail: " + e);
			dispatchEvent(new Event(ImageDataParser.FLICKR_FEED_COMPLETE));
		}			
		
		private function handleLoaded( e : Event ) : void
		{
			e.target.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,handleLoaded);
			e.target.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			trace("-FlickrAdapter COMPLETE!!");
			
			flickrAdapter = IFlickrAdapter(e.currentTarget.content);
			flickrAdapter.addEventListener(FlickrEngineEvent.ON_FROB_SUCCESS, handleFrobSuccess);
			flickrAdapter.addEventListener(FlickrEngineEvent.ON_PHOTO_SUCCESS, handlePhotoSuccess);		
			flickrAdapter.addEventListener(FlickrEngineEvent.ON_FLICKR_LOAD_COMPLETE, handleFlickrLoadComplete);				
			
			flickrAdapter.setFlickrParams(this._flickrID, this._flickrTags);
			flickrAdapter.initiate();
			
			function handleFrobSuccess(e:FlickrEngineEvent):void {  // Flickr session authenticated - execute search
				trace("-FlickrAdapter FROB!");
				flickrAdapter.search(_maxPhotos);
			}		
			// Have successfully parsed all images
			function handlePhotoSuccess(e:FlickrEngineEvent):void {
				// Parse the photos in the photoList
				var myReturnedPhotos:Array = new Array();
				myReturnedPhotos = flickrAdapter.getPhotoURLArray();
				for (var photoIndex:Number = 0; photoIndex < myReturnedPhotos.length; photoIndex++) {
					var currentURL:String = String(myReturnedPhotos[photoIndex]);
					var imageData:ImageData = new ImageData();
					
					// Only take .jpg or .png images from the returned Flickr stream
					var suffix : String = currentURL.substr(currentURL.length - 4, 4);
					if(suffix == ".jpg" || suffix == ".png") 
					{
						imageData.id = currentURL;
						imageData.imageURL = currentURL;
						if (imgIdMap[currentURL] == null) {
//							trace("_imageDataArray: " + imageData.imageURL);
							_imageDataArray.push(imageData);
							
							imgIdMap[currentURL] = currentURL;	
						}
					}
				}
				dispatchEvent(new Event(ImageDataParser.FLICKR_PHOTO_COMPLETE));
			}	
			function handleFlickrLoadComplete(e : FlickrEngineEvent) : void
			{
				flickrAdapter.removeEventListener(FlickrEngineEvent.ON_FROB_SUCCESS, handleFrobSuccess);
				flickrAdapter.removeEventListener(FlickrEngineEvent.ON_PHOTO_SUCCESS, handlePhotoSuccess);		
				flickrAdapter.removeEventListener(FlickrEngineEvent.ON_FLICKR_LOAD_COMPLETE, handleFlickrLoadComplete);				
				
				trace("-FlickrAdapter feed load complete");
				dispatchEvent(new Event(ImageDataParser.FLICKR_FEED_COMPLETE));
			}
		}		
	}  // End class
}  // End package