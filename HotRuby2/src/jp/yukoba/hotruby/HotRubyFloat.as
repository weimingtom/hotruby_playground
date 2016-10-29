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
	public dynamic class HotRubyFloat
	{
		
		public function plus(recver:Object, args:Array, sf:StackFrame):Number 
		{
			return Number(recver) + Number(args[0]);
		}

		public function minus(recver:Object, args:Array, sf:StackFrame):Number 
		{
			return Number(recver) - Number(args[0]);
		}

		public function multiple(recver:Object, args:Array, sf:StackFrame):Number 
		{
			return Number(recver) * Number(args[0]);
		}

		public function divide(recver:Object, args:Array, sf:StackFrame):Number 
		{
			return Number(recver) / Number(args[0]);
		}
		
		public function mod(recver:Object, args:Array, sf:StackFrame):Number 
		{
			return Number(recver) % Number(args[0]);
		}
		
		public function compare(recver:Object, args:Array, sf:StackFrame):int 
		{
			if(recver > args[0])
				return 1;
			else if(recver == args[0])
				return 0;
			if(recver < args[0])
				return -1;
			//not reachable
			return -2;
		}
		
		public function less(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver < args[0] ? this.trueObj :  this.falseObj;
		}

		public function greater(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver > args[0] ? this.trueObj :  this.falseObj;
		}
		
		public function less_equal(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver <= args[0] ? this.trueObj :  this.falseObj;
		}

		public function greater_equal(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver >= args[0] ? this.trueObj :  this.falseObj;
		}
		
		public function equal(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver == args[0] ? this.trueObj :  this.falseObj;
		}
		
		public function times(recver:Object, args:Array, sf:StackFrame):void 
		{
			for (var i:int = 0; i < recver; i++) 
			{
				this.invokeMethod(args[0], "yield", [i], sf, 0, false);
				sf.sp--;
			}
		}
		
		public function to_s(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return this.createRubyString(recver.toString());	
		}
		
		public function HotRubyFloat() 
		{
			this["+"] = plus;
			this["-"] = minus;
			this["*"] = multiple;
			this["/"] = divide;
			this["%"] = mod;
			this["<=>"] = compare;
			this["<"] = less;
			this[">"] = greater;
			this["<="] = less_equal;
			this[">="] = greater_equal;
			this["=="] = equal;
		}
	}
}