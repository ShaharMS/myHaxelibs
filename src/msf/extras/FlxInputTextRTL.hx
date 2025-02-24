package msf.extras;
#if js
import haxe.Timer;
#else
import lime.ui.KeyModifier;
import lime.ui.KeyCode;
import openfl.Lib;
import openfl.events.KeyboardEvent;
#end
import flixel.addons.ui.FlxInputText;
import flixel.util.FlxColor;
import flixel.FlxG;

using flixel.util.FlxStringUtil;
#if js
/**
 * FlxInputText with support for RTL languages.
 */
class FlxInputTextRTL extends FlxInputText
{

	var pressTime:Int = 0;

	var __rtlOffset:Int = 0;
	/**
	 * the input with which were going to capture key presses.
	 */
	var textInput:js.html.InputElement;

	var keyCode:Int;
	/**
	 * @param	X				The X position of the text.
	 * @param	Y				The Y position of the text.
	 * @param	Width			The width of the text object (height is determined automatically).
	 * @param	Text			The actual text you would like to display initially.
	 * @param   size			Initial size of the font
	 * @param	TextColor		The color of the text
	 * @param	BackgroundColor	The color of the background (FlxColor.TRANSPARENT for no background color)
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 */
	public function new(X:Float = 0, Y:Float = 0, Width:Int = 150, ?Text:String, size:Int = 8, TextColor:Int = FlxColor.BLACK,
			BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true)
	{
		super(X, Y, Width, Text, size);
		wordWrap = true;
		getInput();
	}
	override function set_hasFocus(newFocus:Bool):Bool
	{
		if (newFocus)
		{
			if (hasFocus != newFocus)
			{
				_caretTimer = new flixel.util.FlxTimer().start(0.5, toggleCaret, 0);
				caret.visible = true;
				caretIndex = 0;
			}
		}
		else
		{
			// Graphics
			caret.visible = false;
			if (_caretTimer != null)
			{
				_caretTimer.cancel();
			}
		}

		if (newFocus != hasFocus)
		{
			calcFrame();
		}
		return hasFocus = newFocus;
	}
	/**
	   The original `onKeyDown` from `FlxInputText` is replaced with four functions - 
	  
	  | Function | Job |
	  | --- | --- |
	  | **`getInput()`** | used to set up the input element with which were going to listen to text input |
	  | **`updateInput()`** | called every frame, selects the input element to continue listening for text input |
	  | **`typeChar(String)`** | called when special keys (spacebar, backspace...) are pressed since `getInput()` can't listen to those |
	  | **`update(Float)`** | called every frame, checks if one of the special keys (spacebar, backspace...) is pressed to call `typeChar(String)` |
	 **/
	override function onKeyDown(e:flash.events.KeyboardEvent) {}

	/**
	 * Exists to set up the input element, with which
	 * were going to listen for text input
	 */
	function getInput()
	{
		textInput = cast js.Browser.document.createElement('input');
		textInput.type = 'text';
		textInput.style.position = 'absolute';
		textInput.style.opacity = "0";
		textInput.style.color = "transparent";
		textInput.value = String.fromCharCode(127);
		textInput.style.left = "0px";
		textInput.style.top = "50%";
		untyped (textInput.style).pointerEvents = 'none';
		textInput.style.zIndex = "-10000000";
		js.Browser.document.body.appendChild(textInput);
		textInput.addEventListener('input', (e:js.html.InputEvent) ->
		{
			if (caretIndex < 0) caretIndex = 0;
			if (textInput.value.length > 0 && (maxLength == 0 || (text.length + textInput.value.length) < maxLength)) {
				text = insertSubstring(text, textInput.value, caretIndex);
				caretIndex++;
				text = text;
			}
			
		}, true);
	}

	/**
	 * Were getting the text from an invisible input text and it isnt openFL/flixel related.
	 * we have to keep it selected
	 */
	function updateFocus()
	{
		textInput.focus();
		textInput.select();
	}

	function typeChar(?char:String = "") {
		if (char == "bsp") {
			caretIndex--;
			text = text.substring(0, caretIndex);
			onChange(FlxInputText.BACKSPACE_ACTION);
			text = text;
			Timer.delay(() -> {
				var t:Timer;
				t = new Timer(16);
				t.run = () -> {
					if(FlxG.keys.pressed.BACKSPACE) {
						caretIndex--;
						text = text.substring(0, caretIndex);
						onChange(FlxInputText.BACKSPACE_ACTION);
						text = text;
					} else t.stop();
				};
			}, 500);
		}
		else if (char == "del") {
			if (text.length > 0 && caretIndex < text.length)
			{
				text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
				onChange(FlxInputText.DELETE_ACTION);
				text = text;
				Timer.delay(() -> {
					var t:Timer;
					t = new Timer(16);
					t.run = () -> {
						if(FlxG.keys.pressed.DELETE) {
							text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
							onChange(FlxInputText.DELETE_ACTION);
							text = text;
						} else t.stop();
					};
				}, 500);
			}
		}
		else if (char == " ") {
			if (char.length > 0 && (maxLength == 0 || (text.length + char.length) < maxLength)) {
				text = insertSubstring(text, char, caretIndex);
				caretIndex++;
				text = text;
			}			
			Timer.delay(() -> {
				var t:Timer;
				t = new Timer(16);
				t.run = () -> {
					if(FlxG.keys.pressed.BACKSPACE) {
						if (char.length > 0 && (maxLength == 0 || (text.length + char.length) < maxLength)) {
							text = insertSubstring(text, char, caretIndex);
							caretIndex++;
							text = text;
						}						
					} else t.stop();
				};
			}, 500);
		}
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateFocus();
		if (hasFocus) {
			if (FlxG.keys.justPressed.SPACE) typeChar(" ");
			if (FlxG.keys.justPressed.BACKSPACE) typeChar("bsp");
			if (FlxG.keys.justPressed.DELETE) typeChar("del"); 
			if (FlxG.keys.justPressed.LEFT) if (caretIndex > 0) caretIndex --;
			if (FlxG.keys.justPressed.RIGHT) if (caretIndex < text.length) caretIndex ++;
			if (FlxG.keys.justPressed.HOME) caretIndex = 0;
			if (FlxG.keys.justPressed.END) caretIndex = text.length;
		}
	}
}
#else
/**
 * Reguar FlxInputText with extended support for:
 * - All languages
 * - Bi-directional text
 * - Multilne (Almost!)
 */
class FlxInputTextRTL extends FlxInputText 
{

	/**
	 * Creates a new multi-line text input with support for all languages - both RTL and LTR.
	 * 
	 * @param	X				The X position of the text.
	 * @param	Y				The Y position of the text.
	 * @param	Width			The width of the text object (height is determined automatically).
	 * @param	Text			The actual text you would like to display initially.
	 * @param   size			Initial size of the font
	 * @param	TextColor		The color of the text
	 * @param	BackgroundColor	The color of the background (FlxColor.TRANSPARENT for no background color)
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 */
	public function new(X:Float = 0, Y:Float = 0, Width:Int = 150, ?Text:String, size:Int = 8,startEnglish:Bool = true, TextColor:Int = FlxColor.BLACK, BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true) {
		super(X, Y, Width, Text, size, TextColor, BackgroundColor, EmbeddedFont);
		wordWrap = true;

		Lib.application.window.onTextInput.add(regularKeysDown, false, 1);
		Lib.application.window.onKeyDown.add(specialKeysDown, false, 2);
	}

	override function set_hasFocus(newFocus:Bool):Bool {
		if (newFocus) { //text input is selected
			if (hasFocus != newFocus) { //text input wasnt selected before this selection
				_caretTimer = new flixel.util.FlxTimer().start(0.5, toggleCaret, 0);
				caret.visible = true;
				caretIndex = text.length;
				
			}
		} else { //text input isnt selected, update the caret's graphic to show that
			caret.visible = false;
			if (_caretTimer != null) {
				_caretTimer.cancel();
			}
		}

		if (newFocus != hasFocus) { //if the status has changed, redraw the current frame
			calcFrame();
		}
		return hasFocus = newFocus;
	}
	
	/**
	   The original `onKeyDown` from `FlxInputText` is replaced with two functions - 
	  
	  | Function | Job |
	  | --- | --- |
	  | **`specialKeysDown(KeyCode, KeyModifier)`** | used to get "editing" keys (backspace, capslock, arrow keys...) |
	  | **`regularKeysDown(String)`** | used to get "input" keys - regular letters of all languages and directions |
	 **/
	override function onKeyDown(e:KeyboardEvent) {}

	/**
	 * This function replaces `onKeyDown` with support for `delete`, `backspace`, arrow keys and more.
	 * `specialKeysDown()` is one of two functions, and is utilizing `window.onKeyDown` to get button
	 * presses, so pay attention to that when overriding.
	 * 
	 * @param key the keycode of the current key that was presses according to lime's `window.onKeyDown`
	 * @param modifier information about modifying buttons and if theyre on or not - `ctrl`, `shift`, `alt`, `capslock`...
	 */
	function specialKeysDown(key:KeyCode, modifier:KeyModifier) {
		//if the user didnt intend to edit the text, dont do anything
		if (!hasFocus) return;
		//those keys break the caret and places it in caretIndex -1
		if (modifier.altKey || modifier.shiftKey || modifier.ctrlKey || modifier.metaKey) return;
		//fix the caret if its broken
		if (caretIndex < 0) caretIndex = 0;

		//arrow keys (LEFT / RIGHT)
		if (~/1073741904|1073741903/.match(key + ""))
		{
			// left arrow
			if (key == 1073741904)
			{
				if (caretIndex > 0) {
					caretIndex--;
				}
			}
			else // right arrow
			{
				if (caretIndex < text.length) {
					caretIndex++;
				}
			}
		}
		// backspace key
		else if (key == 8)
		{
			if (caretIndex > 0)
			{
				if (FlxCharMaps.rtlLetterArray.contains(text.charAt(caretIndex + 1))
					|| FlxCharMaps.rtlLetterArray.contains(text.charAt(caretIndex))) {
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
				} else {
					caretIndex--;
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
				}
				
				onChange(FlxInputText.BACKSPACE_ACTION);
			}
		}
		// delete key
		else if (key == 127)
		{
			if (text.length > 0 && caretIndex < text.length)
			{
				if (FlxCharMaps.rtlLetterArray.contains(text.charAt(caretIndex + 1)) || FlxCharMaps.rtlLetterArray.contains(text.charAt(caretIndex))) {
					text = text.substring(0, caretIndex - 1) + text.substring(caretIndex);
					caretIndex--;
				} else {
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
				}
				onChange(FlxInputText.DELETE_ACTION);
				text = text;
			}
		}
		// end key
		else if (key == 36)
		{
			caretIndex = text.length;
			text = text; // forces scroll update
		}
		// home key
		else if (key == 35)
		{
			caretIndex = 0;
			text = text; // forces scroll update
		}
	}

	/**
	 * This function replaces `onKeyDown` with support for RTL & LTR letter input
	 * `regularKeysDown()` is one of two functions, and is utilizing `window.onKeyDown` to get button
	 * presses, so pay attention to that when overriding.
	 * @param letter the letter outputted from the current key-press according to lime's `window.onTextInput`
	 */
	function regularKeysDown(letter:String) {
		// if the user didnt intend to edit the text, dont do anything
		if (!hasFocus) return
		//if the caret is broken for some reason, fix it
		if (caretIndex < 0) caretIndex = 0;
		//set up the letter - remove null chars, add rtl mark to letters from RTL languages
		var t:String = "";
		if (letter != null) {
			if (FlxCharMaps.rtlLetterArray.contains(letter)) { t = "‏" + letter;}
			else t = letter;
		} else "";

		if (t.length > 0 && (maxLength == 0 || (text.length + t.length) < maxLength))
		{
			caretIndex++;
			
			text = insertSubstring(text, t, caretIndex - 1);

			text = text; // forces scroll update
			
			onChange(FlxInputText.INPUT_ACTION);
		}
	}
}
#end