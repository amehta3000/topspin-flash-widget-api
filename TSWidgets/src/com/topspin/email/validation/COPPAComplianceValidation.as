package com.topspin.email.validation
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class COPPAComplianceValidation extends EventDispatcher
	{
		public static var COPPA_SHARED_OBJECT : String = "ts_coppa_so"; 
		//		public static var TS_SHARED_OBJECT : String = "ts_agegate_so";
		
		//Public Events
		public static var TYPE_COPPA_COMPLIANCE_FAILED : String = "coppa_fail";
		public static var TYPE_COPPA_COMPLIANCE_COLLECT : String = "coppa_collect_dob";
		public static var TYPE_COPPA_COMPLIANCE_PASSED : String = "coppa_passed";
		
		//Properties
		private var SONY_COOKIE_URL : String = "http://ccc.sonymusic.com/checker/FCookieCheck?u13=";
		private var loader : URLLoader;
		
		//boolean indicating whether to flush the TS_SHARED_OBJECT or not
		private var _flush : Boolean = false;
		
		private var _dob : Date;
		
		/**
		 * Retrieves and sets a guid in the px logger. 
		 * @return GUID -
		 * 
		 */
		public function validateDOB_SO( minAge : Number, checkSonyCookie : Boolean, flushCookie : Boolean = false) : void
		{
			var noCookie : Boolean = false;			
			var mySo : SharedObject;
			var ts : Date;
			var age : Number;
			
			try {
				mySo = SharedObject.getLocal(COPPAComplianceValidation.COPPA_SHARED_OBJECT, "/");
				
//				if (flushCookie && !checkSonyCookie)
				if (flushCookie)
				{
					updateSavedDOB(new Date(),minAge,checkSonyCookie, true);
					dispatchCollectDOBEvent();
					return;
				}				
				
				//See if ud exists				
				if ( mySo.data.dob != null)
				{
					trace("SO dob found 1: " + _dob);					
					noCookie = false;
					_dob = mySo.data.dob;
					ts = mySo.data.ts;	
					//Check the timestamp, if it has been longer 
					//than 30 days, then start from the beginning
					//and ask for the DOB again.
					if (ts)
					{
						var numDays : Number = 30;
						var timetoreset : Number = numDays  * 24 * 60 * 60 * 1000;
						var now : Date = new Date();
						var diff : Number = now.time - ts.time;
						trace("diff :  " + diff + " timetoreset : " + timetoreset);
						if (diff >= timetoreset)
						{
							//Basically if it has been over 30 days and you are not 
							//Sony, then kick out and allow the normal 
							//birthdate collection to happen again.
							//showState(BUTTON_STATE);
							if (!checkSonyCookie) {
								trace("Past 30 days, and this isn't Sony, so go ahead and get a new birthdate");
								dispatchCollectDOBEvent();
								return;	
							}
						}
					}
					
					trace("SO dob: " + _dob);
					//Find the age if the dob in the so exists
					if (dob != null)
					{
						age = calculateAge(dob);
						trace("AGE FOUND: " + age, minAge);			
						//Check the age verse the minAge
						if (age && !isNaN(age)) {  
							if (age > minAge) {
								trace("AGE Passed in SO->");
								if (checkSonyCookie)
								{
									trace("AGE Passed in SO, but lets check Sony->");
									checkLabelCookie(0);
								}else{
									trace("AGE IS PASSED CONTINUE!");
									dispatchPassedEvent();
								}
							}else{
								trace("AGE Found, No PASS block it->");
								if (checkSonyCookie)
								{	
									trace("AGE Found, No PASS, this is just a child, tell SONY, block it->");							
									checkLabelCookie(1);	
								}else{
									dispatchFailedEvent();
								}
							}
							//							return;			
						}else{
							trace("age is jacked, collect DOB");
							dispatchCollectDOBEvent();
						}				
					}
				}else{
					noCookie = true;		
					trace("NO FLASH COOKIE WAS FOUND, get the DOB");
					dispatchCollectDOBEvent();
//					commented 12/16/2010 - Dont' check sony, just get the
//					the dob now
//					trace("No Age found -> Check LABEL COPPA->");
//					if (checkSonyCookie)
//					{
//						trace("No Age found -> Check SONY 0->");
//						checkLabelCookie(0);
//					}else{
//						trace("No Age found -> Get the DOB");
//						dispatchCollectDOBEvent();
//					}
				}
				
			} catch (e : Error) {
				trace("Unable to create and retrieve " + COPPA_SHARED_OBJECT);
				dispatchCollectDOBEvent();
			}
		}				
		
		/**
		 * Saves the dob in a shared object 
		 * @param dob - Date
		 * @param minAge - Number
		 * 
		 */		
		public function updateSavedDOB(birthdate : Date, minAge : Number, updateSonyCookie : Boolean, clearCookie : Boolean = false) : void
		{
			trace("-updateSavedDOB: " + birthdate, minAge);
			var mySo : SharedObject;
			var age : Number;
			
			//set the dob on the class
			_dob = birthdate;
			
			try{
				mySo = SharedObject.getLocal(COPPAComplianceValidation.COPPA_SHARED_OBJECT, "/");
				
				//Set the dob on the ud				
				mySo.data.dob = (clearCookie) ? null : birthdate;
				mySo.data.ts = (clearCookie) ? null : new Date();
				
				//Save the Shared Object		
				trace("store the so: age: " + age);
				var flushResult:Object = mySo.flush(500);	
				
				if (clearCookie) {
					trace("clear cookie, no need to hit up the label");
					return;
				}
				
				age = calculateAge(birthdate);
				//Check the age verses the minAge
				if (minAge != -1 && age < minAge)
				{
					if (updateSonyCookie ) {
						trace("This is just a child, tell Sony");
						checkLabelCookie(1);
					}
				}				
				
			} catch (e : Error) {
				trace("Unable to create and retrieve " + COPPA_SHARED_OBJECT);
			}			
			
		}

		/**
		 * INFO: http://subs.sonymusic.com/coppa/flash_cookie.html
		 * We will lookup the global cookie and see if any other Sony site has reported this to be under 13
	     * If we find out that global cookie exists, we return 1. You have to show the sorry message and take action
		 * {"u13":"1"} 
		 * If we find out that there is no global cookie existing, we return 0. Nothing needs to be done
		 * {"u13":"0"} 
		 * @param u13Code
		 * 
		 */
		private function checkLabelCookie( u13Code : Number ) : void 
		{
			var cookieCheckUrl : String = SONY_COOKIE_URL + u13Code;
			cookieCheckUrl += "&cachebust=" + Math.random();
			trace( "SONY_COOKIE_URL: " + cookieCheckUrl);
			
			loader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, handleJSONResponse);
			loader.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			
			loader.load(new URLRequest(cookieCheckUrl));
		}
		
		private function handleJSONResponse( e : Event) : void
		{
			var jsonStr : String = e.target.data;
			trace("JSON: " + jsonStr);
			try {
				var data : Array = JSON.decode("[" + jsonStr + "]");
				trace("JSON DECODED : " + data);
				if (data && data.length > 0)
				{
					var u13 : Number = data[0].u13;
					trace("u13: " + u13);
					if (u13 == 0) {
						//FAN IS PASSED
						dispatchPassedEvent();
					}else{
						//FAN IS FAILED
						dispatchFailedEvent();
					}
				}else{
					dispatchCollectDOBEvent();
				}
			}catch(e : Error){
				trace("Unabled to decode SONY response, collect DOB");
				dispatchCollectDOBEvent();
			}
			cleanup();
		}
		
		private function handleSecurityError( e : SecurityErrorEvent) : void
		{
			trace("Security Error: Cannot connect to LABEL for COPPA Compliance: " + e);
			dispatchCollectDOBEvent();
//			dispatchPassedEvent();
			cleanup();
		}	
		private function handleIOError( e : IOErrorEvent ) : void
		{
			trace("Cannot connect to LABEL for COPPA Compliance: " + e);
			dispatchCollectDOBEvent();
			cleanup();
		}
		
		private function cleanup() : void
		{
			loader.removeEventListener(Event.COMPLETE, handleJSONResponse);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, handleSecurityError);		
		}		
		
		private function dispatchPassedEvent() : void
		{
			trace("COPPA PASSED");
			dispatchEvent(new Event(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_PASSED, true));			
		}
		private function dispatchFailedEvent() : void
		{
			trace("COPPA FAILED");
			dispatchEvent(new Event(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_FAILED, true));
		}
		private function dispatchCollectDOBEvent() : void
		{
			trace("COPPA COLLECT DOB");
			dispatchEvent(new Event(COPPAComplianceValidation.TYPE_COPPA_COMPLIANCE_COLLECT, true));
		}
		
		public function get dob() : Date
		{
			return _dob;
		}
		
		public function set dob( dob : Date ) : void
		{
			_dob = dob;
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
	}
}