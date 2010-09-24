/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Data class that holds information about an image within the
 * Topspin api.  ImageData are created for slide show functionality
 * 
 *  
 * @copyright	Topspin 
 * @author		amehta@topspinmedia.com
 * @see 		com.topspin.data.model.ITrackData
 * @see 		com.topspin.data.model.VideoData
 *
 */
package com.topspin.api.data.media
{
	import flash.events.EventDispatcher;
		
	public class ImageData //extends EventDispatcher implements ITrackData
	{
		private var _id : String;
		private var _imageURL : String;
		
		//Sizes
		private var _small : String;
		private var _medium : String;
		private var _large : String;
		private var _source : String;
		
		private var _title : String;
		
		
		private var _width : Number;
		private var _height : Number;
		
		public function ImageData( imageXML : XML = null) 
		{
			if (imageXML != null)
			{
				parse(imageXML);
			}
		}
		/*******************************************
		 ** GETTER SETTERS                       
		 ******************************************/
		public function getId() : String
		{
			return _id;
		}
		
		public function get id():String {
			return _id;
		}

		public function set id(o:String):void {
			_id = o;
		}	
		public function get title():String {
			if (_title == null || _title == "null") _title = "";
			return _title;
		}

		public function set title(o:String):void {
			_title = o;
		}		
		public function get imageURL():String {
			return _imageURL;
		}

		public function set imageURL(o:String):void {
			_imageURL = o;
		}		
		public function get width():Number {
			return _width;
		}

		public function set width(o:Number):void {
			_width = o;
		}		
		
		public function get height():Number {
			return _height;
		}

		public function set height(o:Number):void {
			_height = o;
		}		
		
		public function get small():String {
			return _small;
		}
		
		public function set small(o:String):void {
			_small = o;
		}		
		public function get medium():String {
			return _medium;
		}
		
		public function set medium(o:String):void {
			_medium = o;
		}		
		public function get large():String {
			return _large;
		}
		
		public function set large(o:String):void {
			_large = o;
		}		
		public function get source():String {
			return _source;
		}
		
		public function set source(o:String):void {
			_source = o;
		}				
		private function parse( _xml : XML ) : void
		{
			_id = _xml.id;
			_title = _xml .title;
			_small = _xml.small;
			_medium = _xml.medium;
			_large = _xml.large;
			_source = _xml.source;
			
			//default large to the imageURL
			//Changed to source on Setp 23, 2010
			_imageURL = _xml.source;
			
		}
		
	}
}