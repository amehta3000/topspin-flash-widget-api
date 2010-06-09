﻿package{	import com.topspin.api.data.ITSPlaylist;	import com.topspin.api.data.ITSWidget;	import com.topspin.api.data.media.ITrackData;	import com.topspin.api.data.media.Track;	import com.topspin.api.events.E4MEvent;	import com.topspin.api.events.MediaEvent;	import com.topspin.api.events.TSWidgetEvent;		import fl.controls.DataGrid;	import fl.controls.Slider;	import fl.events.SliderEvent;		import flash.display.Bitmap;	import flash.display.DisplayObject;	import flash.display.Graphics;	import flash.display.Loader;	import flash.display.MovieClip;	import flash.display.Sprite;	import flash.events.Event;	import flash.events.IOErrorEvent;	import flash.events.MouseEvent;	import flash.events.TimerEvent;	import flash.media.SoundMixer;	import flash.media.Video;	import flash.net.URLRequest;	import flash.net.navigateToURL;	import flash.sampler.getSetterInvocationCount;	import flash.system.LoaderContext;	import flash.system.SecurityDomain;	import flash.text.StyleSheet;	import flash.utils.ByteArray;	import flash.utils.Dictionary;	import flash.utils.Timer;			/**	 * Test Rig for the Topspin Flash Widget API 	 * Additional documentation found at:	 * https://docs.topspin.net/tiki-index.php?page=Flash+Widget+API	 *  	 * Feedback, questions, concerns email:	 * @author amehta@topspinmedia.com	 * 	 * version 1.0.1 BETA 	 * May 23, 2010	 */		public class WidgetApiPlayground extends Sprite	{		var mc : MovieClip;		var grid : DataGrid;		//localdev		public var WIDGET_API_URL : String = "https://amehtaworkbot.local:7001/widgets/api/TSWidgetAPI.swf";		public var widget_id : String;		public var productionMode : Boolean = false;		public var loaderContext : LoaderContext;				public var tsWidget : ITSWidget;		public var playlist : ITSPlaylist; 		public var inited : Boolean = false;		public var WIDGET_MAP : Dictionary;		public var playTimer : Timer;		//instance of a video object.		public var vid : Video;		public var thumb : Sprite;				private var _scrubbing : Boolean = false;				public function WidgetApiPlayground()		{			stage.scaleMode = "noScale";						init();		}		public function init() : void		{			log("...Loading Topspin Widget API: ITSWidget..."); 			//holder of previous widgets			WIDGET_MAP = new Dictionary();						playlistGrid.columns = ["Index","Title","Length"];			playlistGrid.getColumnAt(0).setWidth(20);			playlistGrid.getColumnAt(2).setWidth(30);						widgetInput.text = "Give me a widget_id and hit Submit";									dobInput.text = "YYYY-MM-DD";			e4mInput.text = "Email Address";			e4mBtn.enabled = false;			e4mBtn.visible = false;									vid = new Video();			vid.smoothing = true;			vid.scaleX = 1;			vid.scaleY = 1;						thumb = new Sprite();			holder.addChild(vid);			holder.addChild(thumb);						//Output window			var style:StyleSheet = new StyleSheet();			var body:Object = new Object();			body.color = "#000000";				var debug:Object = new Object();			debug.color = "#000000";						var warn:Object = new Object();			warn.fontWeight = "bold";			warn.color = "#FF0000";			var error:Object = new Object();			error.fontWeight = "bold";			error.color = "#ff3300";									//get the widget_id from the flashvars			widget_id = (loaderInfo.parameters.widget_id) ? loaderInfo.parameters.widget_id:null;				if (widget_id) widgetInput.text = widget_id;					productionMode = (loaderInfo.parameters.productionMode) ? (loaderInfo.parameters.productionMode == "true") : productionMode;				var api : String = (loaderInfo.parameters.api_url) ? loaderInfo.parameters.api_url : WIDGET_API_URL;			trace("TSWidgetManager.swf: " + api, WARN);			var request : URLRequest = new URLRequest(api);			loaderContext = new LoaderContext();			loaderContext.securityDomain = SecurityDomain.currentDomain;					var loader:Loader = new Loader();				loader.contentLoaderInfo.addEventListener(Event.INIT, handleWidgetAPILoader);				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, widgetIOErrorHandler);				loader.load(request, loaderContext);						}				private function handleWidgetAPILoader( e : Event) : void		{			e.target.loader.contentLoaderInfo.removeEventListener(Event.INIT,handleWidgetAPILoader);			e.target.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, widgetIOErrorHandler);									tsWidget = ITSWidget(e.currentTarget.content);			log("ITSWidget Loaded:  Ready for widget id");			configureListeners();		}		private function widgetIOErrorHandler( e : IOErrorEvent ) : void		{			log("widgetIOErrorHandler: " + e);		}				private function configureListeners() : void		{			//create the instance of the TSEmailAdapter and add listeners			//Add listeners			tsWidget.addEventListener(TSWidgetEvent.WIDGET_LOAD_COMPLETE, handleWidgetEvent);			tsWidget.addEventListener(TSWidgetEvent.WIDGET_LOAD_ERROR, handleWidgetEvent);			tsWidget.addEventListener(TSWidgetEvent.WIDGET_ERROR, handleWidgetEvent);						//Playlist load			tsWidget.addEventListener(TSWidgetEvent.PLAYLIST_READY, handleWidgetEvent);			//Share email via Streaming widget			tsWidget.addEventListener(TSWidgetEvent.SHARE_EMAIL_COMPLETE, handleWidgetEvent);			tsWidget.addEventListener(TSWidgetEvent.SHARE_EMAIL_ERROR, handleWidgetEvent);						//E4M 			tsWidget.addEventListener(E4MEvent.EMAIL_SUCCESS, handleE4MEvent);			tsWidget.addEventListener(E4MEvent.EMAIL_ERROR, handleE4MEvent);			tsWidget.addEventListener(E4MEvent.UNDERAGE_ERROR, handleE4MEvent);						//Add listener for the button			submitBtn.addEventListener(MouseEvent.CLICK, handleSubmitWidgetId);			e4mBtn.addEventListener(MouseEvent.CLICK, handleE4MSubmit);			clearBtn.addEventListener(MouseEvent.CLICK, handleClear);						playBtn.addEventListener(MouseEvent.CLICK, handlePlay);			pauseBtn.addEventListener(MouseEvent.CLICK, handlePause);			prevBtn.addEventListener(MouseEvent.CLICK, handlePrev);			nextBtn.addEventListener(MouseEvent.CLICK, handleNext);			stopBtn.addEventListener(MouseEvent.CLICK, handleStop);									playlistGrid.addEventListener(Event.CHANGE, handleItemSelect);						playTimer = new Timer(50);			playTimer.addEventListener(TimerEvent.TIMER,handleTrackProgress);			playheadSlider.addEventListener(SliderEvent.THUMB_PRESS, handleSliderPress);			playheadSlider.addEventListener(SliderEvent.THUMB_DRAG, handleSliderPress);			playheadSlider.addEventListener(SliderEvent.THUMB_RELEASE, handleSeek);						documentationBtn.useHandCursor = true;			documentationBtn.buttonMode = true;			documentationBtn.addEventListener(MouseEvent.CLICK, handleDocumentationLink);		}						/**		 * Sets up the player 		 * 		 */				private function setupPlayer() : void		{			var tracks : Array = playlist.getTracks();			if (tracks && tracks.length > 0 )			{				log(tsWidget.getArtistName() + " Playlist");				log("Playlist Length : " + tracks.length);				var count : Number = 1;				var t : ITrackData;				var type : String;				for (var i : Number = 0; i < tracks.length; i++)				{					t = tracks[i] as ITrackData;					type = (t.getTrack().mediaType == Track.MEDIA_TYPE_VIDEO) ? "VIDEO" : "AUDIO";					log("\t" + count + ") " + t.getTrack().title + " - " + type );							//Adding a reference to the ITrackData, as well as to the current campaignId					playlistGrid.addItem({"Index":count,"Title":t.getTrack().title + "-"+type,"Length":formatTime(t.getDuration()),"data":t, "cid": tsWidget.getCampaignId()});					count++;				}				t = tracks[0] as ITrackData;			}					}		/**		 * Checks if the register isReady 		 * @return 		 * 		 */				private function isReady() : Boolean		{			if (inited && tsWidget != null)			{				return true;			}else{				log("No widget loaded yet", ERR);				return false;			}		}						////////////////////////////////////////////////////		//		// Event Handlers		//		////////////////////////////////////////////////////		/**		 * Main widget manager event 		 * @param e		 * 		 */				private function handleWidgetEvent( e : TSWidgetEvent ) : void		{			switch (e.type) {				case TSWidgetEvent.WIDGET_LOAD_COMPLETE:					//Widget registered, pull the camapaign_id 					//so that you can use multiple campaigns with					//single ITSWidget instance					var cid : String = tsWidget.getCampaignId();					WIDGET_MAP[widgetInput.text] = cid;										submitBtn.enabled = true;										log("");					log("ITSWidget Loaded Version : " + tsWidget.getVersion(), WARN);					log("------ BEGIN:: ITSWidget Interface Methods List ----", WARN);					log("getWidgetType(): [" + tsWidget.getWidgetType(cid) + "]");					log("getArtistId(): [" + tsWidget.getArtistId(cid) + "]");					log("getArtistName(): [" + tsWidget.getArtistName(cid)+ "]");					log("getCampaignId(): [" + tsWidget.getCampaignId()+ "]");					log("getFlickrId(): [" + tsWidget.getFlickrId(cid)+ "]");					log("getFlickrTags(): [" + tsWidget.getFlickrTags(cid)+ "]");					log("getHeadlineMessage(): [" + tsWidget.getHeadlineMessage(cid)+ "]");					log("getHomepageURL(): [" + tsWidget.getHomepageURL(cid)+ "]");					log("getOfferButtonLabel(): [" + tsWidget.getOfferButtonLabel(cid)+ "]");					log("getOfferURL(): [" + tsWidget.getOfferURL(cid)+ "]");					log("getPosterThumbnailURL(): [" + tsWidget.getPosterThumbnailURL(cid)+ "]");					log("getPosterImageURL(): [" + tsWidget.getPosterImageURL(cid)+ "]");					log("getProductImageURLs(): [" + tsWidget.getProductImageURLs(cid)+ "]");					log("isSharingEnabled(): [" + tsWidget.isSharingEnabled(cid)+ "]");					log("isShowProductImagesEnabled(): [" + tsWidget.isShowProductImagesEnabled(cid)+ "]");										if (tsWidget.getWidgetType() == "single_track_player")					{						e4mBtn.visible = false;					}					if (tsWidget.getWidgetType() == "email_for_media")					{						log("--E4M SPECIFIC CALLS--");						log("getE4MConfirmationTarget(): [" + tsWidget.getE4MConfirmationTarget(cid)+ "]");						log("getE4MOptInHeadline(): [" + tsWidget.getE4MOptInHeadline(cid) + "]");											log("getE4MOptInMessage(): [" + tsWidget.getE4MOptInMessage(cid) + "]");											log("getE4MPostURL(): [" + tsWidget.getE4MPostURL(cid) + "]");											log("getE4MMinimumAgeRequirement(): [" + tsWidget.getE4MMinimumAgeRequirement(cid)+ "]");						log("getE4MUnderageMessage(): [" + tsWidget.getE4MUnderageMessage(cid) + "]");						log("isE4MDOBRequired(): [" + tsWidget.isE4MDOBRequired(cid) + "]");												var optional : String = (tsWidget.isE4MDOBRequired(cid))?"(required)" : "(optional)";						dobInput.text = "YYYY-MM-DD" + optional;						e4mBtn.visible = true;						e4mHeadlineMessage.text = tsWidget.getHeadlineMessage(cid) + " " + tsWidget.getE4MOptInMessage(cid);											}										log("------END:: Interface Methods------", WARN);					log("");					inited = true;										break;								case TSWidgetEvent.WIDGET_LOAD_ERROR:					log("Widget swf failed to load.", ERR);					break;								case TSWidgetEvent.PLAYLIST_READY:										playlist = tsWidget.getPlaylist(tsWidget.getCampaignId());					//MUST ADD THIS MEDIAEVENT LISTENER TO LISTEN TO MEDIA EVENTS					playlist.addMediaEventListener( onMediaEventHandler );					setupPlayer();					break;							}		}		/**		 * Handles E4MEvent 		 * @param e		 * 		 */				private function handleE4MEvent( e : E4MEvent ) : void		{			switch (e.type) {				case E4MEvent.EMAIL_SUCCESS:					log("E4M email sent success!", WARN);					break;				case E4MEvent.EMAIL_ERROR:					log("E4M submit fail: " + e.message, ERR);					break;							case E4MEvent.UNDERAGE_ERROR:					log("E4M Underage fail: " + e.message, ERR);					break;									}		}				/**		 * Handles the item selection of the datagrid		 * Currently only set up to play one playlist		 * at a time.  Need to add a PlaylistManager		 * the handle multiple playlists. 		 * @param e		 * 		 */				private function handleItemSelect(e : Event) : void		{			var t : ITrackData = e.target.selectedItem.data as ITrackData;			var currentTrack : ITrackData = playlist.getCurrentTrack();						//Perform a check to see if the selected item belongs			//to current playlist.  If not, then stop the track			//in the current playlist, pull the current one			//and play.   			//TODO:  The could use some improvement, and			//could be made easier with a PlaylistManager that			//just manage all of this internally.  			//This will get better.//			var cid : String = tsWidget.getCampaignId();//			//			log("Current CID: " + cid + " == " + tCampaignId);//			if (cid != tCampaignId)//			{//				log("Item selected from a different playlist, stop the current one and play the other");//				playlist.stopTrack();//				playlist = tsWidget.getPlaylist(cid);//			}							playTimer.start();			if (currentTrack)			{				log("");				log("Selected item: " + t.getTrack().title + " current Track: " + currentTrack.getTrack().title);				if (currentTrack != t)				{					playlist.playTrackById(t.getId(),null,true);				}			}else{				playlist.playTrackById(t.getId(),null,true);							}			var msg : String =  t.getTrack().title + " [" + formatTime(t.getDuration()) + "]"; 			playlistMessage.text = msg;					log ("Playlist: handleItemSelect : PLAY TRACK : " + msg); 		}			/**		 * Handles slider event 		 * @param e		 * 		 */				private function handleSeek( e : SliderEvent ) : void		{			var value : Number = e.target.value;			log("handleSeek: " + value);			var t : ITrackData = playlist.getCurrentTrack();			if (t)			{				//convert to seconds.  Slider is 0-100				var position : Number = (value/100) * t.getDuration();				playlist.seekTo(position/1000);					_scrubbing = false;			}			}		/**		 * handles slider press 		 * @param e		 * 		 */				private function handleSliderPress( e : SliderEvent) : void		{			_scrubbing = true;			}		/**		 * Handle track progress, continuously updating the slider and time label		 * @param e		 * 		 */				private function handleTrackProgress( e : TimerEvent = null ) : void		{			var t : ITrackData = playlist.getCurrentTrack();			if (t)			{				var time : Number = t.getElapsedTime();				playTimeTxt.text = 	formatTime(time) + " / " + formatTime(t.getDuration());				if (!_scrubbing)				{					var pos : Number = 100 * (t.getElapsedTime() / t.getDuration());					playheadSlider.value = pos;				}			}					//Update the eq			eq();		}		/**		 * Handles the widget id submission		 * @param e		 * 		 */				private function handleSubmitWidgetId( e : MouseEvent ) : void		{			widget_id  = widgetInput.text;			if (WIDGET_MAP[widget_id] == null)			{				log("Registering widget id: [" + widget_id + "]");				productionMode = ckLogging.selected;				tsWidget.registerWidgetId( widget_id, productionMode );			}else{				log("");				log("Widget id already registered.");			}		}			/**		 * Handles the E4M submission. 		 * @param e		 * 		 */				private function handleE4MSubmit( e : MouseEvent ) : void		{			if (!isReady()) return;			log("");			log("Submit E4M");			var dates : Array = dobInput.text.split("-");			var dob : Date = new Date(dates[0],dates[1],dates[2]);			log("DOB: " + dob);			tsWidget.submitE4MEmail(tsWidget.getCampaignId(), e4mInput.text, null, dob);		}				////////////////////////////////////////////////////		//		// PLAYBACK Handlers		//		////////////////////////////////////////////////////				/**		 * Play 		 * @param e		 * 		 */				private function handlePlay( e : MouseEvent) : void		{			if (isReady() && playlist)			{				playTimer.start();				playlist.playTrack(null,true);				var t : ITrackData = playlist.getCurrentTrack();				var msg : String = t.getTrack().title + " [" + formatTime(t.getDuration()) + "]"; 				playlistMessage.text = msg;								log("");				log("Playlist: PLAY TRACK : " + msg);				}					}		/**		 * Pause 		 * @param e		 * 		 */				private function handlePause( e : MouseEvent) : void		{			if (!isReady()) return;						playlist.pauseTrack();			var t : ITrackData = playlist.getCurrentTrack();			if (t.isPlaying()){				playTimer.start();			}else{				playTimer.stop();			}			var msg : String = t.getTrack().title + " [" + formatTime(t.getElapsedTime()) + "/" + formatTime(t.getDuration()) + "]"; 			playlistMessage.text = msg;			log("");			log("Playlist: PAUSE TRACK : " + msg);					}		/**		 * Previous track 		 * @param e		 * 		 */				private function handlePrev( e : MouseEvent = null) : void		{			if (!isReady()) return;			playlist.playTrackById(playlist.getPreviousTrack().getId());			var t : ITrackData = playlist.getCurrentTrack();			var msg : String =  t.getTrack().title + " [" + formatTime(t.getDuration()) + "]"; 			playlistMessage.text = msg;			updatePlaylistGrid();			log("");			log("Playlist: PREVIOUS TRACK :" + msg);					}		/**		 * Next track 		 * @param e		 * 		 */				private function handleNext( e : MouseEvent = null) : void		{			if (!isReady()) return;			playlist.playTrackById(playlist.getNextTrack().getId());			var t : ITrackData = playlist.getCurrentTrack();			var msg : String =  t.getTrack().title + " [" + formatTime(t.getDuration()) + "]"; 			playlistMessage.text = msg;			updatePlaylistGrid();			log("");			log("Playlist: NEXT TRACK : " + msg);					}		/**		 * Stop 		 * @param e		 * 		 */				private function handleStop( e : MouseEvent) : void		{			if (!isReady()) return;			playTimer.stop();			playlist.stopTrack();			var t : ITrackData = playlist.getCurrentTrack();					var msg : String = t.getTrack().title + " [" + formatTime(t.getDuration()) + "]"; 			playlistMessage.text = msg;			playheadSlider.value = 0;			log("");			log("Playlist: STOP TRACK :" + msg);					}				private function updatePlaylistGrid() : void		{			var index : Number = playlist.getCurrentTrackIndex();			playlistGrid.selectedIndex = index;					}				/**		 * Clears the console 		 * @param e		 * 		 */				private function handleClear( e : MouseEvent ) : void		{			outputTxt.text = "";			}		/**		 * Handler for ITrack MediaEvent.  		 * @param e		 * 		 */				private function onMediaEventHandler( e : MediaEvent ) : void		{			var command : String = e.command;			var t : ITrackData = ITrackData(e.invoker);						switch (command){				case MediaEvent.INIT:					log("->onMediaEventHandler [" + t.getId() + "] INIT ", WARN);					//Setup video if track isVideo					setup(t);					break;				case MediaEvent.LOAD_COMPLETE:					log("->onMediaEventHandler [" + t.getId() + "] LOAD_COMPLETE", WARN);					break;				case MediaEvent.LOAD_ERROR:					trace("->onMediaEventHandler [" + t.getId() + "] LOAD_ERROR", ERR);					handleNext();					break;								case MediaEvent.PLAY_COMPLETE:					log("->onMediaEventHandler [" + t.getTitle() + "] PLAY_COMPLETE", WARN );					//Send the current track ended, before setting the next.					if (!playlist.isLastTrack()) 					{						log("->NOT THE LAST TRACK, PLAY THE NEXT");						handleNext();					}else{						log("-->LAST TRACK PLAYLIST_COMPLETE, RESET");						playlist.stopTrack();						var currentTrack : ITrackData = playlist.resetPlaylist();						return;					}					break;				case MediaEvent.METADATA:					log("->onMediaEventHandler [" + t.getId() + "] METADATA REFRESH", WARN);					refresh(t);					break;			}		}				/**		 * Called after MediaEvent.INIT is fired 		 * @param t		 * 		 */				private function setup(t : ITrackData) : void		{			if (t.isVideo())			{				//Attach the Net Stream to the video				vid.attachNetStream(t.ns);				//refresh the size				refresh(t);				vid.visible = true;				thumb.visible = false;			}else{				vid.visible = false;				//you could load the thumbnail here				var url : String = t.getPosterImageUrl("medium");				var loader : Loader = new Loader();				var ldrContext : LoaderContext = new LoaderContext(true);				loader = new Loader();				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleThumbComplete);				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleThumbLoadError);				loader.load(new URLRequest(url),ldrContext);			}		}		/**		 * Handler for loading thumbnail 		 * @param e		 * 		 */				private function handleThumbComplete(e:Event):void {			var ldr : Loader = e.target.loader;			ldr.contentLoaderInfo.removeEventListener(Event.COMPLETE, handleThumbComplete);			ldr.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, handleThumbLoadError);				var bmp : Bitmap = e.target.loader.content as Bitmap;			bmp.smoothing = true;			var clip : Sprite = new Sprite();			clip.addChild(bmp);			resizeClip( clip );			while (thumb.numChildren >0 )			{				thumb.removeChildAt(0);			}			thumb.addChild(clip);			thumb.visible = true;					}		private function handleThumbLoadError(e:Event):void { }						/**		 * Refreshes the video after metadata is loaded 		 * @param t		 * 		 */				private function refresh(t : ITrackData) : void		{			var clip : DisplayObject;			if (t.isVideo())			{				//holder.box is the grey box inside				//the holder where video and thumbnail				//images may load;				vid.width = t.getWidth();				vid.height = t.getHeight();				resizeClip( vid );			}		}		/**		 * Resize a clip in the holder.box 		 * @param clip		 * 		 */				private function resizeClip( clip : DisplayObject ) : void		{			var w : Number = holder.box.width;			var h : Number = holder.box.height;						if( clip.width / w > clip.height / h )			{				clip.height = clip.height * w / clip.width;				clip.width = w;			}			else			{				clip.width = h * clip.width / clip.height;				clip.height = h;			}								clip.y = (h - clip.height) / 2; 				clip.x = (w - clip.width) / 2;										}				private function handleDocumentationLink(e : MouseEvent ) : void		{			navigateToURL(new URLRequest("https://docs.topspin.net/tiki-index.php?page=Flash+Widget+API"),"_self");		}				private static var WARN : String = "warn";		private static var ERR : String = "err";		/**		 *  		 * @param msg		 * @param level debug || warn || error		 * 		 */				private function log( msg : String, level : String = "debug") : void		{			trace(msg);			outputTxt.appendText( msg + "\n");			outputTxt.verticalScrollPosition = outputTxt.maxVerticalScrollPosition;		}		/**		 * Format the time for the time label 		 * @param num		 * @param showHours		 * @return 		 * 		 */				private function formatTime( num : Number, showHours : Boolean = false) : String {				var time : String;			var seconds : Number = Math.floor(num / 1000);			var minutes : Number = Math.floor(seconds / 60);			var hours : Number = Math.floor(minutes / 60);			var sds : Number = seconds % 60;			time = ((showHours) ? formatDoubleOString(hours) + ":" : "" ) + formatDoubleOString(minutes) + ":" + formatDoubleOString(sds);			return time;		}				private function formatDoubleOString( num : Number) : String		{			var str : String = (num < 10) ? "0" + num.toString() : num.toString();			return str;		} 				/**		 * Compute spectrum to show access to 		 * to SoundMixer while using 		 * checkForPolicy true when playlist.play		 * is called. 		 * 		 */				private function eq() : void		{			try {				var bytes:ByteArray = new ByteArray();				const PLOT_HEIGHT:int = 35; //eqHolder;				const CHANNEL_LENGTH:int = 256; //holder.box.width;								SoundMixer.computeSpectrum(bytes, false, 0);				var g:Graphics = eqHolder.graphics;								g.clear();				g.lineStyle(0, 0xD9489F);				g.beginFill(0xD9489F, 0.5);				g.moveTo(0, PLOT_HEIGHT);								var n:Number = 0;								for (var i:int = 0; i < CHANNEL_LENGTH; i++) {					n = (bytes.readFloat() * PLOT_HEIGHT);					g.lineTo(i , PLOT_HEIGHT - n);				}								g.lineTo(CHANNEL_LENGTH , PLOT_HEIGHT);				g.endFill();								g.lineStyle(0, 0x17CAFB);				g.beginFill(0x17CAFB, 0.5);				g.moveTo(CHANNEL_LENGTH , PLOT_HEIGHT);								for (i = CHANNEL_LENGTH; i > 0; i--) {					n = (bytes.readFloat() * PLOT_HEIGHT);					g.lineTo(i , PLOT_HEIGHT - n);				}								g.lineTo(0, PLOT_HEIGHT);				g.endFill();					} catch (e : Error) {							}		}							}}