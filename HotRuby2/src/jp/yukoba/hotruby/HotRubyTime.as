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
	public dynamic class HotRubyTime
	{
		public function initialize(recver:Object, args:Array, sf:StackFrame):void 
		{
			recver.__instanceVars.date = new Date(); 
		}
		
		public function to_s(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return this.createRubyString(recver.__instanceVars.date.toString());
		}
		
		public function to_f(recver:Object, args:Array, sf:StackFrame):Number 
		{
			return recver.__instanceVars.date.getTime() / 1000;
		}
		
		public function HotRubyTime() 
		{
			
		}
	}
}