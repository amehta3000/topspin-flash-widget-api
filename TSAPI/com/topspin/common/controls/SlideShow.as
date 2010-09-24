/**
* Generic slide show component.  Just need to feed in 
* and array of ImageData object and it will slide.
* @author amehta
* @version 0.1
*/
package com.topspin.common.controls {
	import com.topspin.api.data.media.ImageData;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import gs.TweenLite;
	import gs.easing.Circ;

	public class SlideShow extends AbstractControl implements ISlideShow {
				
		// Events
		public static var FLICKR_COMPLETE:String = "flickrComplete";				
		public static var DELAYED_START:String = "delayed_start_show";				
				
		public static const VALIGN_TOP : String = "top";
		public static const VALIGN_CENTER : String = "center";
		public static const VALIGN_BOTTOM : String = "bottom";
						
//		private var _width:Number;
//		private var _height:Number;
		private var _linkColor:uint;
		private var _flickrTOSTextFormat:TextFormat;
		private var _vAlign : String;  				//center, top, bottom.

		private var slideData:Array;  				// Provides and array of ImageData objects, returned from the DataModel
		private var slideMap:Array;  				// Holds all loaded image in an internal associative array to ensure only one time loading
		private var currentIndex:Number;  			// Current slideshow index
		private var selectedImageData:ImageData;
		
		private var slideShowRate:Number; 
		private var slideShowTimer:Timer;

		private var controlClip:Sprite;
		private var padding:Number = 4;
		private var baseColor : Number;

		// Next and Forward Buttons
		private var container:Sprite;
		private var nextBtn:Sprite;
		private var nextBtnBg:Sprite;
		private var nextBtnIcon:Sprite;
		private var prevBtn:Sprite;	
		private var prevBtnBg:Sprite;	
		private var prevBtnIcon:Sprite;

		// Flickr TOS Icon
		private var flickrTOS:Sprite;
		private var flickrTOSIconShape:Sprite;
		private var flickrTOSIconText:TextField;
		private var flickrTOSText:TextField;
		private var _infoMessage : String = "This product uses the Flickr API but is \nnot endorsed or certified by Flickr."
		
		//flag indicating that the slideshow has been initialized
		private var inited : Boolean = false;
		private var listenersInited : Boolean = false;

		//This is a flag set if no imageData has been set but a start
		//has been fired, in waiting for a flickr stream
		private var delayedStart : Boolean = false;
		private var _smoothing : Boolean = false;
		
		private var loaderContext : LoaderContext;

		/**
		 * SlideShow constructor
		 * 
		 * @param imageDataProvider - array of ImageData passed in
		 * @param w - width of the slide show
		 * @param h - height of the slide show
		 * @param h - cross fade rate in SECONDS
		 */
		public function SlideShow(w:Number, h:Number, imageDataProvider:Array = null, linkColor:uint = 0x00A1FF, changeRate:Number = 5, enableSmoothing : Boolean = false) {

			// Will hold all the instances of loaders
			slideMap = new Array();		
			
			//Slidedata is a reference to the imageDataProvider, so it
			//will constantly get updated
			slideData = imageDataProvider;
			slideShowRate = changeRate;
			_smoothing = enableSmoothing;
			
			slideShowTimer = new Timer(slideShowRate*1000);
			slideShowTimer.addEventListener(TimerEvent.TIMER, nextSlide);			
			
			_width = w;
			_height = h;
			
			_linkColor = linkColor;

			graphics.clear();
			graphics.beginFill(0x333333, 0);
			graphics.drawRect(0,0,_width, _height);
			graphics.endFill();				
			
			currentIndex = 0;	
			
			loaderContext = new LoaderContext(_smoothing);
			
			if (slideData && slideData.length>0)
			{
				createChildren();
			}
		}

		/**
		 * Draws the buttons and background 
		 * 
		 */		
		private function createChildren():void {
			container = new Sprite();
			addChild(container);
			
			controlClip = new Sprite();
			addChild(controlClip);
			
			// Next and Forward Icons

			nextBtn = new Sprite();
			nextBtnBg = new Sprite();
			nextBtnIcon = new Sprite();
			prevBtn = new Sprite();
			prevBtnBg = new Sprite();
			prevBtnIcon = new Sprite();

			nextBtn.addChild(nextBtnBg);
			nextBtn.addChild(nextBtnIcon);
				
			prevBtn.addChild(prevBtnBg);	
			prevBtn.addChild(prevBtnIcon);	
			
			draw();
						
			controlClip.addChild(nextBtn);			
			controlClip.addChild(prevBtn);

			controlClip.alpha = 0;
			controlClip.buttonMode = true;
			controlClip.useHandCursor = true;
			controlClip.visible = false;
			
			//draw();
			configureListeners();
			inited = true;
		}
		
		private function showTOS(e:Event):void {
			flickrTOSText.visible = true;
		}

		private function hideTOS(e:Event):void {
			flickrTOSText.visible = false;
		}
		
		/**
		 * Adds all the listners for all the buttons 
		 * 
		 */		
		public function configureListeners():void {  // Listeners are added in this way because the configureListeners method will be called again after the Flickr images are located

			if (!slideData || slideData.length <=1 ) return;
						
			if(!slideShowTimer.hasEventListener(TimerEvent.TIMER)) { slideShowTimer.addEventListener(TimerEvent.TIMER, nextSlide) };

			if(!this.hasEventListener(MouseEvent.MOUSE_OVER)) { this.addEventListener(MouseEvent.MOUSE_OVER, showControls) };
			if(!this.hasEventListener(MouseEvent.MOUSE_OUT)) { this.addEventListener(MouseEvent.MOUSE_OUT, hideControls) };
			
			if(!prevBtn.hasEventListener(MouseEvent.CLICK)) { prevBtn.addEventListener(MouseEvent.CLICK, previousSlide) };
			if(!prevBtn.hasEventListener(MouseEvent.MOUSE_OVER)) { prevBtn.addEventListener(MouseEvent.MOUSE_OVER, prevBtnOver) };
			if(!prevBtn.hasEventListener(MouseEvent.MOUSE_OUT)) { prevBtn.addEventListener(MouseEvent.MOUSE_OUT, prevBtnOut) };
			
			if(!nextBtn.hasEventListener(MouseEvent.CLICK)) { nextBtn.addEventListener(MouseEvent.CLICK, nextSlide) };
			if(!nextBtn.hasEventListener(MouseEvent.MOUSE_OVER)) { nextBtn.addEventListener(MouseEvent.MOUSE_OVER, nextBtnOver) };
			if(!nextBtn.hasEventListener(MouseEvent.MOUSE_OUT)) { nextBtn.addEventListener(MouseEvent.MOUSE_OUT, nextBtnOut) };

			if (flickrTOS) {	
				if(!flickrTOS.hasEventListener(MouseEvent.MOUSE_OVER)) { flickrTOS.addEventListener(MouseEvent.MOUSE_OVER, showTOS) };
				if(!flickrTOS.hasEventListener(MouseEvent.MOUSE_OUT)) { flickrTOS.addEventListener(MouseEvent.MOUSE_OUT, hideTOS) };
			}
			listenersInited = true;
		}

		private function prevBtnOver(e:MouseEvent):void {
			TweenLite.to(prevBtnBg, 0, {autoAlpha:.9, tint:_linkColor});
		}	
	
		private function prevBtnOut(e:MouseEvent):void {
			TweenLite.to(prevBtnBg, 0, {autoAlpha:.5, tint:0x000000});
		}
	
		private function nextBtnOver(e:MouseEvent):void {
			TweenLite.to(nextBtnBg, 0, {autoAlpha:.9, tint:_linkColor});
		}

		private function nextBtnOut(e:MouseEvent):void {
			TweenLite.to(nextBtnBg, 0, {autoAlpha:.5, tint:0x000000});
		}

		/**
		 * Shows the controls of the controlClip 
		 * 
		 * @param e
		 */		
		private function showControls(e:MouseEvent):void {
			TweenLite.to(controlClip, .4, {autoAlpha : 1});
		}
		
		/**
		 * hides the controls of the controlClip 
		 * 
		 * @param e
		 */		
		private function hideControls(e:MouseEvent):void {
			TweenLite.to(controlClip, .8, {autoAlpha : 0});			
		}
		
	    //--------------------------------------
	    // PRIVATE INSTANCE METHODS
	    //--------------------------------------
		/**
		 * starts or stops the timer which is the timer
		 * for the slideshow. 
		 * @param bool
		 * 
		 */		
		private function startTimer(bool:Boolean):void {
			if (slideData.length <= 1) return;
			
			if (bool) {
//				trace("Start it yo");
				slideShowTimer.start();
			} else {
//				trace("stop this bitch");
				slideShowTimer.stop();
			}
		}
	
	    //--------------------------------------
	    // PUBLIC INTERFACE METHODS
	    //--------------------------------------		
		//Sets the ImageData array 
		public function setData( imageDataProvider : Array) : void
		{
			slideData = imageDataProvider;
			refresh();
		}
		/**
		 * Add more imageData onto the array 
		 * @param image
		 * 
		 */		
		public function pushImageData( image : ImageData) : void
		{
			//if no image data has been set, we need to initialize the
			//slideData Array.
			if (!slideData) slideData = new Array();			
			slideData.push( image );
			refresh();
		}
		/**
		 * Refreshes the players of the slideshow, ie
		 * create children and listeners if necc.
		 * 
		 */		
		public function refresh() : void
		{
			return;
			trace("slideshow refresh : " + slideData.length, listenersInited);
			//Creates the slide data children.
			if (slideData && slideData.length>0 && !inited)
			{
//				trace("createChildren");
				createChildren();
			}
			if ( slideData && slideData.length>1 && !listenersInited )
			{
//				trace("configlisteners");
				configureListeners();
			}				
			//if the show is not running then disptach the delay_start incase
			//we've asked it to play.
			if (!slideShowTimer) {
//				trace("There ain't no slide show ");
			}
			
			if (slideShowTimer && !slideShowTimer.running) {
//				trace("START SHOW");
				startShow();
				return;
			}
		}
		/**
		 * ISlideshow interface
		 * Sets the main color of the buttons on the slideshow
		 * 
		 */
		public function setLinkColor( alinkColor : Number) : void
		{
			linkColor = alinkColor;
		}
		
		/**
		 * ISlideShow interface
		 * Sets the Size of the slide show
		 * 
		 */ 
		public override function setSize(w:Number, h:Number):void {
			_width = w;
			_height = h;
			refreshSize();
			draw();
		}
		/**
		 * ISlideShow interface 
		 * set the slide show delay between slides.  
		 * @param seconds : number of seconds between images 
		 * 
		 */		
		public function setChangeRate( seconds : Number ) : void
		{
			slideShowRate = seconds;
			if (slideShowTimer) slideShowTimer.delay = slideShowRate*1000;
		}
		
		public function disableButtons():void {
			nextBtn.visible = false;
			prevBtn.visible = false;
		}
		
		/**
		 * Sets a flickr icon to show up if flickr images are used
		 * 
		 */ 
		public function setInfoTOS(overrideTextFormat:TextFormat, msg : String = null):void {

			if (msg) _infoMessage = msg;

			if (!flickrTOS) {
				flickrTOS = new Sprite();
				
				flickrTOSIconShape = new Sprite();
				flickrTOSIconText = new TextField();
				flickrTOSText = new TextField();
				
				flickrTOSIconShape.addChild(flickrTOSIconText);
				flickrTOS.addChild(flickrTOSIconShape);
				flickrTOS.addChild(flickrTOSIconText);
				flickrTOS.addChild(flickrTOSText);
	
				flickrTOSIconShape.graphics.clear();
				flickrTOSIconShape.graphics.beginFill(0x000000, .4);
				flickrTOSIconShape.graphics.drawCircle(6, 6, 6);
				flickrTOSIconShape.graphics.endFill();
				
				flickrTOSIconText.autoSize = "left";
				//flickrTOSIconText.antiAliasType = "advanced";
				flickrTOSIconText.embedFonts = true;
				flickrTOSIconText.selectable = false;
				
				flickrTOSText.autoSize = "left";
				flickrTOSText.visible = false;
				//flickrTOSText.antiAliasType = "advanced";
				flickrTOSText.embedFonts = true;
				flickrTOSText.selectable = false;
				

				flickrTOS.x = padding;
				flickrTOS.y = padding;

				controlClip.addChild(flickrTOS);

				flickrTOS.addEventListener(MouseEvent.MOUSE_OVER, showTOS);
				flickrTOS.addEventListener(MouseEvent.MOUSE_OUT, hideTOS);	
			}

			// If this is triggered, we show the TOS stuff
			this._flickrTOSTextFormat = overrideTextFormat;
			
			flickrTOSText.text = _infoMessage;
			flickrTOSText.setTextFormat(_flickrTOSTextFormat);
				
			flickrTOSIconText.text = "i";
			var tf : TextFormat = new TextFormat(_flickrTOSTextFormat.font,_flickrTOSTextFormat.size, 0xcccccc);
			flickrTOSIconText.setTextFormat(tf);
			
			flickrTOSIconText.x = Math.ceil((flickrTOSIconShape.width - flickrTOSIconText.width)/2) ;
			flickrTOSIconText.y = Math.floor((flickrTOSIconShape.height - flickrTOSIconText.height)/2);
			flickrTOSText.x = flickrTOSIconShape.width + 2;
			flickrTOSText.y = Math.ceil((flickrTOSIconShape.height - flickrTOSText.height)/2);
			
		}	
		
		private var _started : Boolean = false;
		public function isStarted() : Boolean
		{
			return _started;
		}
		/**
		 * ISlideShow interface 
		 * Starts the slide show
		 *
		 */
		public function startShow():void {
			if (!slideData) {
//				trace("startShow : not slideData so add DELAYED_START listener");
//				addEventListener(DELAYED_START, handleDelayedStart);
				return;
			}
			_started = true;
			loadSlide();
		}		
		/**
		 * ISlideShow interface
		 * Stops the slideshow, kills the timer 
		 * 
		 */
		public function stopShow():void {
			_started = false;
			startTimer(false);	
		}
	
		/**
		 * Called by the timer, increments the index and 
		 * loads the next slide 
		 * 
		 * @param event
		 */
		protected function nextSlide(event:Event = null):void {
			
			currentIndex++;
//			trace("next slide yo: " + currentIndex);
			if (currentIndex > slideData.length-1) currentIndex = 0;
			loadSlide();
		}
		
		/**
		 * Decrements the index and loads the slide 
		 * @param event
		 * 
		 */		
		protected function previousSlide(event:Event = null):void {
			currentIndex--;
			if (currentIndex < 0) currentIndex = slideData.length-1;
			loadSlide();
		}
	
		/**
		 * Load a slide 
		 * 
		 */		
		private function loadSlide():void {
			startTimer(false);
			selectedImageData = slideData[currentIndex];

			if (slideMap[selectedImageData.id] == null) {
				var request : URLRequest = new URLRequest(selectedImageData.imageURL);
				
				var loader : Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoaded);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
					loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, handleProgress);
				
				try {
					loader.load(request, loaderContext);
					
				} catch (e:Error) {
					nextSlide();		
				}
			} else {
				showSelectedSlide(); // The product has already been loaded, tell it to become visible.	
			}
		} 		
		
		/**
		 * Fades outs the previous slide and fades the 
		 * next one in. 
		 * 
		 */		
		private function showSelectedSlide():void {
//			trace("Show Selected Slide: Start the timer");
			startTimer(true);		
			TweenLite.to(container, .5, {autoAlpha : 0, onComplete : fadeInSelected});					
		}		
		
		/**
		 * Fades in a selected slide
		 * 
		 */		
		private function fadeInSelected():void {
			refreshSize();	
			// Remove the current image, then add the next and tween up
	        if (container.numChildren>=1) {
	          container.removeChildAt(0);
	        }			
			var img:DisplayObject = slideMap[selectedImageData.id];
			if (img != null) {
				container.addChild(img);
				TweenLite.to(container, .8, {autoAlpha : 1});
			}			
		}		
		
	    //--------------------------------------
	    // EVENT HANDLERS
	    //--------------------------------------
	    /**
	     * handleProgress - Load progress handler - simply redispatch the progress event at class scope level 
	     *
	     *  @param event
	     * 
	     */
	    private function handleProgress(event:ProgressEvent):void {
	      dispatchEvent(event);
	    }		
		/**
		 * Handler for when the Loader image is loaded 
		 *
		 *  @param e
		 */
		private function handleLoaded( e : Event ) : void
		{
			var loader : Loader = e.target.loader;
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,handleLoaded);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, handleProgress);
			/*** Don't use the bitmap data, since we may not have the policy file granted ***/
			if (_smoothing)
			{
				try{
			    	var bmp : Bitmap = Bitmap(e.target.content);
					bmp.smoothing = true;
			    	var clip : Sprite = new Sprite();
			    	clip.addChild(bmp);
					slideMap[selectedImageData.id] = clip;  // Add this loader to the slideMap
//					trace("Smooth handleLoaded: " + clip);
					loader.unload();
					loader = null;
				} catch (e:Error) {
				
					slideMap[selectedImageData.id] = loader;  // Add this loader to the slideMap				
				}
		 	}else{
				slideMap[selectedImageData.id] = loader;  // Add this loader to the slideMap
		 	}
		    showSelectedSlide();
		}		
		/**
		 * Handler for delayed start show. 
		 * @param e
		 * 
		 */		
//		private function handleDelayedStart( e : Event) : void
//		{
//			removeEventListener(DELAYED_START,handleDelayedStart);
//			startShow();
//		}
		/**
		 * Returns the currently seen image 
		 *
		 *  @return 
		 */		
		private function getCurrentImage():DisplayObject {
			return slideMap[slideData[currentIndex].id];
		}	
		
		/**
		 * Refreshs the size and scales the image proportionally. 
		 * 
		 */		
		private function refreshSize():void {
			var img:DisplayObject = getCurrentImage(); //slideMap[selectedImageData.id];
			if (img != null) {			

				if( img.width / _width > img.height / _height )
				{
					img.height = img.height * _width / img.width;
					img.width = _width;
				}
				else
				{
					img.width = _height * img.width / img.height;
					img.height = _height;
				}						
				
				switch (_vAlign) {
					case VALIGN_TOP:
						img.y = 0; 	
						break;			
					
					case VALIGN_CENTER:
						img.y = (_height - img.height)/2; 	
						break;			
					
					case VALIGN_BOTTOM:
						img.y = _height - img.height; 	
						break;			
					
					default:
						img.y = (_height - img.height)/2; 	
						break;			
				}
				img.x = (_width - img.width) / 2;
			}				
		}
		
		/**
		 * Draw refresh method 
		 * 
		 */		
		protected override function draw():void {
			graphics.clear();
			graphics.beginFill(0x333333, 0);
			graphics.drawRect(0,0,_width, _height);
			graphics.endFill();				
			
			
			var w : Number = 40;
			var white : int = 0xffffff;
			nextBtnBg.graphics.clear();
			nextBtnBg.graphics.beginFill(0x000000);
			nextBtnBg.graphics.drawRoundRect(0, 0, w, w, 10);
			nextBtnIcon.graphics.endFill();

			nextBtnIcon.graphics.clear();
			nextBtnIcon.graphics.beginFill(white,.9);
			nextBtnIcon.graphics.moveTo(0, 0);
			nextBtnIcon.graphics.lineTo(-12, -12);
			nextBtnIcon.graphics.lineTo(-17, -7);
			nextBtnIcon.graphics.lineTo(-10, 0);
			nextBtnIcon.graphics.lineTo(-17, 7);
			nextBtnIcon.graphics.lineTo(-12, 12);
			nextBtnIcon.graphics.lineTo(0, 0);
			nextBtnIcon.graphics.endFill();
			nextBtnIcon.x = (nextBtnBg.width - nextBtnIcon.width)/2 + nextBtnIcon.width;
			nextBtnIcon.y = (nextBtnBg.height - nextBtnIcon.height)/2 + nextBtnIcon.height/2;

			nextBtn.y = (_height - nextBtn.height)/2;
			nextBtn.x  = _width - nextBtn.width - padding;

			prevBtnBg.graphics.clear();
			prevBtnBg.graphics.beginFill(0x000000);
			prevBtnBg.graphics.drawRoundRect(0, 0, w, w, 10);
			prevBtnBg.graphics.endFill();

			prevBtnIcon.graphics.clear();
			prevBtnIcon.graphics.beginFill(white, .9);
			prevBtnIcon.graphics.moveTo(0, 0);
			prevBtnIcon.graphics.lineTo(12, -12);
			prevBtnIcon.graphics.lineTo(17, -7);
			prevBtnIcon.graphics.lineTo(10, 0);
			prevBtnIcon.graphics.lineTo(17, 7);
			prevBtnIcon.graphics.lineTo(12, 12);
			prevBtnIcon.graphics.lineTo(0, 0);
			prevBtnIcon.graphics.endFill();			
			prevBtnIcon.x = (prevBtnBg.width - prevBtnIcon.width) /2  ;
			prevBtnIcon.y = (prevBtnBg.height - prevBtnIcon.height) /2 + prevBtnIcon.height/2;

			prevBtn.x = padding;
			prevBtn.y = (_height - prevBtn.height)/2; 
						
			prevBtnBg.alpha = .5;
			nextBtnBg.alpha = .5;
		}
		
        private function ioErrorHandler(event:IOErrorEvent):void {
            trace("Slideshow ioErrorHandler: " + event);
        }		
		
		public function set linkColor(overrideLinkColor:uint):void {
			this._linkColor = overrideLinkColor;
			draw();
		}
			
		public function setVAlign( vAlign : String ) : void
		{
			this._vAlign = vAlign;
			refreshSize();
		}	
			
		/**
		 * Public method, enable parent to pass a listener on to the container,
		 * this essentially makes it a clickable slideshow. 
		 * @param callback
		 * 
		 */			
		public function addClickListener( callback : Function = null) : void
		{
			container.addEventListener(MouseEvent.CLICK, callback);		
			container.buttonMode = true;	
		}	
			
		public override function activate():void {
			trace("SLIDSHOW ACTIVATE startShow");
//			startTimer(true);
			startShow();
		}
		
		public override function deactivate():void {
//			startTimer(false);
			stopShow();
		}
	
	}
}