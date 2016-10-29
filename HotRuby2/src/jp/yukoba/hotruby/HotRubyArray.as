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
	public dynamic class HotRubyArray
	{
		public function length(recver:Object, args:Array, sf:StackFrame):int 
		{
			return recver.__native.length;
		}
		
		public function size(recver:Object, args:Array, sf:StackFrame):int 
		{
			return recver.__native.length;
		}
		
		public function index(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver.__native[args[0]];
		}
		
		public function setindex(recver:Object, args:Array, sf:StackFrame):void 
		{
			recver.__native[args[0]] = args[1];
		}
		
		public function join(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return this.createRubyString(recver.__native.join(args[0]));
		}
		
		public function to_s(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return this.createRubyString(recver.__native.join(args[0]));
		}
		
		public function HotRubyArray() 
		{
			this["[]"] = index;
			this["[]="] = setindex;
		}
	}
}