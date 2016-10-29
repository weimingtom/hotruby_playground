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
	public dynamic class HotRubyFalseClass
	{
		public function and(recver:Object, args:Array, sf:StackFrame):Boolean 
		{
			return false;
		}
		
		public function or(recver:Object, args:Array, sf:StackFrame):Boolean 
		{
			return args[0] ? true : false;
		}

		public function xor(recver:Object, args:Array, sf:StackFrame):Boolean 
		{
			return args[0] ? true : false;
		}
		
		public function HotRubyFalseClass() 
		{
			this["&"] = and;
			this["|"] = or;
			this["^"] = xor;
		}
		
	}

}