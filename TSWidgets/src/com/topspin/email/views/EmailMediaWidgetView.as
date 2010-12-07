package com.topspin.email.views {
	import com.topspin.api.events.Dependency;
	import com.topspin.api.events.E4MEvent;
	import com.topspin.api.logging.EventLogger;
	import com.topspin.api.logging.TSEvents;
	import com.topspin.common.controls.SimpleLinkButton;
	import com.topspin.common.controls.SlideShow;
	import com.topspin.common.events.DialogEvent;
	import com.topspin.common.events.PlayerAdapterEvent;
	import com.topspin.common.media.IPlayerAdapter;
	import com.topspin.email.controls.DOBControl;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.dialogs.EmailOptInDialog;
	import com.topspin.email.dialogs.FatalDialog;
	import com.topspin.email.dialogs.MessageDialog;
	import com.topspin.email.dialogs.SocialDialog;
	import com.topspin.email.events.MessageStatusEvent;
	import com.topspin.email.style.GlobalStyleManager;
	import com.topspin.email.validation.COPPAComplianceValidation;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
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

	/**
	 * EmailMediaWidgetView main view  
	 * @author amehta
	 * 
	 */	
	public class EmailMediaWidgetView extends AbstractView {

		//Properties
		public static var NAME : String = "EmailMediaWidgetView";
//		public var _root:TSEmailMediaWidget;			//Reference to application
//		private var _width:Number;				
//		private var _height:Number;
		private var dependency : Dependency; 			//Used to load images	

		// Data Instances
		private var dm:DataManager;						//DataManager singleton
		private var styles:GlobalStyleManager;			//StyleManager singleton

		// Loaders
		public var submitLoader:Loader;					//Loader used if custom submit image btn loaded 
		public var ctaLoader : Loader;					//Loader used if custom cta image btn loaded
		public var backgroundLoader:Loader;				//Loader used if custom bg image loaded
		
		// UI
		public var headlineTxt:TextField;				//Main headline text
		public var upperHeadlineTxt:TextField;			//Upper headline text which can be configured
		public var ctaBtn:Sprite;						//Call to action button
		public var controlClip:Sprite;					//Holder of controls
		public var upperControlClip:Sprite;				//Holder of upper headline and controls
		public var emailControl:Sprite;					//Holder of the email container
		public var emailTxt:TextField;					//Textfield for the email text
		public var submitBtn:Sprite;					//Submit button, could be loaded graphic
		public var sharingStrip:Sprite;					//Holder for the sharing UI
		public var embedBtn:SimpleLinkButton;			//Embed button
		public var customLink : TextField;				//Html link button, configure by flashvar customLink
		public var privacyLink : TextField;				//Html link button for the privacy
		public var infoBtn : SimpleLinkButton;			//Little i button to show email opt in messaging
		public var dobControl : DOBControl;				//DOB control for COPPA Compliant widgetz		
		public var slideshow:SlideShow;					//Slideshow control				
		public var playerAdapter:IPlayerAdapter;		//IPlayerAdapter to play media	
		public var playlistContainer:Sprite;			//Holder for the playerAdapter	
		
		private var _DOB_message : String = "Please enter your date of birth";
		private var flipTimer : Timer;
		
		
//		//dialog container
//		public var dialogContainer : Sprite;			//Holds any dialogs

		// Default static text
		private static var _defaultEmail:String = "Enter Email Address";
		private static var _defaultEmailMini:String = "Enter Email";
		private var _finalEmailStr : String;				//emailTxt default string based on the size of the widget
		
		// Animation properties
		private static const PLAYER_ADAPTER_PATH : String =  "/widgets/api/TSPlayerAdapter.swf"; //"/flash/adapters/PlayerAdapter.swf";
		private static var FADE_RATE:Number = .3;		//Animation rate for fades	
		private static var RESET_TIME:Number = 5000;	//Reset timer
		private static var PAD:uint = 4;				//Default PAD between ui
		private var _resetTimer:Timer;					//Timer instance to reset the app				
		
		// States
		private var _isSubmitting : Boolean = false;		//State used to prevent multiple submits.
		private var _e4mSubmitted:Boolean = false; 		//State used with playMedia.  Used to know when to display the
		private var DEFAULT_STATE : String = "default_state";
		private var EMAIL_STATE : String = "email_state";
		private var DOB_STATE : String = "dob_state";
		private var _clips : Array;		
														//play btn
		private var _isPlaying:Boolean = false;			//Indicates whether media is playing or not		
		private var MINI_MODE : Boolean = false;		//State indicating the size of the widget, used to render properly
		
		private var eHeight : Number = 20;
		
		/**
		 * Constructor 
		 * @param width
		 * @param height
		 * @param root - Reference to app
		 * 
		 */		
		public function EmailMediaWidgetView(width:Number, height:Number, root:TSEmailMediaWidget) {
			super(width, height, root);

			//Listen to be added and then additional event listeners
			addEventListener(Event.ADDED_TO_STAGE, handleAdded);
			
			//Get an instance of DataManager
			dm = DataManager.getInstance();
			dm.addEventListener(DataManager.IMAGE_DATA_UPDATE, updateSlideshow);
			
			dm.addE4MHandler(handleE4MEvent);
			
			//Get an instance of GlobalStyleManager
			styles = GlobalStyleManager.getInstance();
			styles.init();

			//Figure out if we are MINI mode or not
			MINI_MODE = (_width < 250) ? true : false;
			_finalEmailStr = (MINI_MODE) ? _defaultEmailMini : _defaultEmail;
			_DOB_message = dm.getDOBMessage();
			//If passed via flashvar, we can load in a bg image
			if(dm.getBGImageLocation()) {
				loadBgImage();
			}
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
		/**
		 *  Creates the children to be configured.
		 *
		 */
		private function createChildren(event:Event = null):void {

			//array of the ui clips
			_clips = new Array();
			
			// Call to Action View
			controlClip = new Sprite();
			addChild(controlClip);
			
			var format : TextFormat = styles.getFormat();

				// Headline TextField
				headlineTxt = new TextField();
				headlineTxt.embedFonts = styles.getEmbedFonts();			
				headlineTxt.multiline = true;
				headlineTxt.antiAliasType = "advanced";
				headlineTxt.width = _width;
				headlineTxt.selectable = false;
				headlineTxt.defaultTextFormat = format; //styles.getFormat();
				headlineTxt.y = 0;
				headlineTxt.autoSize = "left";
				controlClip.addChild(headlineTxt);
				
				// Conditionally add headline text to upper or lower view
				// If the flashvar is passed, you can display another textfield
				// tp the top of the widget
				if(dm.getToggleViews()) {
					upperControlClip = new Sprite();
					addChild(upperControlClip);

					upperHeadlineTxt = new TextField();
					upperHeadlineTxt.embedFonts = styles.getEmbedFonts();			
					upperHeadlineTxt.multiline = true;
					upperHeadlineTxt.antiAliasType = "advanced";
					upperHeadlineTxt.width = _width;
					upperHeadlineTxt.selectable = false;
					upperHeadlineTxt.defaultTextFormat = format; 
					upperHeadlineTxt.y = 0;
					upperHeadlineTxt.autoSize = "left";
					upperHeadlineTxt.text = dm.getHeadlineMessage();
					upperControlClip.addChild(upperHeadlineTxt);

		    		var textHeight:Number = upperHeadlineTxt.getTextFormat().size + 10;
		    		createBGBanner(upperControlClip, _width, textHeight, styles.getBaseColor());
		    		
		    		upperControlClip.y = 0;

				} else {
					headlineTxt.text = dm.getHeadlineMessage();
					headlineTxt.defaultTextFormat = format; 
				}
	
				// Call to Action Button
				ctaBtn = new SimpleLinkButton(dm.getOfferButtonLabel(), styles.getBtnFormat(), styles.getBtnOverFormat(), null, styles.getLinkHasOutline(), 10, 0, 16, "center",2);
				controlClip.addChild(ctaBtn);
				_clips.push(ctaBtn);
			
				// Email Submission View
				emailControl = new Sprite();
				_clips.push(emailControl);
				
				var btnFormat : TextFormat = styles.getBtnFormat();
				var btnOverFormat : TextFormat = styles.getBtnOverFormat();
				if (MINI_MODE) {
					btnFormat.size = 10;
					btnOverFormat.size = 10;
				}
			
				// Submit Button
				submitBtn = new SimpleLinkButton("Submit", btnFormat, btnOverFormat, null, styles.getLinkHasOutline(), (MINI_MODE)? 4:10,(MINI_MODE)? 4:0, 16, "center",2); 
				emailControl.addChild(submitBtn);
				
				var emailControlX:Number = _width - (submitBtn.width + 4 * styles.getHPadding() + EmailMediaWidgetView.PAD);
				
				// Email Input TextField			
				emailTxt = new TextField();
				emailTxt.embedFonts = styles.getEmbedFonts();
				emailTxt.type = "input";
				emailTxt.antiAliasType = "advanced";
				emailTxt.width = (styles.getHAlign() == "center") ? _width - (submitBtn.width + 4 * styles.getHPadding() + EmailMediaWidgetView.PAD) : _width - (submitBtn.width + 2 + 2*styles.getHPadding() + EmailMediaWidgetView.PAD);	
				emailTxt.background = true;
				emailTxt.backgroundColor = 0xffffff;	
				emailTxt.border = true;
				emailTxt.borderColor = styles.getLinkColor()
				emailTxt.text = _finalEmailStr;
				emailTxt.defaultTextFormat = styles.getEmailFormat();
				emailTxt.setTextFormat(styles.getEmailFormat());
				emailTxt.height = emailTxt.textHeight + EmailMediaWidgetView.PAD;// -2*dm.getHPadding;			
				emailControl.addChild(emailTxt);
	
				emailTxt.x = 0;
				submitBtn.x = Math.floor(emailTxt.x + emailTxt.width + (2 * EmailMediaWidgetView.PAD));
				emailTxt.y = (submitBtn.height - emailTxt.height ) /2;	

				emailControlX = ((_width - emailControl.width) / 2) ;
				if (styles.getHAlign() == "right") emailControlX = _width - emailControl.width - styles.getHPadding();
				if (styles.getHAlign() == "left") emailControlX = styles.getHPadding();						
				emailControl.x = emailControlX; //(halign=="center") ? (_width - emailControl.width)/2:dm.getHPadding;			
					
				emailControl.visible = false;
				emailControl.alpha = 0;
			
				controlClip.addChild(emailControl);

				ctaBtn.y = headlineTxt.y + headlineTxt.height + styles.getHPadding();
				emailControlX = ((_width - ctaBtn.width) / 2) ;
				if (styles.getHAlign() == "right") emailControlX = _width - ctaBtn.width - styles.getHPadding();
				if (styles.getHAlign() == "left") emailControlX = styles.getHPadding();						
				ctaBtn.x = emailControlX; //(_width-ctaBtn.width)/2;
				emailControl.y = ctaBtn.y; //headlineTxt.y + headlineTxt.height + 2;

			// Embed Button
			var isSharing : Boolean = dm.getSharing();
			var customUrl : String = dm.getCustomLinkUrl();
			var privacyUrl : String = dm.getPrivacyUrl();
			var optInInfo : String = dm.getInfoContent();
			var showInfoIcon : Boolean = (optInInfo && optInInfo.length>0 && !dm.hideinfo);
			
			//Create the sharing strip at the bottom
			if (isSharing || customUrl != null || showInfoIcon || privacyUrl)  
			{
				sharingStrip = new Sprite();
				
				if (isSharing)
				{
					embedBtn = new SimpleLinkButton("<share>", styles.getSmallFormat(), styles.getSmallFormatOver(), "<share>", false, 4, 0, 16, dm.getEmbedAlign()); 
					emailControlX = (_width-embedBtn.width)/2;
					if (dm.getEmbedAlign() == "right") emailControlX = _width - embedBtn.width - EmailMediaWidgetView.PAD;
					if (dm.getEmbedAlign() == "left") emailControlX = 1;

					embedBtn.x =  emailControlX;
					embedBtn.y = 1;
					sharingStrip.addChild(embedBtn);
					eHeight = embedBtn.height; 
					
				}
				if (customUrl)
				{
					var htmlText : String = "<a href='event:link'>" + dm.getCustomLinkLabel() + "</a>";
					customLink = new TextField();
					customLink.autoSize = "left";
					customLink.embedFonts = true;
					customLink.antiAliasType = AntiAliasType.ADVANCED;
					customLink.htmlText = htmlText;
					customLink.styleSheet = styles.optionsCSS;			
					customLink.width = 50;
					customLink.height = 20;
					customLink.selectable = false;		
					emailControlX = (_width-customLink.width)/2;
					if (dm.getEmbedAlign() == "right") emailControlX = _width - customLink.width - EmailMediaWidgetView.PAD;
					if (dm.getEmbedAlign() == "left") emailControlX = 1;										
					sharingStrip.addChild(customLink);	
					customLink.y = 1; //_height - customLink.height;
					if (!embedBtn) eHeight = customLink.height;
				}
				
				if (privacyUrl)
				{
//					trace("CREATE THE PRIVACY URL " );
					//					var htmlText : String = 
					privacyLink = new TextField();
					privacyLink.autoSize = "left";
					privacyLink.embedFonts = true;
					privacyLink.antiAliasType = AntiAliasType.ADVANCED;
					privacyLink.htmlText = "<a href='event:link'>Privacy</a>";
					privacyLink.styleSheet = styles.optionsCSS;			
					privacyLink.width = 50;
					privacyLink.height = 20;
					privacyLink.selectable = false;		
					emailControlX = 1;										
					sharingStrip.addChild(privacyLink);	
					privacyLink.x = privacyLink.y = 1; //_height - privacyLink.height;
					if (!embedBtn) eHeight = privacyLink.height;
				}				
				
				
				if (showInfoIcon)
				{
					var smOut : TextFormat = new TextFormat(styles.getFormattedFontName(),8,styles.getBaseColor(),true);
					var smOver : TextFormat = new TextFormat(styles.getFormattedFontName(),8,styles.getLinkColor(),true);
					
					infoBtn = new SimpleLinkButton(" i ", smOut, smOver, null,true, 0, 0, 0,"center",1,true); 
					infoBtn.borderOverColor = styles.getLinkColor();
					infoBtn.alpha = .8;
					sharingStrip.addChild(infoBtn);	
					infoBtn.y = 1; //_height - customLink.height;
					if (!embedBtn && !customLink) eHeight = infoBtn.height;
				}				
				
				if (infoBtn != null)
				{
					infoBtn.x = _width - infoBtn.width - 2;					
				}
				if (customLink)
				{
					var xs : Number = (infoBtn) ? infoBtn.x : _width;
					customLink.x = xs - customLink.width - 4;
				}
				sharingStrip.graphics.beginFill(styles.getLinkColor(), 0);
				sharingStrip.graphics.drawRect(0,0,_width,eHeight);
				sharingStrip.graphics.endFill();				
				sharingStrip.y = emailControl.y + emailControl.height + EmailMediaWidgetView.PAD + 2;  
				controlClip.addChild(sharingStrip);	
			}
			
			configureListeners();
			refresh();
			dialogContainer = new Sprite();			

			dependency = new Dependency();
			dependency.addEventListener(Event.COMPLETE, handleLoadComplete);
			dependency.addDependancy("createChildrenComplete");
		
			createDOB();
//			if (dm.collectDOB())
//			{
//				dobControl = new DOBControl(MINI_MODE);
//			 	dobControl.addEventListener(DOBControl.DOB_SUBMITTED, handleDob);
//				dobControl.addEventListener(MessageStatusEvent.TYPE, handleDisplayStatus);
//				dobControl.addEventListener(DOBControl.DOB_VALIDATION_FAIL, showDOBFailDialog);
//				
//			 	dobControl.x = (styles.getHAlign() == "center") ? (_width - dobControl.width)/2 : styles.getHPadding();
//				dobControl.alpha = 0;
//				controlClip.addChild(dobControl);
//				
//				_clips.push(dobControl);				
//			}
		
			if(dm.getPlayMedia() ) {
				dependency.addDependancy(handlePlayerAdapterLoaded);
				retrievePlayerAdapter();
			}
			if(!dm.getDisplayInitialScreen()) {
				ctaBtn.alpha = 0;
				if (dm.collectDOB())
				{
					showState(DOB_STATE);
				}else{
					showState(EMAIL_STATE);					
				}
			}else{
				//Only attempt to load the CTA image if displayInitialScreen is true 
				if (dm.getCTAImageLocation()) {
					loadCTAButton();
				}
			}
			//Load a submit button if passed
			if (dm.getSubmitImageLocation()) {
				loadSubmitButton();	
			} 
			//update the slideshow
			if (dm.getImageData() && dm.getImageData().length > 0)
			{
				updateSlideshow();
			}
			
			dependency.setLoadDependencyMet("createChildrenComplete");
		}
		
		private function createDOB() : void {
			if (!dobControl){
				dobControl = new DOBControl(MINI_MODE);
				dobControl.addEventListener(DOBControl.DOB_SUBMITTED, handleDob);
				dobControl.addEventListener(MessageStatusEvent.TYPE, handleDisplayStatus);
				dobControl.addEventListener(DOBControl.DOB_VALIDATION_FAIL, showDOBFailDialog);
				
				dobControl.x = (styles.getHAlign() == "center") ? (_width - dobControl.width)/2 : styles.getHPadding();
//				dobControl.alpha = 0;
				dobControl.visible = 0;
				controlClip.addChild(dobControl);
				
				_clips.push(dobControl);				
			}
		}
		
		public function handleDisplayStatus( e : MessageStatusEvent ) : void
		{
			displayStatus(e.message, e.isError);
		}
		/**
		 * Callback from the dob widget 
		 * @param e
		 * 
		 */		
		private function handleDob(e : Event ) : void
		{
			showState(EMAIL_STATE);
		}
		/**
		 * Handler for load complete 
		 * @param e
		 * 
		 */		
		private function handleLoadComplete( e : Event ) : void
		{
			trace("LOAD COMPLETE");
			if (dm.getCoppaState() == COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_FAILED) {
				showDOBFailDialog();
			}				
		
			//Dependency is complete, kill it.
			dependency.removeEventListener(Event.COMPLETE, handleLoadComplete);
			
			//Notify the application to tween the view in.
			dispatchEvent(new Event(Event.COMPLETE, true)); 
		}		
		
		////////////////////////////////////////////////////////////////////////
		//
		// Player Adapter, loaded in only if playMedia is true
		//
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * Loads the playerAdapter swf into the widget and handles playing video
		 * or audio for in the widget 
		 * 
		 */		
		private function retrievePlayerAdapter():void {			
			var loaderContext : LoaderContext = new LoaderContext();
			loaderContext.securityDomain = SecurityDomain.currentDomain;	
			var path : String = dm.getBaseURL() + PLAYER_ADAPTER_PATH;	
			trace("->retrievePlayerAdapter: " + path);
			var request:URLRequest = new URLRequest(path);
			var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.INIT, handlePlayerAdapterLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, playerAdapterIOErrorHandler);
				loader.load(request, loaderContext);				
		}

		/**
		 * Handles the load of the playerAdapter swf. 
		 * Need to refactor to use the TSWidget api instead.  Current, this playerAdapter will 
		 * consume the widget_id XML and play a single track or video in a playlist
		 * @param e
		 * 
		 */
		private function handlePlayerAdapterLoaded(e:Event):void {
			e.target.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,handlePlayerAdapterLoaded);
			e.target.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, playerAdapterIOErrorHandler);
			trace("IPlayerAdapter yo yo");
			playerAdapter = IPlayerAdapter(e.currentTarget.content);
			playerAdapter.addEventListener(PlayerAdapterEvent.PLAY_MEDIA_READY, handlePlaylistLoad);
			playerAdapter.addEventListener(PlayerAdapterEvent.MEDIA_PLAY, handleMediaPlay);
			playerAdapter.addEventListener(PlayerAdapterEvent.MEDIA_PAUSE, handleMediaPause);
			
			playerAdapter.setPlaylistParams(dm.getWidgetId(), dm.getClickTag(), this._width, this._height, styles.getLinkColor());
			playerAdapter.setSize(this._width, this._height);
			playerAdapter.setVAlign(styles.getImageVAlign());
			playerAdapter.loop = dm.isLoop();
			playerAdapter.parse(dm.getWidgetXML());
			
			dependency.setLoadDependencyMet(handlePlayerAdapterLoaded);

			function handlePlaylistLoad():void {
				playlistContainer = Sprite(playerAdapter);
				var index : Number = getChildIndex(controlClip);
				addChildAt(playlistContainer,index);
				addChild(controlClip);

				if (dm.isAutoPlay())
				{
					playerAdapter.play(dm.getDelayStart());
				}
			}
		}

		private function playerAdapterIOErrorHandler(e:Event):void { 
			dependency.setLoadDependencyMet(handlePlayerAdapterLoaded);
		}
		
		private function handleMediaPlay(e:PlayerAdapterEvent = null):void {
			if(!this.hasEventListener(MouseEvent.MOUSE_OVER)) { this.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver); }
			if(!this.hasEventListener(MouseEvent.MOUSE_OUT)) { this.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut); }

			if(_e4mSubmitted) {
//				TweenLite.to(controlClip, .8, {autoAlpha:0});
				if(dm.getToggleViews()) {
					TweenLite.to(upperControlClip, .8, {autoAlpha:0});
				}
			}
			_isPlaying = true;
		}
		
		private function handleMediaPause(e:PlayerAdapterEvent):void {
			_isPlaying = false;
		}

		private function handleMouseOver(e:MouseEvent):void {
			playerAdapter.displayOverlayButton();
		}

		private function handleMouseOut(e:MouseEvent):void {
			if(_isPlaying) {
				playerAdapter.hideOverlayButton();
			}
		}
		
		///////////////////////////////////////////////////////////////////////
		
		/**
		 * Shows the control clip. 
		 * @param bool
		 * 
		 */		
		private function showTheControlClip( bool : Boolean = true ) : void {
			TweenLite.to(controlClip, .8, {autoAlpha:(bool)?1:0});
		}

		/**
		 *  Configures the various listeners.
		 *
		 */
		private function configureListeners():void {
			ctaBtn.addEventListener(MouseEvent.CLICK, handleCTAClick );
			submitBtn.addEventListener(MouseEvent.CLICK, handleSubmit );
			

			emailTxt.addEventListener(FocusEvent.FOCUS_IN, autoClearInputs);
			emailTxt.addEventListener(MouseEvent.CLICK, autoClearInputs);
			emailTxt.addEventListener(Event.CHANGE, textChanged);			

			if (embedBtn) embedBtn.addEventListener(MouseEvent.CLICK, showShareDialog );
			if (customLink) customLink.addEventListener(MouseEvent.CLICK, showCustomLink );
			if (infoBtn) infoBtn.addEventListener(MouseEvent.CLICK, showInfoDialog );			
			if (privacyLink) privacyLink.addEventListener(MouseEvent.CLICK, showPrivacy);
		}
		public function showLink( link : String ) : void
		{
			var err : Boolean = false;
			if (link && link != "null") {
				if (dm.getExternalInterfacesAvailable()) { 
					var request:URLRequest = new URLRequest(link);
					try {            
						navigateToURL(request);
					}
					catch (e:Error) {
						err = true;
						trace("Unable to link to " + link);
					}
				}else{
					err=true;
				}
				if (err)
				{
					showMessageDialog("", link);
				}
			}	
		}
		//Clicks out to another place
		public function showPrivacy( e : MouseEvent = null) : void
		{
			showLink(dm.getPrivacyUrl());
		
		}		
		//Clicks out to another place
		public function showCustomLink( e : MouseEvent = null) : void
		{
			showLink(dm.getCustomLinkUrl());	
		}
		
		public function textChanged(evt:Event):void {
			var typed:String = evt.target.text.slice(evt.target.text.length-1, evt.target.text.length);
			if (typed == "\"") {
				evt.target.text = evt.target.text.slice(0, evt.target.text .length-1)+"@";
			}
		}		
		
		public function enterKeyDown(e:KeyboardEvent):void
		{ 
			var kc:Number = e.keyCode;
			
			if (emailControl && controlClip.contains(emailControl) && emailControl.visible) {
				if (stage.focus == emailTxt && e.keyCode == Keyboard.ENTER) {
					handleSubmit();
			    }			
			}
		}	

		/**
		 * Shows the email control and tweens it in 
		 * @param show
		 * 
		 */		
		private function showState( state:String): void {
			refresh();
			switch (state){
				case EMAIL_STATE:
					emailControl.alpha = 0;
					showControlClip(emailControl);
					if (!dm.getDisplayInitialScreen())
					{
						stopDOBFlipTimer();
					}
					emailTxt.text = _finalEmailStr;			
					emailControl.y = ctaBtn.y;		
					displayStatus(dm.getHeadlineMessage());	
					if (dobControl && controlClip.contains(dobControl)) 
					{
						dobControl.visible = false;
						controlClip.removeChild(dobControl);						
					}
					if (ctaBtn) ctaBtn.visible = false;
					break;
				
				case DOB_STATE:
					
					dobControl.alpha = 0;
					dobControl.visible = false;
					if (!controlClip.contains(dobControl))
					{
						controlClip.addChild(dobControl);	
					}						
					showControlClip(dobControl);
					if (!dm.getDisplayInitialScreen())
					{
						startDOBFlipTimer();
					}else{
						displayStatus(_DOB_message);
					}
					dobControl.y = emailControl.y + 4;	
					if (emailControl) emailControl.visible = false;
					if (ctaBtn) ctaBtn.visible = false;
					break;
				
				case DEFAULT_STATE:
					ctaBtn.alpha = 0;
					showControlClip(ctaBtn);

					if (!dm.getDisplayInitialScreen())
					{
						stopDOBFlipTimer();
					}

					displayStatus(dm.getHeadlineMessage());
					ctaBtn.y = headlineTxt.y + headlineTxt.height + EmailMediaWidgetView.PAD;
					if (emailControl) emailControl.visible = false;
					if (dobControl && controlClip.contains(dobControl)) 
					{
						dobControl.visible = false;
						controlClip.removeChild(dobControl);						
					}
					break;
			}
			
		}
		/**
		 * Starts the flip timer 
		 */		
		private function startDOBFlipTimer() : void
		{
			if (!flipTimer)
			{
				flipTimer = new Timer(5000,0);
				flipTimer.addEventListener(TimerEvent.TIMER,flipHeadline);
			}
			flipTimer.start();
		}
		/**
		 * Stops the flip timer 
		 */		
		private function stopDOBFlipTimer() : void
		{
			if (flipTimer)
			{
				flipTimer.stop();
			}
		}
		/**
		 * Flips the headline message if
		 * displayInitialScreen is true 
		 * @param e
		 * 
		 */			
		private function flipHeadline( e : TimerEvent ) : void
		{
			var status : String = getCurrentStatus();
			if (status == _DOB_message)
			{
				displayStatus(dm.getHeadlineMessage());
			}else{
				displayStatus(_DOB_message);
			}	
		}
		/**
		 *  Current status
		 * @return 
		 * 
		 */		
		public function getCurrentStatus() : String
		{
			var str : String;
			if (dm.getToggleViews() && this.upperHeadlineTxt != null)
			{
				str = this.upperHeadlineTxt.text;
			}else{
				str = this.headlineTxt.text;
			}
			return str;
		}		
		/**
		 * Show the proper clip 
		 * @param clip
		 * 
		 */			
		private function showControlClip( clip:Sprite ) : void 
		{
			var cc : Sprite;
			for (var i : Number = 0; i<_clips.length; i++)
			{
				cc = _clips[i];
				if (cc == clip)
				{
					clip.alpha = 0;
					TweenLite.to(clip,FADE_RATE, {autoAlpha:1});				
				}else{
					cc.visible = false;
				}	
			}
		}

//		private function handleSlideshowInit(e:Event):void { 
//			trace("SLIDE SHOW INITED");
//		}
		/**
		 * Updates the slideshow 
		 * @param e
		 * 
		 */		
		private function updateSlideshow(e:Event = null):void {
//			trace("E4M: update a Slideshow");
			if (!slideshow) {
				trace("create a slideshow!!! " + dm.getImageData().length);
				slideshow = new SlideShow(_width, _height, dm.getImageData(), styles.getLinkColor(), 
											dm.crossfaderate, dm.smoothing);
				
				slideshow.setVAlign( styles.getImageVAlign() );
				slideshow.x = 0;//styles.getHPadding();
				slideshow.y = 0;//styles.getHPadding();
				
				if(dm.getPlayMedia() || dm.getImageData().length <= 1) {
					trace("DISABLE BUTTONS?");
					slideshow.disableButtons();
				}
				
				addChildAt(slideshow, 0);
				slideshow.activate();
			
				if (dm.getClickTag()  && dm.getClickTag() != "null" ) {
					slideshow.addClickListener(handleArtistAdRedirect);
				}			
			} else {
//				trace("E4M: udpateSlideshow : slideshow.refresh()");
				slideshow.refresh();
				if(dm.getPlayMedia() || dm.getImageData().length <= 1) {
					slideshow.disableButtons();
				}else{
					slideshow.enableButtons();
				}
			}
		}

		/**
		 *  Refreshes the layout, pretty gnarly refactor this
		 *
		 */
		private function refresh():void {
			formatText(headlineTxt);
			if(dm.getToggleViews()) {
				formatText(upperHeadlineTxt);
			}
			headlineTxt.y = 0;
			ctaBtn.y = headlineTxt.y + headlineTxt.height + EmailMediaWidgetView.PAD;
			if (emailControl && contains(emailControl)) {
				emailControl.y = ctaBtn.y; //headlineTxt.y + headlineTxt.height + PAD;
			}
			if (dobControl)
			{
				dobControl.y = emailControl.y + 4;
			}
			
			var h:Number = headlineTxt.textHeight + 4 * EmailMediaWidgetView.PAD + emailControl.height;
			
			if (dm.getSharing() || dm.getCustomLinkUrl() != null || infoBtn != null) {
				if (dm.getDisplayInitialScreen() && ctaBtn.height > emailControl.height)
				{
					sharingStrip.y = ctaBtn.y + ctaBtn.height + EmailMediaWidgetView.PAD + 2; 
				}else{
					sharingStrip.y = emailControl.y + emailControl.height + EmailMediaWidgetView.PAD + 2; 
				}
				h = sharingStrip.y + sharingStrip.height ; 
			}
			
			var emailControlX:Number = _width - (submitBtn.width + 4 * styles.getHPadding() + EmailMediaWidgetView.PAD);
			emailTxt.width = (styles.getHAlign() == "center") ? _width - (submitBtn.width + 4 * styles.getHPadding() + EmailMediaWidgetView.PAD) : _width - (submitBtn.width + 2 + 2*styles.getHPadding() + EmailMediaWidgetView.PAD);	
			emailTxt.x = 0;
			submitBtn.x = Math.floor(emailTxt.x + emailTxt.width + (2 * EmailMediaWidgetView.PAD));
			emailTxt.y = (submitBtn.height - emailTxt.height ) /2;	
			
			if (emailTxt.text == _finalEmailStr)
			{	
				_finalEmailStr = (MINI_MODE || emailTxt.width <=150) ? _defaultEmailMini : _defaultEmail;	
				emailTxt.text = _finalEmailStr;
			}
			emailControlX = ((_width - emailControl.width) / 2) ;
			if (styles.getHAlign() == "right") emailControlX = _width - emailControl.width - styles.getHPadding();
			if (styles.getHAlign() == "left") emailControlX = styles.getHPadding();						
			emailControl.x = emailControlX; //(halign=="center") ? (_width - emailControl.width)/2:dm.getHPadding;			
			
			if(!dm.getBGImageLocation()) {	

				createBGBanner(controlClip, _width, controlClip.height, styles.getBaseColor());
			}

	    	controlClip.y = _height - h; //h;//getControlHeight(); //controlClip.height;		
			// Returns the headline back to normal state
			TweenLite.to(headlineTxt, FADE_RATE, {autoAlpha:1});			
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
		private function formatText(inputTextField:TextField):void {
			var holderTextFormat:TextFormat = inputTextField.getTextFormat();
				holderTextFormat.size = styles.getDefaultFontSize();
			inputTextField.setTextFormat(holderTextFormat);

			while (inputTextField.textWidth > _width - 2 * styles.getHPadding()) {
				holderTextFormat.size = parseInt(holderTextFormat.size.valueOf()) - 1;
				if (holderTextFormat.size < GlobalStyleManager.MIN_SIZE) break;
				inputTextField.setTextFormat(holderTextFormat);
			}
			var h:Number = (dm.getSharing() || infoBtn!= null || dm.getCustomLinkUrl() != null) ? 4 * EmailMediaWidgetView.PAD + ctaBtn.height + eHeight : 4 * EmailMediaWidgetView.PAD + ctaBtn.height;
				h = _height - h;
			
			while (inputTextField.textHeight > h) {
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
		 * Displays the status in the headlineTxt
		 */
		public override function displayStatus(msg1:String, isError1:Boolean = false):void {		
			// FIX THIS //
			var textFieldToModify:TextField;
			if(dm.getToggleViews()) {
				textFieldToModify = this.upperHeadlineTxt;
			} else {
				textFieldToModify = this.headlineTxt;
			} 
			if(isError1) {
				textFieldToModify = this.headlineTxt;
			} else {
				if(this.upperHeadlineTxt) {
					textFieldToModify = this.upperHeadlineTxt;
				}
			}

			if (msg1 == textFieldToModify.text) return;
			TweenLite.to(textFieldToModify, FADE_RATE, {autoAlpha:0, onComplete: updateText, onCompleteParams:[msg1, isError1]});

			function updateText(msg:String, isError:Boolean):void {
				var f:TextFormat = textFieldToModify.getTextFormat();
					f.color = (isError) ? styles.getErrColor() : styles.getFontColor();
					f.size = (isError) ? styles.getErrorFontSize() : styles.getDefaultFontSize();
				textFieldToModify.setTextFormat(f);
				textFieldToModify.text = msg;
				emailTxt.borderColor = (isError) ? styles.getErrColor() : styles.getLinkColor();
				refresh();
			}
		}
		/**
		 * Resets the widget, if sharing is enabled then
		 * pop up the share dialog. 
		 * 
		 */		
		private function beginReset(showSharing : Boolean = false):void {
			
			_resetTimer = new Timer(RESET_TIME,1);			
			_resetTimer.addEventListener(TimerEvent.TIMER, resetIt);
			
			function resetIt( e : TimerEvent = null)
			{
				if (showSharing && dm.getSharing())
				{
					showShareDialog();
				}					
				showIntro();
			}
			
			_resetTimer.start();
		}
		
		/**
		 * Resets the intro once and email has been submitted 
		 * @param e
		 * 
		 */				
		private function showIntro(e:TimerEvent = null):void {
			if (_resetTimer){
				_resetTimer.reset();
				_resetTimer.removeEventListener(TimerEvent.TIMER, showIntro);
				_resetTimer = null;
			}
			
			
			if(dm.getToggleViews()) {
				upperHeadlineTxt.text = dm.getHeadlineMessage();
				formatText(upperHeadlineTxt);
				headlineTxt.text = "";
			} else {
				headlineTxt.text = dm.getHeadlineMessage();
				
			}
			
			if (dm.getDisplayInitialScreen())
			{
				showState(DEFAULT_STATE);
			}else{
				if (dm.collectDOB()) {
					showState(DOB_STATE);
				}else{
					showState(EMAIL_STATE);
				}
			}
		}
	
		////////////////////////////////////////////////////////////////////////
		//
		// Event handlers
		//
		////////////////////////////////////////////////////////////////////////		
		
		// Data Submission
		/**
		 * Regular expression for the email 
		 * @param input
		 * @return 
		 * 
		 */		
		private function validate(input:String):Boolean {
			return RegExp(/^([a-zA-Z0-9_\.\-\+])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})$/).test(input);
		}

		/**
		 * Handles the submit of the email 
		 * @param e
		 * 
		 */		
		private function handleSubmit( e:MouseEvent = null):void {
			if (_isSubmitting)
			{
				return;
			}else{
				_isSubmitting = true;
			}
			
			var email:String = emailTxt.text;
			if (email == _finalEmailStr || !validate(email) ){
				displayStatus(dm.getEmailErrorMessage(), true);
				_isSubmitting = false;
				return;
			} 
			displayStatus(dm.getSubmitMessage(), true);  // Display the sumbitting messsage			
			
			if(dm.getWidgetStatus() == DataManager.STATUS_UNPUBLISHED ) {
				displayStatus("Email submission not allowed in preview mode.", true);
			} 
			
//			var dob : Date = dm.getDOB();
//			if (dm.collectDOB())
//			{
			//			}			
			
			//Submit the email.
			dm.submitE4M(email);
		}	
		/**
		 * Handles E4MEvent 
		 * @param e
		 * 
		 */		
		private function handleE4MEvent( e : E4MEvent ) : void
		{
			switch (e.type) {
				case E4MEvent.EMAIL_SUCCESS:
					trace("E4M email sent success!");
					emailTxt.text = dm.getSuccessEmailMessage();
					emailTxt.scrollH = 0;
					displayStatus(dm.getSuccessMessage(), false);
					if (dm.collectDOB() && dobControl)
					{
						dobControl.reset();
					}
					_e4mSubmitted = true;
					_isSubmitting = false;
					beginReset(true);					
					break;
				
				case E4MEvent.EMAIL_ERROR:
					trace("E4M submit fail: " + e.message);
					displayStatus(dm.getSubmitFailMessage(), true);
					_isSubmitting = false;
					break;
				
				case E4MEvent.UNDERAGE_ERROR:
					trace("E4M Underage fail: " + e.message);
					displayStatus(e.message, true);
					_isSubmitting = false;
					break;
				case E4MEvent.DOB_NULL_BUT_REQUIRED:
					trace("E4M Collect DOB: " + e.message);
					displayStatus(e.message, true);
					_isSubmitting = false;
					showState(DOB_STATE);
					break;					
			}
		}					
		/**
		 * handleAdded
		 * Handles added to stage event, adds KEY_DOWN event listener
		 * @param e
		 * 
		 */
		private function handleAdded( e : Event ) : void {
			removeEventListener(Event.ADDED_TO_STAGE, handleAdded);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, enterKeyDown,true);	
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
						trace("Unable to link to " + dm.getClickTag());
						showShareDialog();
					}
				} else {
					showShareDialog();
				}
			}			  			  		
		}
		/* Text Input Event Listeners */
		/**
		 * Handler for call to action click.
		 */
		private function handleCTAClick(e:MouseEvent):void {	
			if (dm.collectDOB())
			{
				showState(DOB_STATE);
			}else{
				showState(EMAIL_STATE);
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
		 * Shows the social dialog 
		 * @param e
		 * 
		 */		
		public function showMessageDialog(msg : String, url : String) : void {
			
			var dialog:MessageDialog = new MessageDialog(stage.stageWidth,stage.stageHeight, msg, url);
			dialog.addEventListener(DialogEvent.CLOSE, destroyDialogs);
			
			dialogContainer.addChild(dialog);
			addChild(dialogContainer);		
			dialog.activate();	
			
		}		
		/**
		 * Shows the social dialog 
		 * @param e
		 * 
		 */		
		public function showShareDialog(e:Event = null) : void {
			
			var dialog:SocialDialog = new SocialDialog(stage.stageWidth,stage.stageHeight);
			dialog.addEventListener(DialogEvent.CLOSE, destroyDialogs);
			
			dialogContainer.addChild(dialog);
			addChild(dialogContainer);		
			dialog.activate();	
			
			if(dm.getWidgetStatus() == DataManager.STATUS_UNPUBLISHED ) {
				_root.displayErrorView("Sharing is disabled until this widget is Published");
			}		
		}
		
		/**
		 * Shows the fail dialog if you are underage. 
		 * @param e
		 * 
		 */		
		public override function showDOBFailDialog( e : Event = null) : void
		{
			//			trace('showDOBFailDialog');
			var dialog:FatalDialog = new FatalDialog(_width, controlClip.height + 2,"Sorry", dm.getUnderageMessage());
			dialog.addEventListener(DialogEvent.CLOSE, destroyDialogs);
			
			dialogContainer.addChild(dialog);
			addChildAt(dialogContainer, numChildren-1);		
			controlClip.visible = false;
			dialogContainer.y = _height - dialogContainer.height;
			dialog.activate();				
		}
		/**
		 * Shows the info dialog when clicking on the small i. 
		 * @param e
		 * 
		 */		
		public function showInfoDialog( e : Event = null ) : void
		{
			//			trace('showInfoDialog');
			var dialog:EmailOptInDialog = new EmailOptInDialog(stage.stageWidth,stage.stageHeight);
			dialog.addEventListener(DialogEvent.CLOSE, destroyDialogs);
			
			dialogContainer.addChild(dialog);
			addChild(dialogContainer);		
			dialog.activate();	
		}
		
		////////////////////////////////////////////////////////////////////////
		//
		// Custom images sent via flashvars.  
		//
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * Loads a CTA button (Call to Action) if specified via flashvars 
		 */		
		private function loadCTAButton():void {
			dependency.addDependancy(handleCTAImageLoaded);
			ctaLoader = new Loader();
			ctaLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleCTAImageLoaded);
			ctaLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ctaErrHandler);
			ctaLoader.load(new URLRequest(dm.getCTAImageLocation()));
		}
		/**
		 * Handles a custom loaded cta button 
		 * @param e
		 * 
		 */		
		private function handleCTAImageLoaded(e:Event):void {
			//Need to take away control from the OG cta button and 
			//use this new one.
			if (ctaBtn && controlClip.contains(ctaBtn)) {
				ctaBtn.removeEventListener(MouseEvent.CLICK, handleCTAClick);
				controlClip.removeChild(ctaBtn);
				ctaBtn = null;
			}
			ctaBtn = new Sprite();
			ctaBtn.addChild(ctaLoader);
			ctaBtn.addEventListener(MouseEvent.CLICK, handleCTAClick );
			controlClip.addChild(ctaBtn);
			//Refresh UI
			refresh();
			ctaLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, handleCTAImageLoaded);
			ctaLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ctaErrHandler);
			//Set the load dependency Met
			dependency.setLoadDependencyMet(handleCTAImageLoaded);
		}
		private function ctaErrHandler(e:IOErrorEvent):void {
			// Error Handling here
			dependency.setLoadDependencyMet(handleCTAImageLoaded);			
		}	
		/**
		 * Loads a custom Submit image button (Call to Action) if specified via flashvars 
		 */				
		private function loadSubmitButton():void {
			dependency.addDependancy(submitLoaded);
			submitLoader = new Loader();
			submitLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, submitLoaded);
			submitLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, submitErrorHandler);
			submitLoader.load(new URLRequest(dm.getSubmitImageLocation()));
		}
		/**
		 * Handle for custom submit button 
		 * @param e
		 */		
		private function submitLoaded(e:Event):void {
			if (submitBtn) {
				submitBtn.removeEventListener(MouseEvent.CLICK, handleSubmit);
				emailControl.removeChild(submitBtn);
				submitBtn = null;
			}
			submitBtn = new Sprite();
			submitBtn.addChild(submitLoader);
			submitBtn.addEventListener(MouseEvent.CLICK, handleSubmit );
			emailControl.addChild(submitBtn);
			
			//Refresh UI
			refresh();
			
			submitLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, submitLoaded);
			submitLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, submitErrorHandler);			
			dependency.setLoadDependencyMet(submitLoaded);
		}
		private function submitErrorHandler(e:IOErrorEvent):void {
			// Error Handling here
			dependency.setLoadDependencyMet(submitLoaded);			
		}		
		/**
		 * Loads the bg image if sent via flashvars 
		 * 
		 */		
		private function loadBgImage():void {
			backgroundLoader = new Loader();
			backgroundLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, bgImageLoaded);
			backgroundLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, bgImageIOErrorHandler);
			backgroundLoader.load(new URLRequest(dm.getBGImageLocation()));
		}
		private function bgImageLoaded(e:Event):void {
			backgroundLoader.alpha = 0;
			addChildAt(backgroundLoader, 0);
			TweenLite.to(backgroundLoader, FADE_RATE, {autoAlpha:1});
			
			backgroundLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, bgImageLoaded);
			backgroundLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, bgImageIOErrorHandler);
		}
		private function bgImageIOErrorHandler(e:IOErrorEvent):void { }

	}
}