package com.topspin.common.preloader
{
	import flash.events.IEventDispatcher;
	
	public interface ILoader extends IEventDispatcher
	{
		function start() : void;
		function stop() : void;	
	
	}
}