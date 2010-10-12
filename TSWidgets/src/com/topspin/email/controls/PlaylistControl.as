package com.topspin.email.controls
{
	import com.topspin.api.data.ITSPlaylist;
	import com.topspin.api.data.media.ITrackData;
	import com.topspin.api.data.media.Playlist;
	import com.topspin.common.controls.AbstractControl;
	import com.topspin.common.controls.TrackBasedScrollbarControl;
	import com.topspin.common.events.PlaylistEvent;
	import com.topspin.email.style.GlobalStyleManager;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import gs.TweenLite;
	
	public class PlaylistControl extends AbstractControl {
		// Instances
		private var _inited : Boolean = false;
		
//		private var controller : Controller;  // Singleton reference to the controller
		private var _playlist : ITSPlaylist;  // Singleton reference to the playlist Model
//		private var dm : DataManager;
		private var styles : GlobalStyleManager;
		
		// UI Elements
		private var container : MovieClip;  // Holds all playlist items (element that is scrolled)
		private var maskClip : MovieClip;  // Masks container
		private var scrollbar:TrackBasedScrollbarControl;  // Scrollbar
		
		// Properties		
		private var items : Array;  // Array of playlist items
		private var totalTracks : Number;  // Total number of tracks
		private	var tracks : Array;  // Arrray of the tracks
		private var currentlySelectedItem : PlaylistItem;  // Reference to the currently selected item
		
		// Static
		private static var itemHeight : Number = 26;
//		private static var MINIMUM_HEADER_HEIGHT:Number = 84;
		public static var PLAYLIST_CONTROL_IDLE:String = "playlistControlIdle";
		public static var PLAYLIST_CONTROL_NOT_IDLE:String = "playlistControlNotIdle";
		
		// State variables
		private var timer:Timer;
		private var isIdle:Boolean = false;
		private var playlistControlDrawn:Boolean = false;
		private var scrollbarNeeded:Boolean = false;
		
		private var _itemColor1 : Number;
		private var _itemColor2 : Number;
		private var _selectedColor : Number;
		private var _drawCurves : Boolean;
		private var bgColor : Number = 0x333333;
		private var btnColor : Number = 0x333333;		
		
//		private var bgColor : Number = 0x333333;
		
		private var MINI_MODE : Boolean = false;
		private var _includeArtistName : Boolean;

		
		public function PlaylistControl(w : Number, h : Number, playlist : ITSPlaylist, selectedColor : Number, 
										itemColor1 : Number = 0x515151, 
										itemColor2 : Number = 0x3D3D3D,
										includeArtistName : Boolean = false,
										drawCurves : Boolean = true) {
			_width = w;
			_height = h;
			_playlist = playlist;
			
			_itemColor1 = itemColor1;
			_itemColor2 = itemColor2;
			_selectedColor = selectedColor;
 			_includeArtistName = includeArtistName;
			_drawCurves = drawCurves;
			
			MINI_MODE =  (_width <= 200); 
			itemHeight = (MINI_MODE) ? 20 : 26;
			
			trace("PlaylistControl width: " + _width);
			
			init();
			createChildren();
		}
		
		/**
		 * initialize data 
		 * 
		 */		
		private function init():void {
			totalTracks = _playlist.getTotalTracks();
			styles = GlobalStyleManager.getInstance();
			items = new Array();
		}
				
		public override function setSize(w:Number, h:Number):void {
			super.setSize(w, h);
			// playlistHeader.setSize(w, h);
		}
		
		/**
		 * Create the UI  
		 * 
		 */
		private function createChildren():void {
			container = new MovieClip();
//			container.alpha = 0;
			maskClip = new MovieClip();
			
			
			graphics.clear();
			graphics.beginFill(bgColor, 1);
			if (_drawCurves) {
				graphics.drawRoundRectComplex(0,0,_width, _height,0,0,4,4);
			}else{
				graphics.drawRect(0,0,_width, _height);
			}	
			graphics.endFill();				
			
			addChild(maskClip);
			
			var playlistItem : PlaylistItem;
			var t : ITrackData;
			var colors : Array = [_itemColor1,_itemColor2];
			
			var fontSize : Number = (MINI_MODE) ? 8 : 10;
			var format : TextFormat = new TextFormat(styles.getFormattedFontName(),fontSize,styles.getFontColor());
			
			for (var i:Number = 0; i < totalTracks; i++) {
				t = _playlist.getTrackByIndex(i);
				playlistItem = new PlaylistItem(t, _width, itemHeight, format, colors[i%2], _selectedColor,0xaaaaaa, 0x66ccff, 0xffffff
												,0xffffff,0x000000,0x000000,_includeArtistName);
				
				container.addChild(playlistItem);
				items.push(playlistItem);
				playlistItem.addEventListener(Event.SELECT, handleItemClick);				
			}
			
//			container.mask = maskClip;
			addChild(container);
			
			_inited = true;
			draw();
			
//			this.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
		}		
		

		
		/**
		 * Handles the item click. 
		 * @param event
		 * 
		 */		
		private function handleItemClick(event:Event):void {
			trace("ITEM IS CLICKED");
//			controller.setChangeState();
			var item : PlaylistItem = event.target as PlaylistItem;
			dispatchEvent(new PlaylistEvent(PlaylistEvent.CHANGE,item, item.track));
		}
		
		/**
		 * Utility method to select the proper item based on the
		 * ITrackDate within the PlaylistItem 
		 * @param track
		 * 
		 */		
		private function selectItemByTrack(track:ITrackData):void {
			if (currentlySelectedItem.track != track) {			
				for (var i:Number = 0; i<items.length; i++) {	
					//					trace("selectItemByTrack : " + track.id);
					if (items[i].track == track) {
						currentlySelectedItem.selected = false;
						currentlySelectedItem = items[i];
						currentlySelectedItem.selected = true;
						currentlySelectedItem.setIcon(track.isReady());
					}
				}	
			}	
		}
		
		protected override function draw():void {
			
			if (!_inited) return;
			var vpad : Number = 0;
			trace("PlaylistControl DRAW items: " + items.length);

			maskClip.graphics.clear();
			maskClip.graphics.beginFill(0xcc2211, 1);
			maskClip.graphics.drawRect(0,0,_width, _height - 4);
			maskClip.graphics.endFill();	
						
			container.mask = maskClip;			
			
			// trace("PLAYLISTCONTROL : DRAW " + _width);
			var item : PlaylistItem;
			var lastY : Number = 0;
			var headerHeight : Number;
			var track : ITrackData = _playlist.getCurrentTrack();
			var listH : Number = 0;//itemHeight;
			
			var trackHeight:Number = this.totalTracks * (itemHeight + 1);  // Determine the amount of vertical space the tracks will take up

			
			// Add the playlistItems to the screen
			for (var i:Number = 0; i < items.length; i++) {	// Iterate through the items array (Items is a stack that contains all of the playlistItems)	
				item = items[i] as PlaylistItem;
				item.setSize(_width - 4, itemHeight);
				if (item.track == track) {
					trace("selected : " + track);
					setSelectedItem(item);
				}
				item.addEventListener(Event.SELECT, handleItemClick);
				item.y = lastY + 1;
				item.x = 2;
				lastY += itemHeight;
				listH += itemHeight;
			}
			
//			playlistHeader.update();
			// Scrollbar functionality
			
			
			if (listH > _height) {  // Scrollbar is needed in the UI
				//				trace("PLAYLIST CONTROL I SHOULD HAVE  SCROLLBAR");
				if(!scrollbar) {
					scrollbar = new TrackBasedScrollbarControl(container, this._height - 10, listH, itemHeight, bgColor, styles.getBaseColor());
					addChild(scrollbar);
					scrollbar.alpha = .8;
					trace("SCROLLBAR: " + scrollbar);
				}
				
				scrollbar.x = _width - scrollbar.width - 2;
				scrollbar.y = 0;
				
	
				var newW : Number = _width - scrollbar.width - 5;
				for (i = 0; i<items.length; i++) {			
					item = items[i] as PlaylistItem;
					item.setSize(newW,itemHeight);
					if (item.track == track) {
						setSelectedItem(item);
					}					
				}	 
				listH = _height;
				vpad = 0;				
				
			}
			else {	// Scrollbar isn't needed in the UI
				if(scrollbar && this.contains(scrollbar)) {					
					removeChild(scrollbar);
					scrollbar = null;  //set it to null so it gets recreated again on the draw method
				}
				container.y = 0;
				vpad = 4;
			}		
			
			graphics.clear();
			graphics.beginFill(bgColor, 1);
			if (_drawCurves) {
				graphics.drawRoundRectComplex(0,0,_width, listH + vpad,0,0,4,4);
			}else{
				graphics.drawRect(0,0,_width, listH + vpad);
			}	
			graphics.endFill();				
		}		
		
		/**
		 * Set the selected item  
		 * @param item
		 * 
		 */		
		private function setSelectedItem(item:PlaylistItem):void {
			if (currentlySelectedItem && currentlySelectedItem!=item) {
				currentlySelectedItem.selected = false;
			} 
			currentlySelectedItem = item;
			currentlySelectedItem.setIcon(item.track.isReady());				
			currentlySelectedItem.selected = true;
		}
		
		private var _currentTrack : ITrackData;
		public function setCurrentTrack( t : ITrackData ) : void
		{
			_currentTrack = t;
		}
		/**
		 * Called when model is changed either
		 * because a new track is selected or 
		 * whatever. 
		 * 
		 */		
		public override function update():void {
			if (!_inited) return;
			
//			var t : ITrackData = controller.getCurrentTrack(); 
			var t : ITrackData = _playlist.getCurrentTrack();
			currentlySelectedItem.setIcon(t.isPlaying());			
//			trace("playlistConotrl : " + t.getId());
			if (currentlySelectedItem.track != t) {
				selectItemByTrack(t);
				currentlySelectedItem.setIcon(t.isPlaying());
			}
		}
		
		/*******************************************
		 ** GETTER SETTERS                      
		 ******************************************/		
		
		
	}
}