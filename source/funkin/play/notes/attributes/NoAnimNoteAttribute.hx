package funkin.play.notes.attributes;

/**
 * A custom note kind which has custom functionality, preventing singing animations from playing.
 */
class NoAnimNoteKind extends NoteAttribute
{
  public function new()
  {
    super('noanim', 'No Animation');
  }
}
