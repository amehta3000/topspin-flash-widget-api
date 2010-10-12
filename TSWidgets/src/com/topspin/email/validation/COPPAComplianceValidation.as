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
		
		
		/**
		 * Retrieves and sets a guid in the px logger. 
		 * @return GUID -
		 * 
		 */
		public function validateDOB_SO( minAge : Number, checkSonyCookie : Boolean, flushCookie : Boolean = false) : void
		{
			var noCookie : Boolean = false;			
			var mySo : SharedObject;
			var dob : Date;
			var ts : Date;
			var age : Number;
			
			try {
				mySo = SharedObject.getLocal(COPPAComplianceValidation.COPPA_SHARED_OBJECT, "/");
				
				if (flushCookie && !checkSonyCookie)
				{
					updateSavedDOB(new Date(),minAge,checkSonyCookie, flushCookie);
					dispatchCollectDOBEvent();
					return;
				}				
				
				//See if ud exists				
				if ( mySo.data.dob != null)
				{
					noCookie = false;
					dob = mySo.data.dob;
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
					
					trace("SO dob: " + dob);
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
					trace("No Age found -> Check LABEL COPPA->");
					if (checkSonyCookie)
					{
						checkLabelCookie(0);
					}else{
						trace("No Age found -> Get the DOB");
						dispatchCollectDOBEvent();
					}
				}
				
				//				trace("No Age found -> Passed");
				//				dispatchPassedEvent();
				
				//				var flushResult:Object = mySo.flush(500);				
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
		public function updateSavedDOB(dob : Date, minAge : Number, updateSonyCookie : Boolean, clearCookie : Boolean = false) : void
		{
			trace("-updateSavedDOB: " + dob, minAge);
			var mySo : SharedObject;
			var age : Number;
			try{
				mySo = SharedObject.getLocal(COPPAComplianceValidation.COPPA_SHARED_OBJECT, "/");
				
				//Set the dob on the ud				
				mySo.data.dob = (clearCookie) ? null : dob;
				mySo.data.ts = (clearCookie) ? null : new Date();
				
				age = calculateAge(dob);
				//Check the age verses the minAge
				if (minAge != -1 && age < minAge)
				{
					if (updateSonyCookie) {
						trace("This is just a child, tell Sony");
						checkLabelCookie(1);
					}
				}
				//Save the Shared Object		
				trace("store the so: age: " + age);
				var flushResult:Object = mySo.flush(500);				
			} catch (e : Error) {
				trace("Unable to create and retrieve " + COPPA_SHARED_OBJECT);
			}			
			
		}
		
		
		
		public function checkLabelCookie( u13Code : Number ) : void 
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
				
			}
			cleanup();
		}
		
		private function handleSecurityError( e : SecurityErrorEvent) : void
		{
			trace("Security Error: Cannot connect to LABEL for COPPA Compliance: " + e);
			dispatchCollectDOBEvent();
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