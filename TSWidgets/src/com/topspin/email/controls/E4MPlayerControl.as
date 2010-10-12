package com.topspin.email.controls
{
	import com.topspin.api.data.ITSPlaylist;
	import com.topspin.api.data.media.ITrackData;
	import com.topspin.api.data.media.Playlist;
	import com.topspin.api.events.MediaControlEvent;
	import com.topspin.api.events.MediaEvent;
	import com.topspin.common.controls.AbstractControl;
	import com.topspin.common.controls.PlayPauseIconButton;
	import com.topspin.common.controls.SimpleIconButton;
	import com.topspin.common.controls.SimpleLinkButton;
	import com.topspin.common.controls.TitleScrubBarControl;
	import com.topspin.common.events.PlaylistEvent;
	import com.topspin.common.preloader.animation.SpinLoader;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.style.GlobalStyleManager;
	import com.topspin.email.views.EmailMediaWidgetView;
	
	import fl.motion.easing.Cubic;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import gs.TweenLite;
	import gs.TweenMax;
	
	/**
	 * @author amehta
	 * 
	 */	
	public class E4MPlayerControl extends AbstractControl
	{	
		public static var VIDEO_INIT : String = "video_init";
		public static var VIDEO_CLOSED : String = "video_closed";
		
		
		
		//Properties and flag
		private var _inited : Boolean = false;
		private var playTimer : Timer;				//Internal Timer
		
		private var _availWidth : Number;
		private var _availHeight : Number;
		private var _bgColor : Number = 0x333333;
		private var styles : GlobalStyleManager;
		private var dm : DataManager;
		private var _playlist : ITSPlaylist;
		
		//STATES
		public static var PLAYLIST_STATE : String = "playlist_state";
		public static var SHARE_STATE : String = "share_state";
		public static var INFO_STATE : String = "info_state";
		
		//UI		
		private var playBar : Sprite;
		private var container : Sprite;
		private var holder : Sprite;
		private var holderMask : Sprite;
		//Smaller
		private var _playBtn : PlayPauseIconButton;
		//Large Btn
		private var _playOverlayBtn:PlayPauseIconButton;
		//Current Track scrubber
		private var _scrubberControl:TitleScrubBarControl;
		//Playlist:
		private var playlistControl : PlaylistControl;		
		//Info Control
		private var infoControl : InfoControl;
		//Current State of the widget
		private var _currentState : String; 
		private var _previousState : String;
		//boolean flag if the widget is playing
		private var _isPlaying : Boolean = false;
		
		private var _playInited : Boolean = false;
		
		//Sharing Social buttons
		private var _shareTxt : TextField;
		private var shareStrip : Sprite; 				//container for the social strip
		private var _copyBtn : SimpleLinkButton;
		private var _ctaBtn : SimpleLinkButton;	
		private var _icons : Array; 					//holds all the sharing icons
		
		private var _customLink : TextField;
		private var _privacyLink : TextField;
		
		//Icons
//		private var _playlistBtn : SimpleIconButton;
//		private var _fullscreenBtn : SimpleIconButton;
//		private var _volumeBtn : SimpleIconButton;
		
		[Embed (source="/assets/Facebook-16x16.png")]
		public var fbIcon : Class;
		public var fbBtn : Sprite;
		
		[Embed (source="/assets/MySpace-16x16.png")]
		public var myIcon : Class;
		public var myBtn : Sprite;
		
		[Embed (source="/assets/Twitter-16x16.png")]
		public var twitterIcon : Class;
		public var twitterBtn : Sprite;
		
		[Embed (source="/assets/Digg-16x16.png")]
		public var diggIcon : Class;
		public var diggBtn : Sprite;
		
		[Embed (source="/assets/Delicious-16x16.png")]
		public var delIcon : Class;
		public var delBtn : Sprite;			
		
		[Embed (source="/assets/playlistIcon.png")]
		public var playlistIcon : Class;
		public var playlistIconClip : Sprite;	
		public var playlistBtn : IconButton;

		[Embed (source="/assets/embedIcon.png")]
		public var shareIcon : Class;
		public var shareIconClip : Sprite;	
		
		[Embed (source="/assets/fullscreenIcon.png")]
		public var fullscreenIcon : Class;
		public var fullscreenIconClip : Sprite;
		public var fullscreenBtn : IconButton;
		
		[Embed (source="/assets/volumeIconMax.png")]
		public var volumeMaxIcon : Class;
		public var volumeMaxIconClip : Sprite;
		
		[Embed (source="/assets/volumeIconMute.png")]
		public var volumeMuteIcon : Class;
		public var volumeMuteIconClip : Sprite;		
		public var volumeBtn : IconButton;	
		
		[Embed (source="/assets/infoIcon.png")]
		public var infoIcon : Class;
		public var infoIconClip : Sprite;
		public var infoBtn : IconButton;		
		
		//UI
		private var progress : SpinLoader;
		private var vid : Video;
		private var videoHolder : Sprite;

		private var barH : Number = 20;
		private var PAD : Number = 2;

		private var copyConfirmStr : String = "copied";
		
		private var MINI_MODE : Boolean = false;
		public var MAX_DIM : Number = 380;
		public var drawCurves : Boolean = false;
		
		private var dropShadowFilter : DropShadowFilter;
		
		private var _baseWidth : Number;
		private var _baseHeight : Number;
		
		public function E4MPlayerControl(w : Number, h : Number, playlist : ITSPlaylist)
		{
			this.alpha = 0;
			this.visible = false;
			_baseWidth = w;
			_baseHeight  = h;
			//Override the typical setSize and sets the available Space for video and such.
			setSize(w,h);
			_playlist = playlist;
			MINI_MODE = (h <= 200);
			init();
		}
		
		private function init() : void {
			dm = DataManager.getInstance();
			styles = GlobalStyleManager.getInstance();
			//Timer for the player ui
			playTimer = new Timer(50);
			//init the icons
			_icons = new Array();
			CONTROL_MAP = new Dictionary();
			
//			_bgColor = 
			
			createChildren();
			//start the player
			playTimer.start();
		}

		/**
		 * Create UI children  
		 * 
		 */		
		private function createChildren() : void 
		{
			var roundedCorner : Number = 6;
			var bgAlpha : Number = .8;
			
			//Container holds the entire control
			container = new Sprite();
			//holder contains the playBar and such
			holder = new Sprite();
			//holds only the video
			videoHolder = new Sprite();
			
			addChild(videoHolder);
			addChild(container);			
			container.addChild(holder);
			
			holder.y = barH + PAD;			

			//draw the bg
			var g:Graphics = container.graphics;
			g.clear();
//			g.beginGradientFill( fType, colors, alphas, ratios, matr, sprMethod );
			g.beginFill(_bgColor,1);
			g.drawRect(0,0,_width, barH + PAD);
			g.endFill();		
			
			holderMask = new Sprite();
			g = holderMask.graphics;
			g.clear();
			g.beginFill(0xff0000, .2);
			g.drawRect(0, barH + PAD, _width, _height - (barH + PAD));
			g.endFill();

			addChild(holderMask);
			holder.mask = holderMask;	
			holderMask.x = (_availWidth - _width)/2;
			
			//Play bar
			playBar = new Sprite();
			playBar.y = 2;
			
			container.addChild(playBar);
			
			var smallFormat : TextFormat = new TextFormat(styles.getFormattedFontName(),8,0xffffff);
			
			_playBtn = new PlayPauseIconButton(barH,barH, _bgColor, styles.getLinkColor(),0xffffff,0xffffff,false,roundedCorner,bgAlpha);
			playBar.addChild(_playBtn);
//			_scrubberControl = new TitleScrubBarControl(_width - _playBtn.width - 2, barH, styles.getBaseColor(),
//														styles.getBaseColor(), styles.getBaseColor(),
//														0x3e3e3e, smallFormat,smallFormat,
//														styles.getFontColor(),
//														styles.getFontColor(),1);
			_scrubberControl = new TitleScrubBarControl(_width - _playBtn.width - 2, barH, 0x666666,
				0x333333, 0,
				0x3e3e3e, smallFormat,smallFormat,
				0xffffff,
				0xffffff,1);
			
			
			_scrubberControl.setTitleText("Check this out");		
			_scrubberControl.fontOutColor = 0xffffff;
			_scrubberControl.x = _playBtn.x + barH + 2;
			playBar.addChild(_scrubberControl);			
			
			/// SHARING STRIP
			//Hold all the sharing icons, cta button and info
			
			if (dm.getSharing() || dm.getCustomLinkUrl() != null )
			{
			
				shareStrip = new Sprite();
				shareStrip.graphics.clear();
				shareStrip.graphics.beginFill(_bgColor, 1);
				if (drawCurves) {
					shareStrip.graphics.drawRoundRectComplex(0,0,_width, barH + 2,0,0,4,4 );
				}else{
					shareStrip.graphics.drawRect(0,0,_width, barH + 2 );
				}	
				shareStrip.graphics.endFill();				
				holder.addChild(shareStrip);
				CONTROL_MAP[SHARE_STATE] = shareStrip;
				
				if (dm.getSharing())
				{
					//Create the share strip.
					//Will be html text
					_shareTxt = new TextField();
					_shareTxt.width = _width;
					_shareTxt.height = 20;
					_shareTxt.embedFonts = true;
					_shareTxt.autoSize = "left";			
					_shareTxt.antiAliasType = AntiAliasType.ADVANCED;
					_shareTxt.y = 0;
					_shareTxt.styleSheet = styles.headerCSS;
					_shareTxt.htmlText = "<body>Share:</body>";	
					shareStrip.addChild(_shareTxt);
					_shareTxt.visible = false;
					
					fbBtn = new Sprite();
					fbBtn.addChild(new fbIcon());
					fbBtn.name = "Facebook";
					shareStrip.addChild(fbBtn);
					
					myBtn = new Sprite();
					myBtn.addChild(new myIcon());
					myBtn.name = "MySpace";
					shareStrip.addChild(myBtn);
					
					twitterBtn = new Sprite();
					twitterBtn.addChild(new twitterIcon());
					twitterBtn.name = "Twitter";
					shareStrip.addChild(twitterBtn);
					
					diggBtn = new Sprite();
					diggBtn.addChild(new diggIcon());
					diggBtn.name = "Digg";
					shareStrip.addChild(diggBtn);
					
					delBtn = new Sprite();
					delBtn.addChild(new delIcon());
					delBtn.name = "Delicious";
					shareStrip.addChild(delBtn);
					
					var fontSize : Number = 10;
					var copyEmbedStr : String = (_width < 250) ? "embed" : "copy embed" ;
					var copyButtonFormat : TextFormat = new TextFormat(styles.getFormattedFontName(),fontSize,styles.getLinkColor());            
					var copyButtonOverFormat : TextFormat = new TextFormat(styles.getFormattedFontName(),fontSize,_bgColor);
					_copyBtn = new SimpleLinkButton(copyEmbedStr, copyButtonFormat, copyButtonOverFormat,copyEmbedStr,false,2,0,10,"center",1,true);		
					shareStrip.addChild(_copyBtn);
		
					_icons.push(fbBtn);
					_icons.push(myBtn);
					_icons.push(twitterBtn);
					_icons.push(diggBtn);
					_icons.push(delBtn);
					_icons.push(_copyBtn);			
				}
				
				var link : String = dm.getCustomLinkUrl();
				var privacyUrl : String = dm.getPrivacyUrl();
				if (link != null)
				{
					var label : String = dm.getCustomLinkLabel();
					var htmlText : String = "<a href='" + link + "'>" + label + "</a>";
					_customLink = new TextField();
					_customLink.autoSize = "left";
					_customLink.embedFonts = true;
					_customLink.antiAliasType = AntiAliasType.ADVANCED;
					_customLink.htmlText = htmlText;
					_customLink.styleSheet = styles.optionsCSS;			
					_customLink.width = 50;
					_customLink.height = 20;
					_customLink.selectable = false;		
					
//					shareStrip.addChild(_customLink);	
					_customLink.x = _width - _customLink.width - 4;
					
				}		
				
				if (privacyUrl)
				{
					_privacyLink = new TextField();
					_privacyLink.autoSize = "left";
					_privacyLink.embedFonts = true;
					_privacyLink.antiAliasType = AntiAliasType.ADVANCED;
					_privacyLink.htmlText = "<a href='event:link'>Privacy</a>";
					_privacyLink.styleSheet = styles.optionsCSS;			
					_privacyLink.width = 50;
					_privacyLink.height = 20;
					_privacyLink.selectable = false;		
					shareStrip.addChild(_privacyLink);	
					_privacyLink.x = _width - _privacyLink.width - 4;
				}	
				
			}
			
			// PLAYLIST CONTROLS
			if (_playlist.getTotalTracks() > 1)
			{
				playlistControl = new PlaylistControl(_width,_height - (barH + PAD), _playlist, styles.getLinkColor(),
														0x515151,0x3d3d3d,dm.includeArtistName, drawCurves);
				holder.addChild(playlistControl);
				
				//playlist icon
				playlistIconClip = new Sprite();
				playlistIconClip.addChild(new playlistIcon());				
				
				if (dm.getSharing())
				{
					shareIconClip = new Sprite();
					shareIconClip.addChild(new shareIcon());				
				}
				
				playlistBtn = new IconButton(barH, barH, playlistIconClip,_bgColor,bgAlpha,
												styles.getLinkColor(),false,false,0xcccccc,roundedCorner, true,
												false, shareIconClip);
				playBar.addChild(playlistBtn);
				CONTROL_MAP[PLAYLIST_STATE] = playlistControl;
			}
			
			if (dm.getExternalInterfacesAvailable())
			{
				//fullscreen icon
				fullscreenIconClip = new Sprite();
				fullscreenIconClip.addChild(new fullscreenIcon());				
				fullscreenBtn = new IconButton(barH, barH, fullscreenIconClip,_bgColor,bgAlpha,
												styles.getLinkColor(),false,false,0xcccccc,roundedCorner);
				playBar.addChild(fullscreenBtn);				
			}
			
			if (!dm.hideinfo) {
				//info icon
				infoIconClip = new Sprite();
				infoIconClip.addChild(new infoIcon());				
				infoBtn = new IconButton(barH, barH, infoIconClip,_bgColor,bgAlpha,
					styles.getLinkColor(),false,false,0xcccccc,roundedCorner,true);
				playBar.addChild(infoBtn);		
				
				infoControl = new InfoControl(_width,_height - (barH + PAD*2), _bgColor);
				holder.addChild(infoControl);
				
				CONTROL_MAP[INFO_STATE] = infoControl;
			}
			
			volumeMaxIconClip = new Sprite();
			volumeMaxIconClip.addChild(new volumeMaxIcon());
			volumeMuteIconClip = new Sprite();
			volumeMuteIconClip.addChild(new volumeMuteIcon());
			
			volumeBtn = new IconButton(barH, barH, volumeMaxIconClip,_bgColor,bgAlpha,
				styles.getLinkColor(),false,false,0xcccccc,roundedCorner, true,
				false, volumeMuteIconClip);
			playBar.addChild(volumeBtn);				
			
			var sm : Boolean = (_height < 200);
			var dim : Number = (sm) ? 30 : 40;
			
			dropShadowFilter = new DropShadowFilter(2,90,0x000000,.4,6,6);
			
			if (dm.showPlayButton())
			{
				_playOverlayBtn = new PlayPauseIconButton( dim,dim,_bgColor,styles.getLinkColor(),0xffffff,0xffffff,false,8,bgAlpha);
				_playOverlayBtn.setPad((sm)? 6 :10);
				addChild(_playOverlayBtn);
				_playOverlayBtn.filters = [dropShadowFilter];			
			}
			
			progress = new SpinLoader( dim, dim, 0xFFFFFF);	
			
			configureListeners();
			_inited = true;
			
			draw();
			if (dm.getSharing())
			{
				_currentState = SHARE_STATE;
				_currentControl = shareStrip;
			}else{
				_currentState = PLAYLIST_STATE;
				if (playlistControl)
				{
					_currentControl = shareStrip;
				}
			}
			if (shareStrip)
			{
				shareStrip.y = -shareStrip.height;				
			}
			if (playlistControl){
				playlistControl.y = -playlistControl.height;
				playlistControl.visible = false;
			}
			if (infoControl) {
				infoControl.y = -infoControl.height;
				infoControl.visible = false;
			}
			container.y = -container.height;
			
			//			
			TweenLite.to(this, .8, {autoAlpha:1});
		}

		public function displayOverlayButton():void {
			if (!_playOverlayBtn) return;
			TweenLite.to(_playOverlayBtn, .8, {autoAlpha:1});
		}
		
		public function hideOverlayButton():void {
			trace("HIDEOVERLAY BUTTONS");
			if (!_playOverlayBtn) return;
			TweenLite.to(_playOverlayBtn, .8, {autoAlpha:0});
		}
		
		/**
		 * Configure listeners 
		 * 
		 */		
		private function configureListeners() : void {
			_playlist.addMediaEventListener( onMediaEventHandler );	
			_scrubberControl.addMediaControlListener( onMediaControlHandler );
			
			_playBtn.addEventListener(MouseEvent.CLICK, handlePlayPause);
			if (_playOverlayBtn){
				_playOverlayBtn.addEventListener(MouseEvent.CLICK, handlePlayPause);
			}
			
			playTimer.addEventListener(TimerEvent.TIMER,handleTrackProgress);
			if (playlistBtn)
			{
				playlistBtn.addEventListener(MouseEvent.CLICK, handlePlayShareClick);
			}
			if (fullscreenBtn)
			{
				fullscreenBtn.addEventListener(MouseEvent.CLICK, handleFullscreenClick);
			}

			if (infoBtn)
			{
				infoBtn.addEventListener(MouseEvent.CLICK, handleShowInfo);
			}
			
			volumeBtn.addEventListener(MouseEvent.CLICK, handleVolumeClick);
			if (playlistControl)
			{
				playlistControl.addEventListener(PlaylistEvent.TYPE, handlePlaylistChange);
			}
			
			if (_privacyLink) _privacyLink.addEventListener(MouseEvent.CLICK, showPrivacy);
			if (_customLink) _customLink.addEventListener(MouseEvent.CLICK, showCustomLink );
			
			
			var clip : Sprite;
			for (var i:Number=0;i<_icons.length;i++) {
				clip = _icons[i];
				if (clip == _copyBtn) 
				{
					clip.addEventListener(MouseEvent.CLICK, handleCopy);
				}else {
					clip.addEventListener(MouseEvent.CLICK, handleIconClick);
				}
				clip.buttonMode = true;
				clip.useHandCursor = true;
			}				

		}
		
		//Clicks out to another place
		public function showPrivacy( e : MouseEvent = null) : void
		{
			var link : String = dm.getPrivacyUrl();
			if (link && link != "null") {
				if (dm.getExternalInterfacesAvailable()) { 
					var request:URLRequest = new URLRequest(link);
					try {            
						navigateToURL(request);
					}
					catch (e:Error) {
						trace("Unable to link to " + link);
					}
				}
			}			
		}		
		//Clicks out to another place
		public function showCustomLink( e : MouseEvent = null) : void
		{
			
			if (dm.getCustomLinkUrl() && dm.getCustomLinkUrl() != "null") {
				if (dm.getExternalInterfacesAvailable()) { 
					var request:URLRequest = new URLRequest(dm.getCustomLinkUrl());
					try {            
						navigateToURL(request);
					}
					catch (e:Error) {
						trace("Unable to link to " + dm.getCustomLinkUrl());
					}
				}
			}			
		}
				
		
		public override function setSize( w: Number, h : Number ) : void
		{
			_availWidth = w;
			_availHeight = h;

			
			if (w > MAX_DIM) {
				w = MAX_DIM;
				drawCurves = true;
			}				
			if (_height >= MAX_DIM) {
				h = MAX_DIM;	
			}						
			_width = w;
			_height = h;			
			
			
			draw();
			refreshSize();
		}		
		
		/**
		 * Draws the playerControl based on any size changes
		 * etc. 
		 * 
		 */		
		protected override function  draw() : void 
		{
			if (!_inited) return;
			
			trace("E$MPLAYER DRAW()");
			
			container.x = (_availWidth - _width)/2;
			
			//Play bar controls
			_playBtn.x = PAD;
			var scrubWidth : Number = _width - _playBtn.x - _playBtn.width - 5;
			if (playlistBtn) scrubWidth -= playlistBtn.width + PAD;
			if (infoBtn) scrubWidth -= infoBtn.width + PAD;
			if (fullscreenBtn) scrubWidth -= fullscreenBtn.width + PAD;				
			scrubWidth -= volumeBtn.width + PAD;
			_scrubberControl.setSize(scrubWidth, barH);
			_scrubberControl.x = _playBtn.x + _playBtn.width + PAD;
			var x1 : Number = _scrubberControl.x + scrubWidth + PAD;
			if (playlistBtn){
				playlistBtn.x = x1;
				x1 += playlistBtn.width + PAD;
			} 
			if (infoBtn){
				infoBtn.x = x1;
				x1 += infoBtn.width + PAD;
			} 
			if (fullscreenBtn) {
				fullscreenBtn.x = x1;
				x1 += fullscreenBtn.width + PAD;				
			}
			volumeBtn.x = x1;
			//Sharestrip
			var clip : Sprite;
			x1 = (_width <= 250) ? 2 : _scrubberControl.x; //_shareTxt.x + _shareTxt.width;
			for (var i:Number=0;i<_icons.length;i++) {
				clip = _icons[i];
				clip.x = x1;
				clip.y = 2;
				if (clip == _copyBtn) 
				{
					x1 += _copyBtn.getWidth();
				}else {
					x1 += clip.width + 4;
				}
			}
			if (_customLink)
			{
				_customLink.y = 3;	
			}			
			if (_privacyLink)
			{
				_privacyLink.y = 3;	
			}			
			
			if (_playOverlayBtn) {
				_playOverlayBtn.x = (_availWidth - _playOverlayBtn.width)/2;
				_playOverlayBtn.y = (_availHeight - _playOverlayBtn.height)/2;
				trace("MINI MODE : " + _playOverlayBtn.x, MINI_MODE);
			}
			
			var YPAD : Number = 5;
			var g:Graphics = container.graphics;
			g.clear();
			//			g.beginGradientFill( fType, colors, alphas, ratios, matr, sprMethod );
			g.beginFill(_bgColor,1);
			g.drawRect(0,0,_width, barH + YPAD);
			g.endFill();		
			
			holderMask = new Sprite();
			g = holderMask.graphics;
			g.clear();
			g.beginFill(0xff0000, .2);
			g.drawRect(0, barH + YPAD, _width, _height - (barH + YPAD));
			g.endFill();
			
			playBar.y = 2;
			
			progress.x = (_availWidth - progress.width)/2;
			progress.y = (_availHeight - progress.height)/2;
			
			holderMask.x = (_availWidth - _width)/2;			
			
		}

		
		/**
		 * Handler for the playTimer 
		 * @param e
		 * 
		 */		
		private function handleTrackProgress( e : TimerEvent = null ) : void
		{
			update();
		}
		
		/**
		 * Handlers for the PlayPauseBtn 
		 * @param e
		 * 
		 */		
		private function handlePlayPause(e:MouseEvent):void {
			
			var t : ITrackData = _playlist.getCurrentTrack();			
			//track.playPauseMedia();
			if (!_playInited) _playInited = true;
			if ( t.isPlaying() )
			{
				_playlist.pauseTrack();
			}else
			{
				_playlist.playTrack("HIGH",true);
			}
		}	
		
		private function handlePlayShareClick( e : MouseEvent ) : void
		{
			if (playlistBtn.selected)
			{
				showState(PLAYLIST_STATE);
			}else{
				showState(SHARE_STATE);
			}
		}
		
		private function handleFullscreenClick( e : MouseEvent = null ) : void
		{
			trace("hanldeFullscreeenClick");
			dispatchEvent(new MediaControlEvent(MediaControlEvent.TOGGLE_FULLSCREEN));
		}
		
		private function handleShowInfo( e : MouseEvent ) : void
		{
			if (_currentState == INFO_STATE)
			{
				showState(_previousState);			
			}else{
				showState(INFO_STATE);
			}
		}
		private function handleVolumeClick( e : MouseEvent ) : void
		{
//			dispatchEvent(new MediaControlEvent(MediaControlEvent.));
			(volumeBtn.selected) ? mute() : unmute(.8); 
		}
		private function handleIconClick( e : MouseEvent) : void
		{			
			var name : String = e.currentTarget.name;
			dm.sharePlatform(name);
		} 
		
		public function handleCopy(event : MouseEvent) : void
		{
			var embedCode : String = dm.getEmbedCode();
			System.setClipboard(embedCode);
			_copyBtn.text = copyConfirmStr;
		}			
		
		private var previousTitle : String = "";

		/**
		 * Handles the playlist item selection and thus tells
		 * the controller to set a new track 
		 * @param event
		 * 
		 */		
		private function handlePlaylistChange(event:PlaylistEvent):void {
			_playInited = true;
			var t : ITrackData = event.data as ITrackData;
			_playlist.playTrackById(t.getId(),"HIGH",true);
		}			
		/**
		 * Main controller handler for any view, indicates what
		 * actions should be made on the media.  This method should
		 * be passed into the View so that UI component 
		 * @param e
		 * 
		 */		
		public function onMediaControlHandler( e : MediaControlEvent ) : void
		{
			var command : String = e._command;
			trace("Controller.onMediaChangeHandler[" + command + "]");
			switch (command){
				case MediaControlEvent.PLAY_PAUSE:
					trace("PLAY PAUSE");
					_playInited = true;

					break;
				case MediaControlEvent.SCRUB:
					var pos : Number = e._data.position;
					_playlist.seekTo( pos/1000 );
					break;
//				case MediaControlEvent.TOGGLE_FULLSCREEN:
//					//Need to redispatch this for the app to get it.
//					trace("dispatch this TOGGLE_FULLSCREEN");
//					dispatchEvent(new MediaControlEvent(MediaControlEvent.TOGGLE_FULLSCREEN));
//					break;
			}
		}
		/**
		 * Handler for ITrack MediaEvent.  
		 * @param e
		 * 
		 */		
		private function onMediaEventHandler( e : MediaEvent ) : void
		{
			var command : String = e.command;
			var t : ITrackData = ITrackData(e.invoker);
			
			switch (command){
				case MediaEvent.INIT:
					trace("->onMediaEventHandler [" + t.getId() + "] INIT ");
					//Setup video if track isVideo
					setup(t);
					break;
				case MediaEvent.LOAD_COMPLETE:
					trace("->onMediaEventHandler [" + t.getId() + "] LOAD_COMPLETE");
					break;
				case MediaEvent.LOAD_ERROR:
					trace("->onMediaEventHandler [" + t.getId() + "] LOAD_ERROR");
					handleNext();
					break;				
				case MediaEvent.PLAY_COMPLETE:
					trace("->onMediaEventHandler [" + t.getTitle() + "] PLAY_COMPLETE");
					//Send the current track ended, before setting the next.
					if (!_playlist.isLastTrack()) 
					{
						trace("->NOT THE LAST TRACK, PLAY THE NEXT");
						handleNext();
						
					}else{
						trace("-->LAST TRACK PLAYLIST_COMPLETE, RESET");
						_playlist.stopTrack();
						var currentTrack : ITrackData = _playlist.resetPlaylist();
						return;
					}
					break;
				case MediaEvent.METADATA:
					trace("->onMediaEventHandler [" + t.getId() + "] METADATA REFRESH");
					refresh(t);
					break;
			}
		}
		/**
		 * Next track 
		 * @param e
		 * 
		 */		
		private function handleNext( e : MouseEvent = null) : void
		{
			if (!_playlist) return;
			_playlist.playTrackById(_playlist.getNextTrack().getId());
		}		
		private function setup(t : ITrackData ) : void
		{
			if (t.isVideo())
			{
				if (!vid) {
					vid = new Video();
					vid.smoothing = true;
					vid.scaleX = 1;
					vid.scaleY = 1;
					videoHolder.addChild(vid);
					videoHolder.alpha = 0;
				}
				vid.attachNetStream(t.ns);
				refresh(t);
				TweenLite.to(videoHolder, .4, {autoAlpha:1});
				dispatchEvent(new Event(E4MPlayerControl.VIDEO_INIT));
			}else {
				
				if (vid)
				{
					videoHolder.visible = false;	
				}
				dispatchEvent(new Event(E4MPlayerControl.VIDEO_CLOSED));
			}
		}
		private function refresh( t : ITrackData ) : void
		{
			if (!vid  ) return;
			//Get the latest video in case the meta data has been updated
			vid.width = t.getWidth();
			vid.height = t.getHeight();
			refreshSize();		
		}			
		private var savedSoundTransform : SoundTransform;
		/**
		 * Toggles the volume between mute and unmute 
		 * @param muteIt
		 * 
		 */			
		public function toggleVolume( muteIt : Boolean, volume : Number = .8) : void
		{
			(muteIt) ? mute() : unmute(volume);
		}
		
		public function mute() : void
		{
			savedSoundTransform = SoundMixer.soundTransform;
			setVolume(0);			
		}
		/**
		 * Unmute the player 
		 * 
		 */		
		public function unmute(volume:Number) : void
		{
			setVolume(volume);
		}
		/**
		 * Sets the global sound of the player. 
		 * @param num - volume value between 0-1
		 * 
		 */		
		public function setVolume( num : Number = .6) : void
		{
			SoundMixer.soundTransform = new SoundTransform(num, 0);
		}			
		private var FADE_IN : Number = .2;
		private var FADE_OUT : Number = .3;
		private var _currentControl : Sprite;
		private var CONTROL_MAP : Object;
		
		/**
		 * Shows the appropriate state, sharing or playlist 
		 * @param state
		 * 
		 */		
		public function showState( state : String ) : void {
			trace("showState : " + state);
			_previousState = _currentState;
			
			var clipIn : Sprite;
			var clipOut : Sprite;
			if (shareStrip) shareStrip.visible = true;
			if (playlistControl) playlistControl.visible = true;
			if (infoControl) {
				infoControl.visible = true;
				infoControl.alpha = 1;
			}
			clipOut = CONTROL_MAP[_currentState];
			trace("showState clipOut : " + clipOut);
			switch (state) {
				case SHARE_STATE:
					if (!shareStrip) return;
					clipIn = shareStrip;
					if (!MINI_MODE)
					{
						displayOverlayButton();
					}else{
						hideOverlayButton();
					}
					break;
				case PLAYLIST_STATE:
					if (!playlistControl) return;
					clipIn = playlistControl;					
					hideOverlayButton();
					break;
				case INFO_STATE:
					if (!infoControl) return;
					clipIn = infoControl;					
					hideOverlayButton();
					break;
			}
			_currentControl = clipIn;
			_currentState = state;
			
			TweenLite.to(clipOut, FADE_IN, {y:-clipOut.height, ease:Cubic.easeIn, onComplete: fadeIn});
			
			function fadeIn() : void
			{
				TweenLite.to(clipIn, FADE_IN, {y:0, ease:Cubic.easeIn});						
			}
		}
		
		public function show() : void
		{
			if (_currentState == SHARE_STATE)
			{
				if (!MINI_MODE)
				{
					displayOverlayButton();
				}else{
					hideOverlayButton();
				}
			}
			container.y = 0;
			TweenLite.to(container, FADE_IN, {autoAlpha:1, ease:Cubic.easeIn, onComplete : finishIt});
			
//			TweenLite.to(container, FADE_IN, {autoAlpha:1, ease:Cubic.easeIn, onComplete : finishIt});

			//			TweenLite.to(container, FADE_IN, {y:0, ease:Cubic.easeIn, onComplete : finishIt});				
//			holder.filters = [dropShadowFilter];			

			function finishIt() : void
			{
				if (_currentState == SHARE_STATE && shareStrip)
				{
					TweenLite.to(shareStrip, FADE_OUT, {y:0, ease:Cubic.easeIn});
				} else if (_currentState == PLAYLIST_STATE && playlistControl)
				{
					hideOverlayButton();
					TweenLite.to(playlistControl, FADE_OUT, {y:0, ease:Cubic.easeIn});
				}else if (_currentState == INFO_STATE && infoControl) 
				{
					hideOverlayButton();
					TweenLite.to(infoControl, FADE_OUT, {y:0, ease:Cubic.easeIn});
				}
			}			
		}
		public function hide() : void
		{
			//FADE_IN
			TweenLite.to(container, FADE_IN, {autoAlpha:0, ease:Cubic.easeIn});
			if(_playInited) {
				hideOverlayButton();
			}			
//			holder.filters = null;
		}
		
		public function hideOLD() : void
		{
			trace("hide: _previousState: " + _previousState);
			if(_playInited) {
				hideOverlayButton();
			}			
			
			if (_currentState == SHARE_STATE && shareStrip)
			{
				if (playlistControl) playlistControl.y = -playlistControl.height;
				if (infoControl){
					infoControl.visible = false;
					infoControl.y = -infoControl.height;
				} 
				
				TweenLite.to(shareStrip, FADE_IN, {y:-shareStrip.height, ease:Cubic.easeIn, onComplete : finishIt});
			} else if (_currentState == PLAYLIST_STATE && playlistControl)
			{
				if (shareStrip) shareStrip.y = -shareStrip.height;
				if (infoControl) {
					infoControl.visible = false;
					infoControl.y = -infoControl.height;	
				}
				
				TweenLite.to(playlistControl, FADE_IN, {y:-playlistControl.height, ease:Cubic.easeIn, onComplete : finishIt});
			}else if (_currentState == INFO_STATE && infoControl) {
				if (playlistControl) playlistControl.y = -playlistControl.height;
				if (shareStrip) shareStrip.y = -shareStrip.height;				
				_currentState = _previousState;
				infoBtn.selected = false;
				if (playlistBtn)
				{
					playlistBtn.selected = (_previousState != SHARE_STATE);
				}
				
				TweenLite.to(infoControl, FADE_IN, {y:-infoControl.height, autoAlpha:0, ease:Cubic.easeIn, onComplete : finishIt});
				
			}else{
				finishIt();
			}
			
			
			function finishIt() : void
			{
				
				trace("Hide finish it : container" );
				TweenLite.to(container, FADE_OUT, {y:-container.height, ease:Cubic.easeIn});
				
				holder.filters = null;
			}
		}		
		
		private function showProgress( bool : Boolean ) : void
		{
			if (bool ) {
				addChild(progress);
				progress.alpha = .8;
			} else {
				if (progress && this.contains(progress)) {
					removeChild(progress);
				}
			}			
		}
		
		/**
		 * Will refresh the sizes base on the current _width and _height
		 * of the player, regarless of fullscreen or not. 
		 * 
		 */		
		private function refreshSize():void {
			if (!vid) return;
			
			if( vid.width / _availWidth > vid.height / _availHeight )
			{
				vid.height = vid.height * _availWidth / vid.width;
				vid.width = _availWidth;
			}
			else
			{
				vid.width = _availHeight * vid.width / vid.height;
				vid.height = _availHeight;
			}		
			
			vid.y = (_availHeight - vid.height) / 2; 	
			vid.x = (_availWidth - vid.width) / 2;			
			trace("videoControl.refreshSize - vid.height, vid.width, height, width " + vid.height, vid.width, _availHeight, _availWidth);
		}		
		
		
		/**
		 * Update all the components 
		 * 
		 */		
		public override function update() : void
		{
			var t:ITrackData = _playlist.getCurrentTrack(); 	
			showProgress(t.isBuffering());
			
			_isPlaying = t.isPlaying();
			var trackTitle : String = t.getTrack().title;
			if (trackTitle != previousTitle) {
				previousTitle = trackTitle;
				var trackArtist : String = t.getTrack().artistName;
				
				_scrubberControl.setTitleText(trackTitle);
				if (dm.includeArtistName) {
					_scrubberControl.setArtistName(" by " + dm.getArtistName());
				}		
			}			
			_scrubberControl.update(t);
			
			_playBtn.selected = _isPlaying;		
			if (_playOverlayBtn) {
				_playOverlayBtn.selected = _isPlaying;
			}
			if (playlistControl)
			{
				playlistControl.update();
			}
		}		
		
	}
}