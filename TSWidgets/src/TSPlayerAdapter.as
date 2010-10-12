/***
 * PlayerAdapter is a lightweight media player that sits ontop of TSEmailMediaWidget
 * Play button should BE CONFIGURABLE
 * 
 ***/ 

package {
	import com.topspin.api.data.TSPlaylistAdapter;
	import com.topspin.api.data.media.AudioData;
	import com.topspin.api.data.media.ITrackData;
	import com.topspin.api.data.media.Track;
	import com.topspin.api.data.media.VideoData;
	import com.topspin.api.events.MediaEvent;
	import com.topspin.api.events.TSPlaylistAdapterEvent;
	import com.topspin.common.media.IPlayerAdapter;
	import com.topspin.common.controls.PlayPauseIconButton;
	import com.topspin.common.events.PlayerAdapterEvent;
	import com.topspin.common.media.IPlayerAdapter;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.Video;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.utils.Timer;
	
	import gs.TweenLite;
	
	public class TSPlayerAdapter extends Sprite implements IPlayerAdapter{
		
		public static var NAME : String = "PlayerAdapter_YEASAYER_100310";
		
		public static const VALIGN_TOP : String = "top";
		public static const VALIGN_CENTER : String = "center";
		public static const VALIGN_BOTTOM : String = "bottom";
		
		// Input Variables
		private var _widget_id:String;
		private var _clickTag:String;
		private var _width:Number = 300;
		private var _height:Number = 250;
		private var _linkColor:uint;
		private var _playBtnSize : Number = 40;
		private var _loop : Boolean = false;
		private var _delaystart : Number = 1000;
		
		// Instances
		private var adapter:TSPlaylistAdapter;
		//	private var overlayBtn:ControlButton;
		
		// UI
		private var playPauseBtn : PlayPauseIconButton;
		
		// Data
		private var XMLData:XML;
		private var trackDataArray:Array;
		private var track:ITrackData;
		private var isVideo:Boolean = false;
		private var audioData:AudioData;  // This is the audioData object being rendered
		private var videoData:VideoData;  // This is the videoData object being rendered
		private var vid:Video;  // Video class which will display video
		
		private var _valign : String = "center";
		
		// State
		private var isPlaying:Boolean = false;
		private var isLoaded:Boolean = false;
		
		// Static
		private static const FADE_TIME:Number = 0.5;
		public static var PLAY_MEDIA_READY:String = "playMediaReady";
		private static var PADDING:Number = 5;
		
		// Events
		private var mediaPlayEvent:PlayerAdapterEvent;
		private var mediaPauseEvent:PlayerAdapterEvent;
		
		// TEST
		private var timer:Timer;
		private var _root:Object;
		
		public function TSPlayerAdapter() {
			Security.allowDomain("*");
		}
		
		public function setPlaylistParams(widgetID:String, clickTag:String, width:Number, height:Number, linkColor:uint):void {
			this._widget_id = widgetID;
			this._clickTag = clickTag;
			this._width = width;
			this._height = height;
			this._linkColor = linkColor;
			
			createChildren();
			addEventListeners();
			init();
			draw();
		}
		
		private function createChildren():void {
			adapter = TSPlaylistAdapter.getInstance();
			
			mediaPlayEvent = new PlayerAdapterEvent(PlayerAdapterEvent.MEDIA_PLAY, true);
			mediaPauseEvent = new PlayerAdapterEvent(PlayerAdapterEvent.MEDIA_PAUSE, true);
			
			playPauseBtn = new PlayPauseIconButton(_playBtnSize,_playBtnSize, 0x000000, _linkColor,0xFFFFFF,0xFFFFFF,false, 6);
			playPauseBtn.setPad(10);
			playPauseBtn.pausePad = 5;
			
			addChild(playPauseBtn);
		}
		
		public function setVAlign( valign : String):void
		{
			this._valign = valign;	
		}
		
		private function updatePlayState(updateState:Boolean):void {
			playPauseBtn.selected = updateState;
		}
		
		private function addEventListeners():void {
			adapter.addEventListener(TSPlaylistAdapterEvent.PLAYLIST_COMPLETE, handlePlaylistLoad);
			adapter.addEventListener(TSPlaylistAdapterEvent.PLAYLIST_ERROR, handlePlaylistError);
			playPauseBtn.addEventListener(MouseEvent.CLICK, handleOverlayBtnClick);
		}
		
		private function init():void {
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, handleDataLoad);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			try {
				trace(NAME + " trying to load: " + _widget_id);
				loader.load(new URLRequest(this._widget_id));
			} catch (e:SecurityError) {
				trace("PlayerAdapter:: Security error occurred : " + e);
			}
		}		
		
		private function handleDataLoad(e:Event):void {
			XMLData = new XML(e.target.data);  // Assign input data
			
			// Remove event listeners
			e.target.removeEventListener(Event.COMPLETE, handleDataLoad);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);				 	
			e.target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);				 	
			
			var playlistTrackId:XML = XML(XMLData.media);
			
			if(playlistTrackId && playlistTrackId.children().length() > 0) {
				parse(playlistTrackId);
			} else {
				trace("No playlist");
			}
		}
		
		private function errorHandler(e:Event):void {
			trace("PlayerAdapter:: Load error occurred : " + e);
		}
		
		private function handlePlaylistLoad(e:TSPlaylistAdapterEvent):void {
			
			trackDataArray = e.data as Array;  // Accept the returned array of ITrackData objects
			track = trackDataArray[0];  // Set the global ITrackData as the first (and only) value in the returned array
			
			if (track)
			{	
				track.addEventListener(MediaEvent.TYPE, onMediaEventHandler);
			}
			setup();
			dispatchEvent(new Event(PlayerAdapterEvent.PLAY_MEDIA_READY, true));
		}
		
		private function onMediaEventHandler( e : MediaEvent ) : void
		{
			var command : String = e.command;
			var t : ITrackData = e.invoker as ITrackData;
			
			switch (command){
				case MediaEvent.PLAY_COMPLETE:
					trace("Controller.onMediaEventHandler [" + t.getId() + "] PLAY_COMPLETE " );
					isPlaying = false;
					if (!_loop)
					{
						trace("PA: Not looping, stop it");
						track.stopMedia();
						updatePlayState(false);			
						if (overlayImage) TweenLite.to(overlayImage, .4, {autoAlpha:1});								
					}
					track.setMediaPosition(0);
					if (_loop)
					{
						trace("LOOP It, so PLAY: handleOverlayBtnClick");
						handleOverlayBtnClick();
					}				
					break;
				case MediaEvent.INIT:
					trace("Controller.onMediaEventHandler [" + t.getId() + "] INIT ");
					setup();
					break;
				case MediaEvent.LOAD_COMPLETE:
					trace("Controller.onMediaEventHandler [" + t.getId() + "] LOAD_COMPLETE");
					break;
				case MediaEvent.METADATA:
					trace("Controller.onMediaEventHandler [" + t.getId() + "] METADATA REFRESH");
					if (isVideo && vid)
					{
						vid.width = videoData.getWidth();
						vid.height = videoData.getHeight();
						refreshSize(vid);
						if (isPlaying)
						{
							trace("Hide overlay image");
							if (overlayImage) TweenLite.to(overlayImage, .4, {autoAlpha:0});
						}
					}
					break;
			}
		}		
		
		private function handlePlaylistError(e:TSPlaylistAdapterEvent):void { }
		
		public function parse(node:XML):void { 
			trace("");
			trace("Parse the XML");
			adapter.parse(node);
		}
		
		private function handleOverlayBtnClick(e:Event = null):void {
			if(!isPlaying) {  // Track is not playing - start it
				if (track)
				{
					dispatchEvent(mediaPlayEvent);
					track.playMedia();
					
					isPlaying = true;	
					updatePlayState(true);
					if (overlayImage) TweenLite.to(overlayImage, .4, {autoAlpha:0});
				}
			} else {  // Track is playing, pause it
				if (track)
				{
					dispatchEvent(mediaPauseEvent);
					track.pauseMedia();
					isPlaying = false;
					updatePlayState(false);
				}
			}
			draw();
		}
		
		public function displayOverlayButton():void {
			TweenLite.to(playPauseBtn, .8, {autoAlpha:1});
		}
		
		public function hideOverlayButton():void {
			TweenLite.to(playPauseBtn, .8, {autoAlpha:0});
		}
		
		private function draw():void {
			
			playPauseBtn.x = (this._width - playPauseBtn.width) / 2;
			playPauseBtn.y = (this._height - playPauseBtn.height) / 2;
			
			if(isVideo) {
				//				vid.x = (this._width - vid.width) / 2;
				//				vid.y = (this._height - vid.height) / 2;
				playPauseBtn.y = vid.y + (vid.height - playPauseBtn.height)/2;
			}
		}
		
		public function setSize(width:Number, height:Number):void { 
			this._width = width;
			this._height = height;
			
			draw();
			//			refreshSize();
		}
		
		private function setup():void {
			//Just get the first track and now let does some business
			if(track && track.getTrack().mediaType == Track.MEDIA_TYPE_VIDEO && !vid) {
				isVideo = true;
				
				vid = new Video();
				vid.smoothing = true;
				vid.scaleX = 1;  
				vid.scaleY = 1;
				//				addChildAt(vid,getChildIndex(playPauseBtn));
				addChild(vid);
				setChildIndex(vid,0);
				trace("VIDEO IS ADDED");
			}	
			
			if(isVideo) {
				videoData = this.track as VideoData;
				vid.attachNetStream(videoData.ns);
				vid.width = videoData.getWidth();
				vid.height = videoData.getHeight();
				refreshSize(vid);
				getOverlayImage();
			} else if (track) {
				audioData = this.track as AudioData;
			}
			draw();
		}
		
		private var overlayImage : Sprite;
		private function getOverlayImage():void {
			var overlayImageURL = track.getTrack().imageURL;
			
			if (overlayImage) return;
			
			if(overlayImageURL && overlayImageURL.length > 0) {
				var loader : Loader = new Loader();
				loader.load(new URLRequest(overlayImageURL));
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoadComplete);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleLoadError);
			}
			
			function handleLoadComplete(e:Event):void {
				overlayImage = new Sprite();
				//				var bmp : Bitmap = Bitmap(loader.content);
				//				bmp.smoothing = true;
				//				trace("Smooth the bmp");
				overlayImage.addChild(loader.content);
				//				bmp.scaleX = bmp.scaleY = 0.99;
				
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, handleLoadComplete);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, handleLoadError);
				
				refreshSize(overlayImage);
				
				overlayImage.alpha = 0;
				addChildAt(overlayImage,getChildIndex(playPauseBtn));
				
				if (!isPlaying)
				{
					TweenLite.to(overlayImage, .8, {autoAlpha:1 });
				}				
			}
			
			function handleLoadError(e:Event):void { }
		}
		
		
		private function refreshSize( clip : DisplayObject):void {
			if (!clip) return;
			var w : Number = _width - PADDING*2;
			var h : Number = _height - PADDING*2;
			
			//			trace("refreshSize w,h:" + w,h);
			//			trace("refreshSize clip w,h: " + clip.width, clip.height); 
			
			if( clip.width / _width > clip.height / _height )
			{
				clip.height = clip.height * _width / clip.width;
				clip.width = _width;
			}
			else
			{
				clip.width = _height * clip.width / clip.height;
				clip.height = _height;
			}		
			
			clip.y = (_height - clip.height) / 2; 	
			clip.x = (_width - clip.width) / 2;		
			
			switch (_valign) {
				case VALIGN_TOP:
					clip.y = 0; 	
					break;			
				
				case VALIGN_CENTER:
					clip.y = (_height - clip.height)/2; 	
					break;			
				
				case VALIGN_BOTTOM:
					clip.y = _height - clip.height; 	
					break;			
				
				default:
					clip.y = (_height - clip.height)/2; 	
					break;			
			}			
			
			trace("refreshed the size of the CLIP: " + clip.x, clip.y, clip.width, clip.height);	
		}
		
		public function set loop( loopIt : Boolean ) : void
		{
			_loop = loopIt;
		}
		
		private var delayTimer : Timer;
		
		public function play(delayStart : Number = 1000) : void
		{
			_delaystart = delayStart;
			trace("PlayerAdapter: delayStart " + delayStart); 
			delayTimer = new Timer(_delaystart,1);			
			delayTimer.addEventListener(TimerEvent.TIMER_COMPLETE,delayedPlayMedia);	
			delayTimer.start();
		}
		private function delayedPlayMedia(t : TimerEvent = null) : void
		{
			if (delayTimer)
			{
				delayTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,delayedPlayMedia);
			}
			trace("delayedPlayMedia : " + _delaystart);
			handleOverlayBtnClick();
			if (track){
				hideOverlayButton();
			}			
		}
		
		public function pause() : void
		{
			handleOverlayBtnClick();
			if (track){
				displayOverlayButton();
			}			
		}		
		public function stop() : void
		{
			if (track)
			{	
				track.stopMedia();
				track.setMediaPosition(0);				
			}			
		}
	}
}