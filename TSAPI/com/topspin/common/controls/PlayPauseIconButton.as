package com.topspin.common.controls
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	
	import gs.TweenLite;
	
	public class PlayPauseIconButton extends Sprite
	{
		
		private var holder : Sprite;
		private var bg : Shape;
		private var outline : Shape;
		private var playIcon : Shape;
		private var pauseIcon : Shape;
		
		//properties
		private var _width : Number;
		private var _height : Number;
		private var _outColor : Number;
		private var _bgAlpha : Number;
		private var _overColor : Number;
		private var _iconColor : Number;
		private var _iconOverColor : Number;
		private var _cornerRadius : Number;
		private var _inited : Boolean = false;
		
		private var _drawBorder : Boolean;
		
		private var PAD : Number = 5;
		private var _pausePad : Number = 2;
		private var currentTransform = new ColorTransform();
		
		private var _selected : Boolean = false;
		
		public function PlayPauseIconButton(w : Number = 50, h : Number = 50, outColor : Number = 0xCACACA, overColor : Number = 0x17CAFB, 
											iconColor : Number = 0xffffff, iconOverColor : Number = 0xffffff, drawBorder : Boolean = false, 
											cornerRadius : Number = 2,
											bgAlpha : Number = 1)
		{
			this._width = w;
			this._height = h;
			this._outColor = outColor;
			this._overColor = overColor;
			this._drawBorder = drawBorder;
			this._iconColor = iconColor;
			this._iconOverColor = iconOverColor;
			this._cornerRadius = cornerRadius;
			this._bgAlpha = bgAlpha;
			
			if (_width >= 30)
			{
				pausePad = Math.floor((((_width * .8))/2) * .25);  
			}
			
			init();
		}
		private function init() : void
		{
			holder = new Sprite();
			bg = new Shape();
			outline = new Shape();
			playIcon = new Shape();
			pauseIcon = new Shape();
			
			createChildren();
		}
		
		private function createChildren() : void
		{
			bg.visible = false;
			addChild(bg);
			holder.addChild(outline);
			holder.addChild(playIcon);
			holder.addChild(pauseIcon);
			
			addChild(holder);		
			
			configureListeners();	
			_inited = true;
			draw();
		}
		
		public function setPad( padBuffer : Number = 5) : void
		{
			PAD = padBuffer;
			draw();
		}
		
		public function set pausePad( padBuffer : Number) : void
		{
			_pausePad = padBuffer;
			draw();
		}
		public function get pausePad() : Number
		{
			return _pausePad;
		}		
		
		private function draw() : void
		{
			if (!_inited) return;
			
			this.graphics.clear();
			this.graphics.beginFill(_outColor,_bgAlpha);
			this.graphics.drawRoundRect(0,0,_width,_height,_cornerRadius,_cornerRadius);
			this.graphics.endFill();
			
			bg.graphics.clear();
			bg.graphics.beginFill(_overColor,1);
			bg.graphics.drawRoundRect(0,0,_width,_height,_cornerRadius,_cornerRadius);
			bg.graphics.endFill();
			
			outline.graphics.clear();
			if (_drawBorder) {
				outline.graphics.lineStyle(1,_outColor,1);
			}
			outline.graphics.beginFill(_outColor,0);
			outline.graphics.drawRoundRect(0,0,_width,_height,_cornerRadius,_cornerRadius);
			outline.graphics.endFill();	
			
			var playH : Number = (_height - PAD*2);
			var playW : Number = playH - 2;
			
			playIcon.graphics.clear();
			playIcon.graphics.beginFill(_iconColor);
			playIcon.graphics.moveTo(0,0);
			playIcon.graphics.lineTo(playW, playH/2);
			playIcon.graphics.lineTo(0, playH);
			playIcon.graphics.lineTo(0, 0);
			playIcon.graphics.endFill();			
			
			var pPad : Number = pausePad;
			var pW : Number = (playW-pPad)/2;		
			var g : Graphics = pauseIcon.graphics;
			g.clear();
			g.beginFill(_iconColor);
			g.drawRect(0,0,pW,playH);
			g.drawRect(pW+pPad,0,pW,playH);
			g.endFill();
			pauseIcon.visible= false;
			
			playIcon.x = (_width - playIcon.width)/2;
			playIcon.y = (_height - playIcon.height)/2;					
			
			pauseIcon.x = (_width - pauseIcon.width)/2;
			pauseIcon.y = (_height - pauseIcon.height)/2;			
		}
		
		public function setSize( w : Number, h : Number) : void
		{
			_width = w;
			_height = h;
			draw();
		}
		
		private function configureListeners() : void
		{
			holder.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			holder.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
			addEventListener(MouseEvent.CLICK, handleToggle );
		}
		
		private function handleToggle( e : MouseEvent = null ) : void
		{
			_selected = !_selected;
			update();
			e.stopPropagation();			
		}
		
		private function handleMouseOver( e : MouseEvent) : void
		{
			bg.visible = true;
			TweenLite.to(holder, 0, { tint:_iconOverColor});
			//			currentTransform.color = _overColor;
			//			holder.transform.colorTransform = currentTransform;			
		}
		private function handleMouseOut( e : MouseEvent) : void
		{
			bg.visible = false;
			TweenLite.to(holder, 0, { tint:_iconColor});
			//			currentTransform.color = _outColor;
			//			holder.transform.colorTransform = currentTransform;			
		}
		
		public function set selected( selected : Boolean) :void
		{
			_selected = selected;
			update();
		}
		public function get selected() : Boolean
		{
			return _selected;
		}
		
		private function update() : void
		{
			playIcon.visible = !selected; 
			pauseIcon.visible = selected; 
		}
		
	}
}