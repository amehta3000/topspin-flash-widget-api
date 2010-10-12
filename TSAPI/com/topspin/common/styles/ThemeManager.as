/**
 * -----------------------------------------------------------------
 * Copyright (c) 2010 Topspin Media, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 *  
 * Static class that will contain the style color and configurations
 * based on the theme name.  Initially it will be white and black.
 * This could grow into various customizations for font names
 * etc.
 * 
 * @copyright	Topspin 
 * @author		amehta@topspinmedia.com
 * 
 */
package com.topspin.common.styles
{
	public class ThemeManager
	{
				
		private static var THEME_BLACK : Object = { 
								linkColor : 0x17CAFB,
								linkOverColor : 0x000000,
								baseColor : 0x000000,
								borderColor : 0x515151,  //0x333333,  
								fontColor : 0xFFFFFF,
								secondaryFontColor : 0xCCCCCC, 
								errColor : 0xFFFFFF,
								playlistItemBgColor1 : 0x515151,
								playlistItemBgColor2 : 0x3D3D3D,
								playlistItemOverColor : 0xAAAAAA, 
								playlistItemClickColor : 0x00AAFF, 
								playlistItemSelectColor : 0x66CCFF, 
								playlistItemFontColor : 0xFFFFFF,
								playlistItemFontOverColor : 0xFFFFFF,
								playlistItemFontSelectColor : 0x000000, 
								playlistItemFontClickColor : 0x000000,
								scrollbarBgColor : 0x515151,
								scrollbarButtonColor : 0xAAAAAA,
								controlIconColor : 0xCACACA,
								controlIconOverColor : 0x17CAFB,
								iconColor : 0x000000,
								iconSelectedColor : 0x797979,
								iconOverColor : 0x17CAFB,
								buttonCanvasBorderColor : 0xFFFFFF,
								buttonCanvasColor : 0xF62DAC,
								buttonUseGradients : true,
								buttonGradientColor : 0x989898,
								buttonHighlightColor : 0xFF0000,
								bgButtonColor : 0x000000,
								bgButtonOverColor : 0x17CAFB,
								loadBarColor : 0x333333,
								bgBarColor : 0x000000, //0xCCCCCC,
								fontOutColor : 0xffffff,
								fontOverColor : 0xffffff};

		private static var THEME_WHITE : Object = { 
								linkColor : 0x333333,
								linkOverColor : 0xFFFFFF,
								baseColor : 0xFFFFFF,
								borderColor : 0xCCCCCC,
								fontColor : 0x333333,
								secondaryFontColor : 0x666666, 
								errColor : 0xFF0033,
								playlistItemBgColor1 : 0x515151,
								playlistItemBgColor2 : 0x3D3D3D,
								playlistItemOverColor : 0xAAAAAA, 
								playlistItemClickColor : 0x00AAFF, 
								playlistItemSelectColor : 0x66CCFF, 
								playlistItemFontColor : 0xFFFFFF,
								playlistItemFontOverColor : 0xFFFFFF,
								playlistItemFontSelectColor : 0x000000, 
								playlistItemFontClickColor : 0x000000,
								scrollbarBgColor : 0x515151,
								scrollbarButtonColor : 0xAAAAAA,
								controlIconOverColor : 0x1E1E1E,
								controlIconColor : 0x333333,
								iconColor : 0x000000,
								iconSelectedColor : 0x797979,
								iconOverColor : 0x333333,
								buttonCanvasBorderColor : 0xFFFFFF,
								buttonCanvasColor : 0xF62DAC,
								buttonUseGradients : true,
								buttonGradientColor : 0x989898,
								buttonHighlightColor : 0xFF0000,	
								bgButtonColor : 0xffffff,
								bgButtonOverColor : 0x333333,
								loadBarColor : 0x515151,
								bgBarColor : 0xFFFFFF, //0x515151,//0xee0000,
								fontOutColor : 0x333333, //0x000000,  // 0x999999
								fontOverColor : 0x333333}; //0x7C7C7C};

		private static var THEME_MONOCHROME : Object = { 
								linkColor : 0xFFFFFF,
								linkOverColor : 0xFFFFFF,
								baseColor : 0x000001,
								borderColor : 0xFFFFFF,
								fontColor : 0xFFFFFF,
								secondaryFontColor : 0xFFFFFF };

		/**
		 * Style map hashed by a common text name. 
		 */				
		private static var StyleMap : Object = {BLACK:THEME_BLACK, 
										 WHITE:THEME_WHITE, MONOCHROME:THEME_MONOCHROME};
		/**
		 * Return a object with various colors defined.
		 * @param num
		 * @return 
		 * 
		 */
		public static function getTheme( theme : String ) : Object
		{
			var obj : Object = StyleMap[theme.toUpperCase()];	
			return obj;
		} 		

	}
}