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
	public dynamic class HotRubyHash
	{
		public function index(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver.__native[args[0].__native];
		}
		
		public function setindex(recver:Object, args:Array, sf:StackFrame):Object 
		{
			if (!(args[0].__native in recver.__native)) 
			{
				recver.__instanceVars.length++;
			}
			return (recver.__native[args[0].__native] = args[1]);
		}
		
		public function length(recver:Object, args:Array, sf:StackFrame):int 
		{
			return recver.__instanceVars.length;
		}
		
		public function size(recver:Object, args:Array, sf:StackFrame):int 
		{
			return recver.__instanceVars.length++;
		}
		
		public function HotRubyHash() 
		{
			this["[]"] = index;
			this["[]="] = setindex;
		}
		
	}

}