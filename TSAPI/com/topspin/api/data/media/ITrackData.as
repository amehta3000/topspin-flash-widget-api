/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * ITrackData is a public interface that all playable Topspin media types 
 * implement.  AudioData & VideoData implement this interface
 * and include additional logging to Topspin servers for data tracking
 *  
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 * 
 */
package com.topspin.api.data.media
{
	import flash.events.IEventDispatcher;
	import flash.net.NetStream;
	
	public interface ITrackData extends IEventDispatcher
	{
		//Data
		/**
		 * Returns the uri/id of the ITrackData 
		 * @return 
		 * 
		 */		
		function getId() : String;
		/**
		 * Returns the underlying Track object in all
		 * ITrackData instances 
		 * @return 
		 * 
		 */
		function getTrack() : Track;
		/**
		 * Returns a hashed object of 
		 * all major properties in the Track
		 * object 
		 * @return Object 
		 * 
		 */		
		function getTrackInfo() : Object
		/**
		 * Sets the internal Track object in the ITrackData 
		 * @param _track
		 * 
		 */		
		function setTrack( _track : Track) : void;
		
		//Playback Methods
		/**
		 * Plays a track.  If track is not ready, will
		 * load the stream, wait for the buffer time
		 * and begin to play.  If the track has been 
		 * paused and playMedia is called, track will
		 * begin playing from the point it was paused. 
		 * @param quality : Quality of the stream 
		 * 					"LOW"||"MEDIUM"||"HIGH"
		 * 
		 */		
		function playMedia(quality : String = "HIGH") : void;
		/**
		 * Pauses the media at a give point 
		 * 
		 */
		function pauseMedia() : void;
		/**
		 * Method to stop the stream.  Stream
		 * will stop downloading and close 
		 * any open net connections if applicable. 
		 * 
		 */			
		function stopMedia() : void;
		
		//Properties
		/**
		 * Returns the number of bytes loaded 
		 * @return int
		 * 
		 */		
		function getBytesLoaded() : int;
		/**
		 * Returns to the total bytes 
		 * @return int
		 * 
		 */		
		function getBytesTotal() : int;
		/**
		 * Duration of track in milliseconds 
		 * @return Track duration in milliseconds
		 * 
		 */		
		function getDuration() : Number;
		/**
		 * Returns the elapsed play time of the track
		 * in milliseconds 
		 * @return Number - milliseconds
		 * 
		 */				
		function getElapsedTime() : Number;
		/**
		 * Returns the Poster image url based on the
		 * size string passed in. 
		 * @param size : String - small || medium || large
		 * @return URL path to an image, if none is found, null is 
		 * 		   passed back
		 * 
		 */		
		function getPosterImageUrl( size : String = "small") : String

		/**
		 * Returns the title of the track 
		 * @return String
		 * 
		 */
		function getTitle() : String
		/**
		 * Returns whether track is buffering before the stream is played 
		 * @return Boolean
		 * 
		 */		
		function isBuffering() : Boolean;
		/**
		 * Returns whether a track is playing or not 
		 * @return Boolean
		 * 
		 */		
		function isPlaying() : Boolean;
		/**
		 * Returns whether a track isReady, eg. loaded and ready to play 
		 * @return Boolean
		 * 
		 */		
		function isReady() : Boolean;
		/**
		 * Returns whether ITrackData is of type VideoData 
		 * @return Boolean
		 * 
		 */		
		function isVideo() : Boolean;
		/**
		 * Sets an autoplay flag, so that once the track is loaded, will either begin playing or not 
		 * @param autoplay : boolean
		 * 
		 */		
		function setAutoPlay( autoplay : Boolean = false) : void;
		/**
		 * Sets the position of the playhead for the track based on seconds 
		 * @param pos : Number in seconds
		 * 
		 */		
		function setMediaPosition( pos : Number ) : void 

		//Getter / Setter
		/**
		 * Check policy file when loading media so that permission based operations
		 * may take place in widget. 
		 * @param checkPolicyFile : Boolean 
		 * 
		 */			
		function set checkForPolicyFile( checkPolicyFile : Boolean ) : void;
		function get checkForPolicyFile() : Boolean;

		/**
		 * Set the buffer time before a track begins to stream 
		 * @param buffer
		 * 
		 */
		function set bufferTime( buffer : Number ) : void;
		function get bufferTime() : Number;
		
		/**
		 * VideoData
		 * Returns the net stream object being used so that 
		 * it may be added to a video object for video playback.
		 * Only works if isVideo() returns true.
		 * @return NetStream object 
		 * 
		 */		
		function get ns() : NetStream;
		/**
		 * VideoData
		 * Returns the video object width from
		 * the xml data.  Also once METADATA event
		 * is fired, the width will be pulled in
		 * from the metadata of the video object
		 * @return width Number 
		 * 
		 */		
		function getWidth() : Number;
		/**
		 * VideoData
		 * Returns the video object height from
		 * the xml data.  Also once METADATA event
		 * is fired, the width will be pulled in
		 * from the metadata of the video object
		 * @return h Number 
		 * 
		 */		
		function getHeight() : Number;	

		/**
		 * Removes all listeners and deleted any netstream object if
		 * applicable. 
		 * 
		 */		
		function cleanup() : void;
	}
	
}