/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 *  Track is the model object that all classes implementing the ITrackData 
 *  interface will contain.  It contains metadata about the track
 * 	(ie.  artist, copyright, play status, expiration, etc)
 *  Encapsulated by AudioData & VideoData classes
 *  so that they may be handled appropriately.
 * 	Each with its own type MEDIA_TYPE to make the distinction
 *  
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 * 
 */
package com.topspin.api.data.media
{
	import flash.utils.describeType;
	
	public class Track
	{
		private static var VERSION : String = "1.0.0";
		
		//static values for the the possible media type of a track.
		static public const MEDIA_TYPE_AUDIO : Number = 1;
		static public const MEDIA_TYPE_VIDEO : Number = 4;
		static public const MEDIA_TYPE_IMAGE : Number = 2;
		
		//quality of video being played
		static public const QUALITY_HIGH : String = "HIGH";
	    static public const QUALITY_MEDIUM : String = "MEDIUM";
	    static public const QUALITY_LOW : String = "LOW";
	
		private var _quality : String = "HIGH";
		
		//Reference to this track's parent trackData
		private var _trackData : ITrackData;
		
		//Properties of track - Topspin metadata
		private var _mediaType:Number;						//Track constant
		private var _imageURL:String = "";					//URL to a related image
		private var _mediaURL:String = "";					//URL to media

		private var _id:String;								//REST Style id string
		private var _title:String;							//track title			
		private var _price:String;							//price of individual track
		private var _duration:Number = 0;					//duration in seconds
		private var _maxPlays:Number = 0;					//maximum number of plays before preview ode
		
		private var _playlistIndex : Number;				//current playlist index
		private var _initPlaylistIndex : Number;			//the initial Playlist index, 0 based
		
		//track artist info
		private var _artistId : String;						//REST style artist id
		private var _artistName:String;						//Artist name

		//Video and Image Specific
		private var _width : Number = 320;					//default width
		private var _height : Number = 240;					//default height

		//Properties may be non-null for video tracks
		private var _h264_large_URL : String;				//hi res default h264 video
		private var _h264_small_URL : String;				//smaller default h264 video

		public var image_small_url : String;				//image small
		public var image_medium_url : String;				//image medium 
		public var image_large_url : String;				//image large
		
		
		//track ratings
		private var _expired:Boolean = false;					//expired, means track is in preview mode
			
		//Duration of a preview for a track.
		private var _previewDuration:Number = 30000;			//preview duration, currently set at 30 seconds
		/**
		 * Play status is sent via the set_list_xml.
		 * n == n number of plays till the track shifts to preview mode.
		 * 0 == expired, only preview duration will play
		 * -1 == unlimited full length plays
		 */
		private var _playStatus:Number = 0;				
		/**
		 * totalElapsedTime refers to an internal elapsed time, 
		 * used to log events indicating that a track has been 
		 * played. 
		 */ 
		private var totalElapsedTime:Number = 0;
		//
		//Flags set by a Controller
		private var _timesPlayed:Number;

		/**
		 * Constructor 
		 * 
		 */		
		public function Track() {}		
		
		////////////////////////////////////////////
		// GETTER SETTERS                       
		////////////////////////////////////////////
		
		public function getId() : String
		{
			return _id;
		}
		
		public function get id():String {
			return _id;
		}

		public function set id(o:String):void {
			_id = o;
		}		

		public function get title():String {
			if (_title == null || _title == "null") _title = "";
			return _title;
		}

		public function set title(o:String):void {
			_title = o;
		}
		 
		public function get playStatus():Number {
			return _playStatus;
		}

		public function set playStatus(o:Number):void {
			_playStatus = o;
		}

		public function get duration():Number {
			return _duration;
		}

		public function set duration(o:Number):void {
			_duration = o;
		}

		public function get previewDuration():Number {
			return _previewDuration;
		}

		public function set previewDuration(o:Number):void {
			_previewDuration = o;
		}

		public function get maxPlays():Number {
			return -1;
		}

		public function set maxPlays(o:Number):void {
			_maxPlays = o;
		}

		public function get expired():Boolean {
			return _expired;
		}

		public function set expired(o:Boolean):void {
			_expired = o;
		}

		//Meta data
		public function get artistId():String {
			return _artistId;
		}

		public function set artistId(o:String):void {
			_artistId = o;
		}
		
		public function get artistName():String {
			return _artistName;
		}

		public function set artistName(o:String):void {
			_artistName = o;
		}
		
		public function get imageURL():String {
			return _imageURL;
		}

		public function set imageURL(o:String):void {
			_imageURL = o;
		}

		public function set h264_large_URL(o:String):void {
			_h264_large_URL = o;
		}

		public function get h264_large_URL():String {
			return _h264_large_URL;
		}
		
		public function set h264_small_URL(o:String):void {
			_h264_small_URL = o;
		}

		public function get h264_small_URL():String {
			return _h264_small_URL;
		}

		public function get mediaURL():String {
			return _mediaURL;
		}

		public function set mediaURL(o:String):void {
			_mediaURL = o;
		}

		/**
		 * Returns the optimized video media URL, checks whether
		 * for large, then small, then flv and passed back the 
		 * highest quality file. 
		 * @return 
		 * 
		 */		
		public function getOptimizedVideoURL() : String
		{
			var mURL : String = mediaURL;
			switch (quality) {
 				case QUALITY_HIGH:
					trace("Track.getOptimizedVideoURL() : QUALITY HIGH"); 
					if (h264_large_URL != null && h264_large_URL.length > 0) {
						trace("Track.getOptimizedVideoURL() : H264 Large"); 
						mURL = h264_large_URL;				
					}else if (h264_small_URL != null && h264_small_URL.length > 0 )  {
						trace("Track.getOptimizedVideoURL() : H264 Small"); 
						mURL = h264_small_URL;	
					}else {
						trace("Track.getOptimizedVideoURL() : FLV"); 
					}
					break;
				case QUALITY_MEDIUM:
					trace("Track.getOptimizedVideoURL() : QUALITY MEDIUM"); 
					if (h264_small_URL != null && h264_small_URL.length > 0 )  {
						trace("Track.getOptimizedVideoURL() : H264 Small"); 
						mURL = h264_small_URL;	
					}else {
						trace("Track.getOptimizedVideoURL() : FLV"); 
					}				
					break;
				case QUALITY_LOW:
					trace("Track.getOptimizedVideoURL() : QUALITY LOW"); 			
					trace("Track.getOptimizedVideoURL() : FLV"); 
					//Because the video may not be available, go back up the chain
					if (!mURL) {
						mURL = h264_small_URL;
						trace("Track.getOptimizedVideoURL() : LOW NOT FOUND -> SET QUALITY MEDIUM"); 			
						trace("Track.getOptimizedVideoURL() : H264 Small"); 
					} 
					if (!mURL) {			
						mURL = h264_large_URL;
						trace("Track.getOptimizedVideoURL() : MEDIUM NOT FOUND -> SET QUALITY HIGH"); 			
						trace("Track.getOptimizedVideoURL() : H264 Large"); 
					}
					break;
			}
			
			return mURL;
		}
		/**
		 * Returns the preview video media URL.  Only a 
		 * smaller h264 video will be shown on preview mode.
		 * @return 
		 * 
		 */		
		public function getPreviewVideoURL() : String
		{
			var mURL : String = mediaURL;
			if (h264_small_URL != null && h264_small_URL.length > 0 )  {
				trace("Track.getPreviewVideoURL() : H264 Small"); 
				mURL = h264_small_URL;	
			}else {
				trace("Track.getPreviewVideoURL() : FLV"); 
			}
			return mURL;
		}
		public function get mediaType():Number {
			return _mediaType;
		}

		public function set mediaType(o:Number):void {
			_mediaType = o;
		}

		public function get timesPlayed():Number {
			return _timesPlayed;
		}

		public function set timesPlayed(o:Number):void {
			_timesPlayed = o;
		}
		
		public function get playlistIndex():Number {
			return _playlistIndex;
		}

		public function set playlistIndex(o:Number):void {
			_playlistIndex = o;
		}		
		
		public function get initPlaylistIndex():Number {
			return _initPlaylistIndex;
		}

		public function set initPlaylistIndex(o:Number):void {
			_initPlaylistIndex = o;
		}			
		
		public function get width():Number {
			return _width;
		}

		public function set width(o:Number):void {
			_width = o;
		}		
		
		public function get height():Number {
			return _height;
		}

		public function set height(o:Number):void {
			_height = o;
		}		
		
		public function get quality():String {
			return _quality;
		}

		public function set quality(o:String):void {
			_quality = o;
		}		
		
		
		public function toString() : String {
			
			var str : String = "TRACK: [id:" + id + "]\n";
			var varXML : XML = flash.utils.describeType(this);
			var varList:XMLList = flash.utils.describeType(this)..accessor;
			for(var i:int; i < varList.length(); i++){
				//Show the name and the value
               str += "[" + varList[i].@name+':'+ this[varList[i].@name] + "]\n";
            }
            str += "---";
			return (str);								
			
		}
	
	}
}