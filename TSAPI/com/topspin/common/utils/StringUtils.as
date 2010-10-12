package com.topspin.common.utils
{
	import flash.text.TextField;
	import flash.system.Capabilities;
	
	
	public class StringUtils
	{

		/**
		*  Formats the time and return a string
		*/
		public static function formatTime( num : Number, showHours : Boolean = false) : String {	
			var time : String;
			var seconds : Number = Math.floor(num / 1000);
			var minutes : Number = Math.floor(seconds / 60);
			var hours : Number = Math.floor(minutes / 60);
			//var hoursStr : String = (hours<10) ? "0" + hours.toString() :  
			var sds : Number = seconds % 60;
			//var sdsStr : String = 	(sds<10) ? "0" + sds.toString() : sds.toString();	
			time = ((showHours) ? formatDoubleOString(hours) + ":" : "" ) + formatDoubleOString(minutes) + ":" + formatDoubleOString(sds);
			return time;
			//trace("TIME : " + mins + " : " + secs);
		}	
		
		
		/**
		 * Formats a string so that 1 == 01 
		 * @param num
		 * @return 
		 * 
		 */
		public static function formatDoubleOString( num : Number) : String
		{
			var str : String = (num < 10) ? "0" + num.toString() : num.toString();
			return str;
		} 

		/**
		 * Formats the number to be a currency 
		 * @param number
		 * @param maxDecimals
		 * @param forceDecimals
		 * @param siStyle
		 * @return 
		 * 
		 */		
		public static function numberFormat(number:*, maxDecimals:int = 2, forceDecimals:Boolean = false, siStyle:Boolean = true):String {
		    var i:int = 0, inc:Number = Math.pow(10, maxDecimals), str:String = String(Math.round(inc * Number(number))/inc);
		    var hasSep:Boolean = str.indexOf(".") == -1, sep:int = hasSep ? str.length : str.indexOf(".");
		    var ret:String = (hasSep && !forceDecimals ? "" : (siStyle ? "," : ".")) + str.substr(sep+1);
		    if (forceDecimals) for (var j:int = 0; j <= maxDecimals - (str.length - (hasSep ? sep-1 : sep)); j++) ret += "0";
		    while (i + 3 < (str.substr(0, 1) == "-" ? sep-1 : sep)) ret = (siStyle ? "." : ",") + str.substr(sep - (i += 3), 3) + ret;
		    return str.substr(0, sep - i) + ret;
		}

		/**
		 * Simple utility for tracing out the properties
		 * of an object 
		 * @param obj
		 * @return 
		 * 
		 */		
		public static function traceProps( obj : Object ) : String {
			
			var str : String = "";
			for (var p : String in obj ) {
				str += "\t" + p + "[" + obj[p] + "]\n";
			}
			
			return str;
		}
	
		/**
		 * Adds elipses. 
		 * @param str
		 * @param length
		 * @return 
		 * 
		 */		
		public static function truncate( str : String, length : Number = 30) : String
		{
		    var truncation : String = "...";
		    return (str.length > length) ?
				str.slice(0, length - truncation.length) + truncation : str;
		}
		
			
		//--------------------------------------
		//  PUBLIC METHODS
		//--------------------------------------
		/**
		 * shortenTextField will add a ... to the end of a text field 
		 * @param textField
		 * 
		 */		
		public static function shortenTextField ( textField : TextField ) : void
		{
				if ( textField.textWidth > textField.width )
				{
					StringUtils.applyToSingleLine ( textField );
				}
		}
		

		//--------------------------------------
		//  EVENT HANDLERS
		//--------------------------------------
		
		//--------------------------------------
		//  PRIVATE & PROTECTED INSTANCE METHODS
		//--------------------------------------
		
		private static function applyToSingleLine ( textField : TextField ) : void
		{
			textField.appendText( "..." );
			do 
			{
				StringUtils.truncateText ( textField );
			} while ( textField.textWidth > textField.width );
			
		}
		
		private static function applyToMultiLine ( textField : TextField ) : void
		{
			var visibleCharacters:Number = 0;
			for ( var q = textField.bottomScrollV - 1 ; q >= 0 ; q -- )
			{
				visibleCharacters += textField.getLineLength ( q ) ;
			}
			var tVar = new String ( textField.text ) ;
			textField.text = tVar.substring ( 0 , visibleCharacters );
			textField.appendText ( "..." );
			do 
			{
				StringUtils.truncateText ( textField );
			} while ( textField.textHeight > textField.height );
		}
		
		private static function truncateText ( textField:TextField ) : void
		{
			var str = new String ( textField.text );
			str = str.substring ( 0 , str.length - 4 );
			while ( str.charAt ( str.length - 1 ) == " " )
			{
				str = str.substring ( 0 , str.length - 1 );
			}
			textField.text = str;
			textField.appendText ( "..." );
		}
		
        public static function showCapabilities():void {
            trace("avHardwareDisable: " + Capabilities.avHardwareDisable);
            trace("hasAccessibility: " + Capabilities.hasAccessibility);
            trace("hasAudio: " + Capabilities.hasAudio);
            trace("hasAudioEncoder: " + Capabilities.hasAudioEncoder);
            trace("hasEmbeddedVideo: " + Capabilities.hasEmbeddedVideo);
            trace("hasMP3: " + Capabilities.hasMP3);
            trace("hasPrinting: " + Capabilities.hasPrinting);
            trace("hasScreenBroadcast: " + Capabilities.hasScreenBroadcast);
            trace("hasScreenPlayback: " + Capabilities.hasScreenPlayback);
            trace("hasStreamingAudio: " + Capabilities.hasStreamingAudio);
            trace("hasVideoEncoder: " + Capabilities.hasVideoEncoder);
            trace("isDebugger: " + Capabilities.isDebugger);
            trace("language: " + Capabilities.language);
            trace("localFileReadDisable: " + Capabilities.localFileReadDisable);
            trace("manufacturer: " + Capabilities.manufacturer);
            trace("os: " + Capabilities.os);
            trace("pixelAspectRatio: " + Capabilities.pixelAspectRatio);
            trace("playerType: " + Capabilities.playerType);
            trace("screenColor: " + Capabilities.screenColor);
            trace("screenDPI: " + Capabilities.screenDPI);
            trace("screenResolutionX: " + Capabilities.screenResolutionX);
            trace("screenResolutionY: " + Capabilities.screenResolutionY);
            trace("serverString: " + Capabilities.serverString);
            trace("version: " + Capabilities.version);
        }		
		

	}
}