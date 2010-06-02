package com.topspin.api.data
{
/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * TSPlaylistAdapter is a adapter class which loads in REST api urls or 
 * Topspin set_list_xml and parses the data into ITrackData objects.
 * ITrackData objects represent various media types (Audio & Video) 
 * and provides a wrapper for a Track object contiaining various 
 * Topspin specific metadata. 
 * 
 * Usage:
 *	<code>
 *  var adapter = TSPlaylistAdapter.getInstance();
 *	adapter.addEventListener(TSPlaylistAdapterEvent.PLAYLIST_COMPLETE, handlePlaylistLoad);
 *	adapter.addEventListener(TSPlaylistAdapterEvent.PLAYLIST_ERROR, handlePlaylistError);
 *  
 * 	function handlePlaylistLoad( e : TSPlaylistAdapterEvent) : void {
 * 		var trackDataArray : Array = e.data as Array;   //array of ITrackData objects
 *  }
 * </code>
 *  
 * @see com.topspin.player.PlaylistModel for additional usage
 *  
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 * 
 */	
 
	import com.topspin.api.data.media.AudioData;
	import com.topspin.api.data.media.ITrackData;
	import com.topspin.api.data.media.Track;
	import com.topspin.api.data.media.VideoData;
	import com.topspin.api.events.TSPlaylistAdapterEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	public class TSPlaylistAdapter extends EventDispatcher
	{
		//Singleton implementation
		protected static var instance : TSPlaylistAdapter;
		protected static var allowInstantiation : Boolean;
		protected static var NAME : String = "TSPlaylistAdapter";
				
		//instance of loader used to load data
		private var loader : URLLoader;
		
		private var _tracks:Array;
		private var listIndex:Number = 0;
		//Set this to true if you would rather video metadata to be overriden
		//with data that is surfaced from the XML.  Particularly for
		//video with and height dimensions.  This effects the SingleTrackPlayer
		private var _overrideMetaData : Boolean = false;
		/**
		 * Singleton instance of TSPlaylistAdapter 
		 * 
		 */		
		public function TSPlaylistAdapter()
		{
			if( !allowInstantiation )
			{
				throw new Error( "Error : Instantiation failed: Use TSPlaylistAdapter.getInstance() instead of new." );
			}else{		
				init();	
			}			
		}
		/**
		 * Init sets up the URLLoader 
		 * 
		 */		
		private function init() : void
		{
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, handleComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		}

		/**
		 * Singleton constructor 
		 * @return TSPlaylistAdapter
		 * 
		 */		
		public static function getInstance() : TSPlaylistAdapter
		{
			if( instance == null )
			{
				allowInstantiation = true;
				instance = new TSPlaylistAdapter();
				allowInstantiation = false;
			}
			return instance;
		}
		
		/**
		 * Public method which will initiate a load of a
		 * REST api url or set_list_xml for Topspin
		 * data
		 *  
		 * @param url
		 */		
		public function load(url : String, overrideMetaData : Boolean = false) : void
		{
			_overrideMetaData = overrideMetaData;
			if (url != "" && url != null )
			{
				try{
					loader.load(new URLRequest(url));
				} catch (e : Error) {
					trace(NAME + "::" + e.type + " error occurred : " + e);
				} 
			}else{
				//throw new Error(NAME + ":: No url provided to load");
				broadcastPlaylistError(NAME + " Please specify a url to load");
			}					
		}
		
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
				trace(e.message);
			} 			
		}
		
		/**
		 * Parses the current Topspin playlist.xml following 
		 * xml schema.  Creates a new ITrackData with parsed
		 * Track object.  Will be branched out into separate
		 * TSParser class when additional set lists are introduced
		 * @param tsData - XML
		 * 
		 */		
		public function parse(tsData:XML):void {
			
			_tracks = new Array();  // Initialize the tracks array
			var tsDataChildren:XMLList;  // Dummy XMLList that holds media elements pulled from input XML
			
//			trace("****************************************************");
//			trace(tsData.toXMLString());
//			trace("****************************************************");

			if(tsData.name() == "deprecated" || tsData.name() == "playlist")  {  // Data is being passed using old, non-REST style
//				trace(NAME + " is parsing XML");	
				// Array of ITrackData
				var allTracks : XMLList = tsData.track;
				var t:Track; 
				var listIndex : Number = 0;

				// Set the playlist data
				for each (var track:XML in allTracks)  {
					t = new Track();				
					t.id = track.@id;
					t.imageURL = track.@img;
					t.artistId = track.artist.@id;
					t.artistName = track.artist;
					t.title = track.title;
					t.mediaURL = track.filename;
					t.mediaType = track.type;
					t.maxPlays = track.plays;
					t.duration = parseInt(track.duration) * 1000;
//					t.initPlaylistIndex = t.playlistIndex  = listIndex;

					// Specific for a Video 
					if (track.h264.length()) {
						t.h264_large_URL = track.h264.large;
						t.h264_small_URL = track.h264.small;
					}
					
					if (track.width != undefined) { t.width = track.width; }		
					if (track.height != undefined) { t.height = track.height; }		
					
					// Create the ITrackData and push it onto the array
					_tracks.push(createTrackData( t ));
					listIndex++;
				}
			} else { 
				parseAlbum(tsData);
			}

			// Tell any listeners we are done and pass back the array
			broadcastPlaylistComplete(_tracks);
		}		

		//Recursive function.
		private function parseAlbum( tsData : XML ) : void
		{
			var tsDataChildren : XMLList;
			if(tsData.album.length() > 0) {  // We're looking at an album widget			
				tsDataChildren = tsData.album.media_collection.children();
			} else {  // We're looking at a single track player
				tsDataChildren = tsData.children();
			}			
			for each (var element:XML in tsDataChildren) {
				if(element.name() == "media_collection" || element.name() == "album") {
					parseAlbum(element);
				} 					
				
				if(element.name() == "track") {
					parseTrack(element);
				} 
				
				if(element.name() == "video") {
					parseVideo(element);
				}
			}			
		}
		/**
		 * Parse the track XML 
		 * @param tsData
		 * 
		 */		
		private function parseTrack(tsData:XML):void {
			var t:Track;
			t = new Track();				
			t.id = tsData.id;
			t.artistName = tsData.artist_name;
			t.title = tsData.title;
			t.mediaURL = tsData.stream_mp3_url;
			t.mediaType = Track.MEDIA_TYPE_AUDIO;
			t.duration = parseInt(tsData.total_duration_in_seconds) * 1000;
			t.initPlaylistIndex = t.playlistIndex  = listIndex;
			t.imageURL = tsData.image_url;
			if (tsData.image.length())
			{
				t.image_small_url = tsData.image.small;
				t.image_medium_url = tsData.image.medium;
				t.image_large_url = tsData.image.large;
			}

			listIndex++;
			_tracks.push(createTrackData(t));  // Create the ITrackData and push it onto the array
		}

		/**
		 * parseVideo - parses video element into tracks (media_collection configuration)
		 *  
		 * @param tsData - XML data to parse
		 * 
		 */		
		private function parseVideo(tsData:XML):void {
			var t:Track;
			t = new Track();				
			t.id = tsData.id;
			t.artistName = tsData.artist_name;
			t.title = tsData.title;
			t.mediaURL = tsData.flv;
			t.mediaType = Track.MEDIA_TYPE_VIDEO;
			t.duration = parseInt(tsData.total_duration_in_seconds) * 1000;
			t.h264_large_URL = tsData.h264.large;
			t.h264_small_URL = tsData.h264.small;
			t.initPlaylistIndex = t.playlistIndex  = listIndex;
			t.width = tsData.width;		
			t.height = tsData.height;
			t.imageURL = tsData.image_url;
			if (tsData.image_product.length() && tsData.image_url == null)
			{
				var data : String;
				data = tsData.image_product.medium;
				if (data == null || data.length == 0) data = tsData.image_product.large;
				if (data == null || data.length == 0) data = tsData.image_product.small;	
				
				if (data) {
					t.imageURL = data;
				}			
				t.image_small_url = tsData.image_product.small;
				t.image_medium_url = tsData.image_product.medium;
				t.image_large_url = tsData.image_product.large;				
			}
			listIndex++;
			_tracks.push(createTrackData(t));  // Create the ITrackData and push it onto the array
		}

		/**
		 * Creates a ITrackData object based on the MEDIA TYPE
		 * @param t - A track to be added, will determine what type
		 * 			  of ITrackData to create based on the mediaType
		 */		
		private function createTrackData( t : Track ) : ITrackData
		{
			var trackData : ITrackData;
			switch (t.mediaType) {
				case Track.MEDIA_TYPE_AUDIO:
					trackData = new AudioData();
					break;
				case Track.MEDIA_TYPE_VIDEO:
					trackData = new VideoData();
					VideoData(trackData).overrideMetaData = _overrideMetaData;
					break;
			}
			trackData.setTrack(t);
			return trackData;
		}

		/**
		 * Broadcasts a TSPlaylistAdapterEvent.PLAYLIST_COMPLETE when
		 * tracks have been loaded.  Passes the ITrackData array
		 * on to any listeners.
		 * @param arr
		 * 
		 */		
		private function broadcastPlaylistComplete( arr : Array) : void
		{
			var event : TSPlaylistAdapterEvent = new TSPlaylistAdapterEvent(TSPlaylistAdapterEvent.PLAYLIST_COMPLETE,arr);
			trace("PLAYLIST ADAPTER: " + arr.length);
			dispatchEvent(event);							
		}
		
		/**
		 * Broadcasts a TSPlaylistAdapterEvent.PLAYLIST_ERROR when
		 * tracks have been loaded.  Passes the ITrackData array
		 * on to any listeners.
		 * @param arr
		 * 
		 */		
		private function broadcastPlaylistError( msg : String) : void
		{
			var event : TSPlaylistAdapterEvent = new TSPlaylistAdapterEvent(TSPlaylistAdapterEvent.PLAYLIST_ERROR,msg);
			dispatchEvent(event);							
		}
		
		/**
		 * Overrides and VideoData's onMetaData handler.
		 * By default: false, which allows the actual video width and height
		 * to be saved on the video overriding what is found in the XML data
		 * Set to true, if we should override the onMetaData handler behaviour.  The 
		 * video width and hieght will respect what is given by the database in XML.
		 * @param overrideMeta
		 * 
		 */		
		public function set overrideMetaData( overrideMeta : Boolean ) : void
		{
			_overrideMetaData = overrideMeta;
		}

	    //--------------------------------------
		// INTERNAL LOADER HANDLERS
	    //--------------------------------------
		/**
		 * IO and security error handler 
		 * @param e
		 * 
		 */		
		private function errorHandler( e : Event ) : void
		{
			trace(NAME + "::" + e.type + " occurred: " + e);
			broadcastPlaylistError(e.toString());
		}

	}
}