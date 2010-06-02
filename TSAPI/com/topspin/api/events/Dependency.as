/**
 * -----------------------------------------------------------------
 * Copyright (c) 2008 Topspin, Inc. All Right Reserved.
 * This software is the proprietary information of Topspin Media, Inc.
 * Use is subject to strict licensing terms.
 * -----------------------------------------------------------------
 * 
 * Dependency provides the ability to keep track of external
 * resources that are currently loading.  This enables you to fire off
 * multiple loads of various resources and then wait till all of them have been
 * loaded before proceeding.
 * 
 * Usage:
 * <code>
 *		dependency = new Dependency();
 *		dependency.addEventListener( Event.COMPLETE, handleDependencyComplete );		
 * 		dependency.addDependancy(someObjectOrFunction1);
 * 		dependency.addDependancy(someObjectOrFunction2);
 *  
 * 		//Elsewhere in class, after a dependency has been loaded or complete
 * 		dependency.setLoadDependencyMet(someObjectOrFunction1);
 * 
 * 		//Somewhere else
 * 		dependency.setLoadDependencyMet(someObjectOrFunction2);
 *   
 *		function handleDependencyComplete( event : Event) : void
 * 		{
 * 			dependency.removeEventListener( Event.COMPLETE, handleDependencyComplete );
 * 			dependency = null;
 * 			
 * 			//All dependencies are loaded and handled, you can continue to next steps.
 * 		}
 * </code>
 * 
 * @copyright	Topspin
 * @author		amehta@topspinmedia.com
 * @version 	1.0
 */  
package com.topspin.api.events
{ 
	import flash.events.Event;
	import flash.events.EventDispatcher;
	 
	public class Dependency extends EventDispatcher
	{
		private var dependencies : Array;
		
		public function Dependency()
		{
			dependencies = new Array();
		}
		
		/**
		 * Add a dependency and it's callback function
		 */ 
		public function addDependancy( key : Object ) : void
		{
			dependencies.push( key );
		}
		
		/**
		 * Sets a dependency as loaded
		 */ 
		public function setLoadDependencyMet( key : Object ) : void
		{
			var count : Number = dependencies.length;
			while( count-- )
			{
				if ( dependencies[count] == key )
				{
					dependencies.splice( count, 1 );
					break;
				}
			}
			checkDependenciesLoaded();
		}
		
		/**
		 * Sets a dependency as loaded
		 */ 
		public function checkDependency( key : Object ) : Boolean
		{
			var count : Number = dependencies.length;
			while( count-- )
			{
				if ( dependencies[count] == key )
				{
					return true;
				}
			}
			
			return false;
		}
		
		/**
		 * Checks if all dependencies have been loaded. If so,
		 * dispatch a COMPLETE Event. 
		 */ 
		public function checkDependenciesLoaded() : void
		{
			if( dependencies.length == 0 )
			{
				trace( "Dependency : All Dependencies Loaded" );
				dispatchEvent( new Event( Event.COMPLETE ) );
			} else {
				
				for ( var i : Number = 0; i < dependencies.length; i++ ) 
				{
					trace( "Dependency: Dependency is waiting on : " + dependencies[i] );
				}				
			}
		}

	}
}