/**
 * 全局变量
 * 
 * The license of this source is "Ruby License"
 * 这段代码的许可证为"Ruby许可证"
 */

package jp.yukoba.hotruby 
{
	/**
	 * ...
	 * @author 
	 */
	public dynamic class HotRubyGlobal
	{
		/** nil object */
		public static var nilObj:Object = {
			__className : "NilClass",
			__native : null
		};
		
		/** true object */
		public static var trueObj:Object = {
			__className : "TrueClass",
			__native : true
		};
		
		/** false object */
		public static var falseObj:Object = {
			__className : "FalseClass",
			__native : false
		};
		
		public static var topObject:Object = {
			__className : "Object",
			__native : {}
		};
		
		
		public function HotRubyGlobal() 
		{
			
		}
		
	}

}