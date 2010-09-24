package com.topspin.api.data
{
	import com.topspin.api.data.media.ImageData;
	
	import flash.events.IEventDispatcher;
	
	public interface ITSWidget extends IEventDispatcher
	{
		
		/*-----------INTITIALIZATION-----------*/
		/**
		 * Returns the version of the widget 
		 * @return String
		 * 
		 */		
		function getVersion() : String;
		/**
		 * Registers widget id with the proxy
		 * Will initiate the loading and parsing of the widget_id
		 * 
		 * @param widget_id String id found in the widget embed code from the Topspin widget spin. 
		 * @param production_mode Boolean : Setting to true enables Topspin logging for in application metrics  
		 * @param event_source : Number - Topspin internal usage for the event logger.  
		 * 						By default, event_source will be com.topsin.api.logging.TSApplications.CUSTOM_API_PLAYER
		 * 						Internal topspin widgets will set this to whatever widget type it is.  
		 * 						Dev partners may want to leave it as -1.
		 * 						@see com.topspin.api.logging.TSApplications 
		 */ 
		function registerWidgetId( widget_id : String, production_mode : Boolean = false, event_source : Number = -1) : void
		/*-----------GENERAL ACCESSORS -----------*/			
		/**
		 * Return the artist id from the campaign 
		 * @return String - artist name
		 * 
		 */		
		function getArtistId( campaign_id : String = null ) : String;
		/**
		 * Return Artist Google Analytics tracking UID for use with
		 * Google Analytics 
		 * @param campaign_id
		 * @return Google Analytics tracking UID
		 * 
		 */
		function getArtistGATrackingId( campaign_id : String = null ) : String;
		/**
		 * Return the Artist's record Label if applicable, used specifically
		 * for COPPA Compliant partners, such as Sony
		 * @return String - artist record label
		 * 
		 */		
		function getArtistLabel( campaign_id : String = null ) : String;			
		/**
		 * Return the artist name from the campaign 
		 * @return String - artist name
		 * 
		 */		
		function getArtistName( campaign_id : String = null ) : String;		
		/**
		 * Returns Artist Awesm API key if applicable, if not, will 
		 * return the Topspin key used to awesmize links. 
		 * @param campaign_id
		 * @return Awesm API key
		 * 
		 */		
		function getAwesmAPIKey( campaign_id : String = null ) : String;		
		/**
		 * Return the campaign if of the widget 
		 * @return String - campaign id
		 * 
		 */		
		function getCampaignId() : String;
		/**
		 * Returns the base embed code of the widget found in the
		 * widget_id XML 
		 * @param campaign_id
		 * @return embed code
		 * 
		 */		
		function getEmbedCode( campaign_id : String = null ) : String;		
		/**
		 * Returns the flickrId specified by the Artist for
		 * slide show images  
		 * @return String 
		 * 
		 */		
		function getFlickrId( campaign_id : String = null  ) : String;		
		/**
		 * Returns the flickrTags specified by the Artist for
		 * slide show images.  Comman delimited.  
		 * @return String 
		 * 
		 */		
		function getFlickrTags(campaign_id : String = null ) : String;		
		/**
		 * Returns main campaign headline message as specified by the Artist 
		 * @return String
		 * 
		 */		
		function getHeadlineMessage( campaign_id : String = null ) : String;
		/**
		 * Returns an artist homepage url if specified in the Artist Account 
		 * @return String
		 * 
		 */		
		function getHomepageURL( campaign_id : String = null ) : String;
		/**
		 * Returns the Offer Button/ Call to Action Label set up in the Manager 
		 * @return - String
		 * 
		 */		
		function getOfferButtonLabel( campaign_id : String = null ) : String;
		/**
		 * Returns the destination URL specified for Streaming and Single Track Player
		 * @return - String
		 * 
		 */		
		function getOfferURL( campaign_id : String = null ) : String;	
		/**
		 * Returns the ITSPlaylist given the campaign id 
		 * @param campaign_id
		 * @return ITSPlaylist object
		 * 
		 */		
		function getPlaylist( campaign_id : String ) : ITSPlaylist;				
		/**
		 * Returns the thumbnail images url of the poster image.  If no poster
		 * image is found, usually the Topspin default logo will be returned.
		 * @return URL string to thumbnail
		 * 
		 */		
		function getPosterThumbnailURL( campaign_id : String = null ) : String;	
		/**
		 * Will pull the ImageData object from the Single display image selected at Spin time. 
		 * @return ImageData object with multiple image sizes
		 * 
		 */
		function getPosterImageData( campaign_id : String = null) : ImageData;
		/**
		 * Will pull the image from the Single display image selected at Spin time. 
		 * Pass in the size string to retrieve a particular size.
		 * @param size:  small || medium || large
		 * @return URL to an image
		 * 
		 */
		function getPosterImageURL( campaign_id : String = null, size : String = "large") : String;				
		/**
		 * Return and Array of ImageData objects found in the package and Single Display Image
		 * included in the spin 
		 * @return Array of urls
		 * 
		 */		
		function getAllProductImageData( campaign_id : String = null) : Array;			
		/**
		 * Given a size, will return all images found in the package and Single Display Image
		 * included in the spin 
		 * @param size: small || medium || large
		 * @return Array of urls
		 * 
		 */		
		function getAllProductImageURLs( campaign_id : String = null, size : String = "large") : Array;	
		/**
		 * Returns the non CDN widget id
		 * @return String actual widget id pointing to app.topspin.net
		 * 
		 */			
		function getWidgetId( campaign_id : String = null ) : String;
		/**
		 * Returns the 3 different types of widgets represented by
		 * the widget_id: 
		 * @return String : bundle_widget || single_track_player_widget || email_for_media
		 * 
		 */		
		function getWidgetType( campaign_id : String = null ) : String;	
		
		/*----------- E4M SPECIFIC -----------*/	
		/**
		 * E4M Specific: 
		 * Returns the confirmation target as specified by the artist. 
		 * @return String
		 * 
		 */				
		function getE4MConfirmationTarget( campaign_id : String = null ) : String;
		/**
		 * E4M Specific: 
		 * Returns the Date of Birth messaging set up by artist
		 * @return String
		 * 
		 */				
		function getE4MDOBMessage( campaign_id : String = null ) : String;		
		/**
		 * E4M Specific: 
		 * COPPA Regulation for minimum age requirement for E4M campaigns
		 * @return minimum age limit, -1 is age does not matter
		 * 
		 */		
		function getE4MMinimumAgeRequirement( campaign_id : String = null ) : Number;
		/**
		 * Returns the Artist created Opt in headline
		 * @param campaign_id
		 * @return String
		 * 
		 */
		function getE4MOptInHeadline( campaign_id : String = null ) : String;
		/**
		 * Returns the Artist created Opt in messaging
		 * @param campaign_id
		 * @return String
		 * 
		 */
		function getE4MOptInMessage( campaign_id : String = null ) : String;
		/**
		 * E4M Specific: 
		 * Returns the Topspin api url to post emails 
		 * @return String url
		 * 
		 */		
		function getE4MPostURL( campaign_id : String = null ) : String; 		
		/**
		 * E4M Specific: 
		 * Returns whether the E4M is an email in exchange for
		 * media or simply and email submission for subscription.
		 * Useful for returning descriptive messaging about the
		 * campaign 
		 * @return Boolean
		 * 
		 */		
		function isE4MEmailOnly( campaign_id : String = null ) : Boolean; 		
		/**
		 * E4M Specific:  
		 * Returns artist specific underage messaging 
		 * @return String - message for underage messaging.
		 * 
		 */		
		function getE4MUnderageMessage( campaign_id : String = null ) : String;		
		/**
		 * E4M Specific: 
		 * Returns whether the E4M submission requires a fan's birthdate or not 
		 * @return Boolean
		 * 
		 */				
		function isE4MDOBRequired( campaign_id : String = null ) : Boolean;
		/**
		 * E4M Specific: 
		 * Retreives the custom link url for E4M
		 * @return String
		 * 
		 */	
		function getCustomLinkUrl(campaign_id : String = null ) : String
		/**
		 * E4M Specific: 
		 * Retreives the custom link label for E4M
		 * @return String
		 * 
		 */			
		function getCustomLinkLabel(campaign_id : String = null ) : String
		/**
		 * Retreives the privacy url for E4M
		 * @return String
		 * 
		 */		
		function getPrivacyUrl( campaign_id : String = null ) : String;					
		/**
		 * Indicates whether sharing is enabled or not, as specificed in the MGR 
		 * @return Boolean
		 * 
		 */		
		function isSharingEnabled( campaign_id : String = null ) : Boolean;			
		/**
		 * Indicates artist specified selection on whether to display images associated with the product in the spin.
		 * Use in conjunction with getProductImageURLs() 
		 * @return Boolean
		 * 
		 */
		function isShowProductImagesEnabled( campaign_id : String = null ) : Boolean;		
		/**
		 * E4M Specific: 
		 * Submit a fan email for an E4M offer.  Before submitting an email, add event listener for
		 * E4MEvent which is dispatched upon success and error.
		 *  
		 * @campaign_id String
		 * @param email
		 * @param confirmation_target (Optional:  If not sent, will use default landing page specified in the MGR)
		 * @param date_of_birth (Optional but should be used in conjunction with isE4MDOBRequired()) 
		 * 
		 */		
		function submitE4MEmail( campaign_id : String, 
								  email : String,  
								  confirmation_target : String = null,
								  date_of_birth : Date = null ) : void;		
		/**
		 * Access to the underlying XML structure this api
		 * uses as the Data Model 
		 * @param campaign_id 
		 * @return XML
		 * 
		 */		
		function widgetData( campaign_id : String = null ) : XML
	}
}