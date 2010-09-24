/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * This is a simple inline scrub bar component specific to Topspin.  
 * It features a loading bar, playbar. No
 * buttons are included nor time display until you roll over it.
 * 
 * A small time display appears when mouse interaction over the
 * progress bar.  This is used exclusively in the TSBundleView
 *     
 *  
 * 
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 * 
 */

package com.topspin.common.controls {

	import com.topspin.api.data.media.ITrackData;
	import com.topspin.api.data.media.Track;
	import com.topspin.api.events.MediaControlEvent;
	import com.topspin.common.controls.MaskTextMarquee;
	import com.topspin.common.utils.StringUtils;
	
	import fl.controls.Label;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import gs.TweenLite;
	
	public class TitleScrubBarControl extends Sprite
	{
		// Instances
//		private var styles : GlobalStyleManag;
		
		// Static 
		private var PADDING : Number = 0; //4;		
		private var XPAD : Number = 4;
		private var LOADBAR_EDGE_BUFFER : uint = 100;
		private var _width : Number = 0;
		private var _height : Number = 0;
		private var _inited : Boolean = false;
		
		// UI Elements
		private var titleScrubHolder:Sprite;
		private var loadBarBg:Sprite;
		private var loadBar:MovieClip;
		private var playBar:MovieClip;
		private var hitBar:Sprite;

		// Positioning
		private var barWidth : Number;  // The width of the component
		private var playheadInitX : Number;

		// State
		public var baseAlpha : Number = 0;  // Used to the change the alpha of the background alpha

		public var useBackground : Boolean = false;
		public var useLongFormat : Boolean = false;  // Used to display time in various formats: - true == 00:00:00  false == 00:00

		private var scrubTimer : Timer;  // Timer used to scrub
		private var _currentTrack : ITrackData;  // Current track that is being scrubbed

		private var ticker : Sprite;
		private var elapsedTickerLabel : TextField;
		private var durationTickerLabel:TextField;

		public var titleMaskTextMarquee:MaskTextMarquee;
		private var _titleText:String;
		private var hasStarted:Boolean = false;
		
		
		private var _baseColor : Number = 0x000000;
		private var _borderColor : Number;
		private var _bgBarColor : Number;
		private var _loadBarColor : Number;
		private var _titleFormat : TextFormat;
		private var _timeFormat : TextFormat;
		private var _durationFormat : TextFormat;
		private var _fontOverColor : Number;
		private var _fontOutColor : Number;		

		private var _scrubAlpha : Number = .65;
		private var _scrubOverAlpha : Number = 1;
		private var _scrubbing : Boolean = false;
		private var _continuousScroll : Boolean = true;


		public function TitleScrubBarControl(width:Number, height:Number,
											 baseColor : Number,
											 borderColor : Number,
											 bgBarColor : Number,
											 loadBarColor : Number,
											 titleFormat : TextFormat,
											 timeFormat : TextFormat,
											 fontOutColor : Number,
											 fontOverColor : Number,
											 scrubAlpha : Number = .65,
											 continuousScroll : Boolean = true) {
			this._width = width;
			this._height = height;
			
			this._titleText = "";
			this._baseColor = baseColor;
			this._borderColor = borderColor;
			this._bgBarColor = bgBarColor;
			this._loadBarColor = loadBarColor;
			this._titleFormat = titleFormat;
			this._timeFormat = timeFormat;
			this._fontOutColor = fontOutColor;
			this._fontOverColor = fontOverColor;
			this._continuousScroll = continuousScroll;

			_scrubAlpha = scrubAlpha;
						
			init();
			
			createChildren(); 
			setSize(width, height);
		}
		
		private function init():void {			
			_scrubOverAlpha = (_scrubAlpha == 0) ? 0 : 1;
			
			scaleX = scaleY = 1;
			scrubTimer = new Timer(10);
			scrubTimer.addEventListener(TimerEvent.TIMER,scrubIt);		
		}
		
		public function setArtistName( artistName : String ) : void
		{
			if (titleMaskTextMarquee)
			{
				titleMaskTextMarquee.setArtistText(artistName);
			}
		}
		
		/**
		 * createChildren creates the clips 
		 * 
		 */		
		private function createChildren():void {			
			hitBar = new Sprite();
			addChild(hitBar);

			titleScrubHolder = new Sprite();
			addChild(titleScrubHolder);

				loadBarBg = new Sprite();
				loadBar = new MovieClip();
				playBar = new MovieClip();

				titleScrubHolder.addChild(loadBarBg);
				titleScrubHolder.addChild(loadBar);
				titleScrubHolder.addChild(playBar);

			titleMaskTextMarquee = new MaskTextMarquee(this._width, this._height, _continuousScroll);
			titleMaskTextMarquee.setTitleTextFormat(_titleFormat);
			titleMaskTextMarquee.setArtistTextFormat(_timeFormat);
			titleMaskTextMarquee.x = 1;
			addChild(titleMaskTextMarquee);
			
			setChildIndex(hitBar, numChildren - 1);
			setChildIndex(titleMaskTextMarquee, numChildren - 2);

			ticker = new Sprite();
			addChild(ticker);

				elapsedTickerLabel = new TextField();
				elapsedTickerLabel.height = 14;
				elapsedTickerLabel.width = 45;
				elapsedTickerLabel.embedFonts = true;
				elapsedTickerLabel.defaultTextFormat = _timeFormat;
				elapsedTickerLabel.text = "";
				elapsedTickerLabel.antiAliasType = AntiAliasType.ADVANCED;			
				elapsedTickerLabel.y = elapsedTickerLabel.height - 2;
	
				ticker.addChild(elapsedTickerLabel);
	
				durationTickerLabel = new TextField();
				durationTickerLabel.height = 14;
				durationTickerLabel.width = 45;
				durationTickerLabel.embedFonts = true;
				durationTickerLabel.defaultTextFormat = _timeFormat;
				durationTickerLabel.text = "";
				durationTickerLabel.antiAliasType = AntiAliasType.ADVANCED;			
				durationTickerLabel.y = durationTickerLabel.height - 2;
	
				ticker.addChild(durationTickerLabel);

			setChildIndex(ticker, numChildren - 1);	
			ticker.visible = false;

			titleScrubHolder.alpha = _scrubAlpha;
			trace("_scrubAlpha : " + _scrubAlpha);
			configureListeners();
			_inited = true;

		}
		

		private function handleOver(e:MouseEvent = null):void {
			TweenLite.to(titleScrubHolder, .5, {autoAlpha:_scrubOverAlpha});
			if(hasStarted) {  TweenLite.to(titleMaskTextMarquee, .5, {tint:_fontOverColor});  }
			titleMaskTextMarquee.doScrollText();
		}
		
		private function handleOut(e:MouseEvent = null):void {
			TweenLite.to(titleScrubHolder, .5, {autoAlpha:_scrubAlpha});
			if(hasStarted) {  TweenLite.to(titleMaskTextMarquee, .5, {tint:_fontOutColor});  }
			
		}
		

		private function configureListeners():void {
			hitBar.addEventListener(MouseEvent.MOUSE_DOWN, onScrubBarDown);
			hitBar.addEventListener(MouseEvent.CLICK, onScrubOff);
			
			this.addEventListener(MouseEvent.MOUSE_OVER, handleOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, handleOut);
		}
		
		/**
		 * Main draw function 
		 * 
		 */		
		private function draw():void {
			if (!_inited) return;
			
			var loadBarWidth : Number = _width;

			loadBarBg.graphics.clear();
			loadBarBg.graphics.beginFill(_borderColor);
			loadBarBg.graphics.drawRect(0, 0, loadBarWidth, _height);
			loadBarBg.graphics.endFill();
			loadBarBg.graphics.beginFill(_bgBarColor);
			loadBarBg.graphics.drawRect(1, 1, loadBarWidth-2, _height - (2*PADDING)-2);
			loadBarBg.graphics.endFill();

			barWidth = loadBarWidth-2;
			
			loadBarBg.y = PADDING;
			
			loadBar.visible = playBar.visible = false;
			loadBar.graphics.clear();
			loadBar.graphics.beginFill(_loadBarColor, 1);  
			loadBar.graphics.drawRect(0, 0, barWidth, loadBarBg.height-2);
			loadBar.graphics.endFill();
			loadBar.x = loadBarBg.x + 1;
			loadBar.y = loadBarBg.y + 1;
			
			hitBar.graphics.clear();
			hitBar.graphics.beginFill(0x000000, 0);
			hitBar.graphics.drawRect(0, 0, barWidth, _height);
			hitBar.graphics.endFill();
			hitBar.x = loadBar.x;
			hitBar.y = loadBarBg.y;
			hitBar.buttonMode = true;

			playBar.graphics.clear();
			playBar.graphics.beginFill(_baseColor);  // baseColor
			playBar.graphics.drawRect(0, 0, loadBarWidth-2, loadBar.height);
			playBar.graphics.endFill();
			playBar.x = loadBar.x;
			playBar.y = loadBar.y;
			
			elapsedTickerLabel.x = XPAD;
			elapsedTickerLabel.y = (this._height - elapsedTickerLabel.height) / 2;
			durationTickerLabel.x = this._width - durationTickerLabel.width - 2;
			durationTickerLabel.y = (this._height - durationTickerLabel.height) / 2;
			
			titleMaskTextMarquee.setSize(this._width-XPAD, this._height);
			titleMaskTextMarquee.setTitleText(_titleText);
			titleMaskTextMarquee.x = XPAD;
			titleMaskTextMarquee.y = 1;
			
			playheadInitX = playBar.width = loadBar.width = hitBar.width = 0;
			loadBar.visible = playBar.visible = true;
		}

		public function setSize( w : Number, h : Number) : void {
			_width = w;
			_height = h;

			titleMaskTextMarquee.setFontSize(Math.floor(this._height / 2));

			scaleX = 1;
			scaleY = 1;				
			
			draw();
		}
		
		public function setCurrentTrack( track : ITrackData ) : void
		{
			_currentTrack = track;
		}

		private function onScrubBarDown(e:MouseEvent):void {
			_scrubbing = true;
			stage.addEventListener(MouseEvent.MOUSE_UP,onScrubOff);
			stage.addEventListener(MouseEvent.MOUSE_MOVE,handleOver);
			scrubIt();
			scrubTimer.start();

			ticker.visible = true;
			titleMaskTextMarquee.visible = false;
		}		

		/**
		 * Handler when the the playhead button is released, will
		 * stop the drag. 
		 * 
		 * @param e
		 */
		private function onScrubOff(e:MouseEvent = null):void {
			_scrubbing = false;
			scrubTimer.stop();
			stage.removeEventListener(MouseEvent.MOUSE_UP,onScrubOff);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE,handleOver);
			handleOut();

			ticker.visible = false;
			titleMaskTextMarquee.visible = true;
		}		

		/**
		 * Handler for when the playhead scrubber is scrubbing,
		 * what you going to do with it?  Real time scrubbing
		 * should only happen when a VideoData is being scrubbed 
		 * 
		 * @param e
		 */
		private function scrubIt(timer:TimerEvent = null):void {
			trace("scrubIt ");
			var finalX : Number = (loadBarBg.mouseX-loadBar.x>loadBar.width) ? loadBar.width : loadBarBg.mouseX-loadBar.x;
			var seekTo : Number = (finalX/ barWidth ) * _currentTrack.getDuration();
			dispatchEvent(new MediaControlEvent(MediaControlEvent.SCRUB, {position : seekTo}));						
		}

		/**
		 * Register a listener function so that the Controller
		 * can listen and delegate handlers
		 * @param funcObj - handler
		 * 
		 */		
		public function addMediaControlListener( funcObj : Function ) : void
		{
			addEventListener(MediaControlEvent.CONTROL_TYPE, funcObj);	
		}		
		
		/**
		 * Updates the display and UI 
		 * @param track
		 * 
		 */		
		public function update( track : ITrackData ) : void
		{
//			if (_scrubbing) return;
			if (_currentTrack != track)  _currentTrack = track;
			var t : Track = track.getTrack();
			
			var position : Number = track.getElapsedTime();
			var loaded : int = track.getBytesLoaded();
			var total : int = track.getBytesTotal();
			var duration : Number = track.getDuration();
			
			// update the time display
			elapsedTickerLabel.text = StringUtils.formatTime(position, useLongFormat) ;
			durationTickerLabel.text = StringUtils.formatTime(duration, useLongFormat);
			
			var percentBuffered : Number =  loaded / total;
			
			if (percentBuffered>1)  percentBuffered = 1;
			var loadWidth : Number = barWidth * percentBuffered;
			loadBar.width = loadWidth; 
			hitBar.width = loadBar.width;
						
			var percentPlayed : Number = position / duration;
			if (percentPlayed > 1) percentPlayed = 1;
			var posWidth : Number = playheadInitX + (barWidth * percentPlayed);
			
			playBar.width = posWidth;
		}
		
		public override function toString() : String {
			return "ProgressBar ";
		}
		
		public function setTitleText(overrideTitleText:String):void {
			this._titleText = overrideTitleText;
			draw();
		}
		
		public function trackHasStarted(overrideHasStarted:Boolean):void {
			this.hasStarted = overrideHasStarted;
		}
				
		/*******************************************
		 ** GETTER SETTERS                      
		 ******************************************/		
		public function set titleFormat( format : TextFormat ) : void
		{
			_titleFormat = format;
			draw();
		}
		public function set timeFormat( format : TextFormat ) : void
		{
			_timeFormat = format;	
			_durationFormat = new TextFormat(format.font,format.size,format.color,format.bold, format.italic);
			_durationFormat.align = "right";
			draw();
		}
		public function set fontOverColor( color : Number ) : void
		{
			_fontOverColor = color;
			draw();
		}
		public function set fontOutColor( color : Number ) : void
		{
			_fontOutColor = color;
			draw();
		}
		public function set borderColor( color : Number ) : void {
			_borderColor = color;
			draw();
		}
		public function set bgBarColor( color : Number ) : void {
			_bgBarColor = color;
			draw();
		}
		public function set loadBarColor( color : Number ) : void {
			_loadBarColor = color;
			draw();
		}
		public function set baseColor( color : Number ) : void {
			_baseColor = color;
			draw();
		}		
		
	}
}