package funkin.play.notes.notekind;

import funkin.data.song.SongData.SongNoteData;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.play.notes.attributes.ScriptedNoteAttribute;
import funkin.play.notes.attributes.NoteAttribute.NoteAttributeParam;
import funkin.util.macro.ClassMacro;

class NoteKindManager
{
  /**
   * Every built-in note kind class must be added to this list.
   * Thankfully, with the power of `ClassMacro`, this is done automatically.
   */
  static final BUILTIN_ATTRIBUTES:List<Class<NoteKind>> = ClassMacro.listSubclassesOf(NoteKind);

  /**
   * A map of all note kinds, keyed by their name.
   * This is used to retrieve note kinds by their name.
   */
  public static var noteAttributes:Map<String, NoteKind> = [];

  /**
   * An array of all note attributes present by default on notes.
   */
  public static var defaultNoteAttributes:Array<String> = [];

  /**
   * Retrieve a note kind by its name.
   * @param noteKind The name of the note kind.
   * @return The note kind, or null if it doesn't exist.
   */
  public static function getNoteAttribute(?attribute:String):Null<NoteKind>
  {
    if (attribute == null) return null;
    return noteAttributes.get(attribute);
  }

  /**
   * Retrieve a list of known valid note kinds.
   * @return A list of note kinds
   */
  public static function listNoteAttributes():Array<String>
  {
    return noteAttributes.keyValues();
  }

  /**
   * Initialize custom behavior for note kinds.
   */
  public static function initialize():Void
  {
    clearAttributeCache();

    //
    // BASE GAME EVENTS
    //
    registerBaseAttributes();
    registerScriptedAttributes();
  }

  /**
   * Register the hard-coded note attributes.
   */
  public static function registerBaseAttributes():Void
  {
    trace('Instantiating ${BUILTIN_ATTRIBUTES.length} built-in note attributes...');
    for (noteAttributeCls in BUILTIN_ATTRIBUTES)
    {
      var noteAttributeClsName:String = Type.getClassName(noteAttributeCls);
      if (noteAttributeClsName == 'funkin.play.notes.attributes.NoteAttribute'
        || noteAttributeClsName == 'funkin.play.notes.attributes.ScriptedNoteAttribute') continue;

      var attribute:NoteAttribute = Type.createInstance(noteAttributeCls, ['UNKNOWN']);

      if (attribute != null)
      {
        trace(' Loaded built-in note attribute: ${attribute.name}');
        noteAttributes.set(attribute.name, attribute);
        if (attribute.presentByDefault) defaultNoteAttributes.push(attribute.name);
      }
      else
      {
        trace(' Failed to load built-in note attribute: ${noteAttributeClsName}');
      }
    }
  }

  /**
   * Register the scripted note attributes provided by mods.
   */
  public static function registerScriptedAttributes():Void
  {
    var scriptedClassName:Array<String> = ScriptedNoteAttribute.listScriptClasses();
    if (scriptedClassName.length > 0)
    {
      trace('Instantiating ${scriptedClassName.length} scripted note attribute(s)...');
      for (scriptedClass in scriptedClassName)
      {
        try
        {
          var script:NoteAttribute = ScriptedNoteAttribute.scriptInit(scriptedClass, 'unknown');
          trace(' Initialized scripted note attribute: ${script.noteKind}');
          noteAttributes.set(script.name, script);
          if (script.presentByDefault) defaultNoteAttributes.push(script.name);
        }
        catch (e)
        {
          trace(' FAILED to instantiate scripted note attribute: ${scriptedClass}');
          trace(e);
        }
      }
    }
  }

  /**
   * Calls the given event for note attribute scripts
   * @param event The event
   */
  public static function callEvent(event:ScriptEvent):Void
  {
    // if it is a note script event,
    // then only call the event for the specific note attribute script
    if (Std.isOfType(event, NoteScriptEvent))
    {
      var noteEvent:NoteScriptEvent = cast(event, NoteScriptEvent);

      var attributes:Array<String> = noteEvent?.note?.attributes;

      if (attributes != null)
      {
        for (attribute in attributes)
        {
          ScriptEventDispatcher.callEvent(attribute, event);
        }
      }
    }
    else // call the event for all note kind scripts
    {
      for (attribute in noteAttributes.iterator())
      {
        ScriptEventDispatcher.callEvent(attribute, event);
      }
    }
  }

  /**
   * Retrive custom params of the given note attribute
   * @param noteKind Name of the note attribute
   * @return Array<NoteAttributeParam>
   */
  public static function getParams(attribute:Null<String>):Array<NoteAttributeParam>
  {
    if (attribute == null)
    {
      return [];
    }

    return noteAttributes.get(attribute)?.params ?? [];
  }

  /**
   * Clear the note kind cache.
   * Be sure to register the note kinds again before trying to use them.
   */
  public static function clearAttributeCache():Void
  {
    noteAttributes.clear();
  }
}
