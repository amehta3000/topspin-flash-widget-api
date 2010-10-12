package com.topspin.email.controls
{
	import com.topspin.common.controls.SimpleLinkButton;
	import com.topspin.common.controls.TrackBasedScrollbarControl;
	import com.topspin.common.events.DialogEvent;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.style.GlobalStyleManager;
	
	import fl.motion.easing.Cubic;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import gs.TweenLite;
	
	public class InfoControl extends Sprite
	{
//		public var closeBtn : SimpleLinkButton;
		
		private var dm : DataManager;
		protected var rule : Shape; 
		protected var PADDING : Number;
		private var tfholder : Sprite;
		
		protected var styles : GlobalStyleManager;
		private var _bgColor : Number;
		protected var _width : Number;// = 400;
		protected var _height : Number;// = 400;
		
		private static var FADE_RATE : Number = .4;
		protected var bg : Sprite;
		
		private var scrollbar : TrackBasedScrollbarControl;
		private var _drawCurves : Boolean;
		private var MAX_HEIGHT : Number = 300;
		private var PAD : Number = 6;
//		private var holder : Sprite;
		
		public function InfoControl( w : Number = 400, h : Number = 400, bgColor : Number = 0x999999, drawCurves : Boolean = true)
		{
			_width = w;
			_height = h;
			
			if (_height > MAX_HEIGHT)
			{
				_height = MAX_HEIGHT;
			}
			
			_bgColor = bgColor;
//			alpha = 0;
			dm = DataManager.getInstance();
			_drawCurves = drawCurves;
			
			styles = GlobalStyleManager.getInstance();
			
			PADDING = 5;
			
			createChildren();
		}
		
		private var tf : TextField;
		protected function createChildren() : void
		{
			tfholder = new Sprite();
			var fontName : String = styles.getFormattedFontName();
			
			var smOut : TextFormat = new TextFormat(styles.getFormattedFontName(),8,styles.getBaseColor(),true);
			var smOver : TextFormat = new TextFormat(styles.getFormattedFontName(),8,styles.getLinkColor(),true);
			

			var headline : String = dm.getInfoHeadline();
			var content : String = dm.getInfoContent();					
			
			headline = "<textformat leading='2'><header>" + headline + "</header>" ;
			content = "<message>" + content + "</message></textformat>";
			tf = new TextField();
			tf.width = _width-PADDING;
			tf.height =  _height - PADDING*2;			
			tf.autoSize = "left";
			
			tf.multiline = true;
			tf.wordWrap = true;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.styleSheet = styles.infoCSS;	
			tf.embedFonts = true;
			tf.htmlText = headline  + content;  //"<body>" + headline + "</body>"; 

//			tf.selectable = false;
			tf.y = PADDING;
			tf.x = PADDING;
			tfholder.addChild(tf);
			
			addChild(tfholder);
			
			var yPos : Number = tf.textHeight + PADDING;
			
			if (yPos < MAX_HEIGHT - PAD - PADDING )
			{
				_height = tf.height + PAD + PADDING;
			}else{
				_height = MAX_HEIGHT;
			}
			
			if (yPos > _height - PADDING)
			{			
				if(!scrollbar) {
					var holder : MovieClip = new MovieClip();
					tf.y = 0;
					holder.addChild(tfholder);
					addChild(holder);
					
					scrollbar = new TrackBasedScrollbarControl(holder, this._height - PADDING*2  -1, yPos, 16, _bgColor, styles.getBaseColor());
					scrollbar.x = _width - scrollbar.width - 2;
					scrollbar.y = PADDING;
					addChild(scrollbar);
					scrollbar.alpha = .8;
					
					var mmask : Sprite = new Sprite();
					mmask.graphics.clear();
					mmask.graphics.beginFill(0xcc00cc,.5);
					mmask.graphics.drawRect(0,0,_width,_height);
					addChild(mmask);
					tf.mask = mmask;
					
					trace("SCROLLBAR: " + scrollbar);
				}
//				yPos = _height;
			}else{
				yPos = tf.height + 10;
			}		
			
			this.graphics.clear();
			this.graphics.beginFill(_bgColor, 1);
			if (_drawCurves) {
				graphics.drawRoundRectComplex(0,0,_width, _height,0,0,4,4);
			}else{
				graphics.drawRect(0,0,_width, _height);
			}				
			this.graphics.endFill();				
			
		}
		
		public function handleClose(event : MouseEvent) : void
		{
			deactivate();
		}						
		

		public function activate() : void
		{
			
			visible = true;
			alpha = 1;			
			TweenLite.from(this, FADE_RATE, {y:-_height, ease:Cubic.easeIn}); //, onComplete : showit});
			
//			function showit() : void
//			{
//				closeBtn.visible = true;
//			}
		}
		
		public function deactivate() : void
		{			
//			TweenLite.to(this, FADE_RATE, {y:-_height,  ease:Cubic.easeOut,  onComplete : destroyDialog});
//			function destroyDialog() : void
//			{
//				dispatchEvent(new Event(DialogEvent.CLOSE));
//			}
		}
				
		public function getHeight() : Number
		{
			return _height;
		}
		
	}
}