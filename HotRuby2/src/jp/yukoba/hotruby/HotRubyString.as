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
	public dynamic class HotRubyString
	{
		public function plus(recver:Object, args:Array, sf:StackFrame):Object 
		{
			if(typeof(args[0]) == "object")
				return this.createRubyString(recver.__native + args[0].__native);
			else
				return this.createRubyString(recver.__native + args[0]);
		}
		
		public function multiple(recver:Object, args:Array, sf:StackFrame):Object {
			var ary:Array = new Array(args[0]);
			for (var i:int = 0; i < args[0]; i++) 
			{
				ary[i] = recver.__native;
			}
			return this.createRubyString(ary.join(""));
		}
		
		public function equal(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver.__native == args[0].__native ? this.trueObj : this.falseObj;
		}
		
		public function index(recver:Object, args:Array, sf:StackFrame):Object 
		{
			if (args.length == 1 && typeof(args[0]) == "number") 
			{
				var no:int = args[0];
				if(no < 0) 
					no = recver.__native.length + no;
				if(no < 0 || no >= recver.__native.length)
					return null;
				return recver.__native.charCodeAt(no);
			} 
			else if (args.length == 2 && typeof(args[0]) == "number" && typeof(args[1]) == "number") 
			{
				var start:int = args[0];
				if(start < 0) 
					start = recver.__native.length + start;
				if(start < 0 || start >= recver.__native.length)
					return null;
				if(args[1] < 0 || start + args[1] > recver.__native.length)
					return null;
				return this.createRubyString(recver.__native.substr(start, args[1]));
			} 
			else 
			{
				throw "Unsupported String[]";
			}
		}
		
		public function HotRubyString() 
		{
			this["+"] = plus;
			this["*"] = multiple;
			this["=="] = equal;
			this["[]"] = index;
		}
	}
}