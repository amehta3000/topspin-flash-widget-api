package com.topspin.email.controls
{
	import com.topspin.api.data.media.ITrackData;
	import com.topspin.api.data.media.Track;
	import com.topspin.assets.MinusIcon;
	import com.topspin.assets.controls.PlayBtn;
	import com.topspin.common.controls.MaskTextMarquee;
	import com.topspin.common.controls.ToggleButton;
	import com.topspin.common.utils.StringUtils;
	import com.topspin.email.style.GlobalStyleManager;
	
	import fl.controls.Label;
	
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import gs.TweenLite;
	
	public class PlaylistItem extends Sprite {
		
		
		public var BG_COLOR_DISABLED : uint = 0x666666;
		public var PLAYER_PAD : uint = 8;
		/**
		 * Default height of Buttons 
		 */ 
		public var BUTTON_HEIGHT : uint = 24;
		
		public var track : ITrackData;
		
		private var bgBtn : SimpleButton;
		private var bg : Sprite;
		private var playlistItemHitArea:Sprite;
//		private var label : Label;
		private var marqueeLabel : MaskTextMarquee;
		private var timeLabel : TextField;
		private var playPauseBtn : ToggleButton;
		
		private var _baseColor : uint;
		private var _text : String;
		private var _selected : Boolean = false;
		private var _enabled : Boolean = true;
		private var _width : Number;
		private var _height : Number;
		
		private var _includeArtistName : Boolean = false;
		
		//private var _strokeColor : uint = 0x000000;
		public var formatColor : uint = 0x666666;
		
		public var _overColor : uint = 0x000000;
		public var _outColor : uint = 0xffffff;
		public var _itemFormat : TextFormat;
		
		private var format : TextFormat;
		private var overFormat : TextFormat;
		private var videoIcon : TextField;
		private var plyBtnColorTransform : ColorTransform;
		
		public var useLongFormat:Boolean = true;  // Used to display time in various formats: true == 00:00:00  false == 00:00
		private var selectedTextTransform : ColorTransform;
		private var unSelectedTextTransform : ColorTransform;
		
		// Instances
		private var styles : GlobalStyleManager;
		
		public var PLAYLIST_ITEM_SELECTED_COLOR : uint = 0x00aaff;
		public var PLAYLIST_ITEM_OVER_COLOR : uint = 0xaaaaaa;//0x00aaff;
		public var PLAYLIST_ITEM_CLICK_COLOR : uint = 0x66ccff;
		
		public var PLAYLIST_ITEM_FONT_COLOR : uint = 0xFFFFFF;
		public var PLAYLIST_ITEM_FONT_OVER_COLOR : uint = 0xFFFFFF;
		public var PLAYLIST_ITEM_FONT_SELECTED_COLOR : uint = 0x000000; 
		public var PLAYLIST_ITEM_FONT_CLICK_COLOR : uint = 0x000000;
		
		private var MINI_MODE : Boolean = false;
		private var _continuousScroll : Boolean = true;			

		
		public function PlaylistItem (trackData:ITrackData, w:Number, h:Number, 
									 itemFormat : TextFormat,
									 baseColor : Number = 0x3d3d3d, 
									 selectedColor : Number = 0x00aaff,
									 overColor : Number = 0xaaaaaa,
									 clickColor : Number = 0x66ccff,
									 fontColor : Number = 0xffffff,
									 fontOverColor : Number = 0xffffff,
									 fontSelectedColor : Number = 0x000000,
									 fontClickColor : Number = 0x000000,
									 includeArtistName : Boolean = false,
									 continuousScroll : Boolean = true) {
			// Set input variables
			_baseColor = baseColor;
			_width = w;
			_height = h;
			_includeArtistName = includeArtistName;
			track = trackData;
			
			PLAYLIST_ITEM_SELECTED_COLOR 	= selectedColor;
			PLAYLIST_ITEM_OVER_COLOR 		= overColor;
			PLAYLIST_ITEM_CLICK_COLOR 		= clickColor;
			PLAYLIST_ITEM_FONT_COLOR 		= fontColor;
			PLAYLIST_ITEM_FONT_OVER_COLOR 	= fontOverColor;
			PLAYLIST_ITEM_FONT_SELECTED_COLOR = fontSelectedColor;
			PLAYLIST_ITEM_FONT_CLICK_COLOR 	= fontClickColor;			
			_itemFormat = itemFormat;
			_continuousScroll = continuousScroll;
			
			MINI_MODE = (_width <= 180);
			
			init()
			createChildren();
			configureListeners();
			
			setSize(w,h);
		}
		
		
		private function init() : void {
//			styles = GlobalStyleManager.getInstance();
			// Retrieve styles
//			PLAYLIST_ITEM_SELECTED_COLOR = styles.getPlaylistItemSelectColor();
//			PLAYLIST_ITEM_OVER_COLOR = styles.getPlaylistItemOverColor();
//			PLAYLIST_ITEM_CLICK_COLOR = styles.getPlaylistItemClickColor();
//			PLAYLIST_ITEM_FONT_COLOR = styles.getPlaylistItemFontColor();
//			PLAYLIST_ITEM_FONT_OVER_COLOR = styles.getPlaylistItemFontOverColor();
//			PLAYLIST_ITEM_FONT_SELECTED_COLOR = styles.getPlaylistItemFontSelectColor();
//			PLAYLIST_ITEM_FONT_CLICK_COLOR = styles.getPlaylistItemFontClickColor();
			
			selectedTextTransform = new ColorTransform();
			selectedTextTransform.color = PLAYLIST_ITEM_FONT_SELECTED_COLOR;
			
			unSelectedTextTransform = new ColorTransform();
			unSelectedTextTransform.color = PLAYLIST_ITEM_FONT_COLOR;			
		}
		
		
		private function createChildren():void {
			bgBtn = new SimpleButton();
			addChild(bgBtn);
			
			bg = new Sprite();
			addChild(bg);
			
			playPauseBtn = new ToggleButton(new PlayBtn(), false);
			playPauseBtn.scaleX = playPauseBtn.scaleY = .5;
			addChild(playPauseBtn);
			playPauseBtn.visible = false;
			playPauseBtn.alpha = .5;
			var clip : MovieClip = playPauseBtn.mc;
			plyBtnColorTransform = clip.transform.colorTransform;
			plyBtnColorTransform.color = PLAYLIST_ITEM_FONT_COLOR;
			clip.transform.colorTransform = plyBtnColorTransform;			

			timeLabel = new TextField();
			timeLabel.width = 50;
			timeLabel.height = BUTTON_HEIGHT;
			timeLabel.embedFonts = true;
			timeLabel.autoSize = "left";
			
			var timeformatOut : TextFormat = new TextFormat();
			trace("_itemFormat: " +  _itemFormat.font);
			timeformatOut.font = _itemFormat.font;
			timeformatOut.color = PLAYLIST_ITEM_FONT_COLOR;           
			timeformatOut.size = Number(_itemFormat.size) - 2;		
			
			var headerArtistFormat : TextFormat = new TextFormat();
			headerArtistFormat.font = _itemFormat.font;
			headerArtistFormat.size = Number(_itemFormat.size) - 1;
			headerArtistFormat.color = PLAYLIST_ITEM_FONT_COLOR;
			
			timeLabel.antiAliasType = AntiAliasType.ADVANCED;			
			timeLabel.defaultTextFormat = timeformatOut;
			addChild(timeLabel);	
			
			marqueeLabel = new MaskTextMarquee(100, 20,_continuousScroll);
			marqueeLabel.setTitleTextFormat(_itemFormat);
			marqueeLabel.setArtistTextFormat(headerArtistFormat);
			marqueeLabel.setTitleText(track.getTrack().title);
			//include artist name
			if (_includeArtistName)  marqueeLabel.setArtistText(" by " + track.getTrack().artistName);
			
			marqueeLabel.setSize((_width - (PLAYER_PAD*4) - timeLabel.width), BUTTON_HEIGHT);
			addChild(marqueeLabel)
			
			if (track.getTrack().mediaType == Track.MEDIA_TYPE_VIDEO) {
				videoIcon = new TextField();
				videoIcon.width = 30;//styles.BUTTON_WIDTH;
				videoIcon.height = BUTTON_HEIGHT;
				videoIcon.autoSize = "right";
				videoIcon.embedFonts = true;
				videoIcon.defaultTextFormat = timeformatOut;
				videoIcon.antiAliasType = AntiAliasType.ADVANCED;		
				videoIcon.text = "VIDEO ";	
				addChild(videoIcon);	
				
				marqueeLabel.setSize((_width - (PLAYER_PAD*4) - timeLabel.width - videoIcon.width), BUTTON_HEIGHT);
			}
			
			playlistItemHitArea = new Sprite();
			playlistItemHitArea.buttonMode = true;
			playlistItemHitArea.useHandCursor = true;
			addChild(playlistItemHitArea);
			
			drawBg(_baseColor);
		}
		
		private function configureListeners():void {
			playlistItemHitArea.addEventListener(MouseEvent.MOUSE_OUT, handleMouseEvent);
			playlistItemHitArea.addEventListener(MouseEvent.MOUSE_OVER, handleMouseEvent);
			playlistItemHitArea.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseEvent);
			playlistItemHitArea.addEventListener(MouseEvent.CLICK, handleMouseEvent);
		}
		
		private function handleMouseEvent( e : MouseEvent) : void {
			var type : String = e.type;
			switch (type) {
				case MouseEvent.MOUSE_OUT:
					if (selected) return;
					TweenLite.to(bg, .2, {tint:_baseColor});
					TweenLite.to(marqueeLabel, .2, {tint:PLAYLIST_ITEM_FONT_COLOR});
					TweenLite.to(timeLabel, .2, {tint:PLAYLIST_ITEM_FONT_COLOR});		
					if (videoIcon && this.contains(videoIcon)) TweenLite.to(videoIcon, .2, {tint:PLAYLIST_ITEM_FONT_COLOR});		
					playPauseBtn.visible = false;
					marqueeLabel.stopScrollText();

					break;
				
				case MouseEvent.MOUSE_OVER:
					marqueeLabel.doScrollText();
					
					if (selected) return;
					TweenLite.to(bg, .2, {tint:PLAYLIST_ITEM_OVER_COLOR});
					TweenLite.to(marqueeLabel, .2, {tint:PLAYLIST_ITEM_FONT_OVER_COLOR});
					TweenLite.to(timeLabel, .2, {tint:PLAYLIST_ITEM_FONT_OVER_COLOR});
					if (videoIcon && this.contains(videoIcon)) TweenLite.to(videoIcon, .2, {tint:PLAYLIST_ITEM_FONT_OVER_COLOR});		
					
					playPauseBtn.visible = true;
					break;
				
				case MouseEvent.MOUSE_DOWN:
					if (selected) return;
					TweenLite.to(bg, .2, {tint:PLAYLIST_ITEM_CLICK_COLOR});
					TweenLite.to(marqueeLabel, .2, {tint:PLAYLIST_ITEM_FONT_CLICK_COLOR});
					TweenLite.to(timeLabel, .2, {tint:PLAYLIST_ITEM_FONT_CLICK_COLOR});
					if (videoIcon && this.contains(videoIcon)) TweenLite.to(videoIcon, .2, {tint:PLAYLIST_ITEM_FONT_CLICK_COLOR});		
					
					break;
				
				case MouseEvent.CLICK:
					//if (selected) return;
					dispatchEvent(new Event(Event.SELECT));
					break;
			}
		}
		
		private function changeChildColors( color : uint ) : void
		{
			TweenLite.to(bg, .2, {tint:PLAYLIST_ITEM_OVER_COLOR});
			TweenLite.to(marqueeLabel, .2, {tint:PLAYLIST_ITEM_FONT_OVER_COLOR});
			TweenLite.to(timeLabel, .2, {tint:PLAYLIST_ITEM_FONT_OVER_COLOR});
			if (videoIcon && this.contains(videoIcon)) TweenLite.to(videoIcon, .2, {tint:PLAYLIST_ITEM_FONT_OVER_COLOR});		
			//playPauseBtn.mc.transform.colorTransform = color;			
		}
		
		
		
		private function handleSelected():void {
			
			if (selected) {
				// Item has been selected - transform appropriate colors to over states
				TweenLite.to(bg, .2, {tint:PLAYLIST_ITEM_SELECTED_COLOR});
				TweenLite.to(marqueeLabel, .2, {tint:PLAYLIST_ITEM_FONT_SELECTED_COLOR});
				
				playPauseBtn.selected = !track.isPlaying();
				playPauseBtn.visible = true;
				
				timeLabel.transform.colorTransform = selectedTextTransform;
				playPauseBtn.mc.transform.colorTransform = selectedTextTransform;
				
				if(videoIcon) {	videoIcon.transform.colorTransform = selectedTextTransform; }
				
			} else {
				// Item has been unselected - transform appropriate colors to normal states
				TweenLite.to(bg, .2, {tint:_baseColor});
				playPauseBtn.selected = playPauseBtn.visible = false;
				
				timeLabel.transform.colorTransform = unSelectedTextTransform;
				TweenLite.to(marqueeLabel, .2, {tint:PLAYLIST_ITEM_FONT_COLOR});
				playPauseBtn.mc.transform.colorTransform = unSelectedTextTransform;
				
				if(videoIcon) { videoIcon.transform.colorTransform = unSelectedTextTransform; }
			}			
		}		
		
		public function setIcon(isPlaying:Boolean):void {
			//trace("setIcon : " + isPlaying + " track: " + track.isPlaying());
			playPauseBtn.selected = isPlaying;
		}
		
		public function update():void {
			playPauseBtn.selected = track.isPlaying();
		}
		
		private function handleEnabled():void {
			if(this.enabled) {
				if (!selected){
					drawBg(_baseColor);
				} else {
					drawBg(PLAYLIST_ITEM_SELECTED_COLOR);
				}	
			} else {
				drawBg(BG_COLOR_DISABLED);
			}
		}		
		
		/**
		 *  
		 * @param fillColor
		 * 
		 */
		private function drawBg( fillColor : Number = 0x515151):void {
			//			trace("drawBG: track[" + track.getId() + "] [" + fillColor +"]");
			
			if (timeLabel) {
				timeLabel.textColor = (fillColor == _baseColor) ? _outColor : _overColor ;//PLAYLIST_ITEM_OVER_COLOR;
				//				trace(fillColor, _baseColor, fillColor == _baseColor, track.getTrack().id);
			}
			if (videoIcon) {
				videoIcon.textColor = (fillColor == _baseColor) ? _outColor : _overColor;
			}
			
			bg.graphics.clear();
			bg.graphics.beginFill(fillColor, (selected) ? 1 : .8);
			bg.graphics.drawRect(1,0,_width-2, _height-1);
			bg.graphics.endFill();
			
			playlistItemHitArea.graphics.clear();
			playlistItemHitArea.graphics.beginFill(0x000000, 0);
			playlistItemHitArea.graphics.drawRect(1, 0, _width - 2, _height - 1);
			playlistItemHitArea.graphics.endFill();		
		}
		
		private function draw():void {
			drawBg(_baseColor);
			//			selected = selected;
			handleSelected();
			var duration : Number = track.getDuration();	
			timeLabel.text = StringUtils.formatTime(duration, useLongFormat);
			
			playPauseBtn.x = (MINI_MODE) ? 2 : 4;
			trace("PLAYLIST ITEMS: " + MINI_MODE, playPauseBtn.x, _width);
			timeLabel.x = _width - timeLabel.width - 2;
			
			marqueeLabel.x = playPauseBtn.x + playPauseBtn.width;			
			marqueeLabel.y = (_height - marqueeLabel.height) / 2;
			
			// ADDED
			var tw : Number = (MINI_MODE) ? 0 : timeLabel.width;
			if (track.getTrack().mediaType == Track.MEDIA_TYPE_VIDEO) {
				marqueeLabel.setSize((_width - (PLAYER_PAD * 2) - tw - videoIcon.width), BUTTON_HEIGHT);
			} else {
				marqueeLabel.setSize((_width - (PLAYER_PAD * 2) - tw), BUTTON_HEIGHT);				
			}
			
			playPauseBtn.y = (_height - playPauseBtn.height) / 2;
			var offset : Number = 4;
			
			setChildIndex(marqueeLabel, numChildren - 2);
			setChildIndex(playlistItemHitArea, numChildren - 1);
			
			timeLabel.y = (_height - timeLabel.height)/2 ;
			timeLabel.visible = (!MINI_MODE);
			
			if (videoIcon && this.contains(videoIcon)) {
				videoIcon.x = (!MINI_MODE) ? timeLabel.x - videoIcon.width : _width - videoIcon.width - 2;
				videoIcon.y = timeLabel.y;
			}			
		}
		
		/**
		 * Set size of the item 
		 * @param w
		 * @param h
		 * 
		 */		
		public function setSize(w:Number, h:Number):void {
			_width = w;
			_height = h;
			
			draw();
		}
		
		
		/*******************************************
		 ** GETTER SETTERS                      
		 ******************************************/	
		
		public function get enabled():Boolean {
			return _enabled;
		}
		
		public function set enabled(enabled:Boolean):void {
			_enabled = enabled;
			//handleEnabled();
		}
		
		public function get selected():Boolean {
			return _selected;
		}
		
		public function set selected(selected:Boolean):void {
			_selected = selected;
			handleSelected();			
		}
		
		public function get text():String {
			return track.getTrack().title;
		}
		
		public function set text(t:String):void {
			_text = t;
			draw();
		}
		
	}
	
}


