package com.topspin.email.controls
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;

	/**
	 * Simple icon button which will take in a sprite
	 * and draw a box around it.  On rollover will change
	 * the color of the either the background or the sprite. 
	 * @author amehta
	 * 
	 */	
	public class IconButton extends Sprite
	{
		
		private var _inited : Boolean = false;
		
		//Main icon
		private var _icon : Sprite;  
		private var _toggleIcon : Sprite;
		private var _currentIcon : Sprite;
		private var _bg : Sprite;
		
		//properties
		private var _width : Number;
		private var _height : Number;
		private var _drawBorder : Boolean = false;
		private var _borderColor : Number;
		
		private var _bgColor : Number;
		private var _bgAlpha : Number = 1;
		private var _overColor : Number;
		private var _outColor : Number;
		private var _hightlightIcon : Boolean;
		private var _roundedCornerRadius : Number;
		
		private var _selected : Boolean = false;
		private var _toggle : Boolean = false;
		
		
		public function IconButton(w : Number, h : Number, icon : Sprite, bgColor : Number, 
								   bgAlpha : Number, overColor : Number, 
								   hightlightIcon : Boolean = true,
								   drawBorder : Boolean = true,
								   boderColor : Number = 0xcccccc,
								   roundedCornerRadius : Number = 0,
								   toggle : Boolean = false,
								   selected : Boolean = false,
								   toggleIcon : Sprite = null)
		{
			_width = w;
			_height = h;
			_icon = icon;
			_bgColor = bgColor;
			_bgAlpha = bgAlpha;
			_overColor = overColor;
			_hightlightIcon = hightlightIcon;
			_drawBorder = drawBorder;
			_borderColor = boderColor;
			_roundedCornerRadius = roundedCornerRadius;
			_toggle = toggle;
			_selected = selected;
			_toggleIcon = toggleIcon;
			
			init();
			createChildren();
		}
		
		private function init() : void
		{
			//Set up the outColor
			if (_hightlightIcon)
			{
				var colorTransform : ColorTransform = _icon.transform.colorTransform;
				_outColor = colorTransform.color;
			}else{
				_outColor = _bgColor;
			}
			
			_currentIcon = _icon;	
			
			
		}
		
		private function createChildren() : void
		{
			_bg = new Sprite();
			addChild(_bg);
			addChild(_icon);	
			if (_toggleIcon)
			{
				addChild(_toggleIcon);
				_toggleIcon.visible = false;
				_toggleIcon.x = (_width - _toggleIcon.width)/2;
				_toggleIcon.y = (_height - _toggleIcon.height)/2;				
			}

			_bg.graphics.clear();
			if (_drawBorder)
			{
				_bg.graphics.lineStyle(1,_borderColor);
			}
			_bg.graphics.beginFill(_bgColor, _bgAlpha);
			_bg.graphics.drawRoundRect(0,0,_width,_height,_roundedCornerRadius);
			_bg.graphics.endFill();		
			
			_inited = true;
			configureListeners();
			draw();
		}
		
		private function configureListeners() : void
		{
			this.addEventListener(MouseEvent.MOUSE_OVER, handleOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, handleOut);	
			this.addEventListener(MouseEvent.CLICK, handleClick);	
			
		}
		
		private function draw() : void
		{
			if (!_inited) return;
//			trace("Draw the iconbutton");
//			_bg.graphics.clear();
//			if (_drawBorder)
//			{
//				_bg.graphics.lineStyle(1,_borderColor);
//			}
			if (_toggleIcon)
			{
				_toggleIcon.visible = _selected;
				_icon.visible = !_selected;
				_currentIcon = (!_selected) ? _icon : _toggleIcon; 
			}			
//			if (!_hightlightIcon)
//			{
//				_bg.graphics.beginFill((_selected && !_toggleIcon)?_overColor : _bgColor, _bgAlpha);
//			}else{
//				_bg.graphics.beginFill(_bgColor, _bgAlpha);
//			}
//			_bg.graphics.drawRoundRect(0,0,_width,_height,_roundedCornerRadius);
//			_bg.graphics.endFill();						
			
			_icon.x = (_width - _icon.width)/2;
			_icon.y = (_height - _icon.height)/2;
			
		}
		
		public function set selected( select : Boolean ) : void
		{
			_selected = select;
			draw();
		}		
		
		public function get selected() : Boolean
		{
			return _selected;
		}
		
		/**
		 * Sets the color transform 
		 * @param clip
		 * @param color
		 * 
		 */		
		private function setColorTransform( clip : Sprite, color : Number ) : void
		{
			var transform : ColorTransform = new ColorTransform();
			transform.color = color;
			clip.transform.colorTransform = transform;	
		}
		
		/////////////////////////////////////////////////////
		//
		//  Handlers
		//
		/////////////////////////////////////////////////////
		private function handleOver( e : MouseEvent ) : void
		{
				setColorTransform((_hightlightIcon) ? _currentIcon : _bg ,_overColor);
		}
		private function handleOut( e : MouseEvent ) : void
		{
				setColorTransform((_hightlightIcon) ? _currentIcon : _bg ,_outColor);				
		}
		private function handleClick( e : Event ) : void
		{
			_selected = !_selected;
			draw();
		}
	}
}