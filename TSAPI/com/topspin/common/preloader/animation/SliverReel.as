package com.topspin.common.preloader.animation
{	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	import gs.TweenLite;
	
	public class SliverReel extends Sprite 
	{
		private var iR : Number = 70;
		private var oR : Number = 140;

		private  var ibR : Number = 10;
		private  var obR : Number = 8;
		
		private static var iOrbitFreq : Number = .012;
		private static var iOrbitPhase : Number = 0;
		private static var oOrbitFreq : Number = .005;
		private static var oOrbitPhase : Number = 0;

		private static var bAlpha : Number = 1;
		private static var rAlpha : Number = 1;

		private var blurXY : Number = 4;

		public var ballColor : Number;
		public var ballColor1 : Number;
		public var ballColor2 : Number;
		
		private var cx,cy  : Number;
		private var sw,sh  : Number;
		private var ringMC:Sprite, 
			ballMC:Sprite, 
			ballMC1:Sprite, 
			ballMC2:Sprite;
		private var renderMap:BitmapData;
		private var blurFilter:BlurFilter;
		
		private var maskMC : Sprite;
		private var offset : Number = 1;
		
		private var map : DisplayObject;
		
		private var w, h : Number;
		
		private var timer : Timer;
		
		public function SliverReel(_ballColor:Number=0x00CCFF, 
							 sw:Number = 320, sh:Number=320,      // width, height // center coords						
							 blur : Number = 8)
		{
			this.ballColor = 0xcccccc;//_ballColor;
			this.ballColor1 = 0x00A1FF;
			this.ballColor2 = 0xFF00CC;
	
			
			blurXY = blur;
			
//			iR = mRadius/2;
//			oR = mRadius;
//
//			obR = mRadius/4;
//			ibR = obR/2;				

			w = sw + 20; 
			h = sh + 20 ;
			
			oOrbitFreq = iOrbitFreq/2;
			
			var diameter : Number = sw  ;
	
			iR = diameter/4;
			oR = diameter/2;

			obR = diameter/8;
			ibR = diameter/12;			

			this.cx = w/2;
			this.cy = h/2;

			renderMap = new BitmapData(w, h, true, 0x000000);
			addChild( new Bitmap(renderMap) );
	
			ringMC = new Sprite();
			ballMC = new Sprite();
			ballMC1 = new Sprite();
			ballMC2 = new Sprite();
			maskMC = new Sprite();
			
			//clip = new Sprite();
			
			draw();
			
			ballMC.addChild(ballMC1);
			ballMC.addChild(ballMC2);
			
			addChild(ringMC);
			addChild(ballMC);
			addChild(maskMC);
	
			ballMC.mask = maskMC;

			blurFilter = new BlurFilter(blurXY,blurXY,4);
			this.visible = false;
			
			timer = new Timer(50);
			timer.addEventListener(TimerEvent.TIMER, drawOrbits);

			updateMap(ringMC);
			
		}
		
		private var ia : Number;
		private var oa : Number;
		private var t : int;
		
		private function drawOrbits(evt : Event = null) : void
		{
			t = getTimer();
//			trace("t : " + t);
//			var ia = iOrbitPhase + t*iOrbitFreq;
			
			//Play with the rotation, to make it start
			//at the top and they 			
			ia = iOrbitPhase + t*iOrbitFreq;
			oa = oOrbitPhase + t*oOrbitFreq;
			ballMC1.y = cx + Math.cos(ia)*iR;
			ballMC1.x = cy - Math.sin(ia)*iR;
			
			ballMC2.y = cx - Math.cos(oa)*oR;
			ballMC2.x = cy + Math.sin(oa)*oR;
		
		    renderMap.applyFilter(renderMap, renderMap.rect, new Point(0,0), blurFilter);
			renderMap.draw(map);
		}
	

	
		private function doFadeIn(evt : Event = null) : void
		{
			ballMC.addEventListener(Event.ENTER_FRAME, drawOrbits);		
			//timer.start();	
			TweenLite.to(this, .5, {autoAlpha : 1});	
//			evt.target.alpha += 1/60;
//			if (evt.target.alpha >= 1) {
//				evt.target.removeEventListener( Event.ENTER_FRAME, doFadeIn );
//			}
		}

		private function doFadeOut(evt : Event = null) : void
		{
			TweenLite.to(this, .5, {autoAlpha : 0, onComplete : killEnterFrame});	
			

//			evt.target.alpha -= 1/60;
//			if (evt.target.alpha <= 0) {
//				evt.target.removeEventListener( Event.ENTER_FRAME, doFadeOut );
//				ballMC.removeEventListener(Event.ENTER_FRAME, drawOrbits);
//				// Generate Event.STOP event...
//				this.dispatchEvent( new Event(Event.CLOSE) );
//			}
		}	
	
		private function killEnterFrame( e : Event = null ) : void 
		{
			ballMC.removeEventListener(Event.ENTER_FRAME, drawOrbits);
			//timer.stop();
			this.dispatchEvent( new Event(Event.CLOSE) );
		}	
	
		private function drawDonut (clip: Sprite, r1 : Number , r2 : Number , x : Number, y : Number) : void
		{
		   var TO_RADIANS:Number = Math.PI/180;
		   var g : Graphics = clip.graphics;
		   g.moveTo(0, 0);
		   g.lineTo(r1, 0);
			
		   var endx, endy,ax,ay : Number;

		   // draw the 30-degree segments
		   var a:Number = 0.268;  // tan(15)
		   for (var i : Number =0; i < 12; i++) {
		      endx = r1*Math.cos((i+1)*30*TO_RADIANS);
		      endy = r1*Math.sin((i+1)*30*TO_RADIANS);
		      ax = endx+r1*a*Math.cos(((i+1)*30-90)*TO_RADIANS);
		      ay = endy+r1*a*Math.sin(((i+1)*30-90)*TO_RADIANS);
		      g.curveTo(ax, ay, endx, endy);	
		   }

		   // cut out middle (go in reverse)
		   g.moveTo(0, 0);
		   g.lineTo(r2, 0);

		   for ( i=12; i > 0; i--) {
		     endx = r2*Math.cos((i-1)*30*TO_RADIANS);
		     endy = r2*Math.sin((i-1)*30*TO_RADIANS);
		     ax = endx+r2*(0-a)*Math.cos(((i-1)*30-90)*TO_RADIANS);
		     ay = endy+r2*(0-a)*Math.sin(((i-1)*30-90)*TO_RADIANS);
		     g.curveTo(ax, ay, endx, endy);     
		   }

		   clip.x = x;
		   clip.y = y;
		}	
	
	
		private function draw() : void
		{
			
			ringMC.graphics.clear();
			ringMC.graphics.lineStyle(2, ballColor, .2);
			ringMC.graphics.drawCircle(cx, cy, iR);
			ringMC.graphics.drawCircle(cx, cy, oR);

			//Draws the mask
			//Need a special function to create a donut mask			
			maskMC.graphics.clear();
			maskMC.graphics.beginFill(ballColor1, rAlpha);
			drawDonut(maskMC,iR+offset,iR-offset,cx,cy );
			drawDonut(maskMC,oR+offset,oR-offset,cx,cy );			
			maskMC.graphics.endFill();
			
			
			ballMC1.graphics.clear();
			ballMC1.graphics.beginFill(ballColor, rAlpha);
			ballMC1.graphics.drawCircle(0,0,ibR);
			ballMC1.graphics.endFill();
			
			ballMC2.graphics.clear();
			ballMC2.graphics.beginFill(ballColor, bAlpha);
			ballMC2.graphics.drawCircle(0,0,obR);
			ballMC2.graphics.endFill();			
		}
		
		public function updateMap( clip : DisplayObject) : void
		{
			map = clip;
		}
		
		/**
		 * ILoader implementation 
		 * @return 
		 * 
		 */		
		public function show()
		{
			this.alpha = 0;
			this.visible = true;
//			this.addEventListener(Event.ENTER_FRAME, doFadeIn);
//			ballMC.addEventListener(Event.ENTER_FRAME, drawOrbits);
			doFadeIn();
		}
		
		
		/**
		 * ILoader implementaion 
		 * @return 
		 * 
		 */
		public function hide()
		{
			doFadeOut();
//			this.addEventListener(Event.ENTER_FRAME, doFadeOut);
			//killEnterFrame()
		}		
				
		public function setSize( w: Number, h:Number) : void
		{
			cx = w/2;
			cy = h/2;
			
			var mRadius : Number = w/2;
			iR = mRadius/2;
			oR = mRadius;

			obR = mRadius/4;
			ibR = obR/2;			
			

			draw();
		}
	
	
	} // end class
} // end package
