package com.topspin.email.dialogs
{
	import com.topspin.common.controls.TrackBasedScrollbarControl;
	import com.topspin.common.events.DialogEvent;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.style.GlobalStyleManager;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class FatalDialog extends Sprite
	{
//		public var closeBtn : SimpleLinkButton;
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
		
		private var _headline : String = "Sorry";
		private var _content : String = "Thank you for your interest in registering. As we are committed to protecting your privacy, we are unable to accept your registration. However, we invite you to continue browsing the site without registering.";
		
		
		public function FatalDialog( w : Number = 400, h : Number = 400, headline : String = null, content : String = null )
		{
			_width = w;
			_height = h;
			alpha = 0;
			dm = DataManager.getInstance();
			
			if (headline) _headline = headline;
			if (content) _content = content;
			
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
					var headline : String = dm.getInfoHeadline();
			
			//_headline = "<textformat leading='2'><h1>" + _headline + "</h1>" ;
			_content = "<textformat leading='2'><content>" + _content + "</content></textformat>";

			tf = new TextField();
			tf.autoSize = "left";
			tf.embedFonts = true;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.styleSheet = styles.optionsCSS;	
			tf.htmlText = _content;  //"<body>" + headline + "</body>"; 
			tf.width = _width-PADDING;
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

					scrollbar = new TrackBasedScrollbarControl(holder, this._height - PADDING*2, yPos, 16, styles.getBaseColor());
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
//			TweenLite.from(this, FADE_RATE, {y:-_height, ease:Cubic.easeIn, onComplete : showit});
			
			function showit() : void
			{
//				closeBtn.visible = true;
			}
		}
		
		public function deactivate() : void
		{			
//			closeBtn.visible = false;
//			TweenLite.to(this, FADE_RATE, {y:-_height,  ease:Cubic.easeOut,  onComplete : destroyDialog});
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