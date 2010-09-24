package com.topspin.common.controls
{
	import flash.events.IEventDispatcher;
	import flash.text.TextFormat;
	
	public interface ISlideShow extends IEventDispatcher
	{
		//Sets the ImageData array 
		function setData( imageData : Array) : void;
		
		//Sets the main color of the buttons on the slideshow
		function setLinkColor( linkColor : Number) : void;
		
		//Sets the Size of the slide show
		function setSize( w : Number, h : Number) : void;
		
		//Sets the rate of change between images
		function setChangeRate( seconds : Number ) : void;
		
		//Starts the slideshow
		function startShow() : void;
		
		//Stops or pauses the slideshow
		function stopShow() : void;

		//Refreshs the players of the Slideshow
		function refresh() : void;

		//Sets a flickr icon to show up if flickr images are used
		function setInfoTOS( format : TextFormat, msg : String = null) : void;
		
	}
}