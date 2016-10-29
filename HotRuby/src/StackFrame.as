package  
{
	import flash.text.engine.Kerning;

	/**
	 * StackFrame
     * @class
     * @construtor
     */
	public final class StackFrame
	{	
		/** 
		 * Stack Pointer
		 * @type Number 
		 */
		public var sp:Number = 0;
		
		/** 
		 * Local Variables
		 * @type Array 
		 */
		public var localVars:Array = [];
		
		/** 
		 * Stack 
		 * @type Array 
		 */
		public var stack:Array = [];
		
		/** 
		 * Current class to define methods
		 * @type Object 
		 */
		public var classObj:Object = null;
		
		/** 
		 * Current method name
		 * @type String 
		 */
		public var methodName:String = "";
		
		/** 
		 * Current line no
		 * @type Number 
		 */
		public var lineNo:Number = 0;
		
		/** 
		 * File name
		 * @type String 
		 */
		public var fileName:String = "";
		
		/** 
		 * self
		 * @type Object 
		 */
		public var self:Object = null;
		
		/** 
		 * Parent StackFrame
		 * @type HotRuby.StackFrame 
		 */
		public var parentStackFrame:StackFrame = null;
		
		/** 
		 * Is Proc(Block)
		 * @type boolean 
		 */
		public var isProc:Boolean = false;
		
		/** 
		 * Object Specific class
		 * @type Object 
		 */
		public var cbaseObj:Object = null;
	}
}