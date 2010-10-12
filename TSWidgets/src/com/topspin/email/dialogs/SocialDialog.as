package com.topspin.email.dialogs
{
	import com.topspin.common.controls.SimpleIconButton;
	import com.topspin.common.controls.SimpleLinkButton;
	import com.topspin.common.events.DialogEvent;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.style.GlobalStyleManager;
	
	import fl.motion.easing.Cubic;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import gs.TweenLite;
	
	public class SocialDialog extends Sprite
	{
		private var ICON_PATH : String = "/widgets/assets/icons/";
		private var ICON_MAP : Array = ["Facebook","MySpace", "Twitter", "Digg", "Delicious"];
		public var closeBtn : SimpleLinkButton;
		protected var titleStr : String = "Share this Widget";;
		
		private var dm : DataManager;
		protected var rule : Shape; 
		protected var PADDING : Number;
		private var icons : Array;
		private var holder : Sprite;
		public var copyBtn : SimpleLinkButton;	
		public var copyUrlBtn : SimpleLinkButton;

		protected var styles : GlobalStyleManager;
		
		protected var _width : Number;// = 400;
		protected var _height : Number;// = 400;
		
		private static var FADE_RATE : Number = .3;
		protected var bg : Sprite;
		
		protected var copyEmbedStr : String = "Copy embed";
		protected var copyConfirmStr : String = "Copied!";
		protected var copyUrlStr : String = "Copy URL";
		
		private var MINI_MODE : Boolean = false;
		private var RESTRICTED_MODE : Boolean = false;
		private var embedCodeString : String;
		
		public function SocialDialog( w : Number = 400, h : Number = 400)
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
			
			RESTRICTED_MODE = !dm.getExternalInterfacesAvailable();
			trace("RESTRICTED_MODE : " + RESTRICTED_MODE);

			MINI_MODE =  ((_width < 250) || (_height < 150));
			PADDING = (MINI_MODE) ? 5 :20;//styles.PADDING;		

			createChildren();
		}

		protected function createChildren() : void
		{
			var titleLabel : TextField = new TextField();
			titleLabel.autoSize = "left";
			titleLabel.text = titleStr;
			titleLabel.embedFonts = true;
			titleLabel.setTextFormat(new TextFormat(styles.getFormattedFontNameLight(), 12, styles.getFontColor(), true));
			if (!MINI_MODE) addChild(titleLabel);
			
			var fontName : String = styles.getFormattedFontNameLight();
			var fontSize : Number = 12;
			
			if (!MINI_MODE)
			{
				rule = createHRule(_width - PADDING*2,0x333333);	
				addChild(rule);		
				fontSize = 12;	
			}else{
				fontSize = 10;
			}
			
            var closeButtonFormat : TextFormat = new TextFormat(fontName,10,styles.getLinkColor());            
            var closeButtonOverFormat : TextFormat = new TextFormat(fontName,10,styles.getLinkOverColor());
			closeBtn = new SimpleLinkButton("Close", closeButtonFormat, closeButtonOverFormat,null,false,2,2);			
			addChild(closeBtn);			
			closeBtn.y = PADDING;
			closeBtn.x = _width - closeBtn.width - PADDING;		
			closeBtn.addEventListener(MouseEvent.CLICK, handleClose);	
			
			holder = new Sprite();
			holder.alpha = 0;
			addChild(holder);
			
			var linkButtonFormat : TextFormat = new TextFormat(fontName,fontSize,styles.getFontColor());			
			var linkButtonOverFormat : TextFormat = new TextFormat(fontName,fontSize,styles.getLinkColor());			

            var copyButtonFormat : TextFormat = new TextFormat(fontName,fontSize,styles.getLinkColor());            
            var copyButtonOverFormat : TextFormat = new TextFormat(fontName,fontSize,styles.getLinkOverColor());

			copyBtn = new SimpleLinkButton(copyEmbedStr, copyButtonFormat, copyButtonOverFormat,copyEmbedStr,true,4,0,(MINI_MODE)?12:10,"center",(MINI_MODE)?1:2,true);		
			copyBtn.addEventListener(MouseEvent.CLICK, handleCopy);	
			holder.addChild(copyBtn);			
			icons  = new Array();

			if (!RESTRICTED_MODE)
			{
				var icon : SimpleIconButton;
				var iconURL : String;
				var icon_name : String;
				var icon_size : String = (MINI_MODE) ? "-16x16.png" : "-24x24.png"; 
				var baseUrl : String = dm.getBaseURL();
				for (var i : Number = 0; i < ICON_MAP.length; i++)
				{
					icon_name = ICON_MAP[i];
					iconURL = baseUrl + ICON_PATH+icon_name+icon_size;
					icon = new SimpleIconButton(iconURL,icon_name, linkButtonFormat,linkButtonOverFormat);
					icon.addEventListener(Event.COMPLETE, handleIconComplete);
					icon.addEventListener(MouseEvent.CLICK, handleIconClick(icon_name));
					icon.name = icon_name;
					icon.load();
					holder.addChild(icon);
					icons.push(icon);
				}			
			}else{
				icons.push(copyBtn);
				
				if (dm.getClickTag()  && dm.getClickTag() != "null" ){	
					copyUrlBtn = new SimpleLinkButton(copyUrlStr, copyButtonFormat, copyButtonOverFormat,copyUrlStr,true,4,0,(MINI_MODE)?12:10,"center",(MINI_MODE)?1:2,true);		
					copyUrlBtn.addEventListener(MouseEvent.CLICK, handleCopyUrl);	
					copyUrlBtn.width = 100;
					copyBtn.width = 100;
					
					holder.addChild(copyUrlBtn);		
					icons.push(copyBtn);
				}

				draw();
				TweenLite.to(holder, .5, {autoAlpha:1,  ease:Cubic.easeIn});
				
			}			
			
			
			titleLabel.y = PADDING;
			titleLabel.x = PADDING;
			if (!MINI_MODE)
			{
				rule.x = PADDING;
				rule.y = closeBtn.y + closeBtn.height;
			}
		}
		public function handleCopy(event : MouseEvent) : void
		{
			System.setClipboard(embedCodeString);
			copyBtn.text = copyConfirmStr;
		}			
		
		public function handleCopyUrl(e : MouseEvent)
		{
			System.setClipboard(dm.getClickTag());
			copyUrlBtn.text = copyConfirmStr;
		}
		private function draw() : void
		{
			var iconInit : Boolean = false;
			var x1 : Number = 0;
			var y1 : Number = 0;
			var initX : Number;
			
			var PAD : Number = (MINI_MODE) ? 1 : 4;
			var icon : Sprite;			
			var rows : Number = (MINI_MODE) ? 2 : 3;
			if (_width<250) rows = 3;
			var offset : Number = (MINI_MODE) ? -1 : -10;
			var count : Number = 0;
			trace("RESTRICTEDL: " + RESTRICTED_MODE + " MINIMODE: " + MINI_MODE + " offset: " + offset);
			if (!RESTRICTED_MODE)
			{
				for (var i : Number=0; i<icons.length; i++)
				{
					icon = icons[i];
					if (!iconInit)
					{
						iconInit = true;
						initX = icon.width;
					}	
					icon.x = x1;			
					icon.y = y1 * (icon.height + PAD*3);
					if (i == icons.length-1) {
						
						trace("Check it = " + icon.y, offset);
						icon.y -= offset;
						trace("Check it 2 = " + icon.y);
					}
					y1++;
					count++;			
					
					if (count == rows)
					{
						count = 0;
						y1 = 0;
						x1 = icon.x + initX + PAD*4;
					}
					if (i == icons.length-3 && MINI_MODE && rows==2) 
					{ 
						x1 -= PAD*4;
					}

				}			
			}
			if (RESTRICTED_MODE && copyUrlBtn)
			{
				var xp : Number = (MINI_MODE) ? 4 : 8;
				copyUrlBtn.y = copyBtn.y + copyBtn.height + xp;
				
			}

			holder.x = (_width - holder.width)/2;
			
			
			if (!MINI_MODE)
			{
				holder.y = ((_height - rule.y) - (holder.height))/2 + rule.y - PAD*2;
			}else{
				holder.y = (_height - closeBtn.y - PADDING - holder.height)/2 + closeBtn.y + PADDING*2 - 2;
			}
		}
		
		private var count:Number = 0;
		private function handleIconClick(name : String) : Function
		{
           return function(mouseEvent:MouseEvent):void
           {
				dm.sharePlatform(name);
           };
		}		
		/**
		 * Handler for load complete, queue it up so you can arrange 
		 * @param e
		 * 
		 */		
		private function handleIconComplete(e : Event) : void
		{
			var clip : SimpleIconButton = e.target as SimpleIconButton;
			count++;
			if (count>= icons.length)
			{
				icons.push(copyBtn);
				
				draw();
				TweenLite.to(holder, .5, {autoAlpha:1,  ease:Cubic.easeIn});
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
			TweenLite.to(this, FADE_RATE, {autoAlpha:1,  ease:Cubic.easeIn});
		}
		
		public function deactivate() : void
		{			
			TweenLite.to(this, FADE_RATE, {autoAlpha:0,  ease:Cubic.easeIn, onComplete : destroyDialog});
			
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