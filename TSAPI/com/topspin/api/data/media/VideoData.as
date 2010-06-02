/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Video acts as a wrapper for a Track with media type VIDEO. It is composed
 * of a NetConnection and NetStream object and implicitly manages any Player
 * Events that need to be fired for Topspin metrics.  It implements the
 * ITrackData interface and thus can be used in an Topspin media player.
 * 
 *  
 * @copyright	Topspin 
 * @author		amehta@topspinmedia.com
 * @see 		com.topspin.data.model.ITrackData
 * @see 		com.topspin.data.model.AudioData
 *
 */
package com.topspin.api.data.media
{
	import com.topspin.api.events.MediaEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSEvents;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class VideoData extends EventDispatcher implements ITrackData
	{
		public static var NAME : String = "VideoData";		
		/**
		* Main track class that this AudioData is wrapping by composition.
		*/		
		protected var _track:Track;
		
		//Config properties
		/**
		 *  Number of milliseconds used for the LOG_PLAY_TIME
		 */		
		//Internal members used to track player events
		private var trackPlayed : Boolean = false;
		//play states members and such
		private var _loadInitiated : Boolean = false;
		private var _inited : Boolean = false; 
		private var _playing : Boolean = false;
		private var _overrideMetaData : Boolean = false;
		//Main Video object necc for play		
		private var _ns : NetStream;
		private var _nc : NetConnection;
		private var _metaData : Object;
		private var _isBufferingStream : Boolean = false;		

		//Kinda hacky, but a way to determine which PLAYED event should be fired
		private var _autoplay : Boolean = false;

		//Quality of the stream
		protected var _quality : String;
		protected var _checkForPolicyFile:Boolean = false;		
		protected var _bufferTime : Number = 5;

		//public members
		//play status members and such
		public var _timesPlayed : Number = 0;
		public var _position : Number;
	
		/**
		 *Constructor  
		 * 
		 */	
		public function VideoData() {

			//Default values
			_inited = false;
			_position = 0; 
			_timesPlayed = 0;
		}
		
		//Interface implementation
		/**
		 * getId refers to the _track.track_ID 
		 * @return 
		 * 
		 */		
		public function getId() : String {
			return _track.getId();
		}
		/**
		 * Return the track 
		 * @return Track
		 * 
		 */			
		public function getTrack() : Track {
			return _track;
		}
		/**
		 * Returns a hashed object of 
		 * all major properties in the Track
		 * object 
		 * @return Object 
		 * 
		 */			
		public function getTrackInfo() : Object
		{
			var info : Object = {
					"id" : track.id,
					"type" : "video",
					"title" : track.title,
					"playlistIndex" : track.playlistIndex,
					"width" : track.width,
					"height" : track.height,
					"duration" : track.duration,
					"artist" : track.artistName,
					"artist_id" : track.artistId,
					"stream_url" : track.getOptimizedVideoURL(),
					"image_small_url" : track.image_small_url,
					"image_medium_url" : track.image_medium_url,
					"image_large_url" : track.image_large_url
			}
			return info;				
		}		
		/**
		 * Sets the track of this object 
		 * @param Track
		 * 
		 */			
		public function setTrack(o : Track) : void {
			_track = o;
			
			if (track.maxPlays == 0)
			{
				track.expired = true;
			}
		}
		/**
		 * Getter for the track function 
		 * @return 
		 * 
		 */	
		private function get track():Track {
			return _track;
		}
					
		//Interface implementation		
		/*******************************************
		 ** PLAYBACK CONTROLS                   
		 ******************************************/
		/**
		 * Public api call to the ITrackData 
		 * 
		 */	
		public function playMedia( quality : String = "HIGH" ):void {
			_quality = (quality) ? quality : Track.QUALITY_HIGH;
			if (!_inited)
			{
				loadMedia();
			}else{
				playPauseMedia();			
			}
		}
		/**
		 * Public api call to the ITrackData 
		 * 
		 */		
		public function pauseMedia():void {
			_ns.pause();
			_playing = false;
		}		
		/**
		 * Public api call to the ITrackData 
		 * 
		 */			
		private function playPauseMedia() : void {
			trace(NAME + ": playPauseMedia");
			if (!_inited )
			{
				loadMedia();
			}else{
				if (_playing) {
					_position = _ns.time;
					_ns.pause();			
					_playing = false;
				}else{
					//Else start the playing at where it stopped
					_ns.resume();
					_playing = true;
				}
			}				
		}

		/**
		 * Public interface method to stop the 
		 * audio and perform internal actions. 
		 * 
		 */						
		public function stopMedia() : void {
			trace(NAME + ": StopMedia()");
			if (!_ns) return;
			_ns.pause(); //close();
			_ns.seek(0);
			_playing = false;
		}	
		
		////
		/**
		 * Returns the bytesLoaded when loading 
		 * a Sound object 
		 * @return int - bytesloaded 
		 * 
		 */	
		public function getBytesLoaded() : int
		{
			var bLoaded : Number = 0;
			if (isReady())
			{
				bLoaded = _ns.bytesLoaded;
			}
			return bLoaded;
		}		
		/**
		 * Returns the total bytes of the Sound
		 * object.
		 * @return int - total bytes 
		 * 
		 */			
		public function getBytesTotal() : int
		{
			var bTotal : Number = 0;
			if (isReady())
			{
				bTotal = _ns.bytesTotal;
			}			
			return bTotal;
		}				
		/**
		 * Duration is returned in milliseconds 
		 * @return Number - milliseconds
		 * 
		 */	
		public function getDuration() : Number
		{
			var duration : Number = track.duration;
			if (track.expired)
			{
				duration = (duration < track.previewDuration) ? duration : track.previewDuration;
			}
			return duration;			
		}
		/**
		 * NetStream time is measured in seconds.
		 * To keep it consistent with ITrackData, we multiply
		 * it by 1000 to convert it to milliseconds 
		 * @return Number - milliseconds
		 * 
		 */		
		public function getElapsedTime() : Number
		{
			var time : Number = 0;
			if (isReady())
			{
				time = _ns.time * 1000;
			}
			return time;
		}
		/**
		 * Returns the Poster image url based on the
		 * size string passed in. 
		 * @param size : String - small || medium || large
		 * @return URL path to an image, if none is found, null is 
		 * 		   passed back
		 * 
		 */				
		public function getPosterImageUrl( size : String = "small") : String
		{
			var url : String;
			if (size == "small") url = track.image_small_url;
			if (size == "medium") url = track.image_medium_url;
			if (size == "large") url = track.image_large_url;
			if (!url || url == "")
			{
				url = track.imageURL;
			}
			return url;
		}		
		/**
		 * Returns the title of the track 
		 * @return String
		 * 
		 */
		public function getTitle() : String
		{
			return track.title;
		}		
		/*******************************************
		 ** UTILITY METHODS                       
		 ******************************************/
		/**
		 * Check whether file is buffering 
		 * @return boolean
		 * 
		 */		
		public function isBuffering() : Boolean
		{
			if (!_ns) return false;
			return _isBufferingStream;
		}
		
		/**
		 * Indicates that the media is playing 
		 * @return Boolean - true if the media is playing
		 * 
		 */	
		public function isPlaying() : Boolean
		{
			return _playing;
		}
		
		/**
		 * Indicates that the media is prebuffered
		 * and ready to play.
		 * @return Boolean - true if the media is ready to play
		 * 
		 */	
		public function isReady() : Boolean
		{
			return _inited;
		}
		/**
		 * ITrackData interface 
		 * @return Boolean = true
		 * 
		 */		
		public function isVideo() : Boolean
		{
			return true;
		}
		
		/**
		 * Public getter of the NetStream object
		 * @return NetStream
		 * 
		 */
		public function get ns() : NetStream 
		{
			return _ns;
		}		
		/**
		 * Sets the _autoplay property, to indicate
		 * what type of play event to fire off. 
		 * @param Boolean
		 * 
		 */		
		public function setAutoPlay( autoplay : Boolean = false) : void
		{
			_autoplay = autoplay;
		}			
		/**
		 * Sets the position of the video based on a time sent to the
		 * player. pos is in milliseconds
		 * @param Number - milliseconds
		 * 
		 */				
		public function setMediaPosition( pos : Number ) : void
		{
			if (!isReady()) return;		
			_ns.seek(pos);
		}
		/**
		 * Getter/Setter for checkForPolicyFile property of the SoundLoaderContext.  
		 * Specifies whether Flash Player should check for the existence of a cross-domain policy file 
		 *
		 * @see flash.net.NetStream;
		 *
		 */
		public function get checkForPolicyFile():Boolean
		{
			return _checkForPolicyFile;
		}
		/**
		 * @private (setter)
		 */
		public function set checkForPolicyFile(checkPolicyFile:Boolean):void
		{
			_checkForPolicyFile = checkPolicyFile;
		}	
		/**
		 * Gets or sets buffer time. (milliseconds)
		 */
		public function get bufferTime():Number
		{
			return _bufferTime;
		}
		/**
		 * @private (setter)
		 */
		public function set bufferTime(buffer:Number):void
		{
			_bufferTime = buffer;
		}
		/**
		 * Returns the width of the video, if metadata
		 * is available it will take precendence. 
		 * @return 
		 * 
		 */		
		public function getWidth() : Number
		{
			var w : Number = track.width;
			return w;
		}
		
		/**
		 * Returns the height of the video, if metadata
		 * is available it will take precendence. 
		 * @return 
		 * 
		 */		
		public function getHeight() : Number
		{
			var h : Number = track.height;
			return h;
		}
		/**
		 * Cleans up the VideoData object, resets and nulls
		 * out any listeners, NetConnection and NetStream objects 
		 * 
		 */		
		public function cleanup() : void
		{
			if (!_ns) return;
			_ns.close();
			
			_loadInitiated = false;
			_inited = false;
			_playing = false;
			
			_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);			
			
			_ns = null;
			_nc = null;
		}			
		/**
		 * Getter for the meta data 
		 * @return Object
		 * 
		 */		
		public function get metaData() : Object
		{
			return _metaData;
		}
		/**
		 * Setter for the metadata 
		 * @param info : Metadata object returned upon video load
		 * 
		 */		
		public function set metaData(info : Object) : void
		{
			_metaData = info;
			track.duration = info.duration * 1000;
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
		/*******************************************
		 ** PRIVATE METHODS && HANDLERS                       
		 ******************************************/		
		/**
		 * Loads the media and addListeners. 
		 * 
		 */		
		private function loadMedia() : void
		{
			if (_loadInitiated) return;
			_loadInitiated = true;
			_isBufferingStream = true;
			trace(NAME + ": loadMedia");
			_nc = new NetConnection();
            _nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            _nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);			
			_nc.connect(null);
		}
		/**
		 * Internal method will do the required branching to deliver the proper
		 * stream URL to display depending on the mode this track is in.  If the
		 * track is expired and in preview mode, show only the FLV or small h264 video 
		 * if it exists.  By default, show the optimized h264 video which is large. 
		 * @return url to video
		 * 
		 */		
		private function getVideoURL() : String
		{
			track.quality = _quality;
			var videoURL : String = track.getOptimizedVideoURL();
			
			return videoURL;			
		}
		/**
		 * Internal loading of the netstream 
		 * 
		 */		
		private function connectStream() : void
		{
			trace(NAME + ": NETCONNECTION initiated, play the STREAM Adding netStatusHandler");
			_isBufferingStream = true;
			_ns = new NetStream(_nc);
			_ns.checkPolicyFile = checkForPolicyFile;			
			_ns.bufferTime =  bufferTime;
			_ns.client = this;
			_ns.receiveAudio(true);
			_ns.receiveVideo(true);
			_ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			try {		
				var mediaURL : String = getVideoURL();
				trace(NAME + ": TRY ns.play(mediaURL) : " + mediaURL);
				_ns.play(mediaURL);
			} catch (e : AsyncErrorEvent) {
				trace(e);
			}
		}
		/**
		 * NetstatusHandler which handles the NetConnection and the NetStream 
		 * @param e
		 * 
		 */		
		private function netStatusHandler( e : NetStatusEvent) :void
		{
			switch (e.info.code)
			{
	            case "NetConnection.Connect.Success":
		            _isBufferingStream = true;
	            	trace(NAME + ": NetConnection.Connect.Success _isBufferingStream=" + _isBufferingStream);
                    connectStream();
                    break;
                case "NetStream.Play.StreamNotFound":
                    trace(NAME + ": Stream not found: " + track.mediaURL);
					broadcastLoadErrorEvent();
                    break;			
				case "NetStream.Play.Start":
					trace(NAME + ": NetStream.Play.Start [" + getId() + "] _inited: " + _inited, _playing );
					if (!_inited) 
					{
						_inited = true;
						_playing = true;
					}
					broadcastLoadInitEvent();	
					break;
				case "NetStream.Play.Stop":
					trace(NAME + ": NetStream.Play.Stop [" + getId() + "]");
					_ns.pause();
					_ns.seek(0);
					_playing = false;
					_isBufferingStream = false;
					broadcastMediaCompleteEvent();
					break;
				case "NetStream.Pause.Notify":
					trace(NAME + ":NetStream.Pause.Notify [" + getId() + "]");
					break;
				case "NetStream.Unpause.Notify":
					trace(NAME + ": NetStream.Unpause.Notify [" + getId() + "]");
					break;
				case "NetStream.Buffer.Empty":
					trace(NAME + ": NetStream.Buffer.Empty");
					_isBufferingStream = true;
					break;
				case "NetStream.Buffer.Full":
					trace(NAME + ": NetStream.Buffer.Full");
					_isBufferingStream = false;
					break;
			}
		}
	    /**
	     * Handler for the meta data 
	     * @param info
	     * 
	     */		
	    public function onMetaData(info:Object):void {
	    	trace(NAME + ": onMETADATA");
	    	for (var prop : String in info) 
			{
				trace("\t" + prop + ":\t" + info[prop]);
			}
			
			if (!_overrideMetaData)
			{
				if (info["height"] != null && !isNaN(info["height"])) {
					track.height = Number(info["height"]);
					trace(NAME + ": META SET THE HEIGHT : " + track.height);
				}
				if (info["width"] != null && !isNaN(info["width"])) {			
					track.width = Number(info["width"]);
					trace(NAME + ": META SET THE WIDTH : " + track.width);
				}
			}			
	    	metaData = info;
			dispatchEvent( new MediaEvent(MediaEvent.METADATA, this ) );	
	    }		
	    
		/**
		 * Security handler 
		 * @param event
		 * 
		 */
		private function securityErrorHandler(event:SecurityErrorEvent):void {
            trace(NAME + ":securityErrorHandler: " + event);
			broadcastLoadErrorEvent(NAME + ":securityErrorHandler: " + event);
        }		
		
		/**
		 * Error handler for the sound load. 
		 * @param Event
		 * 
		 */		
		private function broadcastLoadErrorEvent(msg : String = null ):void {
			dispatchEvent( new MediaEvent(MediaEvent.LOAD_ERROR, this, {message : msg}));
		}		
		/**
		 * Dispatch the sound's INIT event 
		 * @param e
		 * 
		 */			
		private function broadcastLoadInitEvent( e : Event = null) : void
		{
			trace(NAME + ": Load INIT");
			_inited = true;	
			dispatchEvent( new MediaEvent(MediaEvent.INIT, this )  );
			logPlayedEvent();
		}
		/**
		 * Broadcasts the videos stream's load complete event 
		 * @param e
		 * 
		 */		
		private function broadcastLoadCompleteEvent( e : Event = null ) : void
		{
			dispatchEvent( new MediaEvent(MediaEvent.LOAD_COMPLETE, this ) );			
		}
		/**
		 * broadcast the media load completion from a SoundChannel
		 * @param e
		 * 
		 */	
		private function broadcastMediaCompleteEvent( e : Event = null) : void
		{
			trace(NAME + " PLAY_COMPLETE");
			dispatchEvent( new MediaEvent(MediaEvent.PLAY_COMPLETE, this ) );
		}	
		/**
		 * Logs a Played event for the track. 
		 * 
		 */		
		private function logPlayedEvent() : void
		{
			if (!trackPlayed)
			{
				trackPlayed = true;	
				if (_autoplay)
				{
					fireLogEvent(TSEvents.TYPE.PLAY, TSEvents.SUBTYPE.PLAY_AUTOPLAY);
				}else{
					fireLogEvent(TSEvents.TYPE.PLAY, TSEvents.SUBTYPE.PLAY_NORMAL);
				}
			}
		}		
		/**
		 * Fire an EventLogger event 
		 * @param eventType
		 * 
		 */		
		private function fireLogEvent( eventType : Number, sub_type : Number = -1 ) : void
		{
			if (sub_type != -1)
			{
				EventLogger.fire(eventType, { artist: track.artistId, track : getId(), play_ms : getElapsedTime(), sub_type : sub_type });	
			}else{
				EventLogger.fire(eventType, { artist: track.artistId, track : getId(), play_ms : getElapsedTime() });	
			}
		}		 		
		

	}
}