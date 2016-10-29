/**
 * the original code is from hotruby:
 * @see http://hotruby.yukoba.jp/
 * @see http://code.google.com/p/hotruby/
 * 
 * The license of this source is "Ruby License"
 */

package jp.yukoba.hotruby
{
	import flash.display.MovieClip;
	
	public class HotRubyFlash //extends MovieClip
	{
		// 测试代码：
		// please run HotRuby for debugging
		public static var src:Array = [
			"YARVInstructionSequence\/SimpleDataFormat",
			1,
			1,
			1,
			{
				"arg_size": 0,
				"local_size": 3,
				"stack_max": 3
			},
			"<main>",
			"plus\\plus.rb",
			"top",
			[
				"a",
				"b"
			],
			0,
			[
				
			],
			[
				1,
				[
					"putobject",
					1
				],
				[
					"setlocal",
					3
				],
				2,
				[
					"putobject",
					2
				],
				[
					"setlocal",
					2
				],
				3,
				[
					"putnil"
				],
				[
					"getlocal",
					3
				],
				[
					"getlocal",
					2
				],
				[
					"send",
					"+",
					1,
					null,
					0,
					null
				],
				[
					"send",
					"puts",
					1,
					null,
					8,
					null
				],
				[
					"leave"
				]
			]
		];
	}
}