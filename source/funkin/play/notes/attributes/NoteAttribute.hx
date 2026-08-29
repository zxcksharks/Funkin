package funkin.play.notes.attributes;

import funkin.modding.IScriptedClass.INoteScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * Class for note scripts
 */
class NoteAttribute implements INoteScriptedClass
{
  /**
   * The name of the note attribute
   */
  public var name:String;

  /**
   * Custom parameters for the chart editor
   */
  public var params:Array<NoteAttributeParam>;

  /**
   * If this parameter is present in all notes by default.
   */
  public var presentByDefault:Bool;

  public function new(name:String, ?params:Array<NoteAttributeParam>, presentByDefault:Bool = false)
  {
    this.name = name;
    this.params = params ?? [];
    this.presentByDefault = presentByDefault;
  }

  public function toString():String
  {
    return name;
  }

  /**
   * Retrieve all notes with this attribute
   * @param visibleCheck If true, only visible notes will be returned
   * @return Array<NoteSprite>
   */
  function getNotes(visibleCheck:Bool = false):Array<NoteSprite>
  {
    var allNotes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
    return allNotes.filter(function(note:NoteSprite)
    {
      return note != null && note.noteData.attributes.exists(this.name) && (!visibleCheck || note.visible);
    });
  }

  /**
   * Retrieve all notes WITHOUT this attribute
   * @param visibleCheck If true, only visible notes will be returned
   * @return Array<NoteSprite>
   */
  function getOtherNotes(visibleCheck:Bool = false):Array<NoteSprite>
  {
    var allNotes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
    return allNotes.filter(function(note:NoteSprite)
    {
      return note != null && note.noteData.attributes.exists(this.name) && (!visibleCheck || note.visible);
    });
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
  }

  public function onCreate(event:ScriptEvent):Void
  {
  }

  public function onDestroy(event:ScriptEvent):Void
  {
  }

  public function onUpdate(event:UpdateScriptEvent):Void
  {
  }

  public function onNoteIncoming(event:NoteScriptEvent):Void
  {
  }

  public function onNoteHit(event:HitNoteScriptEvent):Void
  {
  }

  public function onNoteMiss(event:NoteScriptEvent):Void
  {
  }

  public function onNoteHoldDrop(event:HoldNoteScriptEvent)
  {
  }
}

/**
 * Abstract for setting the type of the `NoteAttributeParam`
 * This would be an enum but apparently polymod is annoying?
 */
abstract NoteAttributeParamType(String) from String to String
{
  public static final STRING:String = 'String';
  public static final INT:String = 'Int';
  public static final FLOAT:String = 'Float';
}

typedef NoteAttributeParamData =
{
  /**
   * If `min` is null, there is no minimum
   */
  ?min:Null<Float>,
  /**
   * If `max` is null, there is no maximum
   */
  ?max:Null<Float>,
  /**
   * If `step` is null, it will use 1.0
   */
  ?step:Null<Float>,
  /**
   * If `precision` is null, there will be 0 decimal places
   */
  ?precision:Null<Int>,
  ?defaultValue:Dynamic
}

/**
 * Typedef for creating custom parameters in the chart editor
 */
typedef NoteAttributeParam =
{
  name:String,
  type:NoteKindParamType,
  ?data:NoteKindParamData
}
