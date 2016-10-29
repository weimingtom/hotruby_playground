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
	public dynamic class HotRubyObject
	{
		public function equal(recver:Object, args:Array, sf:StackFrame):Object 
		{
			return recver == args[0] ? this.trueObj : this.falseObj;	
		}
		
		public function to_s(recver:Object, args:Array, sf:StackFrame):Object 
		{
			if(typeof(recver) == "number")
				return this.createRubyString(recver.toString());
			else
				return this.createRubyString(recver.__native.toString());
		}
		
		public function puts(recver:Object, args:Array, sf:StackFrame):void 
		{
			if (args.length == 0) 
			{
				HotRuby.printDebug("");
				return;
			}
			for (var i:int = 0; i < args.length; i++) 
			{
				var obj:Object = args[i];
				if (obj == null || obj == this.nilObj) 
				{
					HotRuby.printDebug("nil");
					continue;
				}
				if (typeof(obj) == "number") 
				{
					//FIXME:???
					HotRuby.printDebug(String(obj)); 
					continue;
				}
				if (obj.__className == "String") 
				{
					HotRuby.printDebug(obj.__native);
					continue;
				}
				if (obj.__className == "Array") 
				{
					for (var j:int = 0; j < obj.__native.length; j++) 
					{
						HotRuby.printDebug(obj.__native[j]);
					}
					continue;
				}
				var origSP:int = sf.sp;
				try 
				{
					this.invokeMethod(obj, "to_ary", [], sf, 0, false);
					obj = sf.stack[--sf.sp];
					for (j = 0; j < obj.__native.length; j++) 
					{
						HotRuby.printDebug(obj.__native[j]);
					}
					continue;
				} 
				catch (e:Error) 
				{
					
				}
				sf.sp = origSP;
				this.invokeMethod(obj, "to_s", [], sf, 0, false);
				obj = sf.stack[--sf.sp];
				HotRuby.printDebug(obj.__native);
			}
		}
		
		public function HotRubyObject() 
		{
			this["=="] = equal;
		}
	}
}