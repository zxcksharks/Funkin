package funkin.play.notes.attributes;

import funkin.modding.events.ScriptEvent.NoteScriptEvent;

/**
 * A custom note kind which has custom functionality, preventing notes from being scored in the Results Screen.
 */
class NonScoreableNoteKind extends NoteAttribute
{
  public function new()
  {
    super('non_scoreable', 'Non-scoreable');
  }

  override public function onNoteMiss(event:NoteScriptEvent):Void
  {
    event.note.visible = false;
    event.cancel();
  }
}
