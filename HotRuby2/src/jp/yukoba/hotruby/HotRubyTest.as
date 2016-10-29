/**
 * 内置方法
 * 
 * The license of this source is "Ruby License"
 * 这段代码的许可证为"Ruby许可证"
 */

package jp.yukoba.hotruby 
{
	import flash.display.Sprite;
	/**
	 * ...
	 * @author 
	 */
	public class HotRubyTest extends Sprite
	{
		
		public function HotRubyTest() 
		{
			trace("here");
			var t:test = new test();
			trace(t["str1"]());
		}
	}
}

dynamic class test
{
	public function test()
	{
		this["str1"] = str;
	}
	
	public function str():String
	{
		return "this is str()";
	}
}