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
	public dynamic class HotRubyRange
	{
		public function each0(recver:Object, args:Array, sf:StackFrame):void 
		{
			if (recver.__instanceVars.exclude_end == this.trueObj) 
			{
				for (var i:int = recver.__instanceVars.first;i < recver.__instanceVars.last; i++) {
					this.invokeMethod(args[0], "yield", [i], sf, 0, false);
					sf.sp--;
				}
			} 
			else 
			{
				for (i = recver.__instanceVars.first; i <= recver.__instanceVars.last; i++) 
				{
					this.invokeMethod(args[0], "yield", [i], sf, 0, false);
					sf.sp--;
				}
			}
		}
		
		public function begin(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver.__instanceVars.first;
		}
		
		public function first(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver.__instanceVars.first;
		}
		
		public function end(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver.__instanceVars.last;
		}
		
		public function last(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver.__instanceVars.last;
		}
		
		public function functionexclude_end(recver:Object, args:Array, sf:StackFrame):int 
		{
			return recver.__instanceVars.exclude_end;
		}
		
		public function length(recver:Object, args:Array, sf:StackFrame):int 
		{
			with (recver.__instanceVars) 
			{
				return (last - first + (exclude_end == this.trueObj ? 0 : 1));
			}
		}
		
		public function size(recver:Object, args:Array, sf:StackFrame):int 
		{
			with (recver.__instanceVars) 
			{
				return (last - first + (exclude_end == this.trueObj ? 0 : 1));
			}
		}
		
		public function step(recver:Object, args:Array, sf:StackFrame):void 
		{
			var step:int;
			var proc:Object;
			if (args.length == 1) 
			{ 
				step = 1;
				proc = args[0];
			} 
			else 
			{
				step = args[0];
				proc = args[1];
			}
			if (recver.__instanceVars.exclude_end == this.trueObj) 
			{
				for (var i:int = recver.__instanceVars.first; i < recver.__instanceVars.last; i += step) 
				{
					this.invokeMethod(proc, "yield", [i], sf, 0, false);
					sf.sp--;
				}
			} 
			else 
			{
				for (i = recver.__instanceVars.first; i <= recver.__instanceVars.last; i += step) 
				{
					this.invokeMethod(proc, "yield", [i], sf, 0, false);
					sf.sp--;
				}
			}
		}
		
		public function HotRubyRange() 
		{
			this["each"] = each0;
			this["functionexclude_end?"] = functionexclude_end;
		}
	}
}