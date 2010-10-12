package com.topspin.common.media
{
	import flash.events.IEventDispatcher;
	
	/**
	 * Implemented by Topspins Flickr Engine swf which is loaded
	 * in from the CDN to be used in Flickr slideshow.
	 * @author amehta@topspinmedia.com
	 * 
	 */	
	public interface IFlickrAdapter extends IEventDispatcher {

		//Sets a Flickr Params
		function setFlickrParams( flickrId : String, flickrTags:String = null ) : void;	
				
		function initiate() : void;
		
		function search(maxPhotos : Number = 50) : void;
		
		function getPhotoURLArray() : Array;

	}
}