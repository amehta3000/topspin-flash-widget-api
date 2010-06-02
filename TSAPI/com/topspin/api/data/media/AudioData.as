/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * AudioData acts as a wrapper for a Track, but contains logic
 * necessary for an Audio sound object to play properly.  It is composed
 * of a Sound and SoundChannel object and implicitly manages any Player
 * Events that need to be fired for Topspin metrics.  It implements the
 * ITrackData inteface and thus can be used in an Topspin media player.
 * 
 *  
 * @copyright	Topspin 
 * @author		amehta@topspinmedia.com
 * @see 		com.topspin.data.model.ITrackData
 * @see 		com.topspin.data.model.VideoData
 *
 */
package com.topspin.api.data.media
{
	import com.topspin.api.events.MediaEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSEvents;
	
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;

	public class AudioData extends EventDispatcher implements ITrackData
	{
		private static var NAME : String = "AudioData";
		/**
		* Main track class that this AudioData is wrapping by composition.
		*  
		*/		
		protected var _track:Track;
		
		/**
		 *  Number of milliseconds used for the LOG_PLAY_TIME
		 */		
		private static var LOG_PLAY_TIME_INTERVAL : Number = 1000;
		public static var SCRUB_DISTANCE : Number = 5;
		
		/**
		 * Internal properties for Sound and SoundChannel
		 */		
		private var _sound : Sound;
		//channel keeps track of the playhead
		private static var _channel : SoundChannel = new SoundChannel(); 			
		protected var _soundLoaderContext:SoundLoaderContext;
		protected var _checkForPolicyFile:Boolean = false;		
		protected var _bufferTime:Number = 1000;
		protected var _ns : NetStream;
		
		//public members
		public var _loaded : Boolean = false;
		
		//play states members and such
		private var _loadInitiated : Boolean = false;
		private var _inited : Boolean;
		private var _playing : Boolean;
		private var _position : Number; 
		private var _timesPlayed : Number = 0;
		private var _quality : String;
		
		//Kinda hacky, but a way to determine which PLAYED event should be fired
		private var _autoplay : Boolean = false;
		
		//Passed in via on init
		private var _playOnLoad : Boolean = true;
		
		//Internal members used to track player events
		private var trackPlayed : Boolean = false;
								
		/**
		 *Constructor  
		 * 
		 */		
		public function AudioData()
		{
			//Default values
			_inited = false;

			_position = 0; 
			_timesPlayed = 0;
			_playOnLoad = false;
			
			setIsPlaying(false);
		}		
		/**
		 * Refers to the _track.track_ID 
		 * @return 
		 * 
		 */		
		public function getId() : String
		{
			return _track.getId();
		}
		/**
		 * Return the track 
		 * @return Track
		 * 
		 */		
		public function getTrack() : Track
		{
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
				"type" : "audio",
				"title" : track.title,
				"playlistIndex" : track.playlistIndex,
				"width" : track.width,
				"height" : track.height,
				"duration" : track.duration,
				"artist" : track.artistName,
				"artist_id" : track.artistId,
				"stream_url" : track.mediaURL,
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
		public function setTrack(o : Track) : void
		{
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
		public function playMedia( quality : String = "HIGH"):void
		{	
			_quality = quality;
			if (!_inited ) //|| !_loaded)
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
		public function pauseMedia():void
		{
			playPauseMedia();
		}
		
		/**
		 * Public api call to the ITrackData 
		 * 
		 */		
		protected function playPauseMedia() : void
		{
			if (!_inited ) //&& !_loaded)
			{
				loadMedia();
			}else{
				if (_playing) {
					_position = _channel.position;
					_channel.stop();					
					setIsPlaying(false);
				}else{
					//Else start the playing at where it stopped
					_channel = _sound.play(_position);
					addPlayerListener();
					setIsPlaying(true);
				}
			}	
		}
		
		/**
		 * Public interface method to stop the 
		 * audio and perform internal actions. 
		 * 
		 */		
		public function stopMedia() : void
		{
			if (!_sound) return;	
			setIsPlaying(false);			
			_position = 0;
			if (_channel) _channel.stop();			
		}		
		
		/////
		/**
		 * Returns the bytesLoaded when loading 
		 * a Sound object 
		 * @return int - bytesloaded 
		 * 
		 */		
		public function getBytesLoaded() : int
		{
			if (_sound != null)
			{
				return _sound.bytesLoaded;
			}else{
				return 0;
			}
		}		
		/**
		 * Returns the total bytes of the Sound
		 * object.
		 * @return int - total bytes 
		 * 
		 */		
		public function getBytesTotal() : int
		{
			if (_sound != null)
			{		
				return _sound.bytesTotal;
			}else{
				return 0;
			}				
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
				duration = track.previewDuration;
			}
			return duration;			
		}		
		/**
		 * Returns the elapsed play time of the track
		 * in milliseconds 
		 * @return Number - milliseconds
		 * 
		 */		
		public function getElapsedTime() : Number
		{
			var elapsed : Number = 0;
			if (_channel != null)  {
				elapsed = _channel.position;
			}
			return elapsed;
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
		 * Returns whether the sound is buffering or not. 
		 * @return boolean
		 * 
		 */		
		public function isBuffering() : Boolean
		{
			if (!_sound) return false;
			
			return _sound.isBuffering;
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
		 * Returns whether ITrackData is of type VideoData 
		 * @return Boolean
		 * 
		 */				
		public function isVideo() : Boolean
		{
			return false;
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
		 * Sets the channel position that the current track should be 
		 * set at - pos is in milliseconds
		 * @param pos Number in milliseconds
		 * 
		 */		
		public function setMediaPosition( pos : Number ) : void
		{
			if (!_channel || !_sound) return;
			if (pos < _track.duration && pos >=0 ) 
			{
				if ( isPlaying() )
				{
					_channel.stop();
					_channel = _sound.play(pos);	
					addPlayerListener();		
				} else {
					_channel = _sound.play(pos);
					addPlayerListener();
					_position = _channel.position;
					_channel.stop();
				}
			} 
		}		
		/**
		 * Getter/Setter for checkForPolicyFile property of the SoundLoaderContext.  
		 * Specifies whether Flash Player should check for the existence of a 
		 * cross-domain policy file 
		 *
		 * @see flash.media.SoundLoaderContext;
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
		 * Sets an internal flag indicating whether
		 * it is playing ot not 
		 * @param playing
		 * 
		 */		
		private function setIsPlaying( playing : Boolean) : void
		{
			_playing = playing;
		}
		
		/**
		 * Loads the media and addListeners. 
		 * 
		 */		
		public function loadMedia() : void
		{
			//This is so the song is only loaded once
			if (_loadInitiated) return;  
			_loadInitiated = true;
			trace("-AudioData.loadMedia[" + _track.title + "] mediaUrl: " + _track.mediaURL);
			var loaderContext : LoaderContext = new LoaderContext(_checkForPolicyFile);
			var req:URLRequest = new URLRequest(_track.mediaURL);
			_sound = new Sound();
			_sound.addEventListener(Event.OPEN, broadcastLoadInitEvent);
			//got rid of the ID3 event.
			_sound.addEventListener(Event.COMPLETE, broadcastLoadCompleteEvent);
			_sound.addEventListener(ProgressEvent.PROGRESS, broadcastLoadProgressEvent);			
			_sound.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			 
			try {
				_soundLoaderContext = new SoundLoaderContext(bufferTime, _checkForPolicyFile);
				_sound.load(req, _soundLoaderContext);
				_channel = _sound.play();	
				addPlayerListener();
				
			} catch (err:Error) {
				_loadInitiated = false;
				trace(err.message);
			}
		}
		/**
		 * Public getter of the SoundChannel object 
		 * @return SoundChannel
		 * 
		 */
		public function get channel() : SoundChannel
		{
			return _channel;
		}			
		/**
		 * Public getter of the internal sound object 
		 * @return Sound
		 * 
		 */		
		public function get sound() : Sound
		{
			return _sound;
		}		
		/**
		 * Public getter of the NetStream object, ITrackData interface
		 * @return NetStream
		 * 
		 */
		public function get ns() : NetStream 
		{
			return _ns;
		}
		/**
		 * Returns the width of the video, if metadata
		 * is available it will take precendence. 
		 * @return 
		 * 
		 */		
		public function getWidth() : Number
		{
			return -1;
		}
		/**
		 * Returns the height of the video, if metadata
		 * is available it will take precendence. 
		 * @return 
		 * 
		 */		
		public function getHeight() : Number
		{
			return -1;
		}	
		/**
		 * Cleanup the loaders and reset the internal
		 * state of the player 
		 * 
		 */		
		public function cleanup() : void
		{
			if (!_sound) return;		
			_position = 0;
			if (_channel) _channel.stop();			
			_loadInitiated = false;
			_inited = false;
			_loaded = false;
			if (_sound.bytesLoaded < _sound.bytesTotal)
			{
				try {
					_sound.close();
				} catch (err:IOError) {
					trace(NAME + ": stopMedia() : " + err.message);
				}		
			}			
			_sound.removeEventListener(Event.ID3, broadcastLoadInitEvent);
			_sound.removeEventListener(Event.COMPLETE, broadcastLoadCompleteEvent);
			_sound.removeEventListener(ProgressEvent.PROGRESS, broadcastLoadProgressEvent);			
			_sound.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			_sound = null;
			_channel = null;
		}		
			
		/*******************************************
		 ** HANDLERS                       
		 ******************************************/
        /**
         * Error handler for the sound load. 
         * @param errorEvent
         * 
         */		
        private function errorHandler(errorEvent:IOErrorEvent):void {
            trace("-AUDIODATA.The sound could not be loaded: " + errorEvent.text);
            dispatchEvent( new MediaEvent(MediaEvent.LOAD_ERROR, this));
        }
		/**
		 * Dispatch the sound's INIT event 
		 * @param e
		 * 
		 */	
		private function broadcastLoadInitEvent( e : Event = null) : void
		{
			trace("-AUDIODATA.broadcastLoadInitEvent id["  + track.id  + "] duration [" + _track.duration + "] sound.length[" + _sound.length + "] isBuffering " + _sound.isBuffering);						
			setIsPlaying(true);
			_inited = true;	
			e.target.removeEventListener( e.type, broadcastLoadInitEvent)
			dispatchEvent(  new MediaEvent(MediaEvent.INIT, this ) );
			logPlayedEvent();			
		}
		/**
		 * Dispatch the sound's COMPLETE event 
		 * @param e
		 * 
		 */		
		private function broadcastLoadCompleteEvent( e : Event = null ) : void
		{
			_track.duration = _sound.length;
			_loaded = true;
			trace("-AUDIODATA.broadcastLoadCompleteEvent id["  + track.id  + "] duration [" + _track.duration + "] sound.length[" + _sound.length + "]" );						
			dispatchEvent( new MediaEvent(MediaEvent.LOAD_COMPLETE, this ) );			
//			dispatchEvent( e );
		}
		/**
		 * broadcast load progress event 
		 * @param e
		 * 
		 */		
		private function broadcastLoadProgressEvent( e : ProgressEvent = null) : void
		{
			dispatchEvent( e );
		}
		/**
		 * broadcast the media load completion from a SoundChannel
		 * @param e
		 * 
		 */					
		private function broadcastMediaCompleteEvent( e : Event = null) : void
		{
			trace(NAME + " SOUND_COMPLETE dispatch MediaEvent.PLAY_COMPLETE");
			dispatchEvent( new MediaEvent(MediaEvent.PLAY_COMPLETE, this ) );
		}		
		/**
		 * Internal listener that will set up an event listner
		 * on the SoundChannel and listen for SOUND_COMPLETE.
		 * Since this is triggered anytime a Sound is played, it
		 * is also a ideal location to start the internal player time
		 * to track and log the amount of time the track is playing 
		 * for. 
		 * 
		 */		
		private function addPlayerListener() : void
		{
			if (_channel.hasEventListener(Event.SOUND_COMPLETE)) {
				_channel.removeEventListener(Event.SOUND_COMPLETE,broadcastMediaCompleteEvent);
			}
			_channel.addEventListener(Event.SOUND_COMPLETE,broadcastMediaCompleteEvent);
		}
		/**
		 * Logs a play event, once per session.
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