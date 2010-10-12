package com.topspin.common.utils {
	import com.adobe.utils.StringUtil;
	
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	public class SocialUtils {

		//Topspin Awesm API key.
		public static var TOPSPIN_API_KEY = "493340768445cf1788338b22b530d2ff6d59693b0788d5b94f8d31071ce73ade";
		
//		public static var GIDGET_URL : String = "http://share.topspin.net/"		
//		public static var SHARE_TYPE : String = "share/"; 
//		public static var TRACK_TYPE : String = "track/"; 
		
		public static var WIDGET_TYPE_BUNDLE : String = "bundle_widget";
		public static var WIDGET_TYPE_E4M : String = "email_for_media";
		public static var WIDGET_TYPE_SINGLE : String = "single_track_player_widget";
		public static var WIDGET_TYPE_COMBO : String = "combo_widget";
		
		public static var PLATFORM_FACEBOOK : String = "Facebook";
		public static var PLATFORM_MYSPACE : String = "MySpace";
		public static var PLATFORM_TWITTER : String = "Twitter";
		public static var PLATFORM_DIGG : String = "Digg";
		public static var PLATFORM_DELICIOUS : String = "Delicious";
		
		public static var ENV_QA1 : String = "qa1";
		public static var ENV_QA2 : String = "qa2";
		public static var ENV_QA3 : String = "qa3";
		public static var ENV_QA : String = "qa";
		public static var ENV_PP : String = "pp";
		
		private var env : String;
		
		/**
		 * Need to call gidget.php to make Facebook work properly.  It is located at 
		 * http://share.topspin.net/ 
		 * @param wid = widget_id
		 * 
		 */		
		public static function shareFacebook(wid : String, artistName : String, baseurl : String, awesmParentId : String = null, 
											create_type : String = "topspin_api", env : String = null, 
											api_key : String = null, flashVars: String = null) : void { 
			
			//Create the actual gigdet url and then awesm it.
//			baseurl = "http://qa1.topspin.net/";
			trace("FACEBOOK baseurl : " + baseurl);
			var gidgetURL : String = parseGidgetId(wid, artistName, baseurl, env, flashVars);
			trace("FACEBOOK :" + gidgetURL);
			if (gidgetURL)
			{
				gidgetURL = encodeURIComponent(gidgetURL);
			}
			var targetUrl:String = "http://www.facebook.com/sharer.php?u=";
			generateAwesmAndLaunch(gidgetURL,PLATFORM_FACEBOOK, targetUrl, api_key, {parent_awesm: awesmParentId, share_type : "facebook", create_type : create_type});			
		}	
				
		public static function shareMySpace(url:String, title:String, embedCodeString:String, awesmParentId : String = null, create_type : String = "api", api_key : String = null):void {
			var targetUrl:String = "http://www.myspace.com/index.cfm?fuseaction=postto&" + 
			"t=" + encodeURIComponent(title) + "&c=" + encodeURIComponent(embedCodeString)  + "&u="; //+ encodeURIComponent(url);
			var t : String = encodeURIComponent(targetUrl);
			generateAwesmAndLaunch(url,PLATFORM_MYSPACE, t, api_key, {parent_awesm: awesmParentId, share_type : "myspace", create_type : create_type});										
		}
		
		public static function shareTwitter(url:String, title:String, awesmParentId : String = null, create_type : String = "api", api_key : String = null, tweetHash : String = null) : void {
			
			var eTitle : String = title ;
			//Hack to make sure we replace & with and.  twitter doesn't like it.
			if (title.indexOf("&") != -1) {
				eTitle = StringUtil.replace(title,"&","and");
			}
			var thash : String = (tweetHash && tweetHash!="")? " " + tweetHash : "";
			var e1Title : String = encodeURIComponent( eTitle + thash + " - ");
			var targetUrl:String = "http://twitter.com/home?status=" + encodeURIComponent(e1Title);//+ encodeURIComponent(url);

			generateAwesmAndLaunch(url,PLATFORM_TWITTER, targetUrl, api_key, {parent_awesm: awesmParentId, share_type : "twitter", create_type : create_type});
		}
		
		public static function shareDigg(url:String, title:String, awesmParentId : String = null):void {
			var targetUrl:String = "http://digg.com/submit?" + "url=" + encodeURIComponent(url) + "&title=" + encodeURIComponent(title) + "&bodytext=&media=news&topic=music";				
			launchPlatform(targetUrl, PLATFORM_DIGG);
		}
		
		public static function shareDelicious(url:String, title : String, awesmParentId : String = null):void {
			var targetUrl:String = "http://del.icio.us/post?" + "url=" + encodeURIComponent(url) + "&description=" + encodeURIComponent(title);
			launchPlatform(targetUrl, PLATFORM_DELICIOUS);
		}		
		

		/**
		 * Construct a valid gidget.php url including the child id which gets passed on as a  
		 * @param wid
		 * @param artistName
		 * @param type
		 * @param env
		 * @param fv - flash vars with a | delimiter and - marks for equality signs
		 * @return 
		 * 
		 */		
		public static function parseGidgetId( wid : String, artistName : String, baseurl : String, 
											  env : String = null, fv : String = null) : String 
		{
			var shareURL : String = baseurl + "fbshare/";
			var artistID : String;
			var widgetID : String;
			var widgetStr : String;
			var widgetCode : String = "B";
			
			if (wid.indexOf(WIDGET_TYPE_BUNDLE) != -1) widgetCode="B";
			if (wid.indexOf(WIDGET_TYPE_E4M) != -1) widgetCode="E";
			if (wid.indexOf(WIDGET_TYPE_SINGLE) != -1) widgetCode="S";
			if (wid.indexOf(WIDGET_TYPE_COMBO) != -1) widgetCode="C";
			
			//BUNDLE - https://newqa.topspin.net/api/v1/artist/816/bundle_widget/2225 
			//E4M - https://app.topspin.net/api/v1/artist/49/email_for_media/701
			//SINGLE - https://newqa.topspin.net/api_v1_single_track_player_widget/show/2248?artist_id=816
			//http://share.topspin.net/share/BASECAMP/49/E701
			
			var artist : String = "ARTIST";
			trace("artist name : " + artist, wid);
			shareURL += artist + "/";
			trace("SHAREURL " + shareURL);
			var artistReg :RegExp =  new RegExp(/artist\/(\d+)\/[\w_]+\/(\d+)/);
			var matches : Array = artistReg.exec(wid);
			if (matches != null && matches.length==3)
			{
				widgetStr = matches[0];
				//if (widgetStr.indexOf("email_for_media") != -1) widgetCode = "E";
				artistID = matches[1];
				widgetID = matches[2];
				shareURL += artistID + "/" + widgetCode + widgetID; //+ "/" + child2ParentId + "/" + randid();
				trace("shareURL : " + shareURL);			
				if (env != null)
				{
					shareURL += "/?env=" + env;	
				}
				
				if (fv != null)
				{
					if (shareURL.indexOf("/?env=") == -1)
					{
						shareURL += "/?" + fv;						
					}else{
						shareURL += "&" + fv;						
					}
				}
				trace("PARSEGIGDET: " + shareURL);
				
				return shareURL;
			} else {
				return null;
			}
		}
		
		/**
		 * Implements the AwesmService to shorten the length of the url 
		 * @param longURL
		 * @param platform
		 * @param platformURL
		 * 
		 */		
		private static function generateAwesmAndLaunch( longURL : String  , platform : String, platformURL : String = null, api_key : String = null, params : Object = null) : void
		{
			platformURL += "AWESM_TARGET";
			if (platform == PLATFORM_MYSPACE) platformURL += "&l=3"; 
			api_key = (!api_key) ? TOPSPIN_API_KEY : api_key;
			
			var awsm : String = "http://create.awe.sm/url/share?api_key="+api_key+"&version=1";
			if (params != null){
				for (var p : String in params)
				{
					if (params[p] != null && params[p] != "null")
					{
						awsm += "&" + p + "=" + params[p];
					}
				} 
			}			
			awsm += "&target=" + longURL;
			awsm += "&destination=" + platformURL;
			trace("awsm: " + awsm);
			
			launchPlatform(awsm, platform);
			return;
		}
		/**
		 * Calls navigateToUrl to a specified target 
		 * @param target
		 * @param platform
		 * 
		 */		
		private static function launchPlatform( target : String, platform : String) : void
		{
			try {
				trace("FINAL : launchPlatform: " + target  + " to: " + platform);
				navigateToURL(new URLRequest(target), "_blank");
			} catch (e:Error) {
				trace("Error encoding " + platform + " URL: " + e);
			}			
		}
		
		//Util method to generate random 8 character digit for use as a CHILD id
		private static function randid() : String
		{
		    var key:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
		    var idStr:String = key.substr(int(Math.random()*26),1);
		    for (var i = 0; i < 7; ++i)
		        idStr += key.substr(int(Math.random()*36),1);
		    return idStr;
		}		
				
	}
}