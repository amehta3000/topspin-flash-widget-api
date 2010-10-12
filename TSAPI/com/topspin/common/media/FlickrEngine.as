package com.topspin.common.media {
	// Adobe imports
	import com.adobe.webapis.flickr.FlickrService;
	import com.adobe.webapis.flickr.PagedPhotoList;
	import com.adobe.webapis.flickr.Photo;
	import com.adobe.webapis.flickr.PhotoSize;
	import com.adobe.webapis.flickr.events.FlickrResultEvent;
	import com.topspin.common.events.FlickrEngineEvent;
	
	import flash.display.Sprite;
	import flash.system.Security;

	public class FlickrEngine extends Sprite implements IFlickrAdapter {

		// Flickr URL address, used for Security.allowDomain
		public static const FLICKR_URL:String = "http://www.flickr.com";
		public static const CROSSDOMAIN_URL:String = "http://api.flickr.com/crossdomain.xml";

		// Developer's API Information
		public static const FLICKR_KEY:String = "e1907635efc23c70b7b61eb3f92fae98";  // Developer's API Key
		public static const FLICKR_SECRET:String = "07efe0bc89f993ce";  // API's secret number
		
		// Global Flickr Elements
		private var myFlickrService:FlickrService;  // FlickrService instance
		private var photoList:PagedPhotoList;  // PagedPhotoList that holds all retrieved photos
		private var photoURLArray:Array;  // Array of URL locations of discovered photos
		private var photoListTotal:Number;  // Length of returned URL Location array
		private var photoIndex:Number = 0;  // Iterator for returned Flickr images
		
		// Input Variables
		private var _inputName:String;
		private var _inputTags:String;
		
		private var _maxPhotos : Number = 50;
		
		/**
		 * FlickrEngine - default constructor.
		 *  - Initializes crossdomain security protocols
		 *  - Creates FlickrService instance
		 *  - Requests FROB (Flickr authentication)
		 */
		public function FlickrEngine(inputName:String = null , inputTags:String = null):void {
			// Handle the input variables
			this._inputName = inputName;
			this._inputTags = inputTags;

			photoURLArray = new Array();  // Array to hold returned Flickr image URLs
			
			// Flickr domain registration
			Security.allowDomain(FLICKR_URL);
			Security.loadPolicyFile(CROSSDOMAIN_URL);

			myFlickrService = new FlickrService(FLICKR_KEY);  // Create an instance of the FlickrService
			myFlickrService.secret = FLICKR_SECRET;  // Assign the FlickrService instance the secret key

			myFlickrService.addEventListener(FlickrResultEvent.AUTH_GET_FROB, handleGetFrob);
			//myFlickrService.auth.getFrob();  // Request the FROB, an authentication value passed back and forth between Flickr servers
		}
		/**
		 * Public method to initiate the FlickrEngine 
		 * 
		 */		
		public function initiate() : void
		{
			if (myFlickrService && (this._inputName || this._inputTags))
			{
				myFlickrService.auth.getFrob();  // Request the FROB, an authentication value passed back and forth between Flickr servers
			}else{
				trace("No flickrId or flickrTags found!");
			}	
		}
		
		public function setFlickrParams( flickrId : String, flickrTags:String = null ) : void
		{
			this._inputName = flickrId;
			this._inputTags = flickrTags;			
		}
		
		/**
		 * search - If username exists, converts to NSID (Flickr-encoded username), and triggers search
		 * 
		 */
		public function search(maxPhotos : Number = 50):void {
			_maxPhotos = maxPhotos;
			
			if(this._inputName) {  // Flickr ID exists - convert to NSID and trigger search
				myFlickrService.addEventListener(FlickrResultEvent.PEOPLE_FIND_BY_USERNAME, processUsername);
				myFlickrService.people.findByUsername(this._inputName);
			} else {  // Flickr ID is null (no need to look up by username) - 
				doSearch("", this._inputTags);
			}
		}
		
		/**
		 * processUsername - pulls formatted username from response string and triggers photo search
		 * 
		 * @param e:FlickrResultEvent - FlickrResultEvent *NOTE - username located in e.data.user.nsid
		 * 
		 */
		private function processUsername(e:FlickrResultEvent):void {
			myFlickrService.removeEventListener(FlickrResultEvent.PEOPLE_FIND_BY_USERNAME, processUsername);

			if(e.success) {
				var userName:String;
					userName = e.data.user.nsid;
				doSearch(userName, this._inputTags);
				dispatchEvent(new FlickrEngineEvent(FlickrEngineEvent.ON_USERNAME_SUCCESS, true));
			} else {
				dispatchEvent(new FlickrEngineEvent(FlickrEngineEvent.ON_USERNAME_FAIL, true));  // Dispatch fail event
			}
		}

		/**
		 * doSearch - searches photos with input username and tags
		 *  
		 * @param inputName
		 * @param inputTags
		 * 
		 * 
		 */
		private function doSearch(inputName:String, inputTags:String):void {
			myFlickrService.addEventListener(FlickrResultEvent.PHOTOS_SEARCH, processPhotoData);			
			//using all the defaults expect for the _maxPhotos
			myFlickrService.photos.search(inputName, inputTags,"any","",null,null,null,null,-1,"",_maxPhotos);
		}

		/**
		 * processPhotoData - Iterate sthrough returned photos, accessing each the size element of each image (where its URL is stored)
		 *  
		 * @param e:FlickrResultEvent
		 * 
		 */
		private function processPhotoData(e:FlickrResultEvent):void {
			myFlickrService.removeEventListener(FlickrResultEvent.PHOTOS_SEARCH, processPhotoData)
			photoList = e.data.photos as PagedPhotoList;
			photoListTotal = photoList.photos.length;

			myFlickrService.addEventListener(FlickrResultEvent.PHOTOS_GET_SIZES, handlePhotosGetSizes);

			processNextPhoto();
		}

		/**
		 * processNextPhoto - access the next photo and call to get its size
		 * 
		 */
		private function processNextPhoto():void {
			var currentPhoto:Photo = photoList.photos[photoIndex];
			if(currentPhoto) {
				myFlickrService.photos.getSizes(currentPhoto.id);
			}else{
				trace("AlickrAdapter - no photos, cleanup");
				cleanup();
			}							
		}
		
		/**
		 * handlePhotosGetSizes - Adds URL of returned photos to photoURLArray, and dispatches an ON_PHOTO_SUCCESS on completion
		 * 
		 * @param e:FlickrResultEvent
		 * 
		 */
		private function handlePhotosGetSizes(e:FlickrResultEvent):void {  // Add photos to the result array
			var sizeArr:Array = e.data.photoSizes;  // Array of PhotoSizes for each returned image
			var s:PhotoSize = sizeArr[sizeArr.length - 1];  // PhotoSizes are stored in ascending order - last PhotoSize is the largest

			photoURLArray.push(s.source);
			dispatchEvent(new FlickrEngineEvent(FlickrEngineEvent.ON_PHOTO_SUCCESS, true));  // ADDED HERE
			
			if(photoURLArray.length == this.photoListTotal) {  // Reached end of returned pictures
				cleanup();
			} else {  // More pictures remain
				photoIndex++;
				processNextPhoto();
			}
		}
		
		/**
		 * cleanup - Remove event listeners and dispatch an event signaling the Engine has completed a search
		 * 
		 */		
		private function cleanup():void {
			myFlickrService.removeEventListener(FlickrResultEvent.PHOTOS_GET_SIZES, handlePhotosGetSizes);
			dispatchEvent(new FlickrEngineEvent(FlickrEngineEvent.ON_FLICKR_LOAD_COMPLETE, true));  // Dispatch success event
			//dispatchEvent(new FlickrEngineEvent(FlickrEngineEvent.ON_PHOTO_SUCCESS, true));  // Dispatch success event
		}

		/**
		 * handleGetFrob - handler for frob authentication
		 * 
		 * @param e - FlickrResultEvent
		 * 
		 */
		private function handleGetFrob(e:FlickrResultEvent):void {
			var myEvent:FlickrEngineEvent;
			if (e.success) {
				myEvent = new FlickrEngineEvent(FlickrEngineEvent.ON_FROB_SUCCESS, true);
			} else {
				myEvent = new FlickrEngineEvent(FlickrEngineEvent.ON_FROB_ERROR, true);
			}
			dispatchEvent(myEvent);
		}

		// GET METHODS
		
		public function getPhotoList():PagedPhotoList {
			return this.photoList;
		}
		
		public function getPhotoURLArray():Array {
			return this.photoURLArray;
		}
	}
}