package com.topspin.common.utils {
	import com.adobe.utils.StringUtil;
	
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.net.sendToURL;
	
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
		public static var PLATFORM_EMAIL : String = "Email";
		
		public static var ENV_QA1 : String = "qa1";
		public static var ENV_QA2 : String = "qa2";
		public static var ENV_QA3 : String = "qa3";
		public static var ENV_QA : String = "qa";
		public static var ENV_PP : String = "pp";
		
		private var env : String;
		
		public static function shareMyOrFb(platform : String, wid : String, artistName : String, baseurl : String, awesmParentId : String = null, 
										   create_type : String = "topspin_api", env : String = null, 
										   api_key : String = null, flashVars: String = null) : void { 
			
			var targetURL : String;
			var share_type : String;
			
			var artistId : String = "";
			var widgetId : String = ""; 
			var ids : Array = parseIds(wid);
			
			trace("1 FLASHVAR: " + flashVars);
			var src : String = (platform == PLATFORM_FACEBOOK) ? "fb" : "my";
			flashVars += "&src=" + src; 
			trace("2 FLASHVAR: " + flashVars);
			
			if (ids != null && ids.length==3)
			{
				artistId = ids[1];
				widgetId = ids[2];
			}
			
			var gidgetURL : String = parseGidgetId(wid, artistName, baseurl, env, flashVars);
			if (gidgetURL)
			{
				gidgetURL = encodeURIComponent(gidgetURL);
			}
			
			if (platform == PLATFORM_FACEBOOK) {
				
				targetURL = "http://www.facebook.com/sharer.php?u=";
				share_type = "facebook";
			}else{
				
				targetURL = "http://www.myspace.com/Modules/PostTo/Pages/?u=";
				share_type = "myspace";
				
			}
							
			generateAwesmAndLaunch(gidgetURL,platform, targetURL, api_key, {parent_awesm: awesmParentId, share_type : share_type, create_type : create_type, user_id : artistId, notes: widgetId});			
		}
		
//		/**
//		 * Need to call gidget.php to make Facebook work properly.  It is located at 
//		 * http://share.topspin.net/ 
//		 * @param wid = widget_id
//		 * 
//		 */		
//		public static function shareFacebook(wid : String, artistName : String, baseurl : String, awesmParentId : String = null, 
//											create_type : String = "topspin_api", env : String = null, 
//											api_key : String = null, flashVars: String = null) : void { 
//			
//			trace("FACEBOOK baseurl : " + baseurl);
//			var gidgetURL : String = parseGidgetId(wid, artistName, baseurl, env, flashVars);
//			trace("FACEBOOK :" + gidgetURL);
//			if (gidgetURL)
//			{
//				gidgetURL = encodeURIComponent(gidgetURL);
//			}
//			var targetUrl:String = "http://www.facebook.com/sharer.php?u=";
//			generateAwesmAndLaunch(gidgetURL,PLATFORM_FACEBOOK, targetUrl, api_key, {parent_awesm: awesmParentId, share_type : "facebook", create_type : create_type});			
//		}	
//				
//		public static function shareMySpace(url:String, title:String, embedCodeString:String, awesmParentId : String = null, create_type : String = "api", api_key : String = null):void {
//			var targetUrl:String = "http://www.myspace.com/index.cfm?fuseaction=postto&" + 
//			"t=" + encodeURIComponent(title) + "&c=" + encodeURIComponent(embedCodeString)  + "&u="; //+ encodeURIComponent(url);
//			var t : String = encodeURIComponent(targetUrl);
//			generateAwesmAndLaunch(url,PLATFORM_MYSPACE, t, api_key, {parent_awesm: awesmParentId, share_type : "myspace", create_type : create_type});
//
//		}
		
		public static function shareTwitter(wid: String, url:String, title:String, awesmParentId : String = null, create_type : String = "api", api_key : String = null, tweetHash : String = null) : void {
			
			var eTitle : String = title ;
			//Hack to make sure we replace & with and.  twitter doesn't like it.
			if (title.indexOf("&") != -1) {
				eTitle = StringUtil.replace(title,"&","and");
			}
			var thash : String = (tweetHash && tweetHash!="")? " " + tweetHash : "";
			var e1Title : String = encodeURIComponent( eTitle + thash + " - ");
			var targetUrl:String = "http://twitter.com/home?status=" + encodeURIComponent(e1Title);//+ encodeURIComponent(url);

			var artistId : String = getArtistId(wid);
			var widgetId : String = getArtistId(wid);
			
			generateAwesmAndLaunch(url,PLATFORM_TWITTER, targetUrl, api_key, {parent_awesm: awesmParentId, share_type : "twitter", create_type : create_type, user_id : artistId, notes: widgetId});
		}
		
		public static function shareEmail(wid: String, url:String, title:String, awesmParentId : String = null, create_type : String = "api", api_key : String = null) : void {

			var eTitle : String = title;
			//Hack to make sure we replace & with and.  twitter doesn't like it.
			if (title.indexOf("&") != -1) {
				eTitle = StringUtil.replace(title,"&","and");
			}			

//			var targetUrl:String = "http://twitter.com/home?status=" + encodeURIComponent(eTitle);
			
			var artistId : String = getArtistId(wid);
			var widgetId : String = getArtistId(wid);
			var emailBody : String = encodeURIComponent("Hey, check this out:%0A");
			var targetUrl = "mailto:?subject=" + encodeURIComponent(title) + "&body=";
//			try {
//				trace("SEND TO URL: " + targetUrl);
//				navigateToURL(new URLRequest(targetUrl));
//			}catch(e:Error) {
//				trace("THERE IS AN ERROR SENDING EMAIL");
//			}		
			//getURL(mailto,"_self");			
			generateAwesmAndLaunch(url,PLATFORM_EMAIL, encodeURIComponent(targetUrl), api_key, {parent_awesm: awesmParentId, share_type : "email", create_type : create_type, user_id : artistId, notes: widgetId});
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
		 * return: array[1] = artistId
		 * 		   array[2] = widgetId
		 *  
		 * @param wid
		 * @return 
		 * 
		 */		
		private static function parseIds( wid : String ) : Array
		{
			var artistReg :RegExp =  new RegExp(/artist\/(\d+)\/[\w_]+\/(\d+)/);
			var matches : Array = artistReg.exec(wid);
			
			return matches;
		}
		
		private static function getArtistId( wid ) : String
		{
			var artistId : String = "";
			var ids : Array = parseIds(wid);
			if (ids != null && ids.length==3)
			{
				artistId = ids[1];
			}
			return artistId;
		}
		
		private static function getWidgetId( wid ) : String
		{
			var widgetId : String = "";
			var ids : Array = parseIds(wid);
			if (ids != null && ids.length==3)
			{
				widgetId = ids[2];
			}
			return widgetId;
		}
		
		
	
		


		
		/**
		 * Implements the AwesmService to shorten the length of the url 
		 * @param longURL
		 * @param platform
		 * @param platformURL
		 * 
		 */		
		private static function generateAwesmAndLaunch( longURL : String  , platform : String,  platformURL : String = null, api_key : String = null, params : Object = null) : void
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
		
//		private static function genAwesm() : String{
//			var awsm : String = "http://create.awe.sm/url/share?api_key="+api_key+"&version=1";
//			if (params != null){
//				for (var p : String in params)
//				{
//					if (params[p] != null && params[p] != "null")
//					{
//						awsm += "&" + p + "=" + params[p];
//					}
//				} 
//			}			
//			awsm += "&target=" + longURL;			
//		}
		
		
		
		/**
		 * Calls navigateToUrl to a specified target 
		 * @param target
		 * @param platform
		 * 
		 */		
		private static function launchPlatform( target : String, platform : String) : void
		{
			try {
				trace("FINAL : launchPlatform: \n" + target  + " To: \n" + platform);
				if (platform == PLATFORM_EMAIL) {
//					navigateToURL(new URLRequest(target));
					sendToURL(new URLRequest(target));	
				}else{
					navigateToURL(new URLRequest(target), "_blank");
				}
			} catch (e:Error) {
				trace("Error encoding " + platform + " URL: " + e);
			}			
		}
		
		/**
		 * Construct a valid url to the widget landing page including the child id which gets passed on as a  
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
			var shareURL : String = baseurl + "store/";
			var artistID : String;
			var widgetID : String;
			
			var artist : String = "artist";
			trace("artist name : " + artist, wid);
			shareURL += artist + "/";
			var matches : Array = parseIds(wid);
			if (matches != null && matches.length==3)
			{
				artistID = matches[1];
				widgetID = matches[2];
				trace("artistId : " + artistID);
				trace("widgetId : " + widgetID);
				shareURL += artistID + "?wId="  + widgetID;
				
				if (fv != null)
				{
					shareURL += "&" + fv;						
				}
				trace("PARSEGIGDET: " + shareURL);
				
				return shareURL;
			} else {
				return null;
			}
		}			
						
	}
}