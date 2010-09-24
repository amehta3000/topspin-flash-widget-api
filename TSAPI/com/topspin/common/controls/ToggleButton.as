/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * ToggleButton is a simple button which takes in 2 parameters:
 * clip - A movieClip from a swc which has 2 frames, one for each toggle state
 * selected - Boolean: false == frame1  
					   true == frame2
 *  
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 * 
 */
package com.topspin.common.controls
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	public class ToggleButton extends MovieClip
	{
			
		private var _mc : MovieClip;
		protected var _toggle : Boolean = true;
		protected var _selected : Boolean;
		
		private var _on : MovieClip;
		private var _off : MovieClip;
		
		public function ToggleButton( clip : MovieClip, selected : Boolean = false, offClip : MovieClip = null )
		{
			_selected = selected;

			if (!offClip)
			{
				_mc = clip;
				addChild( _mc );
				toggleButton();
			}else{
				
				_on = clip;
				addChild( _on );
				_off = offClip;
				addChild(_off);
				_off.visible = false;
				
			}
			
			addEventListeners();
		}
		
		public function set off( clip : MovieClip) : void
		{
			_off = clip;
		}		
		
		public function set on( clip : MovieClip) : void
		{
			_on = clip;
		}
		
		private function addEventListeners() : void
		{
			addEventListener(MouseEvent.CLICK, handleToggle );
		}
		
		private function handleToggle( e : MouseEvent = null ) : void
		{
			_selected = !_selected;
			if (_mc)
			{
				toggleButton();
			}else{
				toggleClips();
			}
			e.stopPropagation();			
		}

		private function toggleClips() : void
		{			
			//trace("ToggleButton : " + _selected);
			if (!_on || !_off) return;
			
			_on.visible = !selected;
			_off.visible = selected;
		}
		
		
		private function toggleButton() : void
		{			
			//trace("ToggleButton : " + _selected);
			if (!_selected)
			{ 
				_mc.gotoAndStop( "_off" );
			}else{
				_mc.gotoAndStop( "_on" );				
			}

		}
		
		public function get mc() : MovieClip
		{
			return _mc;
		}
		
		public function get selected() : Boolean {
			return _selected;
		}
		
		public function set selected( select : Boolean ) : void {
			if (_selected != select) {
				_selected = select;
				toggleButton();
			}
		}
		
	}
}