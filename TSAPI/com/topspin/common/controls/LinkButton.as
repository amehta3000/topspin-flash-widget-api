package com.topspin.common.controls
{
	
	/**
	 * -----------------------------------------------------------------
	 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
	 * This software is the proprietary information of Topspin Media, Inc.
	 * Use is subject to strict licensing terms.
	 * -----------------------------------------------------------------
	 * 
	 * Simple Button control is meant to copy the Flex Link Button component.
	 * Extends the V3 Button component and sets a new link button skin for
	 * the various states.
	 * 
	 * You may pass in a config object to customize the Linkbutton with 
	 * colors and text format you choose.  Ensure that the font is embedded
	 * before passing the config object
	 * 
	 * Usage of config object and LinkButton:
	 * 
	 *			var linkColor : uint = 0x00A1FF;
	 *			var linkOverColor : uint = 0xffffff;
	 * 
	 *          linkButtonFormat  = new TextFormat();
	 *          linkButtonFormat.font = new LucidaGrandeFont().fontName;
	 *          linkButtonFormat.size = 9;
	 *          linkButtonFormat.color = linkColor; 	
	 *          
	 *          linkButtonOverFormat = new TextFormat();
	 *          linkButtonOverFormat.font = new LucidaGrandeFont().fontName;;
	 *          linkButtonOverFormat.size = 9;
	 *          linkButtonOverFormat.color = linkOverColor;	 
	 * 
	 * 			var linkConfigObj : Object = new Object();
	 *			
	 *			linkConfigObj.format = linkButtonFormat;
	 *			linkConfigObj.overFormat = linkButtonOverFormat;
	 *			linkConfigObj.upSkin = {fillColor:linkColor,fillAlpha: 0};
	 *			linkConfigObj.overSkin = {fillColor:linkColor,fillAlpha: 1};
	 *			linkConfigObj.downSkin = {fillColor:linkColor,fillAlpha: .8};	
	 * 			linkConfigObj.disabledSkin = {fillColor:linkColor,fillAlpha: .3};
	 * 
	 * 			var linkBtn : LinkButton = new LinkButton( linkConfigObj );
	 * 			linkBtn.label = "My Label";
	 * 			linkBtn.setSize( 70, 20 );
	 * 
	 * See LinkButtonSkin for additional properties for stroke, corner size, etc.
	 *
	 * @copyright	Topspin Media
	 * @author		amehta@topspinmedia.com
	 * 				
	 */  
	
	//import com.topspin.fonts.LucidaGrandeFont;
	
	import fl.controls.Button;
	
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextFormat;
	
	public class LinkButton extends Button
	{
		
		private var _format : TextFormat;
		private var _overFormat : TextFormat;	
		
		public function LinkButton( config : Object = null )
		{
			super();
			init();
			setStyles(config || {});		
		}
		
		private function init() : void
		{
			addEventListener(MouseEvent.MOUSE_OVER , handleOver);
			addEventListener(MouseEvent.MOUSE_OUT , handleOut);
			
		}
		
		public function set defaultFormat( format : TextFormat) : void
		{
			_format = format;
			this.setStyle("textFormat", _format);	
		}
		
		public function set overFormat( format : TextFormat) : void
		{
			_overFormat = format;
		}
		
		/**
		 * Handles over state 
		 * @param e
		 * 
		 */		
		private function handleOver( e : MouseEvent) : void
		{
			this.setStyle( "textFormat", _overFormat);				
		}
		/**
		 * Handles out state 
		 * @param e
		 * 
		 */		
		private function handleOut( e : MouseEvent) : void
		{
			this.setStyle( "textFormat", _format);				
		}
		
		/**
		 * Sets the default skin style for the link
		 * button, or the provided skins.
		 * 
		 */		
		public function setStyles(config : Object) : void 
		{
			
			_format = config.format;
			//trace("HERE: "+_format.font);
			_overFormat = config.overFormat;
			
			
			if (!_format) {
				_format = new TextFormat();
				_format.font = "_sans";
				_format.size = 9;
				_format.color = 0x00A1FF; 	
			}
			if (!_overFormat) {
				_overFormat = new TextFormat();
				_overFormat.font = "_sans";
				_overFormat.size = 9;
				_overFormat.color = 0xFFFFFF;
			}
			
			
			var upSkin : LinkButtonSkin = new LinkButtonSkin(config.upSkin || {});
			var overSkin : LinkButtonSkin = new LinkButtonOverSkin(config.overSkin || {});
			var downSkin : LinkButtonSkin = new LinkButtonDownSkin(config.downSkin || {});
			var disabledSkin : LinkButtonSkin =  new LinkButtonSkin(config.disabledSkin || {});
			
			this.setStyle("textFormat", _format);	
			this.textField.antiAliasType = AntiAliasType.ADVANCED;    
			this.setStyle( "upSkin", upSkin);
			this.setStyle( "overSkin", overSkin);
			this.setStyle( "downSkin", downSkin);
			this.setStyle( "disabledSkin", disabledSkin);
			
			if (config.icon)
			{
				this.setStyle("icon", config.icon);	     	
			}
			
		}
		
	}
}

import flash.display.Shape;
import flash.geom.Rectangle;

class LinkButtonSkin extends Shape 
{
	protected var _fillColor : uint = 0x00A1FF;
	protected var _fillAlpha : Number = 0;
	
	protected var _strokeColor : uint = 0x00A1FF;
	protected var _strokeAlpha : Number = 0;
	protected var _strokeThickness : Number = 0;
	
	protected var _width : Number = 60;
	protected var _height : Number = 18;
	protected var _cornerRadius : uint = 6;
	
	public function LinkButtonSkin(config : Object)
	{
		_fillColor = (config.fillColor != undefined) ? config.fillColor : _fillColor;
		_fillAlpha = (config.fillAlpha != undefined) ? config.fillAlpha : _fillAlpha;
		_strokeColor = (config.strokeColor != undefined) ? config.strokeColor : _strokeColor;
		_strokeAlpha = (config.strokeAlpha != undefined) ? config.strokeAlpha : _strokeAlpha;
		_strokeThickness = (config.strokeThickness != undefined) ? config.strokeThickness : _strokeThickness;
		_width = (config.width != undefined) ? config.width : _width;
		_height = (config.height != undefined) ? config.height : _height;
		_cornerRadius = (config.cornerRadius != undefined) ? config.cornerRadius : _cornerRadius;
		init();
	}
	protected function init() : void
	{
		draw();	
	}
	
	protected function draw() : void
	{
		graphics.lineStyle(_strokeThickness, _strokeColor, _strokeAlpha);
		graphics.beginFill(_fillColor, _fillAlpha);
		graphics.drawRoundRect(0,0,_width, _height,_cornerRadius,_cornerRadius);
		graphics.endFill();
		
		var pad : uint = 6;
		var grid:Rectangle = new Rectangle(pad, pad, _width - pad*2, _height-pad*2);
		// apply the scale9Grid to the movieclip "my_mc"
		this.scale9Grid = grid;			
	}
	
}

class LinkButtonOverSkin extends LinkButtonSkin
{
	public function LinkButtonOverSkin(config : Object = null)
	{
		super(config);
	}
	override protected function init() : void
	{
		_fillColor ||= 0x00A1FF;
		_fillAlpha ||= 1;
		
		super.init();
	}
}	

class LinkButtonDownSkin extends LinkButtonSkin
{
	public function LinkButtonDownSkin(config : Object = null)
	{
		super(config);
	}
	override protected function init() : void
	{
		_fillColor ||= 0x66ccff;
		_fillAlpha ||= 1;			
		
		super.init();
	}
	
}

