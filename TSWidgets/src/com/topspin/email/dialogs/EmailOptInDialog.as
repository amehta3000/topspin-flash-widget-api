package com.topspin.email.dialogs
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
	
	public class EmailOptInDialog extends Sprite
	{
		public var closeBtn : SimpleLinkButton;
//		public var infoBtn
		
		private var dm : DataManager;
		protected var rule : Shape; 
		protected var PADDING : Number;
		private var holder : Sprite;

		protected var styles : GlobalStyleManager;
		
		protected var _width : Number;// = 400;
		protected var _height : Number;// = 400;
		
		private static var FADE_RATE : Number = .4;
		protected var bg : Sprite;
		
		private var embedCodeString : String;
		private var scrollbar : TrackBasedScrollbarControl;
		
		
		public function EmailOptInDialog( w : Number = 400, h : Number = 400)
		{
			_width = w;
			_height = h;
			alpha = 0;
			dm = DataManager.getInstance();
			
			embedCodeString = dm.getEmbedCode();
			
			styles = GlobalStyleManager.getInstance();
			
			this.graphics.clear();
			this.graphics.beginFill(styles.getBaseColor(), 1);
			this.graphics.drawRect(0,0,_width, _height);
			this.graphics.endFill();				
			
			PADDING = 5;
			
			createChildren();
		}
	
		private var tf : TextField;
		protected function createChildren() : void
		{
			var fontName : String = styles.getFormattedFontName();

			var smOut : TextFormat = new TextFormat(styles.getFormattedFontName(),8,styles.getBaseColor(),true);
			var smOver : TextFormat = new TextFormat(styles.getFormattedFontName(),8,styles.getLinkColor(),true);
			
			closeBtn = new SimpleLinkButton(" X ", smOut, smOver, null,true, 0, 0, 0,"center",1,true); 
			closeBtn.borderOverColor = styles.getLinkColor();
			closeBtn.alpha = .8;		
			closeBtn.y = _height - closeBtn.height - 1;
			closeBtn.x = _width - closeBtn.width - 1;	
			addChild(closeBtn);
			closeBtn.visible = false;		
			closeBtn.addEventListener(MouseEvent.CLICK, handleClose);			

			var headline : String = dm.getInfoHeadline();
			var content : String = dm.getInfoContent();					
			
			headline = "<textformat leading='2'><header>" + headline + "</header>" ;
			content = "<message>" + content + "</message></textformat>";
			tf = new TextField();
			tf.autoSize = "left";
			tf.embedFonts = true;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.styleSheet = styles.optionsCSS;	
			tf.htmlText = headline  + content;  //"<body>" + headline + "</body>"; 
			tf.width = _width-PADDING - closeBtn.width;
			tf.height =  _height - PADDING*2;
			tf.selectable = false;
			tf.y = PADDING;
			tf.x = PADDING;

			addChild(tf);
			
			var yPos : Number = tf.textHeight;
			if (yPos > _height - PADDING)
			{			
				if(!scrollbar) {
					var holder : MovieClip = new MovieClip();
					tf.y = 0;
					holder.addChild(tf);
					addChild(holder);

					scrollbar = new TrackBasedScrollbarControl(holder, this._height - PADDING*2 - closeBtn.height -1, yPos, 16, styles.getBaseColor());
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
			}
			
		}

		public function handleClose(event : MouseEvent) : void
		{
			deactivate();
		}						
		
		/**
		 * Creates an hrule acrross this piece 
		 * @param width
		 * @param strokeColor
		 * @param shadowColor
		 * @return 
		 * 
		 */
		public static function createHRule( width : Number = 200, strokeColor : Number = 0x666666, shadowColor : Number = 0x000000) : Shape {
			var rule : Shape = new Shape();
			rule.graphics.moveTo(0,0);
			rule.graphics.lineStyle(1,strokeColor);
			rule.graphics.lineTo(width,0);
			rule.graphics.lineStyle(1,shadowColor);
			rule.graphics.moveTo(0,1);
			rule.graphics.lineTo(width,1);
			return rule;									
		}		
		
		public function activate() : void
		{
			
			visible = true;
			alpha = 1;			
			TweenLite.from(this, FADE_RATE, {y:-_height, ease:Cubic.easeIn, onComplete : showit});

//			TweenLite.to(this, FADE_RATE, {autoAlpha:1,  ease:Cubic.easeIn});
			
			function showit() : void
			{
				closeBtn.visible = true;
			}
		}
		
		public function deactivate() : void
		{			
			closeBtn.visible = false;
			TweenLite.to(this, FADE_RATE, {y:-_height,  ease:Cubic.easeOut,  onComplete : destroyDialog});
			function destroyDialog() : void
			{
				dispatchEvent(new Event(DialogEvent.CLOSE));
			}
			
		}
		
		public function centerIt( a : DisplayObject, b : DisplayObject, centerX : Boolean = true ) : void
		{
			if (centerX)
			{
				b.x = Math.floor((a.width - b.width)/2);
			}else{
				b.y = Math.floor((a.height - b.height)/2);
			}
			
		}		
				
	
	}
}