/**
 * 内置方法
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
	public dynamic class HotRubyClasses
	{
		public var ObjectClass:HotRubyObject = new HotRubyObject();
		public var TrueClass:HotRubyTrueClass = new HotRubyTrueClass();
		public var FalseClass:HotRubyFalseClass = new HotRubyFalseClass();
		public var NilClass:Object = new Object();
		public var NativeEnviornment:Object = new Object();
		public var NativeObject:Object = new Object();
		public var NativeClass:Object = new Object();
		public var Proc:HotRubyProc = new HotRubyProc();
		public var Float:HotRubyFloat = new HotRubyFloat();
		public var Integer:HotRubyInteger = new HotRubyInteger();
		public var StringClass:HotRubyString = new HotRubyString();
		public var ArrayClass:HotRubyArray = new HotRubyArray();
		public var Hash:HotRubyHash = new HotRubyHash();
		public var Range:HotRubyRange = new HotRubyRange();
		public var Time:HotRubyTime = new HotRubyTime();
		
		public function HotRubyClasses() 
		{
			this["Object"] = ObjectClass;
			this["String"] = StringClass;
			this["Array"] = ArrayClass;
		}
	}
}