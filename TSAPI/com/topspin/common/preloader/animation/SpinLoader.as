package com.topspin.common.preloader.animation
{
	import com.topspin.common.preloader.ILoader;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	import gs.TweenLite;

	public class SpinLoader extends Sprite implements ILoader
	{
	  private var _container:Sprite;
	  private var _centerX:uint;
	  private var _centerY:uint;
	  private var _radius:uint;
	  private var _steps:uint;
	  private var _rectWidth:uint;
	  private var _rectHeight:uint;
	  private var _color:Number;
	  private var _count:uint;
	  private var _fadeOutDuration:Number;
//      private var _timer:Timer;
      private var _timerInterval:uint;	  
	  
	  
	  public function SpinLoader( w : uint = 50, h : uint = 50, colorer:Number = 0x0000FF, 
	  								radius:uint = 16, steps:uint = 18, rectWidth:uint = 10,
	                                rectHeight:uint = 2, fadeOutDuration:Number = .8 )
	  {

	     _centerX = w/2;
	     _centerY = h/2;
	     _radius = w/3.5;
	     _steps = w/3;
	     _rectWidth = w/5;
	     _rectHeight = rectHeight;
	     _color = colorer;
	     _fadeOutDuration = fadeOutDuration;
		 
		 this.graphics.clear();
		 this.graphics.beginFill(0,.3);
		 this.graphics.drawRoundRect(0,0,w,h,8,8);
		 this.graphics.endFill();
		 
	     _container = new Sprite();
	     _container.x = _centerX;
	     _container.y = _centerY;
	     this.addChild(_container);
			
		 addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);	 
		 addEventListener(Event.REMOVED_FROM_STAGE, handleRemovedFromStage);	 
       
//       	 _timerInterval = 20;
//         _timer = new Timer(_timerInterval, 0);
//         _timer.addEventListener(TimerEvent.TIMER, drawRectangle);		 
      }	  
	  private function handleAddedToStage( e : Event = null) : void
	  {
//	  	trace("ILOADER : added to stage");
	  	if (!this.hasEventListener(Event.ENTER_FRAME))
	  	{
	  		this.addEventListener(Event.ENTER_FRAME, drawRectangle);
	  	}
//	     _timer.start();
	  }
	  private function handleRemovedFromStage( e : Event = null ) : void
	  {
//	  	trace("ILOADER : removed from stage");
	  	this.removeEventListener(Event.ENTER_FRAME, drawRectangle);
//	     _timer.stop();
	  }
	
	  public function start():void
	  {
	     _count = 0;
	     handleAddedToStage();
	  }
	  public function stop():void
	  {
	     if (_container)
	     {
	        TweenLite.to( _container, .5, { alpha:0, onComplete:onContainerFadeOutComplete } );
	     }
	  }
	  private function onContainerFadeOutComplete():void
	  {
		handleRemovedFromStage();
	  }

	  private function drawRectangle(e:Event):void
	  {
	     var rot:Number = _count * 360 / _steps;
	     var rect:Sprite = filledRectangle(_rectWidth, _rectHeight, _color);
	     rect.x = _radius * Math.cos(rot * Math.PI/180);
	     rect.y = _radius * Math.sin(rot * Math.PI/180);
	     rect.rotation = rot;
	     _container.addChild(rect);
	     _count++;
	     TweenLite.to( rect, _fadeOutDuration, { alpha:0, onComplete:onRectFadeOutComplete, onCompleteParams:[rect] } );
	     //e.updateAfterEvent();
	     if (_count == _steps) {
	        _count = 0;
	     }
	  }
	  private function onRectFadeOutComplete(rect:Sprite):void
	  {
	     _container.removeChild(rect);
	  }	  
	  private function filledRectangle(width:uint, height:uint, color:uint):Sprite
	  {
	     var rect:Sprite = new Sprite();
	     rect.graphics.beginFill(color);
	     rect.graphics.drawRect(-width/2, -height/2, width, height);
	     rect.graphics.endFill();
	     return rect;
	  }
	  public function setSize( w : uint, h : uint ) : void
	  {
		 this.graphics.clear();
		 this.graphics.beginFill(0,.3);
		 this.graphics.drawRoundRect(0,0,w,h,8,8);
		 this.graphics.endFill();
		 	  	
	  	 _centerX = w/2;
	  	 _centerY = h/2;
	  }
	}
}