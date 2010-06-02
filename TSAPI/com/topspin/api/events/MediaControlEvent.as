/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Custom event for all Media player UI and control events.
 * 
 *
 * @copyright	Topspin Media
 * @author		amehta@topspinmedia.com
 */  	
package com.topspin.api.events
{
	import flash.events.Event;

	public class MediaControlEvent extends Event
	{
		public static const CONTROL_TYPE : String = "headMediaControl";
		
		public static const PLAY_PAUSE : String = "playPauseMedia";
		public static const PLAY : String = "playMedia";
		public static const PAUSE : String = "pauseMedia";
		public static const STOP : String = "stopMedia";
		public static const FASTFORWARD : String = "ffMedia";
		public static const FASTFORWARD_NEXT : String = "nextMedia";
		public static const REWIND : String = "rwMedia";
		public static const REWIND_PREVIOUS : String = "previousMedia";		
		public static const SCRUB : String = "scrub";
		public static const SCRUBBING : String = "scrubbing";
		public static const BUFFERING : String = "buffering";
		public static const TRACK_INIT : String = "trackInit";

		// Various show methods to dispatch within a player		
		public static const TOGGLE_FULLSCREEN : String = "toggleFullscreen";
		public static const SHOW_DOWNLOAD : String = "show_download_dialog";
		public static const SHOW_EMBED : String = "show_embed_dialog";
		public static const SHOW_SHARE : String = "show_share_dialog";
		public static const SHOW_EMAIL_SHARE : String = "show_email_share_dialog";
		public static const SHOW_PLAYLIST : String = "show_playlist_event";
		public static const SHOW_SLIDESHOW : String = "show_slideshow_event";
		public static const TOGGLE_PLAYLIST : String = "toggle_playlist_event";
		public static const HANDLE_BUY : String = "handle_buy";
		
		public static const SOCIAL_PLATFORM_SHARE : String = "social_platform_share";
		
		
		public var _command : String;
		public var _data : Object;
		
		public function MediaControlEvent(command : String, data : Object = null)
		{
			super(CONTROL_TYPE);
			_command = command;
			_data = data;
		}
		
	}
}