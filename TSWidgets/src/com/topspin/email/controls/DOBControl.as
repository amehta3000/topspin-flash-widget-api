package com.topspin.email.controls
{
	import com.topspin.common.controls.AbstractControl;
	import com.topspin.common.controls.SimpleLinkButton;
	import com.topspin.email.data.DataManager;
	import com.topspin.email.events.MessageStatusEvent;
	import com.topspin.email.style.GlobalStyleManager;
	import com.topspin.email.views.AbstractView;
	import com.topspin.email.views.EmailMediaWidgetView;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	/**
	 * A Date control that collects a birthdate and
	 * sets it on the data manager.  This control
	 * has a reference to its parent, EmailMediaWidgetView
	 * and makes direct calls to update.
	 * @author amehta
	 * 
	 */	
	public class DOBControl extends AbstractControl
	{
		public static var DOB_SUBMITTED : String = "dob_submitted";
		public static var DOB_ERROR : String = "dob_error";
		public static var DOB_VALIDATION_FAIL : String = "dob_validation_fail";
		
		private var dobTxt : TextField;
		private var holder : Sprite;
		private var _ddTxt : TextField;
		private var _mmTxt : TextField;
		private var _yyyyTxt : TextField;
		private var submitBtn : SimpleLinkButton;
		
		private var defaultStr : String = "Date of birth"
		
		private var dm : DataManager;
		private var styles : GlobalStyleManager;
		private var _inited : Boolean = false;
		private var MINI_MODE : Boolean = false;
		
		private var _view : AbstractView;
		
		public function DOBControl(  miniMode : Boolean = false)
		{
			MINI_MODE = miniMode;
//			_view = view;
			init();
			createChildren();
		}
		private function init(): void
		{
			addEventListener(Event.ADDED_TO_STAGE, handleAdded);
			addEventListener(Event.REMOVED_FROM_STAGE, handleRemoved);
			
			dm = DataManager.getInstance();
			styles = GlobalStyleManager.getInstance();
		}
		private function handleAdded( e : Event ) : void
		{
			trace("DOBControl Added, add listeners");
			stage.addEventListener(KeyboardEvent.KEY_DOWN, enterKeyDown,true);	
		}		
		private function handleRemoved( e : Event = null) : void
		{
			trace("DOBControl Removed, remove listeners");
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, enterKeyDown);	
		}
		
		private function createChildren() : void
		{
			holder = new Sprite();
			addChild(holder);
			
			var format : TextFormat = styles.getEmailFormat();
			if (MINI_MODE)
			{
				format.size = styles.emailFontSize - 4;
			}
//			format.size = 10;
//			format.color = styles.getFontColor();
//			format.bold = true;
			
			var sSize : Number = (MINI_MODE) ? 24 : 30;
			var lSize : Number = (MINI_MODE) ? 40 : 50;
			
			// month Input TextField			
			_mmTxt = new TextField();
			_mmTxt.embedFonts = styles.getEmbedFonts();
			_mmTxt.type = "input";
			_mmTxt.antiAliasType = "advanced";
			_mmTxt.width = sSize;
			_mmTxt.background = true;
			_mmTxt.backgroundColor = 0xffffff;	
			_mmTxt.border = true;
			_mmTxt.borderColor = styles.getLinkColor()
			_mmTxt.text = "MM";
			_mmTxt.maxChars = 2;
			_mmTxt.defaultTextFormat = format;
			_mmTxt.setTextFormat(format);
			_mmTxt.restrict = "0-9";
			_mmTxt.height = _mmTxt.textHeight + 4;// -2*dm.getHPadding;			
			holder.addChild(_mmTxt);

			// Email Input TextField			
			_ddTxt = new TextField();
			_ddTxt.embedFonts = styles.getEmbedFonts();
			_ddTxt.type = "input";
			_ddTxt.antiAliasType = "advanced";
			_ddTxt.width = sSize;	
			_ddTxt.background = true;
			_ddTxt.backgroundColor = 0xffffff;	
			_ddTxt.border = true;
			_ddTxt.borderColor = styles.getLinkColor()
			_ddTxt.text = "DD";
			_ddTxt.maxChars = 2;
			_ddTxt.defaultTextFormat = format;
			_ddTxt.setTextFormat(format);
			_ddTxt.restrict = "0-9";
			_ddTxt.height = _ddTxt.textHeight + 4;// -2*dm.getHPadding;			
			holder.addChild(_ddTxt);				
			
			// year Input TextField			
			_yyyyTxt = new TextField();
			_yyyyTxt.embedFonts = styles.getEmbedFonts();
			_yyyyTxt.type = "input";
			_yyyyTxt.antiAliasType = "advanced";
			_yyyyTxt.width = lSize;	
			_yyyyTxt.background = true;
			_yyyyTxt.backgroundColor = 0xffffff;	
			_yyyyTxt.border = true;
			_yyyyTxt.borderColor = styles.getLinkColor()
			_yyyyTxt.text = "YYYY";
			_yyyyTxt.maxChars = 4;
			_yyyyTxt.defaultTextFormat = format;
			_yyyyTxt.setTextFormat(format);
			_yyyyTxt.restrict = "0-9";
			_yyyyTxt.height = _yyyyTxt.textHeight + 4;// -2*dm.getHPadding;			
			holder.addChild(_yyyyTxt);				
			
			var btnFormat : TextFormat = styles.getBtnFormat();
			var btnOverFormat : TextFormat = styles.getBtnOverFormat();
			if (MINI_MODE) {
				btnFormat.size = 10;
				btnOverFormat.size = 10;
			}
			
			submitBtn = new SimpleLinkButton("Next", btnFormat, btnOverFormat, null, 
							styles.getLinkHasOutline(), (MINI_MODE)? 4:10,(MINI_MODE)? 2:0, 16, "center",2); 
			
			holder.addChild(submitBtn);
			
			configureListeners();
			
			_inited= true;
			draw();
		}
		
		private function configureListeners() : void
		{
			submitBtn.addEventListener(MouseEvent.CLICK, handleSubmit);

			_mmTxt.addEventListener(FocusEvent.FOCUS_IN, autoClearInputs);
			_mmTxt.addEventListener(MouseEvent.CLICK, autoClearInputs);
			_ddTxt.addEventListener(FocusEvent.FOCUS_IN, autoClearInputs);
			_ddTxt.addEventListener(MouseEvent.CLICK, autoClearInputs);
			_yyyyTxt.addEventListener(FocusEvent.FOCUS_IN, autoClearInputs);
			_yyyyTxt.addEventListener(MouseEvent.CLICK, autoClearInputs);
		}
		
		private function validate( tf : TextField ) : Boolean
		{
			var bErrors : Boolean = true;
			var val : String = tf.text;
			var num : Number = parseInt(val); 
			
			if (tf == _mmTxt)
			{
				if (val == "MM")
				{
					bErrors = false;
				}
				if (num <= 0 || num >12)
				{
					bErrors = false;
				}		
			}
			
			if (tf == _ddTxt)
			{ 
				if (val == "DD")
				{
					bErrors = false;
				}
				if (num <= 0 || num >31)
				{
					bErrors = false;
				}					

			}
			if (tf == _yyyyTxt)	
			{
				if (val == "YYYY")
				{
					bErrors = false;
				}
				if (num <= 1900 || num > new Date().fullYear)
				{
					bErrors = false;
				}											
			}
			
			tf.borderColor = (!bErrors) ? styles.getErrColor() : styles.getLinkColor();
			
			return bErrors;
		}

		public function enterKeyDown(e:KeyboardEvent):void
		{ 
			var kc:Number = e.keyCode;
			if (this.visible)
			{
				var focusIsThere : Boolean = (stage.focus == _yyyyTxt || stage.focus == _mmTxt || stage.focus == _ddTxt);
				if (focusIsThere && e.keyCode == Keyboard.ENTER) {
					handleSubmit();
				}			
			}
		}	
		
		private function handleSubmit(e : Event = null) : void
		{
			var minAge : Number = dm.getMinAge();
			
			var mm : String = _mmTxt.text;
			var dd : String = _ddTxt.text;
			var yyyy : String = _yyyyTxt.text;
			var valid : Boolean = false;
			
			valid = (validate(_mmTxt) && validate(_ddTxt) && validate(_yyyyTxt));
			if (!valid)
			{
				dispatchEvent(new MessageStatusEvent("Please enter a valid date", true));
				return;
			}			

			var dob : Date = new Date(parseInt(yyyy), parseInt(mm)-1,parseInt(dd));
			var age : Number = calculateAge(dob);
			var now : Date = new Date();
			dm.updateSavedAge(dob);
			trace("________");
			trace("Capabilities.language : " + Capabilities.language);
			
			trace("DOB SON: " + dob);
			trace("AGE SON" + age);	
			if (minAge != -1)
			{
				
				valid = (age >= minAge);
				if (!valid){
//					_view.showDOBFailDialog();
					dispatchEvent(new Event(DOBControl.DOB_VALIDATION_FAIL,true));
					reset();
					return;					
				}
			}
			
			var dob : Date = new Date(yyyy,mm,dd);
			dm.setDOB(dob);
			trace("DOB SET! go to email");		
			handleRemoved();
			dispatchEvent(new Event(DOBControl.DOB_SUBMITTED));
		}
		
		public function reset() : void
		{
			_mmTxt.text = "MM";
			_ddTxt.text = "DD";
			_yyyyTxt.text = "YYYY";	
			dm.setDOB(null);
		}
		
		public function calculateAge(birthdate:Date):Number {
			var dtNow:Date = new Date();// gets current date
			var currentMonth:Number = dtNow.getMonth();
			var currentDay:Number = dtNow.getUTCDate();
			var currentYear:Number = dtNow.getFullYear()
			
			var bdMonth:Number = birthdate.getMonth();
			var bdDay:Number = birthdate.getUTCDate();
			var bdYear:Number = birthdate.getFullYear();
			
			// get the difference in years
			var years:Number = dtNow.getFullYear() - birthdate.getFullYear();
			// subtract another year if we're before the
			// birth day in the current year
			if (currentMonth < bdMonth || (currentMonth == bdMonth && currentDay < bdDay)) {
				years--;
			}
			return years;
		}
		
		/**
		 *  Clears the field 
		 *
		 */		
		private function autoClearInputs(event:Event):void {
			var target = event.target;
			if (target == _mmTxt)
			{
				if (target.text != "MM") return;
				target.text = "";
			}
			if (target == _ddTxt)
			{
				if (target.text != "DD") return;
				target.text = "";
			}
			if (target == _yyyyTxt)
			{
				if (target.text != "YYYY") return;
				target.text = "";
			}
			event.stopImmediatePropagation();
			event.target.addEventListener(FocusEvent.FOCUS_OUT, autoUpdateInputs);
		}		

		/**
		 * Update the inputs 
		 * @param event
		 * 
		 */
		private function autoUpdateInputs( event:Event ):void {
			if (event.target && event.target.text && event.target.text.length > 0) return;
			var target  = event.target ;
			
			if (target == _mmTxt) event.target.text = "MM";
			if (target == _ddTxt) event.target.text = "DD";
			if (target == _yyyyTxt) event.target.text = "YYYY";
			
			event.target.removeEventListener(FocusEvent.FOCUS_OUT, autoUpdateInputs);			
		}			
		
		protected override function draw() : void
		{
			if (!_inited) return;	
			
			_yyyyTxt.x = 0;//dobTxt.width + 4;
			_mmTxt.x = _yyyyTxt.x + _yyyyTxt.width + 4;
			_ddTxt.x = _mmTxt.x + _mmTxt.width + 4;				
			var p : Number = (MINI_MODE) ? 4 : 8;
			submitBtn.x = _ddTxt.x + _ddTxt.width + p;
			submitBtn.y -= 2;
		}		
		


	}
}