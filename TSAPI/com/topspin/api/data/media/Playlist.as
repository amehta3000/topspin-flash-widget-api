package com.topspin.api.data.media
{
	import com.topspin.api.data.ITSPlaylist;
	import com.topspin.api.data.TSPlaylistAdapter;
	import com.topspin.api.events.MediaEvent;
	import com.topspin.api.events.TSPlaylistAdapterEvent;
	import com.topspin.api.logging.EventLogger;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	public class Playlist extends EventDispatcher implements ITSPlaylist
	{
		
		private static var NAME : String = "Playlist";	
		//Campaign id that this play list belongs
		private var _campaignId : String;
		//Interal parser of playlist
		private var _tsAdapter : TSPlaylistAdapter;
		//Array of tracks
		private var _tracks : Array;
		//Dictionary hashed by ITrackData Id
		private var _playlistMap : Dictionary;
		//Order of the playlist
		private var _playlistOrder : Array;
		//The current Index in the playlist of the current ITrackData
		private var _currentPlaylistIndex : Number;
		//The current ITrackData that is being played or is loaded in the playlist
		private var _currentTrackData : ITrackData;

		private var _mediaEventListener : Function;
		//internal ITrackData that keeps track of the track that was just played
		//additional action need to be made on that track, like stopping it and reseting
		private var _previousTrack : ITrackData;		
		
		
		private var _data : XML;
		
		public function Playlist( campaignId : String)
		{
			_campaignId = campaignId;
			init();
		}
		/**
		 * Add the listeners to an instance if 
		 * TSPlaylistAdapter as well as initialize the internal objects used
		 * for the playlist management. 
		 * 
		 */		
		private function init() : void
		{
			//Setting the campaign id on the Playlist
			//ensures that tracks log play events with
			//the proper camapaign.
			if (EventLogger.getInstance().enabled)
			{
				EventLogger.setCampaign(_campaignId);
			}
			
			//TSPlaylistAdapter API implementation
			_tsAdapter = TSPlaylistAdapter.getInstance();
			_tsAdapter.addEventListener(TSPlaylistAdapterEvent.PLAYLIST_COMPLETE, handlePlaylistLoad);
			_tsAdapter.addEventListener(TSPlaylistAdapterEvent.PLAYLIST_ERROR, handlePlaylistError);

			//internal tracking mechanism
			_tracks = new Array();
			_playlistMap = new Dictionary();
			_playlistOrder = new Array();
			_currentPlaylistIndex = 0;
		}	
		/**
		 * Sets the xml data to be parsed via the 
		 * adapter. 
		 * @param xml
		 * 
		 */		
		public function load( _xml : XML ): void
		{
			trace(NAME + ": load: " + _xml);
			_tsAdapter.parse(_xml);
		}

		/**
		 * Handler for the TSPlaylistAdapter load COMPLETE 
		 * @param e
		 * 
		 */		
		private function handlePlaylistLoad( e : TSPlaylistAdapterEvent) : void
		{
			_tsAdapter.removeEventListener(TSPlaylistAdapterEvent.PLAYLIST_COMPLETE, handlePlaylistLoad);
			_tsAdapter.removeEventListener(TSPlaylistAdapterEvent.PLAYLIST_ERROR, handlePlaylistError);	
					
			var arr : Array = e.data as Array;
			var t : ITrackData;
			//Populate our internal maps and order sequence
			//used for multiple tracks being loaded.
			for (var i : Number=0; i < arr.length ; i++)
			{				
				t = arr[i] as ITrackData;			
				if (_playlistMap[t.getId()] == null)
				{
					_playlistMap[t.getId()] = t;
					_playlistOrder.push(t.getId());		
					_tracks.push(t);
				}
			}
			//Tell the DataManager that you are DONE...
			dispatchEvent(new Event(Event.COMPLETE));
		}		
		/**
		 * Handler for the TSPlaylistAdapter error
		 * @param e
		 * 
		 */		
		private function handlePlaylistError( e : TSPlaylistAdapterEvent) : void
		{
			_tsAdapter.removeEventListener(TSPlaylistAdapterEvent.PLAYLIST_COMPLETE, handlePlaylistLoad);
			_tsAdapter.removeEventListener(TSPlaylistAdapterEvent.PLAYLIST_ERROR, handlePlaylistError);			
			log("TSPlaylistAdapter Load Error : " + e.data);
		}		

		//////////////////////////////////////////////////////
		//
		// PUBLIC METHODS - ITSPlaylistApi
		//
		//////////////////////////////////////////////////////
		/**
		 * Add a MediaEvent listener to the playlist which 
		 * would handle all ITrackData events coming from
		 * the playlist 
		 * @param mediaEventHandler : Function
		 * 
		 */		
		public function addMediaEventListener( mediaEventListener : Function ) : void
		{
			_mediaEventListener = mediaEventListener;
		}
		/**
		 * remove a MediaEvent handler form the playlist 
		 * 
		 * @param mediaEventHandler : Function
		 * 
		 */		
		public function removeMediaEventListener( mediaEventListener : Function ) : void
		{
			removeEventListener(MediaEvent.TYPE, mediaEventListener);
		}
		
		/**  GETTER SETTER  **/
		/**
		 * Returns the campaign id, this playlist belongs to. 
		 * @return String : Campaingn id
		 * 
		 */
		public function getCampaignId() : String
		{
			return _campaignId;
		}
		/**
		 * Retrieves the current track data 
		 * @return ITrackData
		 * 
		 */		
		public function getCurrentTrack() : ITrackData 
		{
			var track : ITrackData;
			if (hasData()) {
				track = getTrackById(_playlistOrder[_currentPlaylistIndex]);
			}else{
				track = null;
			}	
			
			return track;
		}			
		/**
		 * Returns the current track index in the playlist 
		 * @return Number - 0 based index 
		 * 
		 */		
		public function getCurrentTrackIndex() : Number
		{
			return _currentPlaylistIndex;
		}
		/**
		 * Returns the nextTrack in the playlist
		 * @return ITrackData - next track
		 * 
		 */		
		public function getNextTrack() : ITrackData
		{
			_currentPlaylistIndex++;
			if (_currentPlaylistIndex >= _playlistOrder.length)
			{
				_currentPlaylistIndex = 0;
			}		
			return getCurrentTrack();
		}
		/**
		 * Returns the previous track in the playlist 
		 * @return ITrackData object of the next track
		 * 
		 */		
		public function getPreviousTrack() : ITrackData
		{
			_currentPlaylistIndex--;
			if (_currentPlaylistIndex < 0 && hasData())
			{
				_currentPlaylistIndex = _playlistOrder.length-1;
			}		
			return getCurrentTrack();
		}	
		/**
		 * Returns the number of tracks in the playlist
		 * @return Number of tracks in the playlist
		 * 
		 */		
		public function getTotalTracks() : Number
		{
			return _playlistOrder.length;
		}		
		/**
		 * Returns an ordered array of tracks in the playlist 
		 * @return Array of ITrackData objects
		 * 
		 */				
		public function getTracks() : Array 
		{	
			return _tracks;
		}	
		/**
		 * Returns the ITrackData based on the track id passed in 
		 * @param id
		 * @return 
		 * 
		 */			
		public function getTrackById(id:String) : ITrackData
		{
			return _playlistMap[id];
		}	
		/**
		 * Returns the ITrackData based on the index of the playlist. 
		 * Playlist index is 0-based
		 * @param Number - index of the playlist
		 * @return ITrackData object
		 * 
		 */			
		public function getTrackByIndex( index : uint ) : ITrackData
		{
			return getTrackById(_playlistOrder[index]);
		}				
		/**
		 * Returns an array of ITrackData object ids 
		 * @return Array of ids
		 * 
		 */
		public function getTrackIds() : Array
		{
			var tids: Array = new Array();
			var trackData : ITrackData;
			if (_tracks){
				for (var i : Number = 0; i < _tracks.length ; i++) {
					trackData = _tracks[i] as ITrackData;	
					tids.push(trackData.getId());
				}
			}
			return tids;
		} 				
		/**
		 * Returns all tracks based on its media type
		 * @param mediaType :  Acceptable types: audio ||video
		 * @return array of ITrackData
		 * 
		 */		
		public function getTracksByMediaType( mediaTypeString : String ) : Array
		{
			if (!hasData()) return null;
			if (mediaTypeString != "audio" && mediaTypeString != "video") return null;
			var mediaType : Number = (mediaTypeString == "audio") ? Track.MEDIA_TYPE_AUDIO : Track.MEDIA_TYPE_VIDEO;			
			var trackArray : Array = new Array();
			var trackData : ITrackData;
			for (var i : Number=0; i<_playlistOrder.length; i++)
			{
				trackData = _playlistMap[_playlistOrder[i]];
				if (trackData.getTrack().mediaType == mediaType)
				{
					trackArray.push(trackData);
				}
			}
			return trackArray;
		}			
		/**
		 * Returns the current tracks duration in milliseconds 
		 * @return Duration in milliseconds
		 * 
		 */		
		public function getTrackDuration() : Number
		{
			var t : ITrackData = getCurrentTrack();
			if (t != null) 
			{
				return t.getDuration();	
			}else{
				return -1;
			}
		}
		/**
		 * Returns the current track playhead position 
		 * @return Position in milliseconds
		 * 
		 */		
		public function getTrackPosition() : Number
		{
			var t : ITrackData = getCurrentTrack();
			if (t != null) 
			{
				return t.getElapsedTime();	
			}else{
				return 0;
			}
		}
		/**
		 * Indicates whether track data exists for the playlist 
		 * @return Boolean 
		 * 
		 */		
		public function hasData() : Boolean 
		{
			return (_tracks.length>0); 
		}			
		/**
		 * Indicates whether the currentTrack is the last track of the
		 * playlist or not.
		 * @return Boolean
		 * 
		 */		
		public function isLastTrack() : Boolean
		{
			return (_currentPlaylistIndex == _playlistOrder.length-1);
		}		
		/**
		 * Play the the current ITrackData 
		 * @param quality: String value of the type of stream to play:  "LOW" || "MEDIUM" || "HIGH"
		 * 			This is negligible for an audio track, but for video, MEDIUM and HIGH will
		 * 			play H.264 streams, while LOW will play an flv.
		 */
		public function playTrack( quality : String = "HIGH", checkPolicyFile : Boolean = false) : void 
		{
			var track : ITrackData = getCurrentTrack();
			if (track) {
				setCurrentTrackData(track);
				_currentTrackData.checkForPolicyFile = checkPolicyFile;
				_currentTrackData.playMedia(quality);
			}
		}
		/**
		 * Given a track id, will set, load, and play the current track 
		 * @param track_id: String track id 
		 * @param quality: String value of the type of stream to play:  "LOW" || "MEDIUM" || "HIGH"
		 * 			This is negligible for an audio track, but for video, MEDIUM and HIGH will
		 * 			play H.264 streams, while LOW will play an flv.
		 * 
		 */		
		public function playTrackById( track_id : String = null, quality : String = "HIGH", checkPolicyFile : Boolean = false) : void
		{
			 var index : Number = getTrackIndexByTrackId(track_id);
			 log(NAME + " playTrackById found index: " + index);
			 if (index != -1)
			 {
			 	setCurrentTrackIndex(index);
			 	playTrack(quality, checkPolicyFile);
			 }else{
			 	log(NAME + ".playTrack(" + track_id + ") = track_id cannot be found"); 
			 }
		}
		/**
		 * Pauses the current track and keeps the track in buffer 
		 * 
		 */		
		public function pauseTrack() : void
		{
			var track : ITrackData = getCurrentTrack();
			if (track)
			{
				track.pauseMedia();
			}
		}
		/**
		 * Returns the first item in the list. 
		 * @return ITrackData : first item in the playlist
		 * 
		 */		
		public function resetPlaylist() : ITrackData
		{
			_currentPlaylistIndex = 0;
			return getCurrentTrack();
		}		
		/**
		 * Sets the position of the current track 
		 * @param seconds
		 * 
		 */			
		public function seekTo( seconds : Number ) : void
		{
			var track : ITrackData = getCurrentTrack();
			var position : Number = seconds;
			if (track is AudioData)
			{
				position *= 1000;
			}
			track.setMediaPosition( position );
			
		}		
		/**
		 * Stops the current track. If track is downloading, will close the net stream
		 * connection and clean up any listeners.
		 * 
		 */		
		public function stopTrack() : void
		{
			var track : ITrackData = getCurrentTrack();
			if (track)
			{
				track.stopMedia();
			}			
		}		

		//////////////////////////////////////////////////////
		//
		// PRIVATE METHODS - internal
		//
		//////////////////////////////////////////////////////			
		/**
		 * Return the track index in the playlist given a track_id
		 * @param track_id 
		 * @return Number : index of the playlist, -1 if not found
		 * 
		 */		
		private function getTrackIndexByTrackId( track_id : String ) : Number
		{
			var index : Number = -1;
			for ( var i : Number = 0; i < _playlistOrder.length; i++ )
			{
				if (_playlistOrder[i] == track_id)
				{
					index = i;
				}	
			}
			return index;
		}
		/**
		 * Runs through the entire playlist and calls
		 * stopMedia, which will also cleanup any
		 * listeners and loaders. 
		 * If you pass in null, it will kill them all
		 * @param t
		 * 
		 */		
		private function killOthers( t : ITrackData = null) : void
		{
			if (!hasData()) return;
			var track : ITrackData;
			var killAll : Boolean = (t == null);
			for (var i : Number = 0; i<_tracks.length;i++)
			{
				track = _tracks[i] as ITrackData;
				if (!killAll && t!=track )
				{
					log("-killOthers: " + track);
					track.cleanup();
//					track.removeEventListener(MediaEvent.TYPE, onMediaEventHandler);
				}
			}
		}		
		/**
		 * Sets the current track index 
		 * @param index 
		 * 
		 */		
		private function setCurrentTrackIndex( index:Number ) : void 
		{
			if (index < _playlistOrder.length && _currentPlaylistIndex != index)
			{
				log(NAME + " setCurrentTrackIndex(" + index + ")");
				_currentPlaylistIndex = index;
//				setCurrentTrackData(_playlistOrder[_currentPlaylistIndex]);
			}
		}
		private function setCurrentTrackIndexByTrack( trackData : ITrackData ) : void
		{
			if (!trackData) return;
			var id : String = trackData.getId();
			for (var i : Number=0; i<_playlistOrder.length;i++)
			{
				if (_playlistOrder[i] == id)
				{
					_currentPlaylistIndex = i;
					break;
				}
			}
			log("Playlist: setCurrentTrackIndexByTrack _currentPlaylistIndex=" + _currentPlaylistIndex); 
		}		
		/**
		 * Sets the currentTrackData that is playing
		 * @param trackData - can be either a AudioData, VideoData 
		 * 
		 */		
		private function setCurrentTrackData( trackData : ITrackData ) : void
		{
			log(NAME + ": setCurrentTrack(" + trackData.getId() + ")");
			if (_currentTrackData != null && _currentTrackData.getId() == trackData.getId())
			{
				log(NAME + ":-->setCurrentTrack SAME TRACK - trigger modelChange");
				return;
			}	
			if (_currentTrackData != null)
			{
				log(NAME + ":-->_currentTrackData " + _currentTrackData + " :playing: " + _currentTrackData.isPlaying() ) ;
				_previousTrack = _currentTrackData;
				if (_previousTrack != null && _previousTrack.isPlaying() )
				{
					//tells the current track to reset to 0;
					seekTo(0);
					//Stops the previous track media.
					_previousTrack.stopMedia();	
				}
				trace("Kill others: " + trackData);
				//This essentially kills all other ITrackData listeners in the application.
				killOthers(trackData);				
			}
			_currentTrackData = trackData;
			setCurrentTrackIndexByTrack(_currentTrackData);
			if (getCurrentTrack().getTrack())
			{
				log(NAME + ":-->New Current Track==> " + getCurrentTrack().getTrack().title );
			}
			if (!_currentTrackData.hasEventListener(MediaEvent.TYPE))
			{
				log(NAME + ":-> Add event listener to the currentTrackData");
				_currentTrackData.addEventListener(MediaEvent.TYPE, _mediaEventListener);
			}
		}		


		public function log( msg : String ) : void
		{
			trace(msg);
		}

		public override function toString() : String
		{
			return "[" + NAME + ", cid:"+ getCampaignId() + ", total track:" + getTotalTracks() +  "]";	
		}
		
	}
}