package com.topspin.email.controls
{
	import com.topspin.api.events.E4MEvent;
	import com.topspin.common.controls.SimpleLinkButton;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.events.MessageStatusEvent;
	import com.topspin.email.style.GlobalStyleManager;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import gs.TweenLite;

	public class EmailControl extends Sprite
	{
		public static var SUBMIT_EMAIL : String = "emailControl_submit_email";
		
		private var dm : DataManager;
		private var styles : GlobalStyleManager;
		
		private var FADE_RATE:Number = .3;		//Animation rate for fades	
		private var RESET_TIME:Number = 5000;	//Reset timer		
		private var PAD:uint = 4;				//Default PAD between ui
		
		
		private var _width : Number;
		private var _height : Number ;
		private var _clips : Array;
		
		//UI
		public var headlineTxt : TextField;
		public var emailHolder : Sprite;
		public var emailTxt:TextField;			//Textfield for the email text
		public var submitBtn:Sprite;			//Submit button, could be loaded graphic
		public var ctaBtn:Sprite;						//Call to action button		
		public var dobControl : DOBControl;				//DOB control for COPPA Compliant widgetz		
	
		
		// States
		private var _isSubmitting : Boolean = false;		//State used to prevent multiple submits.
		private var _e4mSubmitted:Boolean = false; 		//State used with playMedia.  Used to know when to display the
		private var DEFAULT_STATE : String = "default_state";
		private var EMAIL_STATE : String = "email_state";
		private var DOB_STATE : String = "dob_state";
		
		//Properties
		// Default static text
		private static var _defaultEmail:String = "Enter Email Address";
		private static var _defaultEmailMini:String = "Enter Email";
		private var _finalEmailStr : String;			//emailTxt default string based on the size of the widget
		private var _DOB_message : String = "Please enter your date of birth";
		private var flipTimer : Timer;
		private var _resetTimer:Timer;					//Timer instance to reset the app				
		
		
		private var MINI_MODE : Boolean = false;
		
		public function EmailControl( w : Number, h : Number)
		{
			//Listen to be added and then additional event listeners
			addEventListener(Event.ADDED_TO_STAGE, handleAdded);

//			if (w > 400) w = 400;
			
			_width = w;
			_height = h;
			
			init();
			createChildren();
			configureListeners();
		}
		
		private function init() : void
		{
			styles = GlobalStyleManager.getInstance();
			dm = DataManager.getInstance();
			
			//Figure out if we are MINI mode or not
			MINI_MODE = (_width < 250) ? true : false;
			_finalEmailStr = (MINI_MODE) ? _defaultEmailMini : _defaultEmail;
			_DOB_message = dm.getDOBMessage();
			
		}
		
		private function createChildren() : void
		{
			//array of the ui clips
			_clips = new Array();
			
			
			emailHolder = new Sprite();
			

			
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
			if (styles.getWordWrap())
			{	
				headlineTxt.wordWrap = true;
				headlineTxt.multiline = true;
			}
			//			this.addChild(headlineTxt);
			
			headlineTxt.text = dm.getHeadlineMessage();
			headlineTxt.defaultTextFormat = format; 
			
			// Call to Action Button
			ctaBtn = new SimpleLinkButton(dm.getOfferButtonLabel(), styles.getBtnFormat(), styles.getBtnOverFormat(), null, styles.getLinkHasOutline(), 10, 0 , 16, "center",2);
			ctaBtn.x = (_width - ctaBtn.width)/2;
			addChild(emailHolder);			
			addChild(headlineTxt);
			addChild(ctaBtn);
			_clips.push(emailHolder);
			_clips.push(ctaBtn);

			
			var btnFormat : TextFormat = styles.getBtnFormat();
			var btnOverFormat : TextFormat = styles.getBtnOverFormat();
			if (MINI_MODE) {
				btnFormat.size = 10;
				btnOverFormat.size = 10;
			}
			
			// Submit Button
			submitBtn = new SimpleLinkButton("Submit", btnFormat, btnOverFormat, null, styles.getLinkHasOutline(), (MINI_MODE)? 4:10,(MINI_MODE)? 2:0, 16, "center",2); 
			emailHolder.addChild(submitBtn);
			
			var emailHolderX:Number = _width - (submitBtn.width + 4 * styles.getHPadding() + PAD);
			
			var format : TextFormat = styles.getEmailFormat();
			if (MINI_MODE)
			{
				format.size = styles.emailFontSize - 4;
			}			
			// Email Input TextField			
			emailTxt = new TextField();
			emailTxt.embedFonts = styles.getEmbedFonts();
			emailTxt.type = "input";
			emailTxt.antiAliasType = "advanced";
			emailTxt.width = (styles.getHAlign() == "center") ? _width - (submitBtn.width + 4 * styles.getHPadding() + PAD) : _width - (submitBtn.width + 2 + 2*styles.getHPadding() + PAD);	
			emailTxt.background = true;
			emailTxt.backgroundColor = 0xffffff;	
			emailTxt.border = true;
			emailTxt.borderColor = styles.getLinkColor()
			emailTxt.text = _finalEmailStr;
			emailTxt.defaultTextFormat = format;
			emailTxt.setTextFormat(format);
			emailTxt.height = emailTxt.textHeight + PAD;// -2*dm.getHPadding;			

			emailHolder.addChild(emailTxt);

			emailTxt.x = 0;
			submitBtn.x = Math.floor(emailTxt.x + emailTxt.width + (2 * PAD));
			emailTxt.y = (submitBtn.height - emailTxt.height ) /2;	
			
//			var g : Graphics = this.graphics;
//			g.beginFill(0x00ffff, .3);
//			g.drawRect(0,0,_width,_height);
//			g.endFill();
			
			emailHolderX = ((_width - emailHolder.width) / 2) ;
			if (styles.getHAlign() == "right") emailHolderX = _width - emailHolder.width - styles.getHPadding();
			if (styles.getHAlign() == "left") emailHolderX = styles.getHPadding();						
			emailHolder.x = emailHolderX; //(halign=="center") ? (_width - emailHolder.width)/2:dm.getHPadding;		
			
			if (dm.collectDOB())
			{
				dobControl = new DOBControl(MINI_MODE);
				dobControl.addEventListener(DOBControl.DOB_SUBMITTED, handleDob);
				dobControl.addEventListener(MessageStatusEvent.TYPE, handleDisplayStatus);
//				dobControl.addEventListener(DOBControl.DOB_VALIDATION_FAIL, handleDisplayStatus);
				
				dobControl.x = (styles.getHAlign() == "center") ? (_width - dobControl.width)/2 : styles.getHPadding();
				dobControl.alpha = 0;
				addChild(dobControl);
				_clips.push(dobControl);				
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
				showState(DEFAULT_STATE);
			}
			
		}
		private function configureListeners() : void
		{
			dm.addE4MHandler(handleE4MEvent);
			
			ctaBtn.addEventListener(MouseEvent.CLICK, handleCTAClick );			
			submitBtn.addEventListener(MouseEvent.CLICK, handleSubmit );
			
			emailTxt.addEventListener(FocusEvent.FOCUS_IN, autoClearInputs);
			emailTxt.addEventListener(MouseEvent.CLICK, autoClearInputs);
			emailTxt.addEventListener(Event.CHANGE, textChanged);			
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
		
		public function reset() : void
		{
			emailTxt.text = _finalEmailStr;
		}
		public function setErrorState( isError : Boolean ) : void
		{
			emailTxt.borderColor = (isError) ? styles.getErrColor() : styles.getLinkColor();
		}
		
		public function get text() : String
		{
			return emailTxt.text;
		}
		public function set text( txt : String )  : void
		{
			emailTxt.text = txt;
			emailTxt.scrollH = 0;
		}
				
		//////Handlers
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
		////////////////////////////////////////////////////////////////////////
		//
		// Event handlers
		//
		////////////////////////////////////////////////////////////////////////		
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
		private function handleSubmit( e:Event = null):void {
			trace("check this shit");
			if (_isSubmitting)
			{
				return;
			}else{
				_isSubmitting = true;
			}
			
			var email:String = emailTxt.text;
			setErrorState(false);
			if (email == _finalEmailStr || !validate(email) ){
				displayStatus(dm.getEmailErrorMessage(), true);
				_isSubmitting = false;
				return;
			} 
			displayStatus(dm.getSubmitMessage(), true);  // Display the sumbitting messsage			
			
			if(dm.getWidgetStatus() == DataManager.STATUS_UNPUBLISHED ) {
				displayStatus("Email submission not allowed in preview mode.", true);
			} 
			
			var dob : Date;
			if (dm.collectDOB())
			{
				dob = dm.getDOB();
			}			
			
			//Submit the email.
			dm.submitE4M(email, dob);
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
					//					emailTxt.scrollH = 0;
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
			
			headlineTxt.text = dm.getHeadlineMessage();
			
			if (dm.getDisplayInitialScreen()) {
				showState(DEFAULT_STATE);
			}else{
				if (dm.collectDOB()) {
					showState(DOB_STATE);
				}else{
					showState(EMAIL_STATE);
				}
			}
		}		
		
//		private function handleSubmit( e : MouseEvent = null ) : void
//		{
//			trace("handle Submit");
//			var event : Event = new Event(SUBMIT_EMAIL);
//			dispatchEvent(event);
//		}
		public function textChanged(evt:Event):void {
			var typed:String = evt.target.text.slice(evt.target.text.length-1, evt.target.text.length);
			if (typed == "\"") {
				evt.target.text = evt.target.text.slice(0, evt.target.text .length-1)+"@";
			}
		}		
		
		public function enterKeyDown(e:KeyboardEvent):void
		{ 
			var kc:Number = e.keyCode;			
			if (stage.focus == emailTxt && e.keyCode == Keyboard.ENTER) {
				handleSubmit();
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
		
		public function handleDisplayStatus( e : MessageStatusEvent ) : void
		{
			trace("DispayError: " + e.message, e.isError);
			displayStatus(e.message, e.isError);
		}		

		/**
		 * Dispatch an event 
		 * @param msg
		 * @param isError
		 * 
		 */		
		private function displayStatus( msg:String, isError:Boolean = false) : void
		{
//			emailTxt.borderColor = (isError) ? styles.getErrColor() : styles.getLinkColor();
			trace("DISPLAY STATUS: " + msg  + "--> " + headlineTxt.text);
			// FIX THIS //

//			var textFieldToModify:TextField;
//			textFieldToModify = this.headlineTxt;
			headlineTxt.alpha = 0;
//			if (msg1 == textFieldToModify.text) return;
//			TweenLite.to(textFieldToModify, FADE_RATE, {autoAlpha:0, onComplete: updateText, onCompleteParams:[msg1, isError1]});
//			function updateText(msg:String, isError:Boolean):void {
				var f:TextFormat = headlineTxt.getTextFormat();
				f.color = (isError) ? styles.getErrColor() : styles.getFontColor();
				f.size = (isError) ? styles.getErrorFontSize() : styles.getDefaultFontSize();
				headlineTxt.setTextFormat(f);
				trace("What is the msg: " + msg);
				headlineTxt.text = msg;
				setErrorState(isError);
//				emailTxt.borderColor = (isError) ? styles.getErrColor() : styles.getLinkColor();
				refresh();
//			}			
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
			str = this.headlineTxt.text;
			return str;
		}			
		
		/**
		 * Shows the email control and tweens it in 
		 * @param show
		 * 
		 */		
		private function showState( state:String): void {
			
			switch (state){
				case EMAIL_STATE:
					emailHolder.alpha = 0;
					showClip(emailHolder);
					if (!dm.getDisplayInitialScreen())
					{
						stopDOBFlipTimer();
					}
					reset();
					displayStatus(dm.getHeadlineMessage());	
					if (dobControl && this.contains(dobControl)) 
					{
						dobControl.visible = false;
						this.removeChild(dobControl);						
					}
					if (ctaBtn) ctaBtn.visible = false;
					break;
				
				case DOB_STATE:
					
					dobControl.alpha = 0;
					if (!this.contains(dobControl))
					{
						this.addChild(dobControl);	
					}						
					showClip(dobControl);
					if (!dm.getDisplayInitialScreen())
					{
						startDOBFlipTimer();
					}else{
						displayStatus(_DOB_message);
					}
					dobControl.y = emailHolder.y + 4;	
					if (emailHolder) emailHolder.visible = false;
					if (ctaBtn) ctaBtn.visible = false;
					break;
				
				case DEFAULT_STATE:
					ctaBtn.alpha = 0;
					showClip(ctaBtn);
					
					if (!dm.getDisplayInitialScreen())
					{
						stopDOBFlipTimer();
					}
					
					displayStatus(dm.getHeadlineMessage());
					ctaBtn.y = headlineTxt.y + headlineTxt.height + PAD;
					if (emailHolder) emailHolder.visible = false;
					if (dobControl && this.contains(dobControl)) 
					{
						dobControl.visible = false;
						this.removeChild(dobControl);						
					}
					break;
			}
			refresh();
		}		

		/**
		 * Show the proper clip 
		 * @param clip
		 * 
		 */			
		private function showClip( clip:Sprite ) : void 
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
					cc.alpha = 0;
				}	
			}
		}
		
		public function getWidth() : Number
		{
			return _width;
		}		
		
		/**
		 *  Refreshes the layout, pretty gnarly refactor this
		 *
		 */
		private function refresh():void {
			
			trace("--->emailControl and DOB HEIGHT: " + emailHolder.height);
			var h:Number = _height - ( submitBtn.height + PAD*2 + 1  );
			
			
			formatText(headlineTxt, h);
			headlineTxt.y = Math.floor((h - headlineTxt.textHeight)/2);
			emailHolder.y = h + PAD - 1;
			
			h = _height - ( ctaBtn.height + PAD*2 + 1  );
			ctaBtn.y = (MINI_MODE) ? h+ PAD + 2 : h + PAD -1; //emailHolder.y;
			if (dobControl) {
				dobControl.y = (MINI_MODE) ? emailHolder.y + 4 : emailHolder.y;
			}
			// Returns the headline back to normal state
			TweenLite.to(headlineTxt, FADE_RATE, {autoAlpha:1});	
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
	}
}