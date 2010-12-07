package com.topspin.email.views {
	import com.topspin.api.events.Dependency;
	import com.topspin.api.events.E4MEvent;
	import com.topspin.api.events.MediaControlEvent;
	import com.topspin.api.events.TSWidgetEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSEvents;
	import com.topspin.common.controls.SimpleLinkButton;
	import com.topspin.common.controls.SlideShow;
	import com.topspin.common.events.DialogEvent;
	import com.topspin.common.events.PlayerAdapterEvent;
	import com.topspin.common.media.IPlayerAdapter;
	import com.topspin.email.controls.DOBControl;
	import com.topspin.email.controls.E4MPlayerControl;
	import com.topspin.email.controls.EmailControl;
	import com.topspin.email.controls.PlaylistControl;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.dialogs.EmailOptInDialog;
	import com.topspin.email.dialogs.FatalDialog;
	import com.topspin.email.dialogs.SocialDialog;
	import com.topspin.email.events.MessageStatusEvent;
	import com.topspin.email.style.GlobalStyleManager;
	import com.topspin.email.validation.COPPAComplianceValidation;
	
	import fl.transitions.Tween;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.FullScreenEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import gs.TweenLite;
	import gs.TweenMax;
	
	/**
	 * EmailMediaWidgetView main view  
	 * @author amehta
	 * 
	 */	
	public class E4MPlayerView extends AbstractView {
		
		//Properties
		public static var NAME : String = "E4MPlayerView";
		private var dependency : Dependency; 			//Used to load images	
		private var EMAIL_CONTROL_HEIGHT : Number = 70;
		
		// Data Instances
		private var dm:DataManager;						//DataManager singleton
		private var styles:GlobalStyleManager;			//StyleManager singleton
		
		public var emailControl:EmailControl;					//Holder of the email container
		public var slideshow:SlideShow;							//Slideshow control				
		private var playerControl : E4MPlayerControl;			//playerControl
		
		//dialog container
//		public var dialogContainer : Sprite;			//Holds any dialogs
		
		// Default static text
		private static var _defaultEmail:String = "Enter Email Address";
		private static var _defaultEmailMini:String = "Enter Email";
		private var _finalEmailStr : String;			//emailTxt default string based on the size of the widget
		
		// Animation properties
//		private static const PLAYER_ADAPTER_PATH : String =  "/flash/adapters/PlayerAdapter.swf";
		private var FADE_RATE:Number = .3;		//Animation rate for fades	
		private var RESET_TIME:Number = 5000;	//Reset timer
		private  var PAD:uint = 4;				//Default PAD between ui
		private var _resetTimer:Timer;					//Timer instance to reset the app				
		
		// States
		private var _clips : Array;		
		//play btn
//		private var _isPlaying:Boolean = false;			//Indicates whether media is playing or not		
		private var MINI_MODE : Boolean = false;		//State indicating the size of the widget, used to render properly

		private var _baseWidth : Number;
		private var _baseHeight : Number;
		private var _inited : Boolean = false;
		private var _bg : Sprite;
		/**
		 * Constructor 
		 * @param width
		 * @param height
		 * @param root - Reference to app
		 * 
		 */		
		public function E4MPlayerView(width:Number, height:Number, root:TSEmailMediaWidget) {
			
			super(width, height, root);
			
			_baseWidth = _width;
			_baseHeight = _height;
			
			//Listen to be added and then additional event listeners
			addEventListener(Event.ADDED_TO_STAGE, handleAdded);
			
			//Get an instance of DataManager
			dm = DataManager.getInstance();
			//dm.addEventListener(DataManager.SLIDESHOW_INIT, handleSlideshowInit);
			dm.addEventListener(DataManager.IMAGE_DATA_UPDATE, updateSlideshow);
			dm.addEventListener(TSWidgetEvent.PLAYLIST_READY, handlePlaylistLoad);			

			
			
			//Figure out if we are MINI mode or not
//			MINI_MODE = (_width < 250) ? true : false;
//			trace("E$M : " + _width);
			EMAIL_CONTROL_HEIGHT = (_height < 80) ? _height : EMAIL_CONTROL_HEIGHT;
			
			//Get an instance of GlobalStyleManager
			styles = GlobalStyleManager.getInstance();
			styles.init();	
		}
		
		/**
		 * Main init to get this thing started 
		 * 
		 */		
		public override function init():void {
			// Draw the background for the widget
			//MAY need to look into this
			if (dm.getWidgetStatus() == DataManager.STATUS_DELETED) {
				_root.displayErrorView();
			} else {				
				graphics.beginFill( styles.getBaseColor(), styles.getBgAlpha());
				graphics.drawRect(0, 0, _width, _height);
				graphics.endFill();
				createChildren();
			}
		}		
		
		private function handleAdded( e : Event ) : void
		{
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, fullScreenHandler);			
			this.removeEventListener(Event.ADDED_TO_STAGE, handleAdded);			
		}
		
		private function handlePlaylistLoad( e : TSWidgetEvent = null ) : void
		{
			trace("PLAYLIST IS READY");
			if (dm.getPlaylist() && !playerControl)
			{
				trace("EMAIL_CONTROL_HEIGHT: " + EMAIL_CONTROL_HEIGHT);
				var h : Number = _height - EMAIL_CONTROL_HEIGHT;
			
				playerControl =  new E4MPlayerControl(_width, h , dm.getPlaylist());
				playerControl.alpha = .8;
				addChild(playerControl);
				playerControl.addEventListener(E4MPlayerControl.VIDEO_INIT, handleVideoInit);
				playerControl.addEventListener(E4MPlayerControl.VIDEO_CLOSED, handleVideoClosed);				
				playerControl.addEventListener(MediaControlEvent.CONTROL_TYPE, onMediaControlHandler);
			}
		}
		/**
		 * Main controller handler for any view, indicates what
		 * actions should be made on the media.  This method should
		 * be passed into the View so that UI component 
		 * @param e
		 * 
		 */		
		public function onMediaControlHandler( e : MediaControlEvent ) : void
		{
			var command : String = e._command;
			trace("onMediaControlHandler.onMediaChangeHandler[" + command + "]");
			switch (command){
				case MediaControlEvent.TOGGLE_FULLSCREEN:
					//Need to redispatch this for the app to get it.
					trace("dispatch this TOGGLE_FULLSCREEN");
					toggleFullScreen();
					break;
			}
		}
		
		private function handleFullScreen( e : MediaControlEvent ) : void
		{
			trace("Toggle Fullscreen");	
		}
		
		private function handleVideoInit( e : Event ) : void
		{
			if (slideshow) {
				slideshow.stopShow();
				TweenLite.to(slideshow, .4, {autoAlpha:0});
			}
		}
		private function handleVideoClosed( e : Event ) : void
		{
			if (slideshow && !slideshow.isStarted()) {
				slideshow.startShow();
				TweenLite.to(slideshow, .4, {autoAlpha:1});
			}
		}
		
		/**
		 *  Creates the children to be configured.
		 *
		 */
		private function createChildren(event:Event = null):void {
			
			//array of the ui clips
			_clips = new Array();
			_bg = new Sprite();
			_bg.graphics.beginFill(0xccffff, 0);
			_bg.graphics.drawRect(0,0,_baseWidth, _baseHeight);
			_bg.graphics.endFill();
			addChild(_bg);
			
			
			// Email Submission View
//			var controlHeight : Number = 24;
			emailControl = new EmailControl(_width, EMAIL_CONTROL_HEIGHT);
			emailControl.y = _height - EMAIL_CONTROL_HEIGHT;//			emailControl.x = (_width - 
			_clips.push(emailControl);
			addChild(emailControl);
			configureListeners();
			dialogContainer = new Sprite();			

			//update the slideshow
			if (dm.getImageData() && dm.getImageData().length > 0)
			{
				updateSlideshow();
			}

			handleLoadComplete();
		}
		
		/**
		 * Handler for load complete 
		 * @param e
		 * 
		 */		
		private function handleLoadComplete( e : Event = null) : void
		{
//			trace("LOAD COMPLETE");
			if (dm.getCoppaState() == COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_FAILED) {
				showDOBFailDialog();
			}				
			_inited = true;
			//Notify the application to tween the view in.
			dispatchEvent(new Event(Event.COMPLETE, true)); 
		}		
		
		private function handleMouseOver(e:MouseEvent):void {
			if (playerControl)
			{
				idleTimer.stop();
				playerControl.show();
			}
		}
		
		private var idleTimer : Timer;
		
		private function handleMouseOut(e:MouseEvent):void {
//			trace("MOUSE OUT");
			if (playerControl) {
				idleTimer.start();
			}		
			
		}
		private function hidePlayer(): void {
			if (playerControl) playerControl.hide();
		}		
		private function onIdle( e : TimerEvent ) : void
		{
			idleTimer.stop();
			if (playerControl) playerControl.hide();
//				TweenMax.to(playerControl, 1, {dropShadowFilter:{color:0x000000, alpha:0, blurX:0, blurY:0, distance:0, angle:90}});			
//				playerControl.filters = null;
		}
		
		///////////////////////////////////////////////////////////////////////

		/**
		 *  Configures the various listeners.
		 *
		 */
		private function configureListeners():void {
			
			idleTimer = new Timer(1000,1);
			idleTimer.addEventListener(TimerEvent.TIMER,onIdle);
			
//			if(!_bg.hasEventListener(MouseEvent.ROLL_OVER)) { _bg.addEventListener(MouseEvent.ROLL_OVER, handleMouseOver); }
//			if(!_bg.hasEventListener(MouseEvent.ROLL_OUT)) { _bg.addEventListener(MouseEvent.ROLL_OUT, handleMouseOut); }
			if(!this.hasEventListener(MouseEvent.MOUSE_OVER)) { this.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver); }
			if(!this.hasEventListener(MouseEvent.MOUSE_OUT)) {this.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut); }
			
			emailControl.addEventListener(DOBControl.DOB_VALIDATION_FAIL, showDOBFailDialog);
		}
		
		public function handleDisplayStatus( e : MessageStatusEvent ) : void
		{
			displayStatus(e.message, e.isError);
		}
		public function textChanged(evt:Event):void {
			var typed:String = evt.target.text.slice(evt.target.text.length-1, evt.target.text.length);
			if (typed == "\"") {
				evt.target.text = evt.target.text.slice(0, evt.target.text .length-1)+"@";
			}
		}		
		
		/**
		 * Updates the slideshow 
		 * @param e
		 * 
		 */		
		private function updateSlideshow(e:Event = null):void {
			//			trace("E4M: update a Slideshow");
			if (!slideshow) {
//				trace("create a slideshow!!!");
				slideshow = new SlideShow(_width, _height - EMAIL_CONTROL_HEIGHT, dm.getImageData(), styles.getLinkColor(), 
					dm.crossfaderate, dm.smoothing);
				
				slideshow.setVAlign( styles.getImageVAlign());
				slideshow.x = 0;//styles.getHPadding();
				slideshow.y = 0;//styles.getHPadding();
				
				slideshow.disableButtons();
				
				addChildAt(slideshow, 0);
				slideshow.activate();
				
				if (dm.getClickTag()  && dm.getClickTag() != "null" ) {
					slideshow.addClickListener(handleArtistAdRedirect);
				}			
			} else {
				slideshow.refresh();
			}
		}

		/**
		 * Draws a bg banner  
		 * @param target
		 * @param w
		 * @param h
		 * @param bgColor
		 * @param strokeColor
		 * @param drawBottom
		 * 
		 */
		private function createBGBanner(target:Sprite, w:Number, h:Number, bgColor:uint = 0x000000, strokeColor:uint = 0xFFFFFF):void {
			var bgalpha : Number = (styles.getBgAlpha() == 0) ? 0 : .5;
			target.graphics.clear();
			target.graphics.beginFill(bgColor, bgalpha);
			target.graphics.drawRect(0,0,w,h);
			target.graphics.endFill();
		}
		
		/**
		 *  Ensures that the text is sized appropriately to fit inside the 
		 *  widget, will shrink the size of the text to fit
		 *
		 */
		private function formatText(inputTextField:TextField, tHeight : Number):void {
			var holderTextFormat:TextFormat = inputTextField.getTextFormat();
			holderTextFormat.size = styles.getDefaultFontSize();
			inputTextField.setTextFormat(holderTextFormat);
			
			while (inputTextField.textWidth > _width - 2 * styles.getHPadding()) {
				holderTextFormat.size = parseInt(holderTextFormat.size.valueOf()) - 1;
				if (holderTextFormat.size < GlobalStyleManager.MIN_SIZE) break;
				inputTextField.setTextFormat(holderTextFormat);
			}
			
			while (inputTextField.textHeight > tHeight) {
				holderTextFormat.size = parseInt(holderTextFormat.size.valueOf()) - 1;
				if (holderTextFormat.size < GlobalStyleManager.MIN_SIZE) break;
				inputTextField.setTextFormat(holderTextFormat);
			}
			inputTextField.autoSize = "left";
			var ex:Number = ((_width - inputTextField.width) / 2) - 1 ;
			if (styles.getHAlign() == "right") ex = _width - inputTextField.width - styles.getHPadding();
			if (styles.getHAlign() == "left") ex = styles.getHPadding();
			inputTextField.x = ex;
		}
		

		/**
		 * Redirects user to the whereever the clickTag specifies 
		 * @param e
		 * 
		 */		
		private function handleArtistAdRedirect(e:Event):void {
			//Does this still apply.
			EventLogger.fire(TSEvents.TYPE.CLICK, {campaign:dm.getCampaignId(), artist:dm.getArtistId(),  
				clickTag:dm.getClickTag(), 
				sub_type : TSEvents.SUBTYPE.E4M_CLICK });									
			
			if (dm.getClickTag() && dm.getClickTag() != "null") {
				if (dm.getExternalInterfacesAvailable()) { 
					var variables:URLVariables = new URLVariables();
					variables.timestamp = new Date().getTime();
					var request:URLRequest = new URLRequest(dm.getClickTag());
					request.data = variables;
					try {            
						navigateToURL(request);
					}
					catch (e:Error) {
//						trace("Unable to link to " + dm.getClickTag());
//						showShareDialog();
					}
				} else {
//					showShareDialog();
				}
			}			  			  		
		}
	
		
		/**
		 *  Clears the field 
		 *
		 */		
		private function autoClearInputs(event:Event):void {
			
			if (!event.target || !event.target.hasOwnProperty("text") ) return;
			if (event.target.text != _finalEmailStr) return;
			event.target.text = "";
			event.stopImmediatePropagation();
			event.target.parent.removeEventListener(FocusEvent.FOCUS_IN, autoClearInputs);
			event.target.parent.addEventListener(FocusEvent.FOCUS_OUT, autoUpdateInputs);
		}		
		
		/**
		 * Update the inputs 
		 * @param event
		 * 
		 */
		private function autoUpdateInputs( event:FocusEvent):void {
			if (!event.target) return;			
			if (!event.target.hasOwnProperty("text")) return;
			if (event.target.text.length > 0) return;
			
			event.target.text = _finalEmailStr;
			displayStatus(dm.getHeadlineMessage());
			event.target.parent.addEventListener(FocusEvent.FOCUS_IN, autoClearInputs);
			event.target.parent.removeEventListener(FocusEvent.FOCUS_OUT, autoUpdateInputs);			
		}
		
		
		////////////////////////////////////////////////////////////////////////
		//
		// Dialog Management 
		//
		////////////////////////////////////////////////////////////////////////
		/**
		 *  Destroys any dialog that is showing. 
		 * 
		 */		
		public function destroyDialogs( e : Event ) : void
		{
			e.target.removeEventListener(DialogEvent.CLOSE, destroyDialogs);
			for (var i : Number = 0; i < dialogContainer.numChildren; i++)
			{
				dialogContainer.removeChildAt(i);
			}	
			removeChild(dialogContainer);
		}

		/**
		 * Shows the fail dialog if you are underage. 
		 * @param e
		 * 
		 */		
		public override function showDOBFailDialog( e : Event = null) : void
		{
			var dialog:FatalDialog = new FatalDialog(_width, EMAIL_CONTROL_HEIGHT + 2,"Sorry", dm.getUnderageMessage());
			dialog.addEventListener(DialogEvent.CLOSE, destroyDialogs);
			
			dialogContainer.addChild(dialog);
			addChildAt(dialogContainer, numChildren-1);		
//			controlClip.visible = false;
			emailControl.visible = false;
			dialogContainer.y = _height - dialogContainer.height;
			dialog.activate();				
		}

		/**
		 * Toggles the FullScreen mode
		 * 
		 */		
		private function toggleFullScreen():void 
		{
//			trace("toggleFullScreen");
			switch(stage.displayState) {
				case StageDisplayState.NORMAL:
					try {
						stage.displayState = StageDisplayState.FULL_SCREEN;  
					}catch (e : Error) {
						trace("Sorry kid, no fullscreen allowed");
					}	
					break;
				case StageDisplayState.FULL_SCREEN:
				default:
					stage.displayState = StageDisplayState.NORMAL;    
					break;
			}
//			stage.invalidate();
//			setProgressPosition();
		}   		
		
		private function setSize( w:Number, h : Number) : void
		{
			_width = w;
			_height = h;
			draw();
		}
		
		private function draw() : void
		{
			if (!_inited) return;
			
			var h = (stage.displayState == StageDisplayState.FULL_SCREEN) ? _height : _height - EMAIL_CONTROL_HEIGHT;
			
			if (playerControl)
			{
				
				playerControl.setSize(_width, h);
			}
			
			if (slideshow)
			{
				slideshow.setSize(_width,h);
			}
		}
		
		/**
		 * Handler for the stage resize fullscreenhandler 
		 * @param e
		 * 
		 */		
		private function fullScreenHandler( e : FullScreenEvent ) : void
		{
//			trace("fullscreen handler");
//			toggleFullScreen();
			stage.invalidate();
			
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				setSize(stage.fullScreenWidth,stage.fullScreenHeight);
				if (emailControl) emailControl.visible = false;
			}else{
				setSize(_baseWidth,_baseHeight);		
				if (emailControl) emailControl.visible = true;
			}
			
		}		
				
	}
}