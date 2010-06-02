package com.topspin.api.data
{
	import com.topspin.api.data.media.ITrackData;
	
	import flash.events.IEventDispatcher;
	
	public interface ITSPlaylist extends IEventDispatcher
	{

		/**
		 * Add a MediaEvent listener to the playlist which 
		 * would handle all ITrackData events coming from
		 * the playlist 
		 * @param mediaEventHandler : Function
		 * 
		 */		
		function addMediaEventListener( mediaEventListener : Function ) : void
			
		/**
		 * remove a MediaEvent handler form the playlist 
		 * 
		 * @param mediaEventHandler : Function
		 * 
		 */		
		function removeMediaEventListener( mediaEventListener : Function ) : void
			
		//current track duration
		/**
		 * Retrieves the campaign id which this playlist belongs to
		 * @return String
		 * 
		 */		
		function getCampaignId() : String; 
		/**
		 * Retrieves the current track data 
		 * @return ITrackData
		 * 
		 */		
		function getCurrentTrack() : ITrackData; 
		/**
		 * Returns the current track index in the playlist 
		 * @return Number - 0 based index 
		 * 
		 */		
		function getCurrentTrackIndex() : Number;
		/**
		 * Returns the nextTrack in the playlist
		 * @return ITrackData - next track
		 * 
		 */		
		function getNextTrack() : ITrackData;	
		/**
		 * Returns the previous track in the playlist 
		 * @return ITrackData object of the previous track
		 * 
		 */		
		function getPreviousTrack() : ITrackData;			
		/**
		 * Returns the number of tracks in the playlist
		 * @return Number of tracks in the playlist
		 * 
		 */		
		function getTotalTracks() : Number;		
		/**
		 * Returns an ordered array of tracks in the playlist 
		 * @return Array of ITrackData objects
		 * 
		 */				
		function getTracks() : Array; 
		/**
		 * Returns the ITrackData based on the track id passed in 
		 * @param id
		 * @return 
		 * 
		 */			
		function getTrackById(id:String) : ITrackData;		
		/**
		 * Returns the ITrackData based on the index of the playlist. 
		 * Playlist index is 0-based
		 * @param Number - index of the playlist
		 * @return ITrackData object
		 * 
		 */			
		function getTrackByIndex( index : uint ) : ITrackData;
		/**
		 * Returns an array of ITrackData object ids 
		 * @return Array of ids
		 * 
		 */
		function getTrackIds() : Array;		
		/**
		 * Returns all tracks based on its media type
		 * @param mediaType :  Acceptable types: audio ||video
		 * @return array of ITrackData
		 * 
		 */		
		function getTracksByMediaType( mediaTypeString : String ) : Array;
		/**
		 * Returns the current tracks duration in milliseconds 
		 * @return Duration in milliseconds
		 * 
		 */		
		function getTrackDuration() : Number;
		/**
		 * Returns the current track playhead position 
		 * @return Position in milliseconds
		 * 
		 */		
		function getTrackPosition() : Number;	
		/**
		 * Indicates whether track data exists for the playlist 
		 * @return Boolean 
		 * 
		 */		
		function hasData() : Boolean; 			
		/**
		 * Indicates whether the currentTrack is the last track of the
		 * playlist or not.
		 * @return Boolean
		 * 
		 */		
		function isLastTrack() : Boolean;		
		//Playback
		/**
		 * Play the the current ITrackData 
		 * @param quality: String value of the type of stream to play:  "LOW" || "MEDIUM" || "HIGH"
		 * 			This is negligible for an audio track, but for video, MEDIUM and HIGH will
		 * 			play H.264 streams, while LOW will play an flv.
		 * @param checkPolicyFile Boolean - set to true if intended for compute spectrum or any other
		 * 			type of permission required operation.  Sent into a SoundLoaderContext object when loading media
		 * @note 	http://www.adobe.com/livedocs/flash/9.0/ActionScriptLangRefV3/flash/media/SoundLoaderContext.html
		 */
		function playTrack( quality : String = "HIGH", checkPolicyFile : Boolean = false) : void; 

		/**
		 * Given a track id, will set, load, and play the current track 
		 * @param track_id: String track id 
		 * @param quality: String value of the type of stream to play:  "LOW" || "MEDIUM" || "HIGH"
		 * 			This is negligible for an audio track, but for video, MEDIUM and HIGH will
		 * 			play H.264 streams, while LOW will play an flv.
		 * @param checkPolicyFile Boolean - set to true if intended for compute spectrum or any other
		 * 			type of permission required operation.
		 * @note 	http://www.adobe.com/livedocs/flash/9.0/ActionScriptLangRefV3/flash/media/SoundLoaderContext.html
		 * 		 
		 */		
		function playTrackById( track_id : String = null, quality : String = "HIGH", checkPolicyFile : Boolean = false) : void;		
		/**
		 * Pauses the current track and keeps the track in buffer 
		 * 
		 */		
		function pauseTrack() : void;
		/**
		 * Returns the first item in the list. 
		 * @return ITrackData : first item in the playlist
		 * 
		 */		
		function resetPlaylist() : ITrackData;	
		/**
		 * Sets the position of the current track  in seconds
		 * @param seconds
		 * 
		 */		
		function seekTo( seconds : Number ) : void;				
		/**
		 * Stops the current track. If track is downloading, will close the net stream
		 * connection and clean up any listeners.
		 * 
		 */		
		function stopTrack() : void;
			
		
//		function toggleMedia() : void;
//		function stopAllMedia() : void;
//		function setVolume(vol : Number ) : void;  //0-100
//		function getVolume() : Number;

	}
}