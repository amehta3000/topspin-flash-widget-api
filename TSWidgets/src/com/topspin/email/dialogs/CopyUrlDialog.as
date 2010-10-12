package com.topspin.email.dialogs
{
	import com.topspin.controls.SimpleLinkButton;
	
	import flash.display.Sprite;
	
	public class CopyUrlDialog extends Sprite
	{
		protected var titleLabel : Label;

		protected var titleStr : String = "Embed this Player";;
		protected var copyEmbedStr : String = "Copy embed code";
		protected var copyURLStr : String = "Copy URL";
		protected var copyConfirmStr : String = "Copied!";
		private var PADDING : Number;

		//components
		public var copyBtn : SimpleLinkButton;	
		public var  copyBtn2 : SimpleLinkButton;
		
		public var embedCodeString : String;

		public var offer_url : String;
		public var closeBtn : SimpleLinkButton;
		protected var rule : Shape; 
		
		protected var showBoth : Boolean = true;		
		
		public function CopyUrlDialog( w : Number = 400, h : Number = 400)
		{
			_width = w;
			_height = h;
			alpha = 0;
			dm = DataManager.getInstance();
			PADDING = styles.PADDING;		
			styles = GlobalStyleManager.getInstance();
			
			this.graphics.clear();
			this.graphics.beginFill(styles.getBaseColor(), 1);
			this.graphics.drawRect(0,0,_width, _height);
			this.graphics.endFill();				

			createChildren();
		}


		private function createChildren() : void
		{
			
			titleLabel = new Label();
			titleLabel.width = _width - PADDING*2;
			titleLabel.height = styles.BUTTON_HEIGHT;
			titleLabel.setStyle("textFormat", styles.headerTitleFormat);
			titleLabel.textField.antiAliasType = AntiAliasType.ADVANCED;
			titleLabel.text = titleStr;
			addChild(titleLabel);
			rule = createHRule(_width - PADDING*2,0x333333);	
			addChild(rule);

            var linkButtonFormat : TextFormat = new TextFormat(styles.mainFont.fontName,14,styles.getLinkColor());            
            var linkButtonOverFormat : TextFormat = new TextFormat(styles.mainFont.fontName,14,styles.getLinkOverColor());

            var closeButtonFormat : TextFormat = new TextFormat(styles.mainFont.fontName,10,styles.getLinkColor());            
            var closeButtonOverFormat : TextFormat = new TextFormat(styles.mainFont.fontName,10,styles.getLinkOverColor());					

			closeBtn = new SimpleLinkButton("Close", closeButtonFormat, closeButtonOverFormat,null,false,2,2);			
			addChild(closeBtn);					
			
			copyBtn = new SimpleLinkButton(copyEmbedStr, linkButtonFormat, linkButtonOverFormat,null,true,4,3,10,"center",1,true);				
	
	
			//addChild(container);			
			//container.
			addChild(copyBtn);			

			if (showBoth)
			{		
				copyBtn2 = new SimpleLinkButton(copyURLStr, linkButtonFormat, linkButtonOverFormat,null,true,4,3,10,"center",1,true);						
				copyBtn2.setSize(copyBtn.width, copyBtn.height);
				//container.
				addChild(copyBtn2);				
				copyBtn2.addEventListener(MouseEvent.CLICK, handleCopy2);				
			}
			
			closeBtn.addEventListener(MouseEvent.CLICK, handleClose);				
			copyBtn.addEventListener(MouseEvent.CLICK, handleCopy);				
						
			draw();
		}
		
		public function handleCopy(event : MouseEvent) : void
		{
			System.setClipboard(embedCodeString);
			copyBtn.text = copyConfirmStr;
		}			
		
		public function handleCopy2(event : MouseEvent) : void
		{
			System.setClipboard(offer_url);
			copyBtn2.text = copyConfirmStr;
		}					
		
		public function handleClose(event : MouseEvent) : void
		{
			deactivate();
			//BundlePlayerView(parent.parent).destroyDialogs();
		}		
		
		protected function draw() : void
		{
			closeBtn.y = PADDING;
			closeBtn.x = _width - closeBtn.width - styles.PADDING;
			
			titleLabel.y = PADDING;
			titleLabel.x = PADDING;
			rule.x = PADDING;
			rule.y = titleLabel.y + titleLabel.height;					
					
			
			copyBtn.x = (_width - copyBtn.width)/2;
			copyBtn.y = ((_height - rule.y) - copyBtn.height)/2 + rule.y;
			
			if (showBoth)
			{
				copyBtn.y = ((_height - rule.y) - (copyBtn.height*2 + PADDING*3))/2 + rule.y;
				copyBtn2.x = (_width - copyBtn.width)/2;
				copyBtn2.y = copyBtn.y + PADDING*3;			
			}
					
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