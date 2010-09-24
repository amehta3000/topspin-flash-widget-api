/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Customizable scroll bar component.
 *     
 * @copyright	Topspin Media
 * @author		kevans@topspinmedia.com
 * 
 */
package com.topspin.common.controls {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import gs.TweenLite;
	
	public class TrackBasedScrollbarControl extends MovieClip {
		// Input Variables
		private var _target:MovieClip;  // Movieclip that will be moved
		private var _itemHeight:Number;  // Height of a single playlist item
		private var _scrollElementHeight:Number;  // Height of the entire scrollbar (the viewable area)
		private var _trackHeight:Number;  // Height of the entire playlist (the master area)
		private var _scrollbarBgColor:Number;  // Color of the scrollbar track
		private var _scrollbarButtonColor:Number;  // Color of the buttons on the scrollbar
		
		// Display Objects		
		private var scroller:Sprite;
		private var scrollerBoundingBox:Rectangle;
		private var track:Sprite;
		private var upArrow:Sprite;
		private var downArrow:Sprite;

		// Positioning Variables
		private var targetFloor:Number;
		private var targetCeiling:Number;
		private var scrollerCeiling:Number;
		private var scrollerFloor:Number;
		private var scrollerPadding:Number = 2;
		private var viewableSpace:Number;		
		private var trackCorrection:Number;  // Accounts for tracks partially over bounds
		
		/**
		 * TrackBasedScrollbarControl - default constructor that assigns input variables and initializes some positioning variables
		 * 
		 * @param target (MovieClip) - MovieClip that contains track elements
		 * @param scrollbarHeight (Number) - Height of the scrollbar element
		 * @param trackHeight (Number) - Height of the tracks in the target clip
		 * @param itemHeight (Number) - Height of the individual playlist elements
		 * 
		 */
		public function TrackBasedScrollbarControl(target:MovieClip, scrollbarHeight:Number, trackHeight:Number, itemHeight:Number = 26, scrollbarBgColor:uint = 0x515151, scrollbarButtonColor:uint = 0xAAAAAA) {
			// Assign the input variables
			this._target = target;
			this._scrollElementHeight = scrollbarHeight;
			this._itemHeight = itemHeight;
			this._trackHeight = trackHeight;
			this._scrollbarBgColor = scrollbarBgColor;
			this._scrollbarButtonColor = scrollbarButtonColor;
			
			this.trackCorrection = this._itemHeight - 13;  // Corrects for partially overhanging tracks

			this.targetFloor = (this._trackHeight - this._scrollElementHeight) * -1 - this.trackCorrection;  // Minimum y position of the target
			this.targetCeiling = target.y;  // Maximum y position of the target

			init();
			createChildren();
			draw();
			createListeners();
		}

		private function init():void { }
		
		/**
		 * createChildren - instantiate the display objects and add them to the stage 
		 * 
		 */
		private function createChildren():void {
			track = new Sprite();
			upArrow = new Sprite();
			downArrow = new Sprite();
			scroller = new Sprite();
			scrollerBoundingBox = new Rectangle();

			addChild(track);
			addChild(upArrow);
			addChild(downArrow);
			addChild(scroller);
		}
		
		/**
		 * draw - Draw and position display elements, calculate positioning variables 
		 * 
		 */
		private function draw():void {
			// Draw the up arrow element
			upArrow.graphics.beginFill(this._scrollbarBgColor);
			upArrow.graphics.drawRect(0,0,15,15);
			upArrow.graphics.endFill();
			upArrow.graphics.moveTo(3,8);
			upArrow.graphics.beginFill(this._scrollbarButtonColor);
			upArrow.graphics.lineTo(12, 8);
			upArrow.graphics.lineTo(8, 3);
			upArrow.graphics.lineTo(7, 3);
			upArrow.graphics.lineTo(3, 8);
			upArrow.graphics.endFill();

			// Draw the down arrow element
			downArrow.graphics.beginFill(this._scrollbarBgColor);
			downArrow.graphics.drawRect(0,0,15,15);
			downArrow.graphics.endFill();
			downArrow.graphics.moveTo(3,7);
			downArrow.graphics.beginFill(this._scrollbarButtonColor);
			downArrow.graphics.lineTo(12, 7);
			downArrow.graphics.lineTo(8, 12);
			downArrow.graphics.lineTo(7, 12);
			downArrow.graphics.lineTo(3, 7);
			downArrow.graphics.endFill();

			// Draw the track element
			track.graphics.beginFill(this._scrollbarBgColor);
			track.graphics.drawRect(0, 0, 15, (this._scrollElementHeight - upArrow.height - downArrow.height));
			track.graphics.endFill();

 			// Draw the scroller
			var scrollerHeight:Number = Math.floor((track.height / this._target.height) * track.height);  // Calculate the proper height for the scroller
 			if(scrollerHeight < 20) { scrollerHeight = 20; }  // Sets a minimum size for the scrollbar
 			scroller.graphics.beginFill(this._scrollbarButtonColor);
			scroller.graphics.drawRoundRect(2, 0, 11, scrollerHeight, 10, 10);
			scroller.graphics.endFill();
			if(scrollerHeight == 20 && track.height < 50) {  // Accounts for situations where the scrollbar shouldn't be visible
				scroller.visible = false;
			}

			
			// Position the elements vertically
			track.y = upArrow.height;
			downArrow.y = upArrow.height + track.height;
			scroller.y = track.y;

			// Configure the box that contains the draggable scroller element
			scrollerBoundingBox.x = scroller.x;
			scrollerBoundingBox.y = scroller.y;
			scrollerBoundingBox.height = this.track.height - scroller.height;

			// Set overall positioning variables
			this.scrollerFloor = scroller.y; // Minimum y position of the scroller
			this.scrollerCeiling = track.y + track.height - scroller.height;  // Maximum y position of the scroller
			this.viewableSpace = this._trackHeight - this._scrollElementHeight;  // Get the total viewable distance
		}
		
		/**
		 * createListeners - create event listeners for display objects 
		 * 
		 */
		private function createListeners():void {
			upArrow.addEventListener(MouseEvent.CLICK, handleUpArrowClick);
			downArrow.addEventListener(MouseEvent.CLICK, handleDownArrowClick);
			track.addEventListener(MouseEvent.CLICK, handleTrackClick);
			scroller.addEventListener(MouseEvent.MOUSE_DOWN, handleScrollerDown);
			scroller.addEventListener(MouseEvent.MOUSE_UP, handleScrollerUp);
		}
		
		// EVENT LISTENERS
		
		/**
		 * handleUpArrowClick - scrolls target clip and scroller up the height of one track element
		 * 
		 * @param e (MouseEvent)
		 * 
		 */
		private function handleUpArrowClick(e:MouseEvent):void {
			var updatedTargetPosition:Number = _target.y;  // Initial position of the target container

			// Calculate destination and offsets
			var hypotheticalTrackDestination:Number = _target.y + this._itemHeight;  // Where target clip should move to
			var partialTrackOffset:Number = Math.ceil((hypotheticalTrackDestination % this._itemHeight));  // Account for the target falling between two tracks
			partialTrackOffset < 0 ? updatedTargetPosition -= partialTrackOffset : updatedTargetPosition += this._itemHeight;  // Decide between doing a full or a partial track move
			updatedTargetPosition > this.targetCeiling ? updatedTargetPosition = this.targetCeiling : null;  // Make sure the scrolling aligns correctly with the end of the clip

			updateScroller(updatedTargetPosition);  // Update the scrollbar

			TweenLite.to(_target, .25, {y:updatedTargetPosition});  // Move target clip
		}
		
		/**
		 * handleDownArrowClick - scrolls target clip and scroller down the height of one track element
		 * 
		 * @param e (MouseEvent)
		 * 
		 */
		private function handleDownArrowClick(e:MouseEvent):void {
			var updatedTargetPosition:Number = _target.y;  // Initial position of the target container

			// Calculate destination and offsets
			var hypotheticalTrackDestination:Number = _target.y - this._itemHeight;
			var partialTrackOffset:Number = Math.ceil((hypotheticalTrackDestination % this._itemHeight));  // Account for the target falling between two tracks
			updatedTargetPosition -= this._itemHeight + partialTrackOffset;  // Calculate target position updates
			updatedTargetPosition < (this.targetFloor + this.trackCorrection) ? updatedTargetPosition = this.targetFloor + this.trackCorrection : null;  // Make sure the scrolling of the target aligns correctly with the end of the clip

			updateScroller(updatedTargetPosition);  // Update the scrollbar

			TweenLite.to(_target, .25, {y:updatedTargetPosition});  // Move target clip
		}
		
		/**
		 * updateScroller - moves the scrollbar relative to the position of the target element
		 * 
		 * @param updatedTargetPosition (Number) - The new position of the target element
		 * 
		 */
		private function updateScroller(updatedTargetPosition:Number):void {
			var trackPositionRatio:Number = updatedTargetPosition / ((this.targetCeiling - (this.targetFloor + this.trackCorrection)) * -1);  // Calculate the percentage position of the target
			var updatedScrollerPosition:Number = trackPositionRatio * (this.scrollerCeiling - this.scrollerFloor) + track.y;  // Apply the ratio of the target's position to the position of the scroller

			TweenLite.to(scroller, .25, {y:updatedScrollerPosition});  // Move scroller
		}
		
		/**
		 * dragScrollBar - Calculates the correct position of the target element and tweens to that point
		 * 
		 * @param e (MouseEvent)
		 * 
		 */		
		private function dragScrollBar(e:MouseEvent):void {
			var currentScrollPositionRatio:Number = ((scroller.y - track.y) / (this.scrollerCeiling - this.scrollerFloor));  // Percentage location of the scrollbar
			var updatedTargetPosition:Number = this.targetFloor * currentScrollPositionRatio;  // Updated position of the playlist container

			updatedTargetPosition < (this.targetFloor + this.trackCorrection) ? updatedTargetPosition = this.targetFloor + this.trackCorrection : null;  // Make sure the scrolling aligns correctly with the end of the clip
			
			TweenLite.to(_target, .4, {y:updatedTargetPosition});  // Move clip
		}
		
		/**
		 * handleTrackClick - Calculates the correct position of the scroller and target element relative to user clicking on the track element, tweens to that point
		 * 
		 * @param e (MouseEvent)
		 * 
		 */
		private function handleTrackClick(e:MouseEvent):void {
			var updatedTargetPosition:Number;
			var updatedScrollerPosition:Number = mouseY - upArrow.height;  // Get the projected position of the scroller
				updatedScrollerPosition > this.scrollerCeiling ? updatedScrollerPosition = this.scrollerCeiling : null;  // Account for ceiling of the scroller
				updatedScrollerPosition < this.scrollerFloor ? updatedScrollerPosition = this.scrollerFloor : null;  // Account for floor of the scroller

			var currentScrollPositionRatio:Number = ((updatedScrollerPosition - track.y) / (this.scrollerCeiling - this.scrollerFloor));  // Percentage location of the scrollbar

			updatedTargetPosition = (currentScrollPositionRatio * this.targetFloor);  // Calculate the correct location of the target
			updatedTargetPosition < (this.targetFloor + this.trackCorrection) ? updatedTargetPosition = this.targetFloor + this.trackCorrection : null;  // Make sure the scrolling of the target aligns correctly with the end of the clip

			TweenLite.to(_target, .25, {y:updatedTargetPosition});  // Move target clip
			TweenLite.to(scroller, .25, {y:updatedScrollerPosition});  // Move scroller
		}
		
		/**
		 * handleScrollerDown - Handles event dispatching for starting a scroller drag
		 * 
		 * @param e (MouseEvent)
		 * 
		 */
		private function handleScrollerDown(e:MouseEvent):void {
			scroller.startDrag(false, scrollerBoundingBox);  // Enable the scroller to drag, bounded by scrollerBoundingBox
			
			// Add global listeners that allow the user to navigate the scrollbar when the mouse is no longer directly over it
			stage.addEventListener(MouseEvent.MOUSE_UP, handleScrollerUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragScrollBar);
		}
		
		/**
		 * handleScrollerUp - Handles event dispatching for stopping a scroller drag
		 * 
		 * @param e (MouseEvent)
		 * 
		 */
		private function handleScrollerUp(e:MouseEvent):void {
			scroller.stopDrag();
			
			// Remove global listeners
			stage.removeEventListener(MouseEvent.MOUSE_UP, handleScrollerUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragScrollBar);
		}
	}
}